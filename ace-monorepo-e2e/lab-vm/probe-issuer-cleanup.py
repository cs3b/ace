"""Exercise installed issuer cleanup in a disposable Linux VM."""

import argparse
import json
import os
import re
import secrets
import shutil
import subprocess
import sys
import tempfile
import time

parser = argparse.ArgumentParser(description="Probe installed issuer cleanup with a synthetic provider")
parser.add_argument("--ruby", required=True)
parser.add_argument("--gem-home", required=True)
parser.add_argument("--shared-gems", required=True)
parser.add_argument("--version", required=True)
parser.add_argument("--startup-recovery", action="store_true")
args = parser.parse_args()
if os.geteuid() != 0:
    parser.error("requires root inside the disposable Linux VM")
for value in (args.ruby, args.gem_home, args.shared_gems):
    if not value.startswith("/") or not re.fullmatch(r"/[A-Za-z0-9_./-]+", value):
        parser.error("paths must be simple absolute paths")
if not re.fullmatch(r"[A-Za-z0-9.]+", args.version):
    parser.error("invalid gem version")

unit = "ace-e2e-issuer-probe-" + secrets.token_hex(8) + ".service"
unit_file = "/run/systemd/system/" + unit
if os.path.lexists(unit_file):
    raise RuntimeError("unit already exists")
