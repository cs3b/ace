import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
const [directory, portText = '0'] = process.argv.slice(2);
const root = fs.realpathSync(directory);
const port = Number(portText);
const ids = JSON.parse(fs.readFileSync(path.join(root, 'session.json'), 'utf8')).variants;
if (!Array.isArray(ids) || !ids.length || new Set(ids).size !== ids.length || ids.some(id => typeof id !== 'string' || !/^[a-z][a-z0-9_-]{0,31}$/.test(id))) throw new Error('Invalid session variants');
const allowed = relative => relative === 'gallery.html' || relative === 'fixtures.json' || relative.startsWith('assets/') || ids.some(id => relative.startsWith(`variants/${id}/`));
if (!Number.isInteger(port) || port < 0 || port > 65535) throw new Error('port must be 0..65535');
const mime = {'.html':'text/html; charset=utf-8','.css':'text/css','.js':'text/javascript','.mjs':'text/javascript','.json':'application/json','.svg':'image/svg+xml','.gif':'image/gif','.png':'image/png','.jpg':'image/jpeg','.jpeg':'image/jpeg','.webp':'image/webp','.woff':'font/woff','.woff2':'font/woff2'};
const server = http.createServer((req,res) => {
  const respond = (code, text) => {res.writeHead(code, {'Content-Type':'text/plain'});res.end(text);};
  if (!['GET','HEAD'].includes(req.method)) return respond(405, 'Method not allowed');
  if (!/^127\.0\.0\.1(?::\d+)?$/.test(req.headers.host || '')) return respond(403, 'Invalid host');
  try {
    const target = decodeURIComponent(req.url.split('?')[0]);
    if (target.includes('\0') || target.includes('\\') || target.split('/').includes('..')) return respond(403,'Forbidden path');
    const relative = target === '/' ? 'gallery.html' : target.replace(/^\//,'');
    if (!allowed(relative)) return respond(404,'Not found');
    if (relative.split('/').some(p => p.startsWith('.'))) return respond(403,'Forbidden path');
    const file = fs.realpathSync(path.join(root,relative));
    const resolved = path.relative(root,file).split(path.sep).join('/');
    if (!fs.statSync(file).isFile()) return respond(404,'Not found');
    if (!allowed(resolved)) return respond(403,'Forbidden path');
    const type = mime[path.extname(file).toLowerCase()];
    if (!file.startsWith(root + path.sep) || !type) return respond(403,'Forbidden path');
    const bytes=fs.readFileSync(file);
    res.writeHead(200,{'Content-Type':type,'Content-Length':bytes.length,'Cache-Control':'no-store','X-Content-Type-Options':'nosniff','Access-Control-Allow-Origin':'*'});
    res.end(req.method === 'HEAD' ? undefined : bytes);
  } catch {respond(404,'Not found');}
});
server.on('error',e=>{console.error(`Preview failed: ${e.message}`);process.exitCode=1;});
server.listen(port,'127.0.0.1',()=>console.log(`Preview: http://127.0.0.1:${server.address().port}/`));
for (const signal of ['SIGINT','SIGTERM']) process.on(signal,()=>{server.close();server.closeAllConnections();});
