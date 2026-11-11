import {createAiScanner, isAiConfigured} from './ai_scan.mjs';

if (process.env.USISA_RUN_AI_SMOKE !== '1') throw new Error('Set USISA_RUN_AI_SMOKE=1 for one synthetic inference call');
if (!isAiConfigured(process.env.GROQ_API_KEY,process.env.GROQ_MODEL)) throw new Error('AI configuration unavailable');
let usage;
const scan = createAiScanner({apiKey:process.env.GROQ_API_KEY,model:process.env.GROQ_MODEL,onUsage:value=>usage=value});
const start = performance.now();
const result = await scan({text:'GCash support: Send your OTP immediately to prevent account suspension.',responseLanguage:'en'});
console.log(JSON.stringify({state:result.state,risk:result.risk,modelId:result.modelId,promptVersion:result.promptVersion,warningCount:result.warningSigns?.length,latencyMs:Math.round(performance.now()-start),usage}));
if (result.state !== 'completed') process.exitCode=1;