root = tempfile.mkdtemp(prefix="ace-issuer-full-", dir="/run")
nonce = secrets.token_hex(8)
session_dir = "/run/ace-auth-" + nonce
os.mkdir(session_dir, 0o711)
os.chmod(session_dir, 0o711)
passed = False
ruby = r"""
gem 'ace-lab','= '+ENV.fetch('ACE_E2E_GEM_VERSION')
require 'ace/lab'; require 'ace/lab/auth/issuer_cleanup'; require 'etc'; require 'yaml'; require 'time'
root=ARGV.fetch(1); nonce=ARGV.fetch(2); dir='/run/ace-auth-'+nonce; account=Etc.getpwnam('nobody')
class ProbeProvider
 def initialize(root); @root=root; end
 def revoke(profile:, token_ref:, token:)
  raise Ace::Lab::Auth::Providers::RefusedError, 'missing token' unless token=='synthetic-token'
  File.write(File.join(@root,'revoked'),'confirmed'); :revoked
 end
end
Ace::Lab::Auth::Providers.register('probe',ProbeProvider.new(root))
document={'auth'=>{'leases_dir'=>root+'/leases','credentials_dir'=>root+'/other','profiles'=>{'test'=>{'provider'=>'probe','roles'=>['worker'],'repos'=>['ace']}}}}.to_yaml
Ace::Lab::Molecules::GrantResolver.define_singleton_method(:read_verified){|_| document}
svc=Ace::Lab::Auth::Service.new
if ARGV.fetch(0)=='seed'
 lease=svc.store.create(profile:'test',role:'worker',principal:account.name,task:'t',assignment:'a',repos:['ace'],use_until:(Time.now.utc+60).iso8601,provider_expiry:nil,token_ref:'ref',session_uid:account.uid,session_id:'a'*32,session_unit:'ace-auth-session-worker-'+nonce+'.service',issuer_invocation:ENV.fetch('INVOCATION_ID'))
 svc.store.update(lease['id']){|r|r['state']='issued'}
 path=Ace::Lab::Auth::CredentialHandoff.new(dir,recipient:account.name,owner_uid:account.uid).deliver(lease['id'],'synthetic-token')
 File.write(root+'/ready.tmp', lease['id']+' '+path); File.rename(root+'/ready.tmp',root+'/ready'); sleep 300
else
 status=Ace::Lab::Auth::IssuerCleanup.run(service:svc)
 File.write(root+'/result',status.to_s)
 exit status
end
"""
try:
    script = root + "/probe.rb"
    with open(script, "x") as file:
        file.write(ruby)
    os.chmod(script, 0o600)
    bootstrap = root + "/bootstrap.rb"
    with open(bootstrap, "x") as file:
        file.write(ruby.split("if ARGV.fetch(0)=='seed'")[0])
    os.chmod(bootstrap, 0o600)
    stop_hook = "" if args.startup_recovery else (
        f"ExecStopPost=/bin/sh -c '{args.ruby} {args.gem_home}/gems/ace-lab-{args.version}/libexec/issuer-cleanup "
        f"cleanup {root} {nonce}; rc=$?; echo $rc > {root}/result.tmp; mv {root}/result.tmp {root}/result; exit $rc'"
    )
    content = f'''[Unit]
Description=Disposable ACE actual issuer cleanup probe
[Service]
Type=simple
Environment=GEM_HOME={args.gem_home}
Environment=GEM_PATH={args.gem_home}:{args.shared_gems}
Environment=ACE_TOOLCHAIN=installed
Environment=ACE_E2E_GEM_VERSION={args.version}
Environment=RUBYOPT=-r{bootstrap}
ExecStart={args.ruby} {script} seed {root} {nonce}
{stop_hook}
'''
    with open(unit_file, "x") as file:
        file.write(content)
    subprocess.run(["/usr/bin/systemctl", "daemon-reload"], check=True)
    subprocess.run(["/usr/bin/systemctl", "start", unit], check=True, timeout=30)
    for _ in range(200):
        if os.path.exists(root + "/ready"):
            break
        time.sleep(0.1)
    else:
        raise RuntimeError("issuer not ready")
    with open(root + "/ready") as file:
        lease, path = file.read().split(" ", 1)
    subprocess.run(["/usr/bin/systemctl", "kill", "--kill-whom=main", "--signal=KILL", unit], check=True, timeout=30)
    if args.startup_recovery:
        for _ in range(200):
            state = subprocess.check_output(
                ["/usr/bin/systemctl", "show", "-p", "ActiveState", "--value", unit], text=True
            ).strip()
            if state in ("inactive", "failed"):
                break
            time.sleep(0.1)
        else:
            raise RuntimeError("issuer did not stop before startup recovery")
        env = {
            "GEM_HOME": args.gem_home,
            "GEM_PATH": args.gem_home + ":" + args.shared_gems,
            "ACE_TOOLCHAIN": "installed",
            "ACE_E2E_GEM_VERSION": args.version,
            "RUBYOPT": "-r" + bootstrap,
            "PATH": "/usr/bin:/bin",
        }
        recovery = subprocess.run(
            [args.ruby, f"{args.gem_home}/gems/ace-lab-{args.version}/libexec/issuer-recover", "cleanup", root, nonce],
            env=env, capture_output=True, text=True, timeout=45,
        )
        fd = os.open(root + "/recovery.log", os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, "w") as file:
            file.write(recovery.stdout + "\n" + recovery.stderr)
        with open(root + "/result.tmp", "w") as file:
            file.write(str(recovery.returncode))
        os.replace(root + "/result.tmp", root + "/result")
    for _ in range(300):
        if os.path.exists(root + "/result"):
            break
        time.sleep(0.1)
    else:
        raise RuntimeError("cleanup hook did not finish")
    with open(root + "/result") as file:
        status = file.read().strip()
    if status != "0" or not os.path.exists(root + "/revoked") or os.path.exists(path):
        raise RuntimeError("cleanup result differs")
    with open(root + "/leases/" + lease + ".json") as file:
        if json.load(file)["state"] != "revoked":
            raise RuntimeError("lease not revoked")
    passed = True
    path_name = "startup_recovery" if args.startup_recovery else "sigkill_cleanup"
    print(f"installed_{path_name}=true provider_confirmed=true handoff_removed=true")
finally:
    subprocess.run(["/usr/bin/systemctl", "stop", unit], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)
    try:
        os.unlink(unit_file)
    except FileNotFoundError:
        pass
    subprocess.run(["/usr/bin/systemctl", "daemon-reload"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if passed:
        shutil.rmtree(root)
        shutil.rmtree(session_dir)
    else:
        print(f"probe evidence retained: {root} and {session_dir}", file=sys.stderr)

