import {dependencies} from './dependencies.mjs';
try {
 const {chromium,versions} = dependencies(process.argv[2]);
 const browser = await chromium.launch({headless:true});
 await browser.close();
 console.log(JSON.stringify({ready:true,node:process.version,versions,browser:chromium.executablePath()}));
} catch(e) {console.log(JSON.stringify({ready:false,node:process.version,error:e.message}));process.exitCode=1;}
