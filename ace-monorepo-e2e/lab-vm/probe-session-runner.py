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
parser.add_argument('--test-kill-fallback', action='store_true',
                    help='force pidfd signaling failure and require the session cgroup to terminate')
parser.add_argument('--signal-error', choices=('EPERM', 'ESRCH'), default='EPERM')
parser.add_argument('--check-detached-descendant', action='store_true',
                    help='diagnose whether a detached child survives a successful command')
parser.add_argument('--test-writable-cgroup', action='store_true',
                    help='require refusal when the session cgroup control is writable by others')
parser.add_argument('--test-reap-after-failure', action='store_true',
                    help='force containment failure and check eventual pidfd-based reaping')
args = parser.parse_args()
if sum((args.test_kill_fallback, args.check_detached_descendant, args.test_reap_after_failure)) > 1:
    parser.error('choose only one session termination probe')
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
unit = 'ace-auth-session-worker-' + secrets.token_hex(8) + '.service'
attempted = False
passed = False
namespace_fd = None
ruby_program = r'''
gem "ace-lab", "= #{ARGV.fetch(0)}"
expected_gem = File.realpath(File.join(ENV.fetch("GEM_HOME"), "gems", "ace-lab-#{ARGV.fetch(0)}"))
raise "unexpected installed candidate" unless File.realpath(Gem.loaded_specs.fetch("ace-lab").full_gem_path) == expected_gem
require "ace/lab/auth/session_runner"
require "ace/lab/auth/session_attachment"
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
  Ace::Lab::Auth::SessionAttachment.allocate.send(:open_cgroup, group)
end
attach.define_singleton_method(:verify_child!) do |child|
  next false unless SessionNamespace.matches?(namespace, child)
  status = File.readlines("/proc/#{child}/status").to_h { |line| line.chomp.split(":", 2) }
  groups = status.fetch("Groups").split.map(&:to_i)
  cgroups = File.readlines("/proc/#{child}/cgroup").grep(/\A0::/)
  status.fetch("Uid").split.map(&:to_i).all? { |value| value == Integer(uid) } && groups.empty? &&
    status.fetch("NoNewPrivs").strip == "1" && status.fetch("CapEff").to_i(16).zero? &&
    cgroups.size == 1 && cgroups.first.delete_prefix("0::").strip.match?(%r{/#{Regexp.escape(unit)}/ace-exec-[0-9a-f]+\z})
end
runner = SessionRunner.new(uid: Integer(uid), cwd: project, namespace: namespace, attach: attach)
recorded = nil
before_start = lambda do |path|
  raise "invalid command cgroup path" unless SessionAttachment.command_cgroup_path?(path, unit)
  raise "command ran before its cgroup was recorded" if File.exist?(File.join(project, "session-runner-created"))
  recorded = path
end
status = runner.call(["/usr/bin/touch", File.join(project, "session-runner-created")], {"PATH" => "/usr/bin:/bin"}, before_start: before_start)
raise "session runner failed: #{status}" unless status == 0
raise "command cgroup was not recorded or cleaned" unless recorded && !File.exist?(recorded)
after = File.stat("/proc/self/ns/mnt")
unless [after.dev, after.ino] == [parent_namespace.dev, parent_namespace.ino] && Dir.pwd == parent_cwd
  raise "issuer process filesystem context changed"
end
namespace.close
puts "installed SessionRunner joined mapped namespace and attached its child"
'''
fallback_program = r'''
gem "ace-lab", "= #{ARGV.fetch(0)}"
require "ace/lab/auth/session_runner"
require "ace/lab/auth/session_namespace"
require "ace/lab/auth/session_attachment"
unit, pid, uid, project = ARGV.values_at(1, 2, 3, 4)
namespace = Ace::Lab::Auth::SessionNamespace.capture(Integer(pid))
attach = Object.new
attach.define_singleton_method(:prepare) do
  group = IO.popen(["/usr/bin/systemctl", "show", "--property=ControlGroup", "--value", unit], &:read).strip
  raise "unexpected cgroup" unless $?.success? && File.basename(group) == unit && group.start_with?("/")
  Ace::Lab::Auth::SessionAttachment.allocate.send(:open_cgroup, group)
end
attach.define_singleton_method(:verify_child!) { |child| Ace::Lab::Auth::SessionNamespace.matches?(namespace, child) }
runner = Ace::Lab::Auth::SessionRunner.new(uid: Integer(uid), cwd: project, namespace: namespace, attach: attach)
signal = runner.method(:signal_child!)
runner.define_singleton_method(:signal_child!) do |handle, number, group: false|
  raise Errno.const_get(ARGV.fetch(5)) if number != 0
  signal.call(handle, number, group: group)
end
marker = File.join(project, "kill-fallback-ready")
main = Thread.current
interrupter = Thread.new do
  deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10
  sleep 0.01 until File.file?(marker) || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
  main.raise(Interrupt, "cancel probe")
end
begin
  begin
    runner.call(["/bin/sh", "-c", 'echo ready > "$1"; exec /bin/sleep 60', "runner", marker], {})
    abort "runner did not receive cancellation"
  rescue Interrupt
    raise "session command did not start" unless File.file?(marker)
  end
  raise "session main did not survive command cleanup" unless system("/usr/bin/systemctl", "is-active", "--quiet", unit)
  puts "failed pidfd signal terminated the command cgroup; session remained active"
ensure
  interrupter.kill
  interrupter.join
  namespace.close
end
'''
detached_program = r'''
gem "ace-lab", "= #{ARGV.fetch(0)}"
require "ace/lab/auth/session_runner"
require "ace/lab/auth/session_namespace"
require "ace/lab/auth/session_attachment"
unit, pid, uid, project = ARGV.values_at(1, 2, 3, 4)
namespace = Ace::Lab::Auth::SessionNamespace.capture(Integer(pid))
attach = Object.new
attach.define_singleton_method(:prepare) do
  group = IO.popen(["/usr/bin/systemctl", "show", "--property=ControlGroup", "--value", unit], &:read).strip
  raise "unexpected cgroup" unless $?.success? && File.basename(group) == unit && group.start_with?("/")
  Ace::Lab::Auth::SessionAttachment.allocate.send(:open_cgroup, group)
end
attach.define_singleton_method(:verify_child!) { |child| Ace::Lab::Auth::SessionNamespace.matches?(namespace, child) }
runner = Ace::Lab::Auth::SessionRunner.new(uid: Integer(uid), cwd: project, namespace: namespace, attach: attach)
marker = File.join(project, "detached-child-pid")
status = runner.call(["/bin/sh", "-c", '/usr/bin/setsid /bin/sleep 60 & echo $! > "$1"', "runner", marker], {})
raise "command failed" unless status.zero?
child = Integer(File.read(marker))
stat = File.read("/proc/#{child}/stat") rescue nil
raise "detached child survived successful runner exit" if stat && !stat.match?(/\) Z /)
raise "session main did not survive command cleanup" unless system("/usr/bin/systemctl", "is-active", "--quiet", unit)
puts "detached child terminated after command exit; session remained active"
namespace.close
'''
reap_program = r'''
gem "ace-lab", "= #{ARGV.fetch(0)}"
require "ace/lab/auth/session_runner"
require "ace/lab/auth/session_attachment"
unit, pid, uid, project = ARGV.values_at(1, 2, 3, 4)
namespace = Ace::Lab::Auth::SessionNamespace.capture(Integer(pid))
attach = Object.new
attach.define_singleton_method(:prepare) do
  group = IO.popen(["/usr/bin/systemctl", "show", "--property=ControlGroup", "--value", unit], &:read).strip
  raise "unexpected cgroup" unless $?.success? && File.basename(group) == unit && group.start_with?("/")
  prepared = Ace::Lab::Auth::SessionAttachment.allocate.send(:open_cgroup, group)
  @path = prepared.path
  prepared.define_singleton_method(:terminate!) { raise IOError, "synthetic containment failure" }
  prepared
end
attach.define_singleton_method(:verify_child!) do |child|
  @child_pid = child
  Ace::Lab::Auth::SessionNamespace.matches?(namespace, child)
end
runner = Ace::Lab::Auth::SessionRunner.new(uid: Integer(uid), cwd: project, namespace: namespace, attach: attach)
signal = runner.method(:signal_child!)
runner.define_singleton_method(:signal_child!) do |handle, number, group: false|
  raise Errno::EPERM if number != 0
  signal.call(handle, number, group: group)
end
marker = File.join(project, "reaper-ready")
main = Thread.current
interrupter = Thread.new do
  deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10
  sleep 0.01 until File.file?(marker) || Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
  main.raise(Interrupt, "cancel probe")
end
begin
  begin
    runner.call(["/bin/sh", "-c", 'echo ready > "$1"; exec /bin/sleep 1', "runner", marker], {})
    abort "containment failure was accepted"
  rescue Ace::Lab::Auth::UncontainedSessionError
    raise "session command did not start" unless File.file?(marker)
  end
  child = attach.instance_variable_get(:@child_pid)
  deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
  sleep 0.01 while File.exist?("/proc/#{child}") && Process.clock_gettime(Process::CLOCK_MONOTONIC) < deadline
  raise "uncontained child was not reaped" if File.exist?("/proc/#{child}")
  Dir.rmdir(attach.instance_variable_get(:@path))
  raise "session main stopped" unless system("/usr/bin/systemctl", "is-active", "--quiet", unit)
  puts "unconfirmed containment reported; exited child reaped through pidfd"
ensure
  interrupter.kill
  interrupter.join
  namespace.close
end
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
writable_group_program = r'''
gem "ace-lab", "= #{ARGV.fetch(0)}"
require "ace/lab/auth/session_attachment"
begin
  Ace::Lab::Auth::SessionAttachment.allocate.send(:open_cgroup, ARGV.fetch(1))
  abort "writable cgroup was accepted"
