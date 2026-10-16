import fs from 'node:fs';
import path from 'node:path';
import {createRequire} from 'node:module';
const expected = JSON.parse(fs.readFileSync(new URL('./package.json', import.meta.url),'utf8')).dependencies;
export function dependencies(directory) {
  const [major, minor] = process.versions.node.split('.').map(Number);
  if (major < 22 || (major === 22 && minor < 12)) throw new Error('Node 22.12+ is required for browser inspection');
  const base = path.resolve(directory);
  for (const [name,version] of Object.entries(expected)) {
    const file = path.join(base,'node_modules',name,'package.json');
    if (!fs.existsSync(file)) throw new Error(`Missing ${name}@${version}; copy packaged browser/package*.json to runtime_dir and run npm ci there`);
    const installed = JSON.parse(fs.readFileSync(file,'utf8')).version;
    if (installed !== version) throw new Error(`Expected ${name}@${version}, found ${installed}; run npm ci with the packaged lockfile`);
  }
  const require = createRequire(path.join(base,'package.json'));
  const {chromium} = require('playwright');
  if (!fs.existsSync(chromium.executablePath())) throw new Error('Chromium missing; run npx playwright install chromium in runtime_dir');
  const axe = require('@axe-core/playwright');
  return {chromium, AxeBuilder: axe.default || axe, versions: expected};
}
