export const warningCodes = ['credential_request','payment_request','urgency','impersonation','prize','suspicious_link','gambling_ad','other'];
export const recommendationCodes = ['dont_share_secrets','verify_official_channel','pause_payment','contact_provider_if_shared'];
export const aiSchema = {
  type:'object',additionalProperties:false,
  properties:{
    risk:{type:'string',enum:['low','caution','high','unknown']},
    summary:{type:'string'},
    warningSigns:{type:'array',items:{type:'object',additionalProperties:false,properties:{code:{type:'string',enum:warningCodes},evidence:{type:'string'}},required:['code','evidence']}},
    recommendationCodes:{type:'array',items:{type:'string',enum:recommendationCodes}},
  },required:['risk','summary','warningSigns','recommendationCodes'],
};

const exactKeys = (value, keys) => value && typeof value === 'object' && !Array.isArray(value) && Object.keys(value).length === keys.length && keys.every(key=>Object.hasOwn(value,key));
const quoted = (evidence, text) => evidence.trim().length > 0 && [...evidence].length <= 160 && text.includes(evidence);

// Returns the verdict with mismatched quotes dropped, or null when the answer is unusable.
export function checkedVerdict(value, text) {
  if (!(exactKeys(value,aiSchema.required) && ['low','caution','high','unknown'].includes(value.risk) &&
    typeof value.summary === 'string' && value.summary.trim().length > 0 && [...value.summary].length <= 480 &&
    Array.isArray(value.warningSigns) && value.warningSigns.length <= 5 &&
    value.warningSigns.every(sign=>exactKeys(sign,['code','evidence']) && warningCodes.includes(sign.code) && typeof sign.evidence === 'string') &&
    (value.risk !== 'unknown' || value.warningSigns.length === 0) &&
    Array.isArray(value.recommendationCodes) && value.recommendationCodes.length <= 4 &&
    new Set(value.recommendationCodes).size === value.recommendationCodes.length && value.recommendationCodes.every(code=>recommendationCodes.includes(code)))) return null;
  const warningSigns = value.warningSigns.filter(sign=>quoted(sign.evidence,text));
  // Caution/high still needs at least one real quote behind it.
  if (['caution','high'].includes(value.risk) && warningSigns.length === 0) return null;
  return {...value,warningSigns};
}
