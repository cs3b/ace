"""Exercise installed SessionPeer, SessionAttachment and SessionRunner together.

This disposable Linux probe uses a dummy filesystem command, not an auth
profile or token. It creates uniquely named systemd units and a socket.
"""

import argparse
import errno
import json
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
import urllib.error
import urllib.request

parser = argparse.ArgumentParser()
parser.add_argument('--ruby', required=True)
parser.add_argument('--gem-home', required=True)
parser.add_argument('--shared-gems', required=True)
parser.add_argument('--version', required=True)
parser.add_argument('--prepopulate-runtime', action='store_true',
                    help='require two refusals after an untrusted file is placed in the session runtime')
parser.add_argument('--issuer-crash', action='store_true',
                    help='kill a real session issuer during execution and verify its recovery hook')
parser.add_argument('--lease-expiry', action='store_true',
                    help='expire a session command and verify credential revocation')
parser.add_argument('--real-forgejo', action='store_true',
                    help='use a scoped token on the local disposable Forgejo in the issuer-crash scenario')
args = parser.parse_args()
if sum((args.prepopulate_runtime, args.issuer_crash, args.lease_expiry)) > 1:
    parser.error('choose one fault scenario')
if args.real_forgejo and not (args.issuer_crash or args.lease_expiry):
    parser.error('--real-forgejo requires --issuer-crash or --lease-expiry')
recovery_mode = args.issuer_crash or args.lease_expiry
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
recovery_path = os.path.join(root, 'recovery.rb')
config_path = os.path.join(root, 'authorization.yml')
recovered_path = os.path.join(root, 'recovered')
command_started = os.path.join(project, 'command-started')
admin_name = 'acecrash' + secrets.token_hex(8)
password_path = os.path.join(root, 'admin-password')
token_path = os.path.join(root, 'test-token')
forge_base = ['/usr/sbin/runuser', '-u', 'forgejo', '--', '/usr/local/bin/forgejo', 'admin', 'user']
forge_common = ['--config', '/etc/forgejo/app.ini', '--work-path', '/var/lib/forgejo']
admin_created = False
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
 if not {args.prepopulate_runtime!r} and not {recovery_mode!r} and result!=b"ok\\n": sys.exit(3)
 if {recovery_mode!r} and result!=b"": sys.exit(5)
if {recovery_mode!r}:
 import time
 deadline=time.monotonic()+40
 while not os.path.exists({recovered_path!r}) and time.monotonic()<deadline: time.sleep(.05)
 if not os.path.exists({recovered_path!r}): sys.exit(6)
