import os,pathlib,subprocess,socket,json,struct,time,hashlib,traceback
proof={"scope":"isolated installed gate, not actual Lab/gad.2 acceptance","source_head":"e2d3dad3e3c93247e0d741ddaef3cf07cddaa46f"}
ROOT=pathlib.Path("/var/lib/ace-fixture")
ENV={"PATH":"/usr/local/bundle/bin:/usr/local/bin:/usr/bin:/bin","GEM_HOME":"/usr/local/bundle","GEM_PATH":"/usr/local/bundle:/usr/local/lib/ruby/gems/3.4.0","TERM":"xterm-256color"}
def as_uid(uid,argv,**kwargs):
 env=ENV|{"HOME":f"/home/ace-{uid}"}|kwargs.pop("env",{})
 return subprocess.Popen(["setpriv","--bounding-set=-all","--no-new-privs",f"--reuid={uid}",f"--regid={uid}",f"--groups={uid}"]+argv,env=env,**kwargs)
def server_children():
 rows=[]
 for path in pathlib.Path("/proc").iterdir():
  if not path.name.isdigit():continue
  try:
   fields=(path/"stat").read_text().rsplit(")",1)[1].split()
   if int(fields[1])==server.pid:rows.append({"pid":int(path.name),"exe":str((path/"exe").resolve()),"birth_ticks":fields[19]})
  except (OSError,ValueError):pass
 return sorted(rows,key=lambda row:row["pid"])
def wait_for(predicate,seconds=10):
 deadline=time.monotonic()+seconds
 while time.monotonic()<deadline:
  if predicate():return
  time.sleep(.05)
 raise AssertionError("fixture wait expired")
def native(method,params={}):
 with socket.socket(socket.AF_UNIX,socket.SOCK_STREAM) as s:
  s.settimeout(5);s.connect("/run/ace-native/control.sock");s.sendall((json.dumps({"id":"installer","method":method,"params":params})+"\n").encode())
  result=json.loads(s.makefile("rb").readline());assert "result" in result,result;return result["result"]
def identity(pid):
 fields=dict(line.split(":",1) for line in pathlib.Path(f"/proc/{pid}/status").read_text().splitlines())
 stat=pathlib.Path(f"/proc/{pid}/stat").read_text().rsplit(")",1)[1].split()
 assert all(int(fields[k],16)==0 for k in ("CapInh","CapPrm","CapEff","CapBnd","CapAmb"))
 assert fields["NoNewPrivs"].strip()=="1"
 return {"pid":pid,"uid":int(fields["Uid"].split()[0]),"gid":int(fields["Gid"].split()[0]),"groups":list(map(int,fields["Groups"].split())),"parent_pid":int(fields["PPid"]),"started_at":"linux:"+pathlib.Path("/proc/sys/kernel/random/boot_id").read_text().strip()+":"+stat[19],"host":socket.gethostname()}
def git(*args):
 result=subprocess.run(["git","-c","safe.directory=/var/lib/ace-journal","-C","/var/lib/ace-journal",*args],capture_output=True,text=True,check=True);return result.stdout.strip()
def journal_states(assignment="assignment"):
 paths=git("ls-tree","-r","--name-only","refs/ace/execution","--","execution/"+assignment+"/events/").splitlines()
 events=[json.loads(git("show","refs/ace/execution:"+path)) for path in paths]
 states=[event["payload"]["data"] for event in events if event["type"]=="authority_mutation"]
 return sorted(states,key=lambda state:(state.get("generation",0),state.get("phase")!="registered"))
