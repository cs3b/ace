# frozen_string_literal: true

module Ace
  module Core
    module Atoms
      # Pure functions for process termination with graceful fallback to force kill
      module ProcessTerminator
        module_function

        # Terminate a process gracefully, then forcefully if needed
        #
        # Sends SIGTERM first to allow graceful shutdown, then SIGKILL if process
        # still exists after a brief wait. Silently handles cases where the process
        # has already terminated or is inaccessible.
        #
        # @param pid [Integer, nil] Process ID to terminate
        # @param grace_period [Float] Seconds to wait between TERM and KILL (default: 0.1)
        # @return [Boolean] true if termination was attempted, false if pid was nil
        def terminate(pid, grace_period: 0.1)
          return false unless pid

          begin
            # Try graceful termination first (SIGTERM)
            Process.kill("TERM", pid)
            # Give it a moment to terminate
            sleep(grace_period)
            # Check if still running and force kill if needed
            Process.kill(0, pid) # Check if process exists
            Process.kill("KILL", pid)
          rescue Errno::ESRCH, Errno::EPERM
            # Process already terminated or we don't have permission - that's fine
          end

          true
        end
      end
    end
  end
end
