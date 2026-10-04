# frozen_string_literal: true

require "open3"
require "socket"

module Ace
  module Runtime
    module Molecules
      # A PID is an address, not an identity. Keep only non-secret OS facts;
      # command lines may contain credentials and are never journaled.
      class ProcessIdentity
        def initialize(executor: Open3, hostname: Socket.gethostname)
          @executor = executor
          @hostname = hostname
        end

        def owner(shell_pid:, caller_pid:)
          shell = capture(shell_pid)
          return nil unless shell && caller_pid.is_a?(Integer) && caller_pid != shell_pid

          seen = []
          current = caller_pid
          child = nil
          64.times do
            return nil if seen.include?(current)
            seen << current
            identity = capture(current)
            return nil unless identity && identity["uid"] == shell["uid"]
            parent = parent_pid(current)
            return nil unless parent
            child = identity
            return {"shell_identity" => shell, "process_identity" => child} if parent == shell_pid
            current = parent
          end
          nil
        end

        def parent_pid(pid)
          output, status = @executor.capture2("ps", "-p", pid.to_s, "-o", "ppid=", stdin_data: "")
          value = output.strip
          status.success? && value.match?(/\A[0-9]+\z/) ? value.to_i : nil
        rescue SystemCallError, IOError
          nil
        end

        def capture(pid)
          return nil unless pid.is_a?(Integer) && pid.positive?

          output, status = @executor.capture2("ps", "-p", pid.to_s, "-o", "pid=,uid=,stat=,lstart=", stdin_data: "")
          return nil unless status.success?

          match = output.strip.match(/\A(\d+)\s+(\d+)\s+(\S+)\s+(.+)\z/)
          return nil unless match && match[1].to_i == pid && !match[3].match?(/[ZX]/)

          {"pid" => pid, "uid" => match[2].to_i, "started_at" => match[4], "host" => @hostname}
        rescue SystemCallError, IOError
          nil
        end

        def observe(identity)
          at = Time.now.utc.iso8601
          unless identity.is_a?(Hash) && identity["host"] == @hostname &&
              identity["started_at"].is_a?(String) && identity["uid"].is_a?(Integer)
            return {"liveness" => "unknown", "observed_at" => at, "reason" => "verified process identity unavailable"}
          end

          live = capture(identity["pid"])
          if live == identity
            {"liveness" => "live", "observed_at" => at, "reason" => "process identity matches", "identity" => live}
          elsif live
            {"liveness" => "unknown", "observed_at" => at, "reason" => "process address reused"}
          else
            # An inaccessible ps result cannot prove death or absence of
            # descendants. Recovery retains the worktree and writer slot.
            {"liveness" => "unknown", "observed_at" => at, "reason" => "process identity no longer observable"}
          end
        end
      end
    end
  end
end
