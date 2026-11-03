"""Probe installed SessionRunner in a disposable systemd mount namespace.

The attachment is a test seam opening the session cgroup; this does not
authenticate a session or enable the guarded credential issuer.
"""

import argparse
import os
import pwd
import re
import secrets
import select
import shutil
import stat
import subprocess
import sys
import tempfile

parser = argparse.ArgumentParser()
parser.add_argument('--ruby', required=True)
parser.add_argument('--gem-home', required=True)
parser.add_argument('--shared-gems', required=True)
parser.add_argument('--version', required=True)
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


root = tempfile.mkdtemp(prefix='runner-probe.', dir=base)
os.chmod(root, 0o755)
project = os.path.join(root, 'project')
os.mkdir(project)
account = pwd.getpwnam('mo')
os.chown(project, account.pw_uid, account.pw_gid)
unit = 'ace-e2e-runner-' + secrets.token_hex(16) + '.service'
attempted = False
passed = False
namespace_fd = None
ruby_program = r'''
gem "ace-lab", "= #{ARGV.fetch(0)}"
expected_gem = File.realpath(File.join(ENV.fetch("GEM_HOME"), "gems", "ace-lab-#{ARGV.fetch(0)}"))
raise "unexpected installed candidate" unless File.realpath(Gem.loaded_specs.fetch("ace-lab").full_gem_path) == expected_gem
require "ace/lab/auth/session_runner"
include Ace::Lab::Auth
begin
  SessionNamespace.capture(Process.pid)
  abort "initial mount namespace was accepted"
rescue ArgumentError => e
  raise unless e.message.include?("private system namespace")
end
unit, pid, uid, project = ARGV.values_at(1, 2, 3, 4)
parent_namespace = File.stat("/proc/self/ns/mnt")
parent_cwd = Dir.pwd
namespace = SessionNamespace.capture(Integer(pid))
raise "session namespace changed" unless SessionNamespace.matches?(namespace, Integer(pid))
attach = Object.new
attach.define_singleton_method(:prepare) do
  group = IO.popen(["/usr/bin/systemctl", "show", "--property=ControlGroup", "--value", unit], &:read).strip
  raise "unexpected cgroup" unless $?.success? && File.basename(group) == unit && group.start_with?("/")
  File.open(File.join("/sys/fs/cgroup", group.delete_prefix("/"), "cgroup.procs"), File::WRONLY | File::NOFOLLOW)
end
attach.define_singleton_method(:verify_child!) do |child|
  next false unless SessionNamespace.matches?(namespace, child)
  status = File.readlines("/proc/#{child}/status").to_h { |line| line.chomp.split(":", 2) }
  groups = status.fetch("Groups").split.map(&:to_i)
  cgroups = File.readlines("/proc/#{child}/cgroup").grep(/\A0::/)
  status.fetch("Uid").split.map(&:to_i).all? { |value| value == Integer(uid) } && groups.empty? &&
    status.fetch("NoNewPrivs").strip == "1" && status.fetch("CapEff").to_i(16).zero? &&
    cgroups.size == 1 && File.basename(cgroups.first.delete_prefix("0::").strip) == unit
end
runner = SessionRunner.new(uid: Integer(uid), cwd: project, namespace: namespace, attach: attach)
status = runner.call(["/usr/bin/touch", File.join(project, "session-runner-created")], {"PATH" => "/usr/bin:/bin"})
raise "session runner failed: #{status}" unless status == 0
after = File.stat("/proc/self/ns/mnt")
unless [after.dev, after.ino] == [parent_namespace.dev, parent_namespace.ino] && Dir.pwd == parent_cwd
  raise "issuer process filesystem context changed"
end
namespace.close
puts "installed SessionRunner joined mapped namespace and attached its child"
'''
foreign_namespace_program = r'''
gem "ace-lab", "= #{ARGV.fetch(0)}"
require "ace/lab/auth/session_namespace"
begin
  Ace::Lab::Auth::SessionNamespace.capture(Integer(ARGV.fetch(1)))
  abort "foreign user namespace was accepted"
rescue ArgumentError => e
  raise unless e.message.include?("private system namespace")
end
puts "foreign-user-owned mount namespace refused"
'''

