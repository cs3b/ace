"""Probe socket activation and refusal in a disposable Linux VM."""

import argparse
import os
import re
import secrets
import subprocess
import sys
import time

parser = argparse.ArgumentParser(description='Probe socket activation against an isolated session')
parser.add_argument('--ruby', required=True)
parser.add_argument('--gem-home', required=True)
parser.add_argument('--shared-gems', required=True)
parser.add_argument('--version', required=True)
args = parser.parse_args()
if os.geteuid() != 0 or not os.path.isdir('/var/lib/ace-e2e'):
    parser.error('requires root inside a provisioned disposable ACE VM')
for path in (args.ruby, args.gem_home, args.shared_gems):
    if not path.startswith('/') or not re.fullmatch(r'/[A-Za-z0-9_./-]+', path):
        parser.error('paths must be simple absolute paths')
if not re.fullmatch(r'[A-Za-z0-9.]+', args.version):
    parser.error('invalid gem version')
nonce = secrets.token_hex(8)
sockunit = 'ace-e2e-auth-' + nonce + '.socket'
template = 'ace-e2e-auth-' + nonce + '@.service'
issuer_slice = 'ace-e2e-issuer-' + nonce + '.slice'
worker = 'ace-auth-session-worker-' + nonce + '.service'
paths = ['/run/systemd/system/' + name for name in (sockunit, template, worker)]
sock = '/run/ace-e2e-auth-' + nonce + '.sock'
client = '/run/ace-e2e-auth-client-' + nonce + '.py'
for path in paths + [sock, client]:
    if os.path.lexists(path):
        raise RuntimeError('probe path already exists')
ruby = args.ruby
home = args.gem_home
gem = home + '/gems/ace-lab-' + args.version
socket_conf = f'''[Socket]
ListenStream={sock}
SocketMode=0666
Accept=yes
Service={template}
'''
service_conf = f'''[Service]
Type=simple
User=root
Slice={issuer_slice}
StandardInput=socket
StandardOutput=journal
StandardError=journal
Environment=GEM_HOME={home}
Environment=GEM_PATH={home}:{args.shared_gems}
Environment=ACE_TOOLCHAIN=installed
ExecStart={ruby} {gem}/libexec/issuer-request
ExecStopPost={ruby} {gem}/libexec/issuer-cleanup
'''
worker_conf = f'''[Service]
Type=simple
Slice=ace-auth-sessions.slice
DynamicUser=yes
User=aceaw{nonce[:12]}
NoNewPrivileges=yes
CapabilityBoundingSet=
KillMode=control-group
Delegate=no
RuntimeDirectory=ace-auth-{nonce}
RuntimeDirectoryMode=0711
RuntimeDirectoryPreserve=no
ExecStart=/usr/bin/python3 {client}
'''
client_py = f"""import socket,json
s=socket.socket(socket.AF_UNIX)
s.connect({sock!r})
s.sendall((json.dumps({{'profile':'nonexistent-e2e-profile','role':'worker','task':'test','assignment':'test','repos':['e2e-integrator/ace']}})+'\\n').encode())
result=b''
while True:
 part=s.recv(4096)
 if not part: break
 result+=part
print(result.decode(),flush=True)
"""
with open('/proc/sys/kernel/yama/ptrace_scope') as file:
    original = file.read().strip()
passed = False
try:
    for path, content in zip(paths, [socket_conf, service_conf, worker_conf]):
        with open(path, 'x') as file:
            file.write(content)
    with open(client, 'x') as file:
        file.write(client_py)
    os.chmod(client, 0o755)
    with open('/proc/sys/kernel/yama/ptrace_scope', 'w') as file:
        file.write('2')
    subprocess.run(['/usr/bin/systemctl', 'daemon-reload'], check=True)
    subprocess.run(['/usr/bin/systemctl', 'start', sockunit], check=True, timeout=30)
    subprocess.run(['/usr/bin/systemctl', 'start', worker], check=True, timeout=30)
    for _ in range(200):
        state = subprocess.check_output(
            ['/usr/bin/systemctl', 'show', '-p', 'ActiveState', '--value', worker], text=True
        ).strip()
        if state in ('inactive', 'failed'):
            break
        time.sleep(0.1)
    else:
        raise RuntimeError('worker did not finish')
    result = subprocess.check_output(['/usr/bin/journalctl', '--no-pager', '-o', 'cat', '-u', worker], text=True)
    if '"ok":false' not in result or 'unknown auth profile' not in result:
        raise RuntimeError('did not observe authenticated refusal')
    passed = True
    print('socket_activated_issuer=true real_session_authenticated=true unknown_profile_refused=true')
finally:
    for unit in (worker, sockunit, issuer_slice):
        subprocess.run(['/usr/bin/systemctl', 'stop', unit], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30)
    for path in paths + [sock, client]:
        try:
            os.unlink(path)
        except FileNotFoundError:
            pass
    subprocess.run(['/usr/bin/systemctl', 'daemon-reload'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    with open('/proc/sys/kernel/yama/ptrace_scope', 'w') as file:
        file.write(original)
    if not passed:
        print(f'diagnostic journals retained: {worker}, {sockunit}, {issuer_slice}', file=sys.stderr)

