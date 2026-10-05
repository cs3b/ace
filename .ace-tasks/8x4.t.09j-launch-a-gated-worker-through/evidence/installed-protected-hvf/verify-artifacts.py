import hashlib,json,pathlib,sys
manifest=json.loads(pathlib.Path(sys.argv[1]).read_text())
for name,expected in manifest['files'].items():
 h=hashlib.sha256()
 with pathlib.Path(name).open('rb') as f:
  for chunk in iter(lambda:f.read(1024*1024),b''):h.update(chunk)
 if h.hexdigest()!=expected:raise SystemExit('artifact changed: '+name)
print('PASS exact offline kernel/rootfs/gem/fixture artifact hashes')
