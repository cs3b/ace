"""Exercise installed command-cgroup recovery in a disposable Linux VM."""

import argparse
import os
import re
import secrets
import select
import shutil
import signal
import stat
import subprocess
import sys
import tempfile
import time

parser = argparse.ArgumentParser()
for option in ('ruby', 'gem-home', 'shared-gems', 'version'):
    parser.add_argument('--' + option, required=True)
args = parser.parse_args()
if os.geteuid() != 0 or not os.path.isdir('/var/lib/ace-e2e'):
    parser.error('requires root in a disposable ACE VM')
for path in (args.ruby, args.gem_home, args.shared_gems):
    if not re.fullmatch(r'/[A-Za-z0-9_./-]+', path) or os.path.normpath(path) != path:
        parser.error('paths must be canonical simple absolute paths')
if not re.fullmatch(r'[A-Za-z0-9.]+', args.version):
    parser.error('invalid version')


def run(argv, **kwargs):
    return subprocess.run(argv, check=True, timeout=20, text=True, **kwargs)


def output(argv):
    return subprocess.check_output(argv, timeout=20, text=True).strip()


nonce = secrets.token_hex(8)
unit = 'ace-auth-session-worker-' + nonce + '.service'
subgroup = None
process = None
child_handle = None
main_handle = None
control = None
started = False
passed = False
root = tempfile.mkdtemp(prefix='command-recovery.', dir='/var/lib/ace-e2e')
os.chmod(root, 0o700)
config = os.path.join(root, 'authorization.yml')
with open(config, 'x', encoding='utf-8') as file:
    file.write(f'''auth:
  leases_dir: {root}/leases
  credentials_dir: {root}/credentials
  profiles:
    test:
      provider: synthetic
      roles: [worker]
      principals: [probe]
      repos: [fixture]
''')
os.chmod(config, 0o600)
ruby = r'''
gem "ace-lab", "= #{ARGV.fetch(0)}"
require "ace/lab/auth"
path, unit, invocation = ARGV.values_at(1, 2, 3)
wrong = invocation == "a" * 32 ? "b" * 32 : "a" * 32
begin
  Ace::Lab::Auth::SessionAttachment.recover_command!(path: path, unit: unit, invocation_id: wrong)
  abort "foreign invocation was accepted"
rescue Ace::Lab::Auth::Error
end
Process.kill(0, Integer(ARGV.fetch(4))) # foreign invocation must not kill the command
class SyntheticProvider
  def capabilities = {"expiry_mode" => "process"}
  def revoke(profile:, token_ref:, token: nil) = :revoked
end
Ace::Lab::Auth::Providers.register("synthetic", SyntheticProvider.new)
service = Ace::Lab::Auth::Service.new(authorization_path: ARGV.fetch(5), principal: -> { "root" })
issuer = "f" * 32
lease = service.store.create(profile: "test", role: "worker", principal: "probe", task: "t", assignment: "a",
  repos: ["fixture"], use_until: (Time.now.utc + 60).iso8601, provider_expiry: nil,
  token_ref: "synthetic-ref", session_uid: Integer(ARGV.fetch(6)), session_id: invocation,
  session_unit: unit, issuer_invocation: issuer)
service.store.update(lease.fetch("id")) do |record|
  record["state"] = "issued"
  record["execution"] = "in-progress"
  record["execution_cgroup"] = path
end
result = service.revoke_issuer(invocation: issuer)
raise "issuer recovery did not revoke" unless result.size == 1 && result.first["cleanup"] == "revoked"
record = service.store.load(lease.fetch("id"))
raise "execution marker survived recovery" if record.key?("execution") || record.key?("execution_cgroup")
raise "repeated recovery was not idempotent" unless Ace::Lab::Auth::SessionAttachment.recover_command!(path: path, unit: unit, invocation_id: invocation) == :absent
puts "foreign invocation refused; issuer contained exact command and revoked lease"
'''
try:
    run(['/usr/bin/systemd-run', '--quiet', '--unit=' + unit, '--slice=ace-auth-sessions.slice',
         '--property=Type=exec', '--property=DynamicUser=yes', '--property=Delegate=no',
         '--property=NoNewPrivileges=yes', '/bin/sleep', '60'])
    started = True
    pid = int(output(['/usr/bin/systemctl', 'show', '--property=MainPID', '--value', unit]))
    group = output(['/usr/bin/systemctl', 'show', '--property=ControlGroup', '--value', unit])
    invocation = output(['/usr/bin/systemctl', 'show', '--property=InvocationID', '--value', unit])
    if pid <= 0 or not re.fullmatch(r'[0-9a-f]{32}', invocation) or os.path.basename(group) != unit:
        raise RuntimeError('session identity was not available')
    main_handle = os.pidfd_open(pid)
    info = os.stat('/proc/' + str(pid))
    if info.st_uid <= 0 or info.st_uid != info.st_gid:
        raise RuntimeError('session UID/GID are not isolated')
    subgroup = '/sys/fs/cgroup' + group + '/ace-exec-' + secrets.token_hex(16)
    os.mkdir(subgroup, 0o700)
    control = os.open(subgroup + '/cgroup.procs', os.O_WRONLY | os.O_CLOEXEC | os.O_NOFOLLOW)
    reader, writer = os.pipe()
    process = os.fork()
    if process == 0:
        try:
            os.close(reader)
            os.setgroups([])
            os.setgid(info.st_gid)
            os.setuid(info.st_uid)
            os.write(control, b'0\n')
            os.close(control)
            os.write(writer, b'ready\n')
            os.close(writer)
            os.setsid()
            time.sleep(60)
            os._exit(0)
        except BaseException:
            os._exit(1)
    os.close(writer)
    child_handle = os.pidfd_open(process)
    if not select.select([reader], [], [], 10)[0] or os.read(reader, 6) != b'ready\n':
        raise RuntimeError('command did not enter its cgroup')
    os.close(reader)
    env = {'PATH': '/usr/bin:/bin', 'HOME': '/var/empty', 'ACE_TOOLCHAIN': 'installed',
           'GEM_HOME': args.gem_home, 'GEM_PATH': args.gem_home + ':' + args.shared_gems}
    run([args.ruby, '-e', ruby, args.version, subgroup, unit, invocation, str(process), config,
         str(info.st_uid)], env=env)
    if not select.select([child_handle], [], [], 5)[0]:
        raise RuntimeError('command survived recovery')
    if select.select([main_handle], [], [], 0)[0]:
        raise RuntimeError('recovery stopped the session main process')
    os.waitpid(process, 0)
    process = None
    if os.path.lexists(subgroup):
        raise RuntimeError('command cgroup remained after recovery')
    passed = True
    print('command terminated; session remained active')
finally:
    if control is not None:
        os.close(control)
    if subgroup and os.path.isdir(subgroup):
        try:
            with open(subgroup + '/cgroup.kill', 'w', encoding='ascii') as kill:
                kill.write('1\n')
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                try:
                    os.rmdir(subgroup)
                    break
                except OSError:
                    time.sleep(0.05)
            else:
                passed = False
        except OSError:
            passed = False
    if process is not None:
        try:
            os.kill(process, signal.SIGKILL)  # our own unreaped child; its PID cannot be reused
        except ProcessLookupError:
            pass
        os.waitpid(process, 0)
    for fd in (child_handle, main_handle):
        if fd is not None:
            os.close(fd)
    if started:
        run(['/usr/bin/systemctl', 'stop', unit], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if passed:
        shutil.rmtree(root)
    if not passed:
        print('recovery probe failed; preserve ' + root + '; unit ' + unit, file=sys.stderr)
        sys.exit(1)
