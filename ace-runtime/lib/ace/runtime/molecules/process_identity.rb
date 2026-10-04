# frozen_string_literal: true

require "open3"
require "socket"
require "fiddle"

module Ace
  module Runtime
    module Molecules
      # A PID is an address, not an identity. Keep only non-secret OS facts;
      # command lines may contain credentials and are never journaled.
      class ProcessIdentity
        def initialize(executor: Open3, hostname: Socket.gethostname, birth_reader: nil)
          @executor = executor
          @hostname = hostname
          @birth_reader = birth_reader || method(:native_birth)
        end

        def owner(shell_pid:, caller_pid:)
          shell = capture(shell_pid)
          return nil unless shell && caller_pid.is_a?(Integer) && caller_pid != shell_pid

          seen = []
          observations = []
          current = caller_pid
          child = nil
          64.times do
            return nil if seen.include?(current)
            seen << current
            identity = capture(current)
            return nil unless identity && identity["uid"] == shell["uid"]
            parent = parent_pid(current)
            return nil unless parent
            observations << [identity, parent]
            child = identity
            if parent == shell_pid
              return nil unless capture(shell_pid) == shell && observations.all? { |saved, ppid| capture(saved["pid"]) == saved && parent_pid(saved["pid"]) == ppid }
              return {"shell_identity" => shell, "process_identity" => child}
            end
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

          before = @birth_reader.call(pid)
          return nil unless before
          output, status = @executor.capture2("ps", "-p", pid.to_s, "-o", "pid=,uid=,stat=,lstart=", stdin_data: "")
          return nil unless status.success?

          match = output.strip.match(/\A(\d+)\s+(\d+)\s+(\S+)\s+(.+)\z/)
          return nil unless match && match[1].to_i == pid && !match[3].match?(/[ZX]/)

          birth = @birth_reader.call(pid)
          return nil unless birth && birth == before

          {"pid" => pid, "uid" => match[2].to_i, "started_at" => birth, "host" => @hostname}
        rescue SystemCallError, IOError
          nil
        end

        # Linux start ticks are scoped to the boot; Darwin exposes microsecond
        # process birth through libproc's documented proc_bsdinfo structure.
        # Platforms lacking either exact facility remain unobservable.
        def native_birth(pid)
          if RUBY_PLATFORM.include?("linux")
            stat = File.read("/proc/#{pid}/stat")
            fields = stat.sub(/\A.*\) /, "").split
            boot = File.read("/proc/sys/kernel/random/boot_id").strip
            "linux:#{boot}:#{fields.fetch(19)}"
          elsif RUBY_PLATFORM.include?("darwin")
            library = Fiddle.dlopen("/usr/lib/libproc.dylib")
            function = Fiddle::Function.new(library["proc_pidinfo"],
              [Fiddle::TYPE_INT, Fiddle::TYPE_INT, Fiddle::TYPE_LONG_LONG, Fiddle::TYPE_VOIDP, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
            buffer = Fiddle::Pointer.malloc(136)
            return nil unless function.call(pid, 3, 0, buffer, 136) == 136
            seconds, micros = buffer[120, 16].unpack("Q2")
            return nil unless seconds.positive? && micros < 1_000_000
            "darwin:#{seconds}:#{micros}"
          end
        rescue SystemCallError, IOError, IndexError, Fiddle::DLError
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