try:
    env = {'PATH': '/usr/bin:/bin', 'HOME': '/var/empty', 'ACE_TOOLCHAIN': 'installed',
           'GEM_HOME': args.gem_home, 'GEM_PATH': args.gem_home + ':' + args.shared_gems}
    foreign = subprocess.Popen(['/usr/bin/unshare', '--user', '--map-root-user', '--mount',
                                '/bin/sh', '-c', 'printf "ready\\n"; exec /bin/sleep 15'],
                               stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    try:
        if not select.select([foreign.stdout], [], [], 5)[0] or foreign.stdout.readline().strip() != 'ready':
            raise RuntimeError('foreign namespace process did not become ready')
        run([args.ruby, '-e', foreign_namespace_program, args.version, str(foreign.pid)], env=env)
    finally:
        foreign.terminate()
        try:
            foreign.wait(timeout=5)
        except subprocess.TimeoutExpired:
            foreign.kill()
            foreign.wait(timeout=5)
        foreign.stdout.close()
        foreign.stderr.close()
    attempted = True
    run(['/usr/bin/systemd-run', '--quiet', '--unit=' + unit, '--property=Type=exec',
         '--property=DynamicUser=yes', '--property=PrivateMounts=yes', '--property=NoNewPrivileges=yes',
         '--property=Delegate=yes', '--property=ProtectSystem=strict', '--property=ReadWritePaths=' + root,
         '/bin/sleep', '60'])
    pid = int(output(['/usr/bin/systemctl', 'show', '--property=MainPID', '--value', unit]))
    if pid <= 0:
        raise RuntimeError('systemd did not expose a main process')
    status = {}
    with open(f'/proc/{pid}/status', encoding='utf-8') as file:
        for line in file:
            if line.startswith(('Uid:', 'Gid:')):
                key, value = line.split(':', 1)
                status[key] = int(value.split()[1])
    uid, gid = status['Uid'], status['Gid']
    if uid <= 0 or uid == account.pw_uid:
        raise RuntimeError('session does not have a separate UID')
    namespace_fd = os.open(f'/proc/{pid}/ns/mnt', os.O_RDONLY | os.O_CLOEXEC)
    pinned, host = os.fstat(namespace_fd), os.stat('/proc/1/ns/mnt')
    if (pinned.st_dev, pinned.st_ino) == (host.st_dev, host.st_ino):
        raise RuntimeError('unit did not get a private mount namespace')
    if int(output(['/usr/bin/systemctl', 'show', '--property=MainPID', '--value', unit])) != pid:
        raise RuntimeError('unit main process changed')
    run(['/usr/bin/systemctl', 'is-active', '--quiet', unit])
    run(['/usr/bin/nsenter', '--mount=/proc/self/fd/' + str(namespace_fd), '--', '/bin/mount', '--bind',
         '-o', f'X-mount.idmap=u:{account.pw_uid}:{uid}:1 g:{account.pw_gid}:{gid}:1', project, project],
        pass_fds=(namespace_fd,))
    run([args.ruby, '-e', ruby_program, args.version, unit, str(pid), str(uid), project], env=env)
    owner = os.stat(os.path.join(project, 'session-runner-created'))
    if (owner.st_uid, owner.st_gid) != (account.pw_uid, account.pw_gid):
        raise RuntimeError('file owner differs from project owner')
    run(['/usr/bin/systemctl', 'stop', unit])
    attempted = False
    passed = True
    print('host project ownership preserved after session stop')
finally:
    if namespace_fd is not None:
        os.close(namespace_fd)
    if attempted:
        try:
            run(['/usr/bin/systemctl', 'stop', unit], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        except (subprocess.SubprocessError, OSError):
            print('could not stop probe unit: ' + unit, file=sys.stderr)
            passed = False
    if passed:
        shutil.rmtree(root)
    else:
        print('probe failed; preserve ' + root + '; unit ' + unit, file=sys.stderr)
