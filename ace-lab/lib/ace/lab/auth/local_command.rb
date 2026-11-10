# frozen_string_literal: true

require "timeout"
require_relative "error"

module Ace
  module Lab
    module Auth
      # One ordinary child process group. Credentials are environment values,
      # never argv. Cleanup runs on normal exit, deadline and interruption.
      # This does not contain a malicious process that leaves its group.
      class LocalCommand
        def call(argv, environment, deadline:)
          remaining = deadline - Time.now
          raise Refusal, "lease expired before execution" unless remaining.positive?

          pid = Process.spawn(environment, [argv.first, argv.first], *argv.drop(1),
            unsetenv_others: true, pgroup: true)
          previous = Signal.trap("TERM") { raise SignalException, "TERM" } if Thread.current == Thread.main
          begin
            _, status = Timeout.timeout(remaining) { Process.wait2(pid) }
            reaped = true
            status.exitstatus || 128 + status.termsig.to_i
          rescue Timeout::Error
            124
          ensure
            begin
              reaped = stop_group(pid, reaped: reaped)
              Timeout.timeout(2) { Process.wait(pid) } unless reaped
            rescue Errno::ECHILD
              nil
            rescue SystemCallError, Timeout::Error => e
              raise ExecutionCleanupError, "command process group cleanup is unconfirmed (#{e.class}: #{e.message})"
            ensure
              Signal.trap("TERM", previous) if previous
            end
          end
        end

        private

        def stop_group(pid, reaped:)
          Process.kill("TERM", -pid)
          sleep 0.05
          # Darwin reports EPERM when a group contains only our unreaped
          # zombie. Reap it before checking for surviving descendants.
          reaped ||= !Process.waitpid(pid, Process::WNOHANG).nil?
          Process.kill("KILL", -pid)
          reaped
        rescue Errno::ESRCH
          reaped
        end
      end
    end
  end
end
