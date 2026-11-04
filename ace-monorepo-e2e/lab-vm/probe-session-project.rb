#!/usr/bin/env ruby
# frozen_string_literal: true

# Installed-artifact component probe, not the autonomous E2E verdict.
require "ace/lab/auth/session_launcher"
require "ace/lab/auth/session_project_mount"
require "pty"
require "etc"
require "securerandom"
require "json"

raise "root diagnostic entry required" unless Process.euid.zero?
forgejo = ARGV.delete("--forgejo")
raise "usage: probe-session-project.rb [--forgejo]" unless ARGV.empty?
account = Etc.getpwnam("mo")
project = "/lab/e2e-launch-#{SecureRandom.hex(8)}"
Dir.mkdir(project, 0o755)
File.chown(account.uid, account.gid, project)
tasks = File.join(project, ".ace-tasks")
private_tasks = File.join(tasks, "_overseer")
Dir.mkdir(tasks, 0o755)
Dir.mkdir(private_tasks, 0o755)
File.chown(account.uid, account.gid, tasks, private_tasks)
sentinel = File.join(private_tasks, "private-sentinel")
File.write(sentinel, "must remain private")
File.chown(account.uid, account.gid, sentinel)
output = File.join(project, "result")
other_project = "/lab/e2e-other-#{SecureRandom.hex(8)}"
Dir.mkdir(other_project, 0o755)
File.chown(account.uid, account.gid, other_project)
other_sentinel = File.join(other_project, "other-session")
File.write(other_sentinel, "not assigned")
File.chown(account.uid, account.gid, other_sentinel)
privacy_check = "try:\n    open(#{sentinel.inspect}).read()\nexcept PermissionError:\n    pass\nelse:\n    raise RuntimeError('private task was readable')\n"
privacy_check += "try:\n    open(#{other_sentinel.inspect}).read()\nexcept FileNotFoundError:\n    pass\nelse:\n    raise RuntimeError('other project was visible')\n"
privacy_check += "import os, errno\ntry:\n    os.rename(#{tasks.inspect}, #{(tasks + '-relocated').inspect})\nexcept OSError as error:\n    assert error.errno == errno.EBUSY, error\nelse:\n    raise RuntimeError('private task parent was relocatable')\n"
if forgejo
  privacy_check += <<~PYTHON
  import sys
  sys.tracebacklimit = 0
  import subprocess, json
  cli = #{File.join(ENV.fetch("GEM_HOME"), "bin", "ace-lab").inspect}
  request = subprocess.run([cli, 'auth', 'request', '--profile', 'e2e-worker', '--role', 'worker', '--task', 'diagnostic-singleton', '--assignment', #{File.basename(project).inspect}, '--repo', 'e2e-integrator/ace', '--ttl', '1'], cwd=#{project.inspect}, capture_output=True, text=True, timeout=30)
  assert request.returncode == 0, request.stdout + request.stderr
  lease = json.loads(request.stdout)['id']
  execution = subprocess.run([cli, 'auth', 'exec', lease, '--cmd', '/usr/bin/git', '--cmd', 'ls-remote', '--cmd', 'http://127.0.0.1:3000/e2e-integrator/ace.git'], cwd=#{project.inspect}, capture_output=True, text=True, timeout=30)
  assert execution.returncode == 0, execution.stdout + execution.stderr
  assert 'refs/heads/main' in execution.stdout, execution.stdout
  assert '"cleanup": "revoked"' in execution.stdout, execution.stdout
  status = subprocess.run([cli, 'auth', 'status', lease], cwd=#{project.inspect}, capture_output=True, text=True, timeout=15)
  assert status.returncode == 0, status.stdout + status.stderr
  assert json.loads(status.stdout)['state'] == 'revoked'
PYTHON
end
unit = Ace::Lab::Auth::SessionUnit.new(role: "worker", id: SecureRandom.hex(8), directory: project,
  command: [File.realpath("/usr/bin/python3"), "-c", "exec(#{privacy_check.inspect}); open('result', 'w').write('worker completed')"],
  environment: {"GEM_HOME" => ENV.fetch("GEM_HOME"), "GEM_PATH" => ENV.fetch("GEM_PATH")})
launcher = Ace::Lab::Auth::SessionLauncher.new
launch = identity = nil
completed = false
transport_reaped = false
PTY.open do |master, slave|
  begin
    launch = launcher.start(unit: unit, terminal: slave)
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10
    loop do
      begin
        identity = launcher.identify(launch)
        break
      rescue Ace::Lab::Auth::Error
        raise if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
        sleep 0.05
      end
    end
    raise "worker ran before preparation" if File.exist?(output)
    Ace::Lab::Auth::SessionProjectMount.new.call(identity: identity, project: project)
    raise "worker ran before release" if File.exist?(output)
    master.write("start\n")
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + (forgejo ? 85 : 10)
    until File.exist?(output)
      ended = Process.waitpid2(launch.transport_pid, Process::WNOHANG)
      if ended
        transport_reaped = true
        raise "worker exited before reporting success (#{ended.last.exitstatus})"
      end
      raise "worker did not complete" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
      sleep 0.05
    end
    stat = File.stat(output)
    raise "backing ownership changed" unless [stat.uid, stat.gid] == [account.uid, account.gid]
    raise "unexpected worker result" unless File.read(output) == "worker completed"
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
    loop do
      ended = Process.waitpid2(launch.transport_pid, Process::WNOHANG)
      if ended
        transport_reaped = true
        raise "session command failed" unless ended.last.success?
        break
      end
      raise "session termination unconfirmed" if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
      sleep 0.05
    end
    puts JSON.generate(unit: identity.unit, invocation: identity.invocation_id,
      session_uid: identity.process.fetch("uid"), backing_uid: stat.uid, barrier: "passed", write: "passed",
      private_task_open: "denied", private_task_parent_rename: "denied", other_project: "hidden", forgejo_lease_cycle: !!forgejo)
    completed = true
  rescue StandardError
    begin
      diagnostic = master.read_nonblock(4096, exception: false)
      warn "session terminal: #{diagnostic}" if diagnostic.is_a?(String)
    rescue Errno::EIO
      nil
    end
    raise
  ensure
    identity&.pidfd&.close
    if launch && !transport_reaped
      raise "session stop failed" unless system("/usr/bin/systemctl", "stop", unit.name)
      Process.waitpid(launch.transport_pid)
    end
    if completed
      File.unlink(output)
      File.unlink(sentinel)
      Dir.rmdir(private_tasks)
      Dir.rmdir(tasks)
      Dir.rmdir(project)
      File.unlink(other_sentinel)
      Dir.rmdir(other_project)
    else
      warn "diagnostic project preserved: #{project}"
    end
  end
end
