import json,os,pathlib,subprocess,socket,struct,time,sys,select
base=pathlib.Path('/tmp/ace-native-shape');base.mkdir(mode=0o755)
root=base/'runtime';root.mkdir(mode=0o700);os.chown(root,13001,13001)
home=pathlib.Path('/home/ace-worker');home.mkdir(exist_ok=True);os.chown(home,13001,13001)
sock=root/'native.sock'
client='''import socket,struct,json,sys
s=socket.socket(socket.AF_UNIX,socket.SOCK_STREAM);s.settimeout(5);s.connect(sys.argv[1]);p=struct.unpack("3i",s.getsockopt(socket.SOL_SOCKET,socket.SO_PEERCRED,12));s.sendall((sys.argv[2]+"\\n").encode())
if sys.argv[3]=="lost":s.close();print(json.dumps({"reply":"deliberately unread"}));sys.exit(0)
r=s.makefile("rb").readline();print(json.dumps({"peer_pid":p[0],"peer_uid":p[1],"reply":json.loads(r)}))
'''
def call(method,params={},lost=False):
 command=['setpriv','--bounding-set=-all','--no-new-privs','--reuid=13002','--regid=13002','--clear-groups',sys.executable,'-c',client,str(sock),json.dumps({'id':'fixture','method':method,'params':params}),'lost' if lost else 'read']
 r=subprocess.run(command,capture_output=True,text=True,timeout=8)
 assert r.returncode==0,r.stderr
 return json.loads(r.stdout)
inventory = """import pathlib,json,sys
rows=[]
for p in pathlib.Path('/proc').iterdir():
 if not p.name.isdigit():continue
 try:
  stat=(p/'stat').read_text().rsplit(')',1)[1].split()
  if int(stat[1])==int(sys.argv[1]):rows.append({'pid':int(p.name),'uid':p.stat().st_uid,'exe':str((p/'exe').resolve()),'birth_ticks':stat[19]})
 except (OSError,ValueError):pass
print(json.dumps(sorted(rows,key=lambda x:x['pid'])))
"""
def children():
 command=['setpriv','--bounding-set=-all','--no-new-privs','--reuid=13001','--regid=13001','--clear-groups',sys.executable,'-c',inventory,str(server.pid)]
 result=subprocess.run(command,capture_output=True,text=True,timeout=3)
 assert result.returncode==0,result.stderr
 return json.loads(result.stdout)
def wait_count(expected):
 end=time.monotonic()+3
 while time.monotonic()<end:
  rows=children()
  if len(rows)==expected:return rows
  time.sleep(.02)
 raise AssertionError('child count mismatch '+repr(children()))
proof={'scope':'real Herdr0.9.3 API shape only; test bootstrap; Yama0 is not protected acceptance','worker_uid':13001,'launcher_uid':13002}
server=subprocess.Popen(['setpriv','--bounding-set=-all','--no-new-privs','--reuid=13001','--regid=13001','--clear-groups','/probe/herdr','server'],env={'HOME':str(home),'PATH':'/usr/bin:/bin','SHELL':'/bin/sh','TERM':'xterm-256color','HERDR_SOCKET_PATH':str(sock)},stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
try:
 end=time.monotonic()+10
 while not sock.exists() and server.poll() is None and time.monotonic()<end:time.sleep(.05)
 assert sock.exists(),'server missing'
 subprocess.run(['setfacl','-m','u:13002:--x',str(root)],check=True)
 subprocess.run(['setfacl','-m','u:13002:rw-',str(sock)],check=True)
 proof['server_pid']=server.pid;proof['ping']=call('ping')
 seed=call('workspace.create',{'cwd':str(home),'focus':False}) # installer-owned container, before measured launch
 wid=seed['reply']['result']['workspace']['workspace_id'];proof['installed_container']=wid
 proof['preflight']=call('layout.export',{'workspace_id':wid})
 assert proof['preflight']['reply']['result']['layout']['workspace_id']==wid
 baseline=children();proof['baseline']=baseline
 command=['/usr/libexec/ace-native-test-bootstrap','mapping','ticket']
 result=call('layout.apply',{'workspace_id':wid,'focus':False,'root':{'type':'pane','cwd':str(home),'command':command}})
 layout=result['reply']['result']['layout'];proof['original_layout']=result
 assert layout['workspace_id']==wid and layout['root']['command']==command
 after=wait_count(len(baseline)+1);delta=[row for row in after if row['pid'] not in {x['pid'] for x in baseline}]
 assert len(delta)==1 and delta[0]['exe']=='/usr/libexec/ace-native-test-bootstrap',delta
 proof['created_child_delta']=delta
 pane=layout['root']['pane_id'];info=call('pane.process_info',{'pane_id':pane});proof['exact_child']=info
 assert info['reply']['result']['process_info']['shell_pid']==delta[0]['pid']
 handle=os.pidfd_open(delta[0]['pid']);assert not select.select([handle],[],[],0)[0]
 proof['close']=call('pane.close',{'pane_id':pane});assert select.select([handle],[],[],3)[0];os.close(handle)
 proof['after_gate_close']=wait_count(len(baseline));assert proof['after_gate_close']==baseline
 proof['close_container']=call('workspace.close',{'workspace_id':wid})
 before_missing=children();proof['missing_container_reply']=call('layout.apply',{'workspace_id':wid,'focus':False,'root':{'type':'pane','cwd':str(home),'command':command}})
 assert 'error' in proof['missing_container_reply']['reply'];assert children()==before_missing
 proof['missing_container_child_delta']=[]
 # A lost reply can create one gate, but does not authorize a retry.
 seed2=call('workspace.create',{'cwd':str(home),'focus':False});wid2=seed2['reply']['result']['workspace']['workspace_id']
 before_lost=children();proof['lost_reply']=call('layout.apply',{'workspace_id':wid2,'focus':False,'root':{'type':'pane','cwd':str(home),'command':command}},lost=True)
 lost_after=wait_count(len(before_lost)+1);proof['lost_reply_child_delta']=[x for x in lost_after if x['pid'] not in {y['pid'] for y in before_lost}]
 assert len(proof['lost_reply_child_delta'])==1 and proof['lost_reply_child_delta'][0]['exe']=='/usr/libexec/ace-native-test-bootstrap'
 proof['bootstrap_start_count']=len(pathlib.Path('/tmp/native-bootstrap-starts').read_text().splitlines());assert proof['bootstrap_start_count']==2
 proof['verdict']='passed'
finally:
 server.terminate()
 try:server.wait(timeout=3)
 except subprocess.TimeoutExpired:server.kill();server.wait()
 pathlib.Path('/out/native-shape.json').write_text(json.dumps(proof,indent=2)+'\n')
 print(json.dumps(proof),flush=True)
