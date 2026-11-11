const allowedThreats = new Set(['MALWARE', 'SOCIAL_ENGINEERING', 'UNWANTED_SOFTWARE']);
const provider = 'Google Safe Browsing';

export function createReputationLookup({apiKey, fetchImpl = fetch} = {}) {
  return async function lookup(input) {
    const unavailable = () => ({status:'unavailable', threatTypes:[], checkedAt:null,
      expiresAt:null, provider});
    if (!apiKey) return unavailable();
    try {
      const url = new URL('https://safebrowsing.googleapis.com/v4/threatMatches:find');
      url.searchParams.set('key', apiKey);
      const response = await fetchImpl(url, {
        method:'POST', headers:{'Content-Type':'application/json'},
        body:JSON.stringify({client:{clientId:'usisa',clientVersion:'1.0.0'},threatInfo:{
          threatTypes:[...allowedThreats],platformTypes:['ANY_PLATFORM'],
          threatEntryTypes:['URL'],threatEntries:[{url:input}],
        }}), signal:AbortSignal.timeout(5000), redirect:'error',
      });
      if (!response.ok) return unavailable();
      const body = await response.json();
      if (!body || typeof body !== 'object' || Array.isArray(body)) return unavailable();
      const checkedAt = new Date().toISOString();
      if (Object.keys(body).length === 0 ||
          (Object.keys(body).length === 1 && Array.isArray(body.matches) && !body.matches.length)) {
        return {status:'noMatch',threatTypes:[],checkedAt,expiresAt:null,provider};
      }
      if (!Array.isArray(body.matches) || !body.matches.length) return unavailable();
      const threats = new Set();
      let lifetimeMs = 300000;
      for (const match of body.matches) {
        const duration = typeof match?.cacheDuration === 'string' && /^(\d+(?:\.\d{1,9})?)s$/.exec(match.cacheDuration);
        const ms = duration ? Number(duration[1]) * 1000 : NaN;
        if (!allowedThreats.has(match?.threatType) || match.threatEntryType !== 'URL' ||
            match.threat?.url !== input || !Number.isFinite(ms) || ms < 1) return unavailable();
        threats.add(match.threatType);
        lifetimeMs = Math.min(lifetimeMs, ms);
      }
      return {status:'matched',threatTypes:[...threats],checkedAt,
        expiresAt:new Date(Date.parse(checkedAt) + lifetimeMs).toISOString(),provider};
    } catch (_) { return unavailable(); }
  };
}
