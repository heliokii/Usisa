export const warningCodes = ['credential_request','payment_request','urgency','impersonation','prize','suspicious_link','other'];
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
export function validVerdict(value, text) {
  return exactKeys(value,aiSchema.required) && ['low','caution','high','unknown'].includes(value.risk) &&
    typeof value.summary === 'string' && value.summary.trim().length > 0 && [...value.summary].length <= 480 &&
    Array.isArray(value.warningSigns) && value.warningSigns.length <= 5 &&
    value.warningSigns.every(sign=>exactKeys(sign,['code','evidence']) && warningCodes.includes(sign.code) && typeof sign.evidence === 'string' && sign.evidence.trim().length > 0 && [...sign.evidence].length <= 160 && text.includes(sign.evidence)) &&
    (!['caution','high'].includes(value.risk) || value.warningSigns.length > 0) &&
    (value.risk !== 'unknown' || value.warningSigns.length === 0) &&
    Array.isArray(value.recommendationCodes) && value.recommendationCodes.length <= 4 &&
    new Set(value.recommendationCodes).size === value.recommendationCodes.length && value.recommendationCodes.every(code=>recommendationCodes.includes(code));
}
