import {createServer} from 'node:http';
import {pathToFileURL} from 'node:url';
import {createReputationLookup} from './reputation.mjs';

function readBody(req) {
  return new Promise((resolve,reject) => {
    let size = 0;
    let excessive = false;
    const chunks = [];
    req.on('data', chunk => {
      size += chunk.length;
      if (size > 8192) {
        if (!excessive) { excessive = true; chunks.length = 0; reject({status:413}); }
      } else if (!excessive) chunks.push(chunk);
    });
    req.on('end', () => { if (!excessive) resolve(Buffer.concat(chunks).toString('utf8')); });
    req.on('error', () => reject({status:400}));
    req.on('aborted', () => reject({status:400}));
  });
}

export function createGateway({lookup = createReputationLookup({apiKey:process.env.WEB_RISK_API_KEY}),
  configured = Boolean(process.env.WEB_RISK_API_KEY), allowedOrigin = process.env.ALLOWED_ORIGIN ?? ''} = {}) {
  const rates = new Map();
  let active = 0;
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
      res.setHeader('Access-Control-Allow-Headers','Content-Type');
    }
    if (req.method === 'OPTIONS') { res.writeHead(204); res.end(); return; }
    if (req.url === '/v1/capabilities' && req.method === 'GET') {
      send(200,{urlReputation:configured,aiScanning:false}); return;
    }
    if (req.url !== '/v1/link-check') { send(404,{error:'not_found'}); return; }
    if (req.method !== 'POST') { res.setHeader('Allow','POST'); send(405,{error:'method_not_allowed'}); return; }
    const now = Date.now();
    for (const [key,value] of rates) if (value.reset <= now) rates.delete(key);
    // Use the actual socket peer; a public deployment must configure trusted ingress limits.
    const ip = req.socket.remoteAddress ?? 'unknown';
    if (!rates.has(ip) && rates.size >= 10000) { send(429,{error:'rate_limited'}); return; }
    const rate = rates.get(ip) ?? {count:0,reset:now+60000};
    rate.count++; rates.set(ip,rate);
    if (rate.count > 30) { res.setHeader('Retry-After',String(Math.ceil((rate.reset-now)/1000))); send(429,{error:'rate_limited'}); return; }
    if (!String(req.headers['content-type'] ?? '').startsWith('application/json')) { send(415,{error:'json_required'}); return; }
    try {
      const body = JSON.parse(await readBody(req));
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
    console.log(`Usisa gateway listening on http://127.0.0.1:${port}; URL checks ${process.env.WEB_RISK_API_KEY ? 'configured' : 'unavailable'}`);
  });
}
