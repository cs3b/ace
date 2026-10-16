import fs from 'node:fs';
import path from 'node:path';
import {dependencies} from './dependencies.mjs';
const [runtime, url, out] = process.argv.slice(2);
const {chromium} = dependencies(runtime);
const browser = await chromium.launch({headless:true});
try {
  const page = await browser.newPage({viewport:{width:1440,height:1000}});
  await page.goto(url,{waitUntil:'domcontentloaded',timeout:45000});
  await page.screenshot({path:path.join(out,'mockup.png'),fullPage:true,timeout:20000});
  fs.writeFileSync(path.join(out,'page.html'),await page.content());
  fs.writeFileSync(path.join(out,'visible.txt'),await page.locator('body').innerText());
  fs.writeFileSync(path.join(out,'capture.json'),JSON.stringify({requested:url,final:page.url(),title:await page.title()},null,2));
} finally { await browser.close(); }
