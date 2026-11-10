const allowedThreats = new Set(['MALWARE', 'SOCIAL_ENGINEERING', 'UNWANTED_SOFTWARE']);

export function createReputationLookup({apiKey, fetchImpl = fetch} = {}) {
  return async function lookup(input) {
    const unavailable = () => ({status:'unavailable', threatTypes:[], checkedAt:null,
      expiresAt:null, provider:'Google Web Risk'});
    if (!apiKey) return unavailable();
    try {
      const url = new URL('https://webrisk.googleapis.com/v1/uris:search');
      url.searchParams.set('key', apiKey);
      url.searchParams.set('uri', input);
      for (const type of allowedThreats) url.searchParams.append('threatTypes', type);
      const response = await fetchImpl(url, {signal:AbortSignal.timeout(5000), redirect:'error'});
      if (!response.ok) return unavailable();
      const body = await response.json();
      if (!body || typeof body !== 'object' || Array.isArray(body)) return unavailable();
      const checkedAt = new Date().toISOString();
      if (Object.keys(body).length === 0) return {status:'noMatch',threatTypes:[],checkedAt,expiresAt:null,provider:'Google Web Risk'};
      const threat = body.threat;
      if (!threat || !Array.isArray(threat.threatTypes) || !threat.threatTypes.length ||
          threat.threatTypes.some(type => !allowedThreats.has(type)) ||
          typeof threat.expireTime !== 'string' || !Number.isFinite(Date.parse(threat.expireTime)) ||
          Date.parse(threat.expireTime) <= Date.now()) return unavailable();
      return {status:'matched',threatTypes:threat.threatTypes,checkedAt,
        expiresAt:threat.expireTime,provider:'Google Web Risk'};
    } catch (_) { return unavailable(); }
  };
}
