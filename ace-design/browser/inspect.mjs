import fs from 'node:fs';
import path from 'node:path';
import {dependencies} from './dependencies.mjs';
const [url,surface,out,runtime,seconds='45'] = process.argv.slice(2);
const timeout = Number(seconds)*1000;
const report = {schema_version:1,url,surface,status:'incomplete',viewports:[],findings:[],errors:[],coverage:{automated:['axe WCAG 2.2 A/AA','document overflow','broken images','page load and JavaScript errors'],manual_required:['visual hierarchy','text clipping and overlays','keyboard task completion','required states and languages','brand and content fit'],source:'not inspected'}};
let browser;
const add = (rule,width,details) => report.findings.push({rule,width,...details});
try {
 if(!['site','app'].includes(surface)) throw new Error('surface must be site or app');
 const target=new URL(url);
 if(!['http:','https:'].includes(target.protocol)||target.username||target.password) throw new Error('HTTP(S) URL without credentials required');
 const {chromium,AxeBuilder,versions}=dependencies(runtime);
 report.versions=versions;
 browser=await chromium.launch({headless:true});
 for (const [width,height] of [[390,844],[768,1024],[1440,900]]) {
  const context=await browser.newContext({viewport:{width,height},reducedMotion:'reduce'});
  const page=await context.newPage();
  page.setDefaultTimeout(timeout);
  page.setDefaultNavigationTimeout(timeout);
  page.on('pageerror',e=>add('javascript-error',width,{message:e.message}));
  let timer;
  try {
   const audit = async()=>{
    const response=await page.goto(url,{waitUntil:'load'});
    if(!response || response.status()>=400) throw new Error(`HTTP load failed: ${response?.status() ?? 'no response'}`);
    await page.evaluate(()=>document.fonts.ready);
    // Trigger lazy content once, with a bounded number of screens, then return to the top.
    const screens=await page.evaluate(()=>Math.min(12,Math.ceil(document.body.scrollHeight/innerHeight)));
    for(let i=1;i<screens;i++){await page.evaluate(y=>scrollTo(0,y),i*height);await page.waitForTimeout(80);}
    await page.evaluate(()=>scrollTo(0,0));
    const metrics=await page.evaluate(()=>({
      overflow:document.documentElement.scrollWidth>innerWidth+1,
      broken:[...document.images].filter(i=>i.complete && !i.naturalWidth).map(i=>i.getAttribute('src')),
      pending:[...document.images].filter(i=>!i.complete).map(i=>i.getAttribute('src')),
      title:document.title
    }));
    if(metrics.overflow)add('horizontal-overflow',width,{message:'Document exceeds viewport width'});
    for(const src of metrics.broken)add('broken-image',width,{src});
    for(const src of metrics.pending)add('image-not-loaded',width,{src});
    const screenshot=`viewport-${width}.png`;
    await page.screenshot({path:path.join(out,screenshot),fullPage:true,animations:'disabled',timeout});
    const accessibility=await new AxeBuilder({page}).withTags(['wcag2a','wcag2aa','wcag21a','wcag21aa','wcag22aa']).analyze();
    for(const violation of accessibility.violations)add('accessibility',width,{id:violation.id,impact:violation.impact,message:violation.help,help_url:violation.helpUrl,nodes:violation.nodes.map(n=>({target:n.target,summary:n.failureSummary}))});
    report.viewports.push({width,height,screenshot,title:metrics.title,axe_incomplete:accessibility.incomplete.map(v=>({id:v.id,help:v.help})),status:'inspected'});
   };
   await Promise.race([audit(),new Promise((_,reject)=>{timer=setTimeout(()=>reject(new Error('Viewport inspection timed out')),timeout);})]);
  } catch(e) {report.errors.push({width,message:e.message});}
  finally {clearTimeout(timer);await context.close();}
 }
 report.status=report.errors.length || report.viewports.length!==3 ? 'incomplete' : report.findings.length ? 'findings' : 'pass';
} catch(e){report.errors.push({message:e.message});}
finally {
 try {if(browser)await browser.close();}
 catch(e){report.errors.push({message:`Browser cleanup failed: ${e.message}`});report.status='incomplete';}
 fs.writeFileSync(path.join(out,'report.json'),JSON.stringify(report,null,2)+'\n');
 const lines=[`# Design inspection: ${report.status}`,`\nSurface: ${surface}`,`\nURL: ${url}`,`\nViewports inspected: ${report.viewports.length}/3`,`\nFindings: ${report.findings.length}`,`\n## Findings`,...report.findings.map(f=>`- ${f.width}px ${f.rule}: ${f.message || f.src || f.id}`),`\n## Errors`,...report.errors.map(e=>`- ${e.width || 'runner'}: ${e.message}`),`\n## Coverage`,`\nAutomated: ${report.coverage.automated.join('; ')}.`,`\nStill requires review: ${report.coverage.manual_required.join('; ')}.`,`\nSource: not inspected. A pass only covers the automatic checks.`,...report.viewports.map(v=>`\n![${v.width}px](${v.screenshot})\nAxe checks requiring review: ${v.axe_incomplete.length}.`)];
 fs.writeFileSync(path.join(out,'report.md'),lines.join('\n')+'\n');
 console.log(JSON.stringify({status:report.status,report:path.join(out,'report.json')}));
 process.exitCode=report.status==='pass'?0:report.status==='findings'?1:2;
}
