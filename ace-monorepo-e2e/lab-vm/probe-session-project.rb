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
account = Etc.getpwnam("mo")
project = "/lab/e2e-launch-#{SecureRandom.hex(8)}"
Dir.mkdir(project, 0o755)
File.chown(account.uid, account.gid, project)
output = File.join(project, "result")
unit = Ace::Lab::Auth::SessionUnit.new(role: "worker", id: SecureRandom.hex(8),
  command: [File.realpath("/usr/bin/python3"), "-c", "open(#{output.inspect}, 'w').write('worker completed')"],
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
    deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10
    until File.exist?(output)
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
      session_uid: identity.process.fetch("uid"), backing_uid: stat.uid, barrier: "passed", write: "passed")
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
      Dir.rmdir(project)
    else
      warn "diagnostic project preserved: #{project}"
    end
  end
end