rescue Ace::Lab::Auth::Error => error
  raise unless error.message.include?("not root-controlled")
end
puts "writable session cgroup refused"
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
         '--property=Delegate=no', '--property=ProtectSystem=strict', '--property=ReadWritePaths=' + root,
         '/bin/sleep', '60'])
    pid = int(output(['/usr/bin/systemctl', 'show', '--property=MainPID', '--value', unit]))
    if pid <= 0:
        raise RuntimeError('systemd did not expose a main process')
    if args.test_writable_cgroup:
        group = output(['/usr/bin/systemctl', 'show', '--property=ControlGroup', '--value', unit])
        if not group.startswith('/') or os.path.basename(group) != unit:
            raise RuntimeError('unexpected unit cgroup')
        control = '/sys/fs/cgroup' + group + '/cgroup.procs'
        original_mode = stat.S_IMODE(os.stat(control).st_mode)
        try:
            os.chmod(control, original_mode | 0o002)
            run([args.ruby, '-e', writable_group_program, args.version, group], env=env)
        finally:
            os.chmod(control, original_mode)
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
    if args.test_kill_fallback:
        run([args.ruby, '-e', fallback_program, args.version, unit, str(pid), str(uid), project,
             args.signal_error], env=env)
    if args.check_detached_descendant:
        run([args.ruby, '-e', detached_program, args.version, unit, str(pid), str(uid), project], env=env)
    if args.test_reap_after_failure:
        run([args.ruby, '-e', reap_program, args.version, unit, str(pid), str(uid), project], env=env)
    group = output(['/usr/bin/systemctl', 'show', '--property=ControlGroup', '--value', unit])
    group_path = '/sys/fs/cgroup' + group
    if not group or any(name.startswith('ace-exec-') for name in os.listdir(group_path)):
        raise RuntimeError('command cgroup remained after completion')
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