server=None;authority=None
try:
 proof["kernel"]=subprocess.check_output(["uname","-r"],text=True).strip();proof["boot_id"]=pathlib.Path("/proc/sys/kernel/random/boot_id").read_text().strip()
 proof["outer_kernel"]=json.loads(pathlib.Path("/opt/ace-fixture/host-kernel.json").read_text())
 assert proof["kernel"]!=proof["outer_kernel"]["kernel"] and proof["boot_id"]!=proof["outer_kernel"]["boot_id"]
 proof["gems"]=json.loads(pathlib.Path("/opt/ace-gems/manifest.json").read_text())
 proof["installed_bootstrap_sha256"]=hashlib.sha256(pathlib.Path("/usr/libexec/ace-worker-gate").read_bytes()).hexdigest()
 for path in ("/usr/libexec/ace-worker-gate","/usr/libexec/ace-fixture-payload","/usr/local/bin/herdr"):
  stat=pathlib.Path(path).stat();assert stat.st_uid==0 and stat.st_mode & 0o6022==0
 assert proof["kernel"]=="6.1.0-53-arm64";assert pathlib.Path("/proc/sys/kernel/yama/ptrace_scope").read_text().strip()=="2"
 for uid in (13001,13002,13003,13004):
  subprocess.run(["groupadd","-g",str(uid),f"ace-{uid}"],check=True)
  subprocess.run(["useradd","-u",str(uid),"-g",str(uid),"-d",f"/home/ace-{uid}","-m",f"ace-{uid}"],check=True)
 for path,uid in (("/run/ace-native",13001),("/run/ace-authority",13003),("/var/lib/ace-authority",13003),("/var/lib/ace-journal",13003),("/var/lib/ace-checkout",13003),("/var/lib/ace-assignments",13003),("/var/lib/ace-candidates",13003),("/var/lib/ace-worker",13001),("/var/lib/ace-launcher",13002),("/var/lib/ace-supervisor",13004)):
  pathlib.Path(path).mkdir(mode=0o700,parents=True,exist_ok=True);os.chown(path,uid,uid);os.chmod(path,0o700)
 pathlib.Path("/run/ace-payload-starts").touch(mode=0o600);os.chown("/run/ace-payload-starts",13001,13001)
 native_home=pathlib.Path("/var/lib/ace-native-home");(native_home/".config/herdr").mkdir(parents=True,mode=0o755)
 (native_home/".config/herdr/config.toml").write_text("")
 server=as_uid(13001,["/usr/local/bin/herdr","server"],env={"HOME":str(native_home),"HERDR_SOCKET_PATH":"/run/ace-native/control.sock","SHELL":"/bin/sh"})
 wait_for(lambda:pathlib.Path("/run/ace-native/control.sock").exists())
 wid=native("workspace.create",{"cwd":"/home/ace-13001","focus":False})["workspace"]["workspace_id"]
 sock=pathlib.Path("/run/ace-native/control.sock").stat();server_id=identity(server.pid)
 os.chown("/run/ace-native",0,0)
 for path,acl in (("/run/ace-native","u:13001:--x,u:13002:--x"),("/run/ace-native/control.sock","u:13002:rw-"),("/run/ace-authority","u:13001:--x,u:13002:--x,u:13004:--x")):
  subprocess.run(["setfacl","-m",acl,path],check=True)
 authority_data={"uid":13003,"gid":13003,"groups":[13003],"socket_path":"/run/ace-authority/control.sock","state_root":"/var/lib/ace-authority","composition":"launch"}
 project={"journal_repository":"/var/lib/ace-journal","evidence_git_ref":"refs/ace/execution","evidence_checkout_root":"/var/lib/ace-checkout","assignment_root":"/var/lib/ace-assignments","candidate_root":"/var/lib/ace-candidates","launcher_uids":[13002],"reviewer_uids":[],"worker_uids":[13001],"service_executor_uids":[],"supervisor_uids":[13004],"peer_credentials":{str(uid):{"gid":uid,"groups":[uid],"scratch_root":path} for uid,path in ((13001,"/var/lib/ace-worker"),(13002,"/var/lib/ace-launcher"),(13004,"/var/lib/ace-supervisor"))}}
 mapping={"project_id":"project","authority_id":"authority","launcher_uid":13002,"launcher_gid":13002,"launcher_groups":[13002],"worker_uid":13001,"worker_gid":13001,"worker_groups":[13001],"worker_actor":"worker","worker_cwd":"/home/ace-13001","worker_argv":["/usr/libexec/ace-fixture-payload"],"worker_env":{"PATH":"/usr/bin:/bin"},"bootstrap":"/usr/libexec/ace-worker-gate","bootstrap_sha256":hashlib.sha256(pathlib.Path("/usr/libexec/ace-worker-gate").read_bytes()).hexdigest(),"native":{"workspace_id":wid,"socket_path":"/run/ace-native/control.sock","socket_identity":[sock.st_dev,sock.st_ino,sock.st_uid],"executable":"/usr/local/bin/herdr","version":"0.9.3","server_identity":server_id}}
 pathlib.Path("/etc/ace").mkdir(mode=0o755);pathlib.Path("/etc/ace/assignment-authorities.json").write_text(json.dumps({"schema":"ace.assign.authorities/v1","authorities":{"authority":authority_data},"projects":{"project":project},"launch_mappings":{"mapping":mapping}}))
 definition={"session_id":"assignment","name":"installed native fixture","created_at":"2026-10-05T00:00:00Z","source_config":"fixture","task_id":"09j","project_id":"project"}
 pathlib.Path("/etc/ace/definition.json").write_text(json.dumps(definition))
 for args in (("init","-b","main","/var/lib/ace-journal"),("-C","/var/lib/ace-journal","-c","user.name=fixture","-c","user.email=fixture@localhost","commit","--allow-empty","-m","base")):
  process=as_uid(13003,["git",*args]);assert process.wait()==0
 base=git("rev-parse","HEAD")
 authority=as_uid(13003,["ace-assign","authority","serve","--authority","authority"])
 wait_for(lambda:pathlib.Path("/run/ace-authority/control.sock").exists())
 subprocess.run(["setfacl","-m","u:13001:rw-,u:13002:rw-,u:13004:rw-","/run/ace-authority/control.sock"],check=True)

 def hostile_worker_checks(target_pid=None):
  code = """import os,ctypes,json,pathlib,sys
libc=ctypes.CDLL(None,use_errno=True);pid=int(sys.argv[1]);results={}
results['ptrace']={'result':libc.ptrace(16,pid,0,0),'errno':ctypes.get_errno()}
class IOVec(ctypes.Structure):_fields_=[('base',ctypes.c_void_p),('length',ctypes.c_size_t)]
buffer=ctypes.create_string_buffer(1);local=IOVec(ctypes.cast(buffer,ctypes.c_void_p),1);remote=IOVec(1,1)
results['process_vm_readv']={'result':libc.process_vm_readv(pid,ctypes.byref(local),1,ctypes.byref(remote),1,0),'errno':ctypes.get_errno()}
results['process_vm_writev']={'result':libc.process_vm_writev(pid,ctypes.byref(local),1,ctypes.byref(remote),1,0),'errno':ctypes.get_errno()}
try:
 fd=os.open(f'/proc/{pid}/mem',os.O_WRONLY);os.close(fd);results['process_mem_write']='unexpectedly_opened'
except OSError as e:results['process_mem_write']=e.errno
for name,path in [('server_mem',f'/proc/{pid}/mem'),('authority_journal','/var/lib/ace-journal/.git/HEAD'),('bootstrap_write','/usr/libexec/ace-worker-gate'),('mapping_write','/etc/ace/assignment-authorities.json'),('native_config_write','/var/lib/ace-native-home/.config/herdr/config.toml')]:
 try:
  fd=os.open(path,os.O_RDONLY if name in ('server_mem','authority_journal') else os.O_WRONLY);os.close(fd);results[name]='unexpectedly_opened'
 except OSError as e:results[name]=e.errno
try:os.setuid(0);results['setuid_root']='unexpectedly_succeeded'
except OSError as e:results['setuid_root']=e.errno
print(json.dumps(results))
"""
  process=as_uid(13001,["python3","-c",code,str(target_pid or server.pid)],stdout=subprocess.PIPE,text=True)
  output=process.communicate(timeout=5)[0];assert process.returncode==0
  result=json.loads(output);assert result['ptrace']=={'result':-1,'errno':1},result
  assert result['process_vm_readv']=={'result':-1,'errno':1},result
  assert result['process_vm_writev']=={'result':-1,'errno':1},result
  assert result['process_mem_write'] in (1,13),result
  for key in ('server_mem','authority_journal','bootstrap_write','mapping_write','native_config_write'):assert result[key] in (1,13),result
  assert result['setuid_root']==1,result
  return result

 # Disposable guest-only SUID executable: NNP must prevent gaining root on exec.
 import shutil
 shutil.copyfile('/usr/bin/id','/usr/libexec/ace-fixture-setuid')
 os.chown('/usr/libexec/ace-fixture-setuid',0,0);os.chmod('/usr/libexec/ace-fixture-setuid',0o4755)
 suid=as_uid(13001,['/usr/libexec/ace-fixture-setuid','-u'],stdout=subprocess.PIPE,text=True)
 suid_uid=suid.communicate(timeout=5)[0].strip();assert suid.returncode==0 and suid_uid=='13001'
 proof['post_exec_suid']={'root_installed_mode':'4755','effective_uid':int(suid_uid),'no_new_privs':1}
 proof['hostile_worker']=hostile_worker_checks()
 proof["server_identity"]=server_id;proof["authority_identity"]=identity(authority.pid);proof["process_policy"]={str(pid):{k:v.strip() for k,v in (line.split(":",1) for line in pathlib.Path(f"/proc/{pid}/status").read_text().splitlines()) if k in ("CapInh","CapPrm","CapEff","CapBnd","CapAmb","NoNewPrivs")} for pid in (server.pid,authority.pid)};proof["installed_workspace"]=wid
 dry=as_uid(13002,["ace-assign","authority","launch","--mapping","mapping","--dry-run"]);assert dry.wait(timeout=15)==0
 proof["native_child_baseline"]=server_children()
 launch=as_uid(13002,["ace-assign","authority","launch","--mapping","mapping","--assignment","assignment","--definition","/etc/ace/definition.json","--step","010","--base-head",base,"--mutation","installed-launch"]);assert launch.wait(timeout=30)==0
 proof["native_children_before_verdict"]=server_children()
 proof["native_layout_before_verdict"]=native("workspace.get",{"workspace_id":wid})
 states=journal_states();proof["canonical_phases"]=[state["phase"] for state in states];assert states[-1]["phase"]=="issued",states
 wait_for(lambda:len(pathlib.Path("/run/ace-payload-starts").read_text().splitlines())==1)
 proof["payload_start_lines"]=pathlib.Path("/run/ace-payload-starts").read_text().splitlines();proof["canonical_binding"]=states[-1]["process_binding"]
 proof["native_children_after_launch"]=server_children()
 delta=[row for row in proof["native_children_after_launch"] if row["pid"] not in {old["pid"] for old in proof["native_child_baseline"]}]
 assert len(delta)==1 and delta[0]["pid"]==states[-1]["process_binding"]["process_identity"]["pid"] and delta[0]["exe"]=="/usr/libexec/ace-fixture-payload",delta
 proof["worker_after_exec"]=identity(states[-1]["process_binding"]["process_identity"]["pid"])
 assert proof["worker_after_exec"]==states[-1]["process_binding"]["process_identity"]

 # Distinct worker cannot forge a launch mutation even with the actual ticket.
 attack_code=r"""import socket,json,sys
s=socket.socket(socket.AF_UNIX);s.connect('/run/ace-authority/control.sock');s.sendall((json.dumps({'version':1,'operation':'release_launch','mutation_id':'worker-forge','project_id':'project','params':json.loads(sys.argv[1])})+'\n').encode());print(s.makefile('rb').readline().decode())
"""
 binding=states[-1]['process_binding'];current=states[-1]
 attack_params={k:current[k] for k in ('assignment_id','attempt_id','launch_ticket')};attack_params.update({'mapping_id':'mapping','process_binding':binding,'expected_generation':current['generation']})
 attack=as_uid(13001,['python3','-c',attack_code,json.dumps(attack_params)],stdout=subprocess.PIPE,text=True)
 result=json.loads(attack.communicate(timeout=5)[0]);assert result['status']=='error',result
 proof['worker_forged_release']=result
 before=server_children()
 retry=as_uid(13002,['ace-assign','authority','launch','--mapping','mapping','--assignment','assignment','--definition','/etc/ace/definition.json','--step','010','--base-head',base,'--mutation','installed-launch'])
 assert retry.wait(timeout=15)!=0
 assert server_children()==before
 proof['new_launcher_retry']='refused_without_creation'

 def phase(mode):
  return as_uid(13002,['ruby','/opt/ace-fixture/phase-client.rb',mode,base])
 loss=phase('launcherloss')
 wait_for(lambda:any(state.get('phase')=='bound' for state in journal_states('fixture-launcherloss')),15)
 bound=max(journal_states('fixture-launcherloss'),key=lambda state:state['generation'])
 pid=bound['process_binding']['process_identity']['pid']
 proof['gated_child_memory_write']=hostile_worker_checks(pid)
 proof['startup_interval']='Inherited enforced Yama2 and empty capabilities/NNP; actual memory probes observe original gated child after layout/bind, not the interval before first prctl.'
 # Bytes sent to the pane stdin cannot act as an authenticated socket permission.
 native('pane.send_text',{'pane_id':bound['process_binding']['pane'],'text':'echo forged-release\n'})
 assert len(pathlib.Path('/run/ace-payload-starts').read_text().splitlines())==1

 # Same-UID direct native child with the real ticket still lacks canonical child identity.
 mimic_code=r"""import socket,json,sys
s=socket.socket(socket.AF_UNIX);s.connect('/run/ace-native/control.sock');s.sendall((json.dumps({'id':'worker-mimic','method':'layout.apply','params':json.loads(sys.argv[1])})+'\n').encode());print(s.makefile('rb').readline().decode())
"""
 mimic_params={'workspace_id':wid,'focus':False,'root':{'type':'pane','cwd':'/home/ace-13001','command':['/usr/libexec/ace-worker-gate','mapping',bound['launch_ticket']]}}
 mimic=as_uid(13001,['python3','-c',mimic_code,json.dumps(mimic_params)],stdout=subprocess.PIPE,text=True)
 mimic_reply=json.loads(mimic.communicate(timeout=5)[0]);assert mimic.returncode==0 and 'result' in mimic_reply,mimic_reply
 mimic_pane=mimic_reply['result']['layout']['root']['pane_id']
 mimic_pid=native('pane.process_info',{'pane_id':mimic_pane})['process_info']['shell_pid']
 assert mimic_pid!=pid
 proof['worker_native_gate_mimic']={'identity':identity(mimic_pid),'canonical_child':bound['process_binding']['process_identity'],'permission':'none'}
 assert len(pathlib.Path('/run/ace-payload-starts').read_text().splitlines())==1
 native('pane.close',{'pane_id':mimic_pane})
 loss.kill();loss.wait()
 wait_for(lambda:not pathlib.Path('/proc/'+str(pid)).exists(),5)
 terminate=as_uid(13004,['ace-assign','authority','terminate','--mapping','mapping','--assignment','fixture-launcherloss','--attempt',bound['attempt_id']])
 assert terminate.wait(timeout=15)==0
 terminal=max(journal_states('fixture-launcherloss'),key=lambda state:state['generation'])
 assert terminal['phase']=='failed' and terminal['abort_observation']['release']=='not_issued' and not any(item['phase']=='issued' for item in journal_states('fixture-launcherloss')),terminal
 proof['launcherloss']={'exact_child':bound['process_binding']['process_identity'],'final':terminal,'payload_count':len(pathlib.Path('/run/ace-payload-starts').read_text().splitlines())}
 assert proof['launcherloss']['payload_count']==1

 lost=phase('lostrelease');assert lost.wait(timeout=15)==0
 release=max(journal_states('fixture-lostrelease'),key=lambda state:state['generation'])
 assert release['phase']=='issued' and release['execution']=='potentially_executed'
 wait_for(lambda:len(pathlib.Path('/run/ace-payload-starts').read_text().splitlines())==2)
 proof['lostrelease']={'final':release,'payload_count':2,'exact_replay':'true_as_asserted_by_original_client'}
 # Issued child death does not prove absence of all attributable writers.
 native('pane.close',{'pane_id':release['process_binding']['pane']})
 issued_stop=as_uid(13004,['ace-assign','authority','terminate','--mapping','mapping','--assignment','fixture-lostrelease','--attempt',release['attempt_id']])
 assert issued_stop.wait(timeout=15)==0
 stopped=max(journal_states('fixture-lostrelease'),key=lambda state:state['generation'])
 assert stopped['phase']=='uncertain' and stopped['execution']=='potentially_executed',stopped
 proof['issued_child_exit']=stopped

 creation_baseline=server_children()
 missing=phase('lostcreation');assert missing.wait(timeout=15)==0
 created=server_children();delta=[row for row in created if row['pid'] not in {row['pid'] for row in creation_baseline}]
 assert len(delta)==1 and delta[0]['exe']=='/usr/libexec/ace-worker-gate',delta
 reserved=journal_states('fixture-lostcreation')[-1]
 assert reserved['phase']=='reserved' and 'process_binding' not in reserved
 proof['lostcreation']={'one_gate_only':delta,'canonical':reserved,'payload_count':2,'exact_reservation_replay':'true_as_asserted_by_original_client'}
 assert len(pathlib.Path('/run/ace-payload-starts').read_text().splitlines())==2

 # Actual original-client reply losses and process crash stages, before authority restart.
 proof['additional_windows']={}
 for mode,expected in [('lostreserve','reserved'),('prespawn','reserved'),('spawncrash','reserved'),('recordcrash','recorded'),('recordreplycrash','recorded'),('bindreplycrash','bound')]:
  prior=server_children();count=len(pathlib.Path('/run/ace-payload-starts').read_text().splitlines())
  proc=phase(mode)
  wait_for(lambda:journal_states('fixture-'+mode) and journal_states('fixture-'+mode)[-1]['phase']==expected,15)
  current=journal_states('fixture-'+mode)[-1]
  if mode=='spawncrash':wait_for(lambda:len(server_children())>len(prior),5)
  if mode=='lostreserve':assert proc.wait(timeout=10)==0
  else:proc.kill();proc.wait()
  if 'process_binding' in current:
   child=current['process_binding']['process_identity']['pid']
   terminate=as_uid(13004,['ace-assign','authority','terminate','--mapping','mapping','--assignment','fixture-'+mode,'--attempt',current['attempt_id']])
   assert terminate.wait(timeout=15)==0
   wait_for(lambda:not pathlib.Path('/proc/'+str(child)).exists(),5)
   final=journal_states('fixture-'+mode)[-1]
   assert final['phase']=='failed' and final['abort_observation']['release']=='not_issued',final
  else:
   final=journal_states('fixture-'+mode)[-1];assert final==current
  assert len(pathlib.Path('/run/ace-payload-starts').read_text().splitlines())==count
  if mode in ('lostreserve','prespawn'):assert server_children()==prior
  proof['additional_windows'][mode]={'before':current,'final':final,'payload_count':count,'native_children':server_children()}
 for mode in ('lostrecord','lostbind'):
  count=len(pathlib.Path('/run/ace-payload-starts').read_text().splitlines())
  proc=phase(mode);assert proc.wait(timeout=15)==0
  wait_for(lambda:len(pathlib.Path('/run/ace-payload-starts').read_text().splitlines())==count+1)
  final=journal_states('fixture-'+mode)[-1];assert final['phase']=='issued'
  proof['additional_windows'][mode]={'final':final,'payload_count':count+1,'exact_replay':'asserted by original installed client'}
  native('pane.close',{'pane_id':final['process_binding']['pane']})

 # Authority crash closes the original gate stream; replacement owner has no retained pidfd proof.
 crash=phase('authorityloss')
 wait_for(lambda:any(state.get('phase')=='bound' for state in journal_states('fixture-authorityloss')),15)
 crash_state=journal_states('fixture-authorityloss')[-1]
 crash_pid=crash_state['process_binding']['process_identity']['pid']
 authority.kill();authority.wait()
 wait_for(lambda:not pathlib.Path('/proc/'+str(crash_pid)).exists(),5)
 # Verified installer recovery: old owner positively exited, original socket inode still fixed.
 old_endpoint=pathlib.Path('/run/ace-authority/control.sock').stat()
 assert old_endpoint.st_uid==13003
 os.unlink('/run/ace-authority/control.sock')
 authority=as_uid(13003,['ace-assign','authority','serve','--authority','authority'])
 wait_for(lambda:pathlib.Path('/run/ace-authority/control.sock').exists())
 subprocess.run(['setfacl','-m','u:13001:rw-,u:13002:rw-,u:13004:rw-','/run/ace-authority/control.sock'],check=True)
 status=as_uid(13004,['ace-assign','authority','status','--mapping','mapping','--assignment','fixture-authorityloss','--attempt',crash_state['attempt_id']])
 assert status.wait(timeout=15)==0
 refusal=as_uid(13004,['ace-assign','authority','terminate','--mapping','mapping','--assignment','fixture-authorityloss','--attempt',crash_state['attempt_id']])
 assert refusal.wait(timeout=15)!=0
 retained=journal_states('fixture-authorityloss')[-1]
 assert retained==crash_state and retained['phase']=='bound'
 assert len(pathlib.Path('/run/ace-payload-starts').read_text().splitlines())==4
 proof['authority_crash_recovery']={'canonical':retained,'replacement_identity':identity(authority.pid),'termination':'refused_without_retained_exact_handle','payload_count':4}
 crash.kill();crash.wait()
 # Installer-only endpoint replacement: pinned generation refuses without fallback.
 os.rename('/run/ace-native/control.sock','/run/ace-native/original.sock')
 replacement=socket.socket(socket.AF_UNIX);replacement.bind('/run/ace-native/control.sock');os.chown('/run/ace-native/control.sock',13001,13001);os.chmod('/run/ace-native/control.sock',0o600)
 subprocess.run(['setfacl','-m','u:13002:rw-','/run/ace-native/control.sock'],check=True)
 refusal=as_uid(13002,['ace-assign','authority','launch','--mapping','mapping','--dry-run']);assert refusal.wait(timeout=10)!=0
 replacement.close();os.unlink('/run/ace-native/control.sock');os.rename('/run/ace-native/original.sock','/run/ace-native/control.sock')
 proof['native_endpoint_replacement']='refused'
 for label,args in [('dac_override_bounding',['setpriv','--bounding-set=-all,+dac_override','--no-new-privs','--reuid=13002','--regid=13002','--groups=13002']),('capability_bounding',['setpriv','--bounding-set=-all,+setuid','--no-new-privs','--reuid=13002','--regid=13002','--groups=13002']),('no_new_privs_missing',['setpriv','--bounding-set=-all','--reuid=13002','--regid=13002','--groups=13002'])]:
  process=subprocess.Popen(args+['ace-assign','authority','launch','--mapping','mapping','--dry-run'],env=ENV|{'HOME':'/home/ace-13002'})
  assert process.wait(timeout=10)!=0
  proof[label]='refused'
 
 native('workspace.close',{'workspace_id':wid})
 refusal=as_uid(13002,['ace-assign','authority','launch','--mapping','mapping','--dry-run']);assert refusal.wait(timeout=10)!=0
 proof['closed_installed_container']='refused_without_fallback'
 # Real native restart, followed by explicit root installer refresh; no adoption.
 old_server=identity(server.pid);old_socket=mapping['native']['socket_identity']
 server.terminate();assert server.wait(timeout=5)==0
 stale=as_uid(13002,['ace-assign','authority','launch','--mapping','mapping','--dry-run'])
 assert stale.wait(timeout=10)!=0
 # The old native process positively exited. These endpoints are fixture-owned.
 for endpoint in ('/run/ace-native/control.sock','/run/ace-native/client.sock'):
  if pathlib.Path(endpoint).exists():os.unlink(endpoint)
 subprocess.run(['setfacl','-b','/run/ace-native'],check=True)
 os.chown('/run/ace-native',13001,13001);os.chmod('/run/ace-native',0o700)
 server=as_uid(13001,['/usr/local/bin/herdr','server'],env={'HOME':str(native_home),'HERDR_SOCKET_PATH':'/run/ace-native/control.sock','SHELL':'/bin/sh'})
 wait_for(lambda:pathlib.Path('/run/ace-native/control.sock').exists())
 new_wid=native('workspace.create',{'cwd':'/home/ace-13001','focus':False})['workspace']['workspace_id']
 new_server=identity(server.pid);new_socket=pathlib.Path('/run/ace-native/control.sock').stat()
 assert new_server['started_at']!=old_server['started_at']
 assert [new_socket.st_dev,new_socket.st_ino,new_socket.st_uid]!=old_socket
 stale=as_uid(13002,['ace-assign','authority','launch','--mapping','mapping','--dry-run'])
 assert stale.wait(timeout=10)!=0
 mapping['native'].update({'workspace_id':new_wid,'server_identity':new_server,'socket_identity':[new_socket.st_dev,new_socket.st_ino,new_socket.st_uid]})
 fixed_map={'schema':'ace.assign.authorities/v1','authorities':{'authority':authority_data},'projects':{'project':project},'launch_mappings':{'mapping':mapping}}
 path=pathlib.Path('/etc/ace/assignment-authorities.json')
 pending=path.with_suffix('.installer');pending.write_text(json.dumps(fixed_map));pending.chmod(0o644);os.replace(pending,path)
 os.chown('/run/ace-native',0,0);os.chmod('/run/ace-native',0o700)
 subprocess.run(['setfacl','-m','u:13001:--x','/run/ace-native'],check=True)
 missing_acl=as_uid(13002,['ace-assign','authority','launch','--mapping','mapping','--dry-run'])
 assert missing_acl.wait(timeout=10)!=0
 subprocess.run(['setfacl','-m','u:13002:--x','/run/ace-native'],check=True)
 subprocess.run(['setfacl','-m','u:13002:rw-','/run/ace-native/control.sock'],check=True)
 # New owner explicitly loads refreshed installed map after old authority exit.
 authority.kill();authority.wait();os.unlink('/run/ace-authority/control.sock')
 authority=as_uid(13003,['ace-assign','authority','serve','--authority','authority'])
 wait_for(lambda:pathlib.Path('/run/ace-authority/control.sock').exists())
 subprocess.run(['setfacl','-m','u:13001:rw-,u:13002:rw-,u:13004:rw-','/run/ace-authority/control.sock'],check=True)
 subprocess.run(['groupadd','-g','13006','ace-13006'],check=True)
 subprocess.run(['useradd','-u','13006','-g','13006','-m','ace-13006'],check=True)
 connect_code="import socket; s=socket.socket(socket.AF_UNIX); s.connect('/run/ace-native/control.sock')"
 unrelated=as_uid(13006,['python3','-c',connect_code]);assert unrelated.wait(timeout=5)!=0
 mapped=as_uid(13002,['ace-assign','authority','launch','--mapping','mapping','--dry-run']);assert mapped.wait(timeout=10)==0
 restart_definition=definition|{'session_id':'fixture-native-restart'}
 pathlib.Path('/etc/ace/restart-definition.json').write_text(json.dumps(restart_definition))
 baseline=server_children();count=len(pathlib.Path('/run/ace-payload-starts').read_text().splitlines())
 reconnect=as_uid(13002,['ace-assign','authority','launch','--mapping','mapping','--assignment','fixture-native-restart','--definition','/etc/ace/restart-definition.json','--step','010','--base-head',base,'--mutation','native-restart-launch'])
 assert reconnect.wait(timeout=30)==0
 wait_for(lambda:len(pathlib.Path('/run/ace-payload-starts').read_text().splitlines())==count+1)
 final=journal_states('fixture-native-restart')[-1];assert final['phase']=='issued'
 delta=[row for row in server_children() if row['pid'] not in {row['pid'] for row in baseline}]
 assert len(delta)==1 and delta[0]['pid']==final['process_binding']['process_identity']['pid'],delta
 proof['native_server_restart']={'old_server':old_server,'new_server':new_server,'old_socket':old_socket,'new_socket':mapping['native']['socket_identity'],'installed_workspace':new_wid,'stale_mapping':'refused','missing_launcher_acl':'refused','unrelated_uid':'refused','mapped_launcher':'public launch issued','baseline':baseline,'fresh_child':delta,'canonical':final}
 proof['verdict']='expanded_installed_cases_passed'

except BaseException:
 proof["failure"]=traceback.format_exc();traceback.print_exc()
finally:
 for process in (authority,server):
  if process and process.poll() is None:process.terminate()
 print("ACE_INSTALLED_PROOF "+json.dumps(proof),flush=True)
 if "failure" in proof:raise SystemExit(1)
