"""Exercise installed SessionPeer, SessionAttachment and SessionRunner together.

This disposable Linux probe uses a dummy filesystem command, not an auth
profile or token. It creates uniquely named systemd units and a socket.
"""

import argparse
import errno
import os
import pwd
import re
import secrets
import shutil
import stat
import subprocess
import sys
import tempfile
import time

parser = argparse.ArgumentParser()
parser.add_argument('--ruby', required=True)
parser.add_argument('--gem-home', required=True)
parser.add_argument('--shared-gems', required=True)
parser.add_argument('--version', required=True)
parser.add_argument('--prepopulate-runtime', action='store_true',
                    help='require two refusals after an untrusted file is placed in the session runtime')
args = parser.parse_args()
base = '/var/lib/ace-e2e'
if os.geteuid() != 0:
    parser.error('requires root inside a disposable ACE VM')
for path in (args.ruby, args.gem_home, args.shared_gems):
    if not re.fullmatch(r'/[A-Za-z0-9_./-]+', path) or os.path.normpath(path) != path:
        parser.error('paths must be canonical simple absolute paths')
if not re.fullmatch(r'[A-Za-z0-9.]+', args.version):
    parser.error('invalid candidate version')
base_stat = os.lstat(base)
if not stat.S_ISDIR(base_stat.st_mode) or base_stat.st_uid != 0 or base_stat.st_mode & 0o022:
    parser.error('probe parent must be root-controlled')


def run(argv, **kwargs):
    return subprocess.run(argv, check=True, timeout=20, text=True, **kwargs)


def output(argv):
    return subprocess.check_output(argv, timeout=20, text=True).strip()


nonce = secrets.token_hex(8)
sockunit = 'ace-e2e-peer-' + nonce + '.socket'
template = 'ace-e2e-peer-' + nonce + '@.service'
issuer_slice = 'ace-e2e-peer-' + nonce + '.slice'
worker = 'ace-auth-session-worker-' + nonce + '.service'
unit_paths = ['/run/systemd/system/' + name for name in (sockunit, template, worker)]
socket_path = '/run/ace-e2e-peer-' + nonce + '.sock'
if any(os.path.lexists(path) for path in unit_paths + [socket_path]):
    raise RuntimeError('probe systemd path already exists')
root = tempfile.mkdtemp(prefix='authenticated-runner.', dir=base)
os.chmod(root, 0o755)
project, control = os.path.join(root, 'project'), os.path.join(root, 'control')
os.mkdir(project)
os.mkdir(control)
os.chmod(control, 0o777)
gate = os.path.join(control, 'gate')
os.mkfifo(gate, 0o666)
os.chmod(gate, 0o666)
account = pwd.getpwnam('mo')
os.chown(project, account.pw_uid, account.pw_gid)
client_path = os.path.join(root, 'client.py')
server_path = os.path.join(root, 'server.rb')
client = f'''import os,select,socket,sys
fd=os.open({gate!r},os.O_RDWR)
if not select.select([fd],[],[],20)[0] or os.read(fd,3)!=b"go\\n": sys.exit(2)
os.chdir({project!r})
if {args.prepopulate_runtime!r}:
 with open({('/run/ace-auth-' + nonce + '/untrusted')!r},'w') as f: f.write('untrusted')
for _ in range(2 if {args.prepopulate_runtime!r} else 1):
 s=socket.socket(socket.AF_UNIX); s.settimeout(15); s.connect({socket_path!r})
 result=b""
 while not result.endswith(b"\\n"):
  part=s.recv(1024)
  if not part: break
  result+=part
 s.close()
 if {args.prepopulate_runtime!r} and result!=b"": sys.exit(4)
 if not {args.prepopulate_runtime!r} and result!=b"ok\\n": sys.exit(3)
print("contaminated_runtime_refused_twice" if {args.prepopulate_runtime!r} else "authenticated_session_runner_ok",flush=True)
'''
server = r'''require "socket"
gem "ace-lab", "= #{ARGV.fetch(0)}"
expected = File.realpath(File.join(ENV.fetch("GEM_HOME"), "gems", "ace-lab-#{ARGV.fetch(0)}"))
raise "unexpected installed candidate" unless File.realpath(Gem.loaded_specs.fetch("ace-lab").full_gem_path) == expected
require "ace/lab"
require "ace/lab/auth"
require "ace/lab/auth/session_peer"
require "ace/lab/auth/session_attachment"
require "ace/lab/auth/session_runner"
socket = Socket.for_fd(0)
identity = nil
begin
  identity = Ace::Lab::Auth::SessionPeer.new.authenticate(socket)
  raise "unexpected peer cwd" unless identity.cwd == File.realpath(ARGV.fetch(1))
  attachment = Ace::Lab::Auth::SessionAttachment.new(identity: identity)
  runner = Ace::Lab::Auth::SessionRunner.new(uid: identity.uid, cwd: identity.cwd,
    namespace: identity.mount_namespace, attach: attachment)
  status = runner.call(["/usr/bin/touch", File.join(identity.cwd, "authenticated-created")], {"PATH" => "/usr/bin:/bin"})
  raise "runner failed: #{status}" unless status == 0
  socket.write("ok\n")
ensure
  identity&.close
  socket.close
end
'''
socket_conf = f'''[Socket]
ListenStream={socket_path}
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
Environment=GEM_HOME={args.gem_home}
Environment=GEM_PATH={args.gem_home}:{args.shared_gems}
Environment=ACE_TOOLCHAIN=installed
ExecStart={args.ruby} {server_path} {args.version} {project}
'''
worker_conf = f'''[Service]
Type=exec
Slice=ace-auth-sessions.slice
DynamicUser=yes
User=aceaw{nonce[:12]}
NoNewPrivileges=yes
CapabilityBoundingSet=
KillMode=control-group
Delegate=no
PrivateMounts=yes
ReadWritePaths={root}
WorkingDirectory={project}
RuntimeDirectory=ace-auth-{nonce}
RuntimeDirectoryMode=0711
RuntimeDirectoryPreserve=no
ExecStart=/usr/bin/python3 {client_path}
'''
with open('/proc/sys/kernel/yama/ptrace_scope', encoding='ascii') as file:
    original_yama = file.read().strip()
