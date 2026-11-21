const allowedThreats = new Set(['MALWARE', 'SOCIAL_ENGINEERING', 'UNWANTED_SOFTWARE']);
const provider = 'Google Safe Browsing';

export function createReputationLookup({apiKey, fetchImpl = fetch} = {}) {
  // Checks a batch of URLs in one call; matches must name a URL that was sent.
  return async function lookup(urls) {
    const sent = new Set(urls);
    const unavailable = () => ({status:'unavailable', threatTypes:[], matches:{}, checkedAt:null,
      expiresAt:null, provider});
    if (!apiKey) return unavailable();
    try {
      const url = new URL('https://safebrowsing.googleapis.com/v4/threatMatches:find');
      url.searchParams.set('key', apiKey);
      const response = await fetchImpl(url, {
        method:'POST', headers:{'Content-Type':'application/json'},
        body:JSON.stringify({client:{clientId:'usisa',clientVersion:'1.0.0'},threatInfo:{
          threatTypes:[...allowedThreats],platformTypes:['ANY_PLATFORM'],
          threatEntryTypes:['URL'],threatEntries:[...sent].map(url => ({url})),
        }}), signal:AbortSignal.timeout(5000), redirect:'error',
      });
      if (!response.ok) return unavailable();
      const body = await response.json();
      if (!body || typeof body !== 'object' || Array.isArray(body)) return unavailable();
      const checkedAt = new Date().toISOString();
      if (Object.keys(body).length === 0 ||
          (Object.keys(body).length === 1 && Array.isArray(body.matches) && !body.matches.length)) {
        return {status:'noMatch',threatTypes:[],matches:{},checkedAt,expiresAt:null,provider};
      }
      if (!Array.isArray(body.matches) || !body.matches.length) return unavailable();
      const threats = new Set();
      const matches = {};
      let lifetimeMs = 300000;
      for (const match of body.matches) {
        const duration = typeof match?.cacheDuration === 'string' && /^(\d+(?:\.\d{1,9})?)s$/.exec(match.cacheDuration);
        const ms = duration ? Number(duration[1]) * 1000 : NaN;
        if (!allowedThreats.has(match?.threatType) || match.threatEntryType !== 'URL' ||
            !sent.has(match.threat?.url) || !Number.isFinite(ms) || ms < 1) return unavailable();
        threats.add(match.threatType);
        const list = matches[match.threat.url] ??= [];
        if (!list.includes(match.threatType)) list.push(match.threatType);
        lifetimeMs = Math.min(lifetimeMs, ms);
      }
      return {status:'matched',threatTypes:[...threats],matches,checkedAt,
        expiresAt:new Date(Date.parse(checkedAt) + lifetimeMs).toISOString(),provider};
    } catch (_) { return unavailable(); }
  };
}