print("lease_expiry_recovered" if {args.lease_expiry!r} else "contaminated_runtime_refused_twice" if {args.prepopulate_runtime!r} else (("issuer_crash_real_forgejo_recovered" if {args.real_forgejo!r} else "issuer_crash_recovered") if {recovery_mode!r} else "authenticated_session_runner_ok"),flush=True)
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
crash_server = r'''require "socket"
gem "ace-lab", "= #{ARGV.fetch(0)}"
require "ace/lab/auth"
class SyntheticProvider
  def capabilities = {"expiry_mode" => "process"}
  def revoke(profile:, token_ref:, token: nil) = :revoked
end
Ace::Lab::Auth::Providers.register("synthetic", SyntheticProvider.new)
socket = Socket.for_fd(0)
identity = Ace::Lab::Auth::SessionPeer.new.authenticate(socket)
raise "unexpected peer cwd" unless identity.cwd == File.realpath(ARGV.fetch(1))
account = Etc.getpwuid(identity.uid)
service = Ace::Lab::Auth::Service.new(authorization_path: ARGV.fetch(2), session: identity,
  issuer_invocation: ENV.fetch("INVOCATION_ID"))
profile_name = ARGV.fetch(4)
profile = service.config.fetch("profiles").fetch(profile_name)
provider = Ace::Lab::Auth::Providers.resolve(profile.fetch("provider"))
id = "lease-#{SecureRandom.hex(8)}"
repos = profile_name == "forge" ? ["e2e-integrator/ace"] : ["fixture"]
token_ref = profile_name == "forge" ? provider.token_ref_for(lease_id: id) : "synthetic-ref"
lease = service.store.create(id: id, profile: profile_name, role: "worker", principal: account.name, task: "t", assignment: "a",
  repos: repos, use_until: (Time.now.utc + 60).iso8601, provider_expiry: nil,
  token_ref: token_ref, session_uid: identity.uid, session_id: identity.invocation_id,
  session_unit: identity.unit, issuer_invocation: ENV.fetch("INVOCATION_ID"))
if profile_name == "forge"
  grant = provider.issue(profile: profile, lease: lease)
  token = grant.fetch("token")
  require "net/http"
  uri = URI("http://127.0.0.1:3000/api/v1/repos/e2e-integrator/ace")
  request = Net::HTTP::Get.new(uri)
  request["Authorization"] = "token #{token}"
  response = Net::HTTP.start(uri.hostname, uri.port, open_timeout: 5, read_timeout: 5) { |http| http.request(request) }
  raise "scoped Forgejo token was not usable before recovery" unless response.code.to_i == 200
  File.open(ARGV.fetch(5), File::WRONLY | File::CREAT | File::EXCL, 0600) { |file| file.write(token) }
else
  token = "synthetic-only"
end
handoff = Ace::Lab::Auth::CredentialHandoff.new(identity.runtime_dir, recipient: account.name,
  owner_uid: identity.uid, create_root: false)
handoff.deliver(lease.fetch("id"), token)
service.store.update(lease.fetch("id")) do |record|
  record["state"] = "issued"
  record["use_until"] = (Time.now.utc + 5).iso8601 if ARGV.fetch(6) == "expiry"
end
marker = ARGV.fetch(3)
if ARGV.fetch(6) == "crash"
  Thread.new do
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 20
    sleep 0.01 until File.file?(marker) || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
    Process.kill("KILL", Process.pid)
  end
  service.exec(lease_id: lease.fetch("id"), argv: ["/bin/sh", "-c", 'echo started > "$1"; exec /bin/sleep 60', "runner", marker])
  abort "issuer unexpectedly survived"
else
  cleanup_attempt = Thread.new do
    wait_until = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 3
    sleep 0.01 until File.file?(marker) || Process.clock_gettime(Process::CLOCK_MONOTONIC) > wait_until
    raise "command did not start before cleanup race" unless File.file?(marker)
    operator = Ace::Lab::Auth::Service.new(authorization_path: ARGV.fetch(2), principal: -> { "root" })
    begin
      operator.revoke_issuer(invocation: ENV.fetch("INVOCATION_ID"))
      raise "issuer recovery accepted a running command"
    rescue Ace::Lab::Auth::Error => error
      raise unless error.message.include?("issuer recovery could not inspect or clean leases")
    end
  end
  begin
    service.exec(lease_id: lease.fetch("id"), argv: ["/bin/sh", "-c", 'echo started > "$1"; exec /bin/sleep 60', "runner", marker])
    abort "expired command unexpectedly succeeded"
  rescue Ace::Lab::Auth::Error => error
    raise unless error.message.include?("lease expired during execution")
  end
  cleanup_attempt.value
  raise "command did not start" unless File.file?(marker)
end
'''
recovery = r'''gem "ace-lab", "= #{ARGV.fetch(0)}"
require "ace/lab/auth"
class SyntheticProvider
  def capabilities = {"expiry_mode" => "process"}
  def revoke(profile:, token_ref:, token: nil) = :revoked
end
Ace::Lab::Auth::Providers.register("synthetic", SyntheticProvider.new)
service = Ace::Lab::Auth::Service.new(authorization_path: ARGV.fetch(1), principal: -> { "root" })
result = service.revoke_issuer(invocation: ENV.fetch("INVOCATION_ID"))
raise "issuer recovery did not revoke the lease" unless result.size == 1 && result.first["cleanup"] == "revoked"
record = service.store.all.fetch(0)
raise "execution remained unresolved" if record.key?("execution") || record.key?("execution_cgroup")
raise "session main stopped during recovery" unless system("/usr/bin/systemctl", "is-active", "--quiet", ARGV.fetch(3))
File.write(ARGV.fetch(2), "recovered")
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
if recovery_mode:
    server = crash_server
    profile_name = 'forge' if args.real_forgejo else 'test'
    service_conf = service_conf.replace(
        f'ExecStart={args.ruby} {server_path} {args.version} {project}',
        f'ExecStart={args.ruby} {server_path} {args.version} {project} {config_path} {command_started} {profile_name} {token_path} {"expiry" if args.lease_expiry else "crash"}\n'
        f'ExecStopPost={args.ruby} {recovery_path} {args.version} {config_path} {recovered_path} {worker}')
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
    if args.real_forgejo:
        run(['/usr/bin/systemctl', 'is-active', '--quiet', 'ace-e2e-forgejo.service'])
        created = subprocess.run(forge_base + ['create'] + forge_common + [
            '--username', admin_name, '--email', admin_name + '@example.invalid', '--random-password',
            '--must-change-password=false', '--admin'], timeout=60, text=True, capture_output=True)
        if created.returncode:
            raise RuntimeError('temporary Forgejo administrator creation failed')
        admin_created = True
        match = re.search(r"(?i)password\s+is\s+'([^']+)'", created.stdout + '\n' + created.stderr)
        if not match:
            raise RuntimeError('temporary Forgejo administrator password format differs')
        fd = os.open(password_path, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, 'w', encoding='utf-8') as file:
            file.write(match.group(1))
    extra_paths = [recovery_path, config_path] if recovery_mode else []
    config = f'''auth:\n  leases_dir: {root}/leases\n  credentials_dir: {root}/credentials\n  profiles:\n    test:\n      provider: synthetic\n      roles: [worker]\n      principals: [session:worker]\n      repos: [fixture]\n'''
    if args.real_forgejo:
        config += f'''    forge:\n      provider: forgejo\n      roles: [worker]\n      principals: [session:worker]\n      repos: [e2e-integrator/ace]\n      scopes: ["write:repository"]\n      issuer:\n        url: http://127.0.0.1:3000\n        account: e2e-integrator\n        admin_username: {admin_name}\n        password_file: {password_path}\n'''
    extra_content = [recovery, config] if recovery_mode else []
    for path, content in zip(unit_paths + [client_path, server_path] + extra_paths,
                             [socket_conf, service_conf, worker_conf, client, server] + extra_content):
        with open(path, 'x', encoding='utf-8') as file:
            created_paths.append(path)
            file.write(content)
        os.chmod(path, 0o600 if path == config_path else 0o644)
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
    deadline = time.monotonic() + (45 if recovery_mode else 20)
    while time.monotonic() < deadline:
        state = output(['/usr/bin/systemctl', 'show', '--property=ActiveState', '--value', worker])
        if state in ('inactive', 'failed'):
            break
        time.sleep(0.1)
    else:
        raise RuntimeError('worker did not complete')
    journal = output(['/usr/bin/journalctl', '--no-pager', '-o', 'cat', '-u', worker])
    expected = ('contaminated_runtime_refused_twice' if args.prepopulate_runtime else
                (('issuer_crash_real_forgejo_recovered' if args.real_forgejo else 'issuer_crash_recovered')
                 if recovery_mode else 'authenticated_session_runner_ok'))
    if args.lease_expiry:
        expected = 'lease_expiry_recovered'
    if expected not in journal:
        raise RuntimeError('authenticated session runner did not succeed')
    created_path = os.path.join(project, 'authenticated-created')
    if recovery_mode:
        if not os.path.isfile(command_started) or not os.path.isfile(recovered_path):
            raise RuntimeError('issuer crash or recovery marker is missing')
        lease_dir = os.path.join(root, 'leases')
        files = [name for name in os.listdir(lease_dir) if name.endswith('.json')]
        if len(files) != 1:
            raise RuntimeError('unexpected lease inventory after issuer recovery')
        with open(os.path.join(lease_dir, files[0]), encoding='utf-8') as file:
            record = json.load(file)
        if record.get('state') != 'revoked' or 'execution' in record or 'execution_cgroup' in record:
            raise RuntimeError('issuer recovery did not settle the recorded execution')
        if args.real_forgejo:
            with open(token_path, encoding='utf-8') as file:
                token = file.read().strip()
            request = urllib.request.Request('http://127.0.0.1:3000/api/v1/repos/e2e-integrator/ace',
                                             headers={'Authorization': 'token ' + token})
            try:
                with urllib.request.urlopen(request, timeout=5):
                    raise RuntimeError('Forgejo token still authorizes after recovery')
            except urllib.error.HTTPError as error:
                if error.code not in (401, 403):
                    raise RuntimeError('unexpected Forgejo token verification response') from error
    elif args.prepopulate_runtime:
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
    if passed and admin_created:
        deleted = subprocess.run(forge_base + ['delete'] + forge_common + ['--username', admin_name],
                                 timeout=60, text=True, capture_output=True)
        if deleted.returncode:
            passed = False
            print('temporary Forgejo administrator removal failed: ' + admin_name, file=sys.stderr)
        else:
            print('temporary_admin_removed=true')
    if passed:
        shutil.rmtree(root)
    else:
        print(f'probe failed; preserve {root}; journals: {worker}, {sockunit}, {issuer_slice}; administrator: {admin_name if admin_created else "none"}', file=sys.stderr)
if not passed:
    sys.exit(1)
