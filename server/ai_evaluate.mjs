import assert from 'node:assert/strict';
import {readFile,writeFile} from 'node:fs/promises';
import {createAiScanner,isAiConfigured,promptVersion} from './ai_scan.mjs';

const order = ['low','caution','high'];
const alert = risk => ['caution','high'].includes(risk);
function counts(rows,engine) {
  const c=[0,0,0,0];
  for(const row of rows.filter(row=>row.scam !== null)) c[row.scam ? alert(row[engine]) ? 0 : 2 : alert(row[engine]) ? 1 : 3]++;
  return c;
}
assert.deepEqual(counts([{scam:true,ai:'high'},{scam:false,ai:'high'},{scam:true,ai:null},{scam:false,ai:'low'}],'ai'),[1,1,1,1]);
if(process.env.USISA_RUN_AI_EVAL !== '1') throw new Error('Set USISA_RUN_AI_EVAL=1 to send the 20 synthetic held-out messages');
if(!isAiConfigured(process.env.GROQ_API_KEY,process.env.GROQ_MODEL)) throw new Error('AI configuration unavailable');
const fixtures=JSON.parse(await readFile(new URL('../test/fixtures/ai_messages.json',import.meta.url),'utf8'));
assert.equal(new Set(fixtures.map(row=>row.id)).size,fixtures.length);
const local=JSON.parse(await readFile(new URL('../.verification/ai-local.json',import.meta.url),'utf8'));
let inputTokens=0,outputTokens=0;
const scanner=createAiScanner({apiKey:process.env.GROQ_API_KEY,model:process.env.GROQ_MODEL,onUsage:({promptTokens,completionTokens})=>{inputTokens+=promptTokens;outputTokens+=completionTokens;}});
const rows=[];
for(const fixture of fixtures.filter(row=>row.split === 'held_out')) {
  assert.ok(order.includes(local[fixture.id]));
  const start=performance.now();
  const assessment=await scanner({text:fixture.text,responseLanguage:fixture.language === 'English' ? 'en' : 'fil'});
  const ai=assessment.risk ?? null;
  const combined=order[Math.max(order.indexOf(local[fixture.id]),order.indexOf(ai))];
  const {text,...metadata}=fixture;
  rows.push({...metadata,local:local[fixture.id],ai,combined,state:assessment.state,latencyMs:Math.round(performance.now()-start)});
  console.log(`${fixture.id}: ${assessment.state}, ${rows.at(-1).latencyMs}ms`);
}
const percent=(n,d)=>d ? `${(100*n/d).toFixed(1)}%` : 'n/a';
const lines=[`# AI synthetic diagnostic evaluation\n`,`${new Date().toISOString()}; model ${process.env.GROQ_MODEL}; prompt ${promptVersion}; rules-v1; reasoning low; temperature 0.2.`,
  '\nTwenty held-out synthetic examples written by the implementer after the prompt was frozen; six separate development examples. No tuning on these outcomes. This is not an independent or real-world accuracy study. Caution/high count as alerts; unknown/unavailable count as no AI alert, including misses, and are reported separately. Two ambiguous cases are excluded from binary metrics. No URL was fetched.\n',
  '| Slice | Engine | N | TP | FP | FN | TN | Precision | Recall | FPR |','|---|---|---:|---:|---:|---:|---:|---:|---:|---:|'];
for(const slice of ['All',...new Set(rows.map(row=>row.language)),...new Set(rows.map(row=>row.category))]) {
  const selected=rows.filter(row=>(slice === 'All' || row.language === slice || row.category === slice) && row.scam !== null);
  if(!selected.length) continue;
  for(const engine of ['local','ai','combined']) {
    const c=counts(selected,engine);
    lines.push(`| ${slice} | ${engine} | ${selected.length} | ${c.join(' | ')} | ${percent(c[0],c[0]+c[1])} | ${percent(c[0],c[0]+c[2])} | ${percent(c[1],c[1]+c[3])} |`);
  }
}
const sorted=rows.map(row=>row.latencyMs).sort((a,b)=>a-b);
lines.push(`\nAI unassessed/unavailable: ${rows.filter(row=>!row.ai).length}/${rows.length}. Disagreement among assessed cases: ${rows.filter(row=>row.ai && row.local !== row.ai).length}/${rows.filter(row=>row.ai).length}. Latency p50 ${sorted[Math.ceil(sorted.length*.5)-1]}ms, p95 ${sorted[Math.ceil(sorted.length*.95)-1]}ms. Valid-response input tokens ${inputTokens}, output tokens ${outputTokens}.`,
  '\nActual billed cost and account data controls are not accessible through this test. At the published 120B uncached input $0.15/M and output $0.60/M rates (checked 10 November 2026), the estimate below excludes unknown provider usage on failed calls and is not a billing receipt. [Groq pricing](https://console.groq.com/docs/model/openai/gpt-oss-120b).',
  `\nEstimated token cost for validated 120B responses: ${process.env.GROQ_MODEL === 'openai/gpt-oss-120b' ? `$${(inputTokens*.15/1e6+outputTokens*.60/1e6).toFixed(6)}` : 'not calculated for this model'}.`,
  '\n| ID | Label | Local | AI | Combined | State | ms |','|---|---|---|---|---|---|---:|',...rows.map(row=>`| ${row.id} | ${row.scam === null ? 'ambiguous' : row.scam ? 'scam' : 'benign'} | ${row.local} | ${row.ai ?? 'unknown'} | ${row.combined} | ${row.state} | ${row.latencyMs} |`),
  '\nRelease gates: independent PH annotation, agreed error thresholds, human Filipino review, physical-device checks and verified provider account retention/spend settings remain open. No model switch was made; compare 20B on the same frozen set before switching. The process-local daily gateway cap is not an organization billing cap. Never advertise these synthetic percentages as accuracy.\n',
  'Reproduce: `dart run tool/ai_local_evaluate.dart`, then from server set `USISA_RUN_AI_EVAL=1` and run `node --env-file=../.env ai_evaluate.mjs`. No automatic retries or completed-response cache.\n');
await writeFile(new URL('../.verification/ai-evaluation.json',import.meta.url),JSON.stringify({model:process.env.GROQ_MODEL,promptVersion,inputTokens,outputTokens,rows},null,2));
await writeFile(new URL('../docs/ai-evaluation.md',import.meta.url),lines.join('\n'));
console.log(`Saved ${rows.length} synthetic outcomes; no raw text or provider prose in reports.`);
