import {createServer} from 'node:http';
import {pathToFileURL} from 'node:url';
import {createHash} from 'node:crypto';
import {createReputationLookup} from './reputation.mjs';
import {createAiScanner, isAiConfigured} from './ai_scan.mjs';

function readBody(req, limit = 8192) {
  return new Promise((resolve,reject) => {
    let size = 0;
    let excessive = false;
    const chunks = [];
    req.on('data', chunk => {
      size += chunk.length;
      if (size > limit) {
        if (!excessive) { excessive = true; chunks.length = 0; reject({status:413}); }
      } else if (!excessive) chunks.push(chunk);
    });
    req.on('end', () => { if (!excessive) resolve(Buffer.concat(chunks).toString('utf8')); });
    req.on('error', () => reject({status:400}));
    req.on('aborted', () => reject({status:400}));
  });
}

export function createGateway({lookup = createReputationLookup({apiKey:process.env.SAFE_BROWSING_API_KEY}),
  configured = Boolean(process.env.SAFE_BROWSING_API_KEY), allowedOrigin = process.env.ALLOWED_ORIGIN ?? '',
  scanAi = createAiScanner({apiKey:process.env.GROQ_API_KEY,model:process.env.GROQ_MODEL}),
  aiConfigured = isAiConfigured(process.env.GROQ_API_KEY,process.env.GROQ_MODEL),
  aiDailyLimit = Number(process.env.AI_DAILY_LIMIT ?? 50)} = {}) {
  const rates = new Map();
  const pending = new Map();
  let active = 0;
  let aiActive = 0, aiDay = '', aiCalls = 0;
  const server = createServer(async (req,res) => {
    const send = (status, body) => {
      if (res.writableEnded || res.destroyed) return;
      res.writeHead(status, {'Content-Type':'application/json; charset=utf-8',
        'Cache-Control':'no-store','X-Content-Type-Options':'nosniff'});
      res.end(JSON.stringify(body));
    };
    const origin = req.headers.origin;
    if (origin) {
      if (origin !== allowedOrigin) { send(403,{error:'origin_not_allowed'}); return; }
      res.setHeader('Access-Control-Allow-Origin',allowedOrigin);
      res.setHeader('Vary','Origin');
      res.setHeader('Access-Control-Allow-Methods','GET, POST, OPTIONS');
      res.setHeader('Access-Control-Allow-Headers','Content-Type, Idempotency-Key');
    }
    if (req.method === 'OPTIONS') { res.writeHead(204); res.end(); return; }
    if (req.url === '/v1/capabilities' && req.method === 'GET') {
      send(200,{urlReputation:configured,aiScanning:aiConfigured}); return;
    }
    const isAi = req.url === '/v1/ai-scan';
    if (!isAi && req.url !== '/v1/link-check') { send(404,{error:'not_found'}); return; }
    if (req.method !== 'POST') { res.setHeader('Allow','POST'); send(405,{error:'method_not_allowed'}); return; }
    const now = Date.now();
    for (const [key,value] of rates) if (value.reset <= now) rates.delete(key);
    // Use the actual socket peer; a public deployment must configure trusted ingress limits.
    const ip = `${isAi ? 'ai' : 'url'}:${req.socket.remoteAddress ?? 'unknown'}`;
    if (!rates.has(ip) && rates.size >= 10000) { send(429,{error:'rate_limited'}); return; }
    const rate = rates.get(ip) ?? {count:0,reset:now+60000};
    rate.count++; rates.set(ip,rate);
    if (rate.count > (isAi ? 10 : 30)) { res.setHeader('Retry-After',String(Math.ceil((rate.reset-now)/1000))); send(429,{error:'rate_limited'}); return; }
    if (!String(req.headers['content-type'] ?? '').startsWith('application/json')) { send(415,{error:'json_required'}); return; }
    try {
      const body = JSON.parse(await readBody(req,isAi ? 65536 : 8192));
      if (isAi) {
        if (!body || typeof body !== 'object' || Array.isArray(body) || Object.keys(body).length !== 2 || typeof body.text !== 'string' || !body.text.trim() || [...body.text].length > 10000 || !body.text.isWellFormed() || !['en','fil'].includes(body.responseLanguage)) { send(400,{error:'invalid_input'}); return; }
        const key = req.headers['idempotency-key'];
        if (typeof key !== 'string' || !/^[A-Za-z0-9_-]{8,100}$/.test(key)) { send(400,{error:'invalid_submission'}); return; }
        if (!aiConfigured) { send(503,{error:'unavailable'}); return; }
        const id = `${ip}:${key}`;
        const fingerprint = createHash('sha256').update(JSON.stringify({text:body.text,responseLanguage:body.responseLanguage})).digest('hex');
        let entry = pending.get(id);
        if (entry && entry.fingerprint !== fingerprint) { send(409,{error:'submission_conflict'}); return; }
        if (!entry) {
          const day = new Date().toISOString().slice(0,10);
          if (aiDay !== day) { aiDay = day; aiCalls = 0; }
          if (res.destroyed) return;
          if (aiActive >= 4 || !Number.isSafeInteger(aiDailyLimit) || aiDailyLimit < 1 || aiCalls >= aiDailyLimit) { send(503,{error:'unavailable'}); return; }
          aiCalls++; aiActive++;
          const controller = new AbortController();
          entry = {fingerprint,controller,clients:0};
          pending.set(id,entry);
          entry.promise = Promise.resolve().then(()=>scanAi(body,controller.signal)).catch(()=>({state:'unavailable'})).finally(()=>{aiActive--;pending.delete(id);});
        }
        const current = entry;
        current.clients++;
        let attached = true;
        const disconnect = () => {
          if (!attached) return;
          attached = false;
          if (--current.clients === 0 && !res.writableEnded) current.controller.abort();
        };
        res.once('close',disconnect);
        const result = await current.promise;
        res.removeListener('close',disconnect);
        if (attached) { attached = false; current.clients--; }
        send(result.state === 'unavailable' ? 503 : 200,result);
        return;
      }
      if (!body || typeof body !== 'object' || Array.isArray(body) ||
          Object.keys(body).length !== 1 || typeof body.url !== 'string' || body.url.length > 2048) {
        send(400,{error:'invalid_url'}); return;
      }
      let url;
      try { url = new URL(body.url); } catch (_) { send(400,{error:'invalid_url'}); return; }
      if (!['http:','https:'].includes(url.protocol) || !url.hostname || /\s/.test(body.url)) {
        send(400,{error:'invalid_url'}); return;
      }
      if (!configured || active >= 8) { send(503,{error:'unavailable'}); return; }
      active++;
      try {
        const result = await lookup(url.href);
        send(result.status === 'unavailable' ? 503 : 200,result);
      } finally { active--; }
    } catch (error) { send(error?.status === 413 ? 413 : 400,{error:error?.status === 413 ? 'request_too_large' : 'invalid_request'}); }
  });
  server.requestTimeout = 10000;
  server.headersTimeout = 10000;
  return server;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const port = Number(process.env.PORT ?? 8787);
  if (!Number.isInteger(port) || port < 1 || port > 65535) throw new Error('Invalid PORT');
  createGateway().listen(port,'127.0.0.1',() => {
    console.log(`Usisa gateway listening on http://127.0.0.1:${port}; URL checks ${process.env.SAFE_BROWSING_API_KEY ? 'configured' : 'unavailable'}`);
  });
}