namespace_fd = None
created_paths = []
started = False
passed = False
try:
    for path, content in zip(unit_paths + [client_path, server_path],
                             [socket_conf, service_conf, worker_conf, client, server]):
        with open(path, 'x', encoding='utf-8') as file:
            created_paths.append(path)
            file.write(content)
        os.chmod(path, 0o644)
    with open('/proc/sys/kernel/yama/ptrace_scope', 'w', encoding='ascii') as file:
        file.write('2')
    run(['/usr/bin/systemctl', 'daemon-reload'])
    started = True
    run(['/usr/bin/systemctl', 'start', sockunit])
    run(['/usr/bin/systemctl', 'start', worker])
    pid = int(output(['/usr/bin/systemctl', 'show', '--property=MainPID', '--value', worker]))
    if pid <= 0:
        raise RuntimeError('worker has no main process')
    worker_stat = os.stat(f'/proc/{pid}')
    if worker_stat.st_uid <= 0 or worker_stat.st_uid == account.pw_uid:
        raise RuntimeError('worker does not have a separate dynamic UID')
    namespace_fd = os.open(f'/proc/{pid}/ns/mnt', os.O_RDONLY | os.O_CLOEXEC)
    pinned, host = os.fstat(namespace_fd), os.stat('/proc/1/ns/mnt')
    if (pinned.st_dev, pinned.st_ino) == (host.st_dev, host.st_ino):
        raise RuntimeError('worker has no private mount namespace')
    if int(output(['/usr/bin/systemctl', 'show', '--property=MainPID', '--value', worker])) != pid:
        raise RuntimeError('worker main process changed')
    run(['/usr/bin/systemctl', 'is-active', '--quiet', worker])
    run(['/usr/bin/nsenter', '--mount=/proc/self/fd/' + str(namespace_fd), '--', '/bin/mount', '--bind',
         '-o', f'X-mount.idmap=u:{account.pw_uid}:{worker_stat.st_uid}:1 g:{account.pw_gid}:{worker_stat.st_gid}:1',
         project, project], pass_fds=(namespace_fd,))
    # The worker opens both ends before waiting; opening for write is bounded
    # and refuses a worker that did not actually reach the gate.
    deadline = time.monotonic() + 10
    while True:
        try:
            gate_fd = os.open(gate, os.O_WRONLY | os.O_NONBLOCK)
            break
        except OSError as error:
            if error.errno != errno.ENXIO or time.monotonic() >= deadline:
                raise
            time.sleep(0.05)
    try:
        os.write(gate_fd, b'go\n')
    finally:
        os.close(gate_fd)
    deadline = time.monotonic() + 20
    while time.monotonic() < deadline:
        state = output(['/usr/bin/systemctl', 'show', '--property=ActiveState', '--value', worker])
        if state in ('inactive', 'failed'):
            break
        time.sleep(0.1)
    else:
        raise RuntimeError('worker did not complete')
    journal = output(['/usr/bin/journalctl', '--no-pager', '-o', 'cat', '-u', worker])
    expected = 'contaminated_runtime_refused_twice' if args.prepopulate_runtime else 'authenticated_session_runner_ok'
    if expected not in journal:
        raise RuntimeError('authenticated session runner did not succeed')
    created_path = os.path.join(project, 'authenticated-created')
    if args.prepopulate_runtime:
        if os.path.lexists(created_path):
            raise RuntimeError('contaminated runtime executed a command')
    else:
        created = os.stat(created_path)
        if (created.st_uid, created.st_gid) != (account.pw_uid, account.pw_gid):
            raise RuntimeError('created file is not owned by project owner')
    passed = True
    print(expected)
finally:
    stopped_clean = True
    if namespace_fd is not None:
        os.close(namespace_fd)
    if started:
        for unit in (worker, sockunit, issuer_slice):
            try:
                run(['/usr/bin/systemctl', 'stop', unit], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            except (subprocess.SubprocessError, OSError):
                passed = False
                stopped_clean = False
                print('could not stop probe unit: ' + unit, file=sys.stderr)
    if stopped_clean and os.path.lexists(socket_path):
        endpoint = os.lstat(socket_path)
        if stat.S_ISSOCK(endpoint.st_mode) and endpoint.st_uid == 0:
            os.unlink(socket_path)
        else:
            passed = False
            print('unexpected probe socket path: ' + socket_path, file=sys.stderr)
    for path in created_paths:
        try:
            os.unlink(path)
        except FileNotFoundError:
            pass
    try:
        run(['/usr/bin/systemctl', 'daemon-reload'], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    except (subprocess.SubprocessError, OSError):
        passed = False
    with open('/proc/sys/kernel/yama/ptrace_scope', 'w', encoding='ascii') as file:
        file.write(original_yama)
    if passed:
        shutil.rmtree(root)
    else:
        print(f'probe failed; preserve {root}; journals: {worker}, {sockunit}, {issuer_slice}', file=sys.stderr)
if not passed:
    sys.exit(1)
