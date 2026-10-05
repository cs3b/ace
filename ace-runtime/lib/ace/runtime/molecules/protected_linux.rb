# frozen_string_literal: true
require "json"
require "socket"
require "fiddle"
require_relative "process_identity"

module Ace
  module Runtime
    module Molecules
      # Kernel observations for protected launch. No absence inferred from ps.
      class ProtectedLinux
        def initialize(identity: ProcessIdentity.new)
          @identity = identity
        end

        def supported!
          unless RUBY_PLATFORM.include?("linux") && File.read("/proc/sys/kernel/yama/ptrace_scope").strip == "2"
            raise RuntimeUnavailableError, "protected launch requires Linux Yama ptrace_scope=2"
          end
          true
        rescue SystemCallError
          raise RuntimeUnavailableError, "protected process policy is unavailable"
        end

        def capture(pid)
          before = @identity.capture(pid)
          raise RuntimeUnavailableError, "exact kernel process is unavailable" unless before
          fields = File.readlines("/proc/#{pid}/status").to_h { |line| line.strip.split(/:\s*/, 2) }
          ids = %w[Uid Gid].to_h { |name| [name, fields.fetch(name).split.map { |v| Integer(v, 10) }] }
          caps = %w[CapInh CapPrm CapEff CapBnd CapAmb].to_h { |name| [name, Integer(fields.fetch(name), 16)] }
          unless @identity.capture(pid) == before && ids.fetch("Uid").first == before.fetch("uid") && ids.values.all? { |v| v.size == 4 && v.uniq.size == 1 } &&
              caps.values.all?(&:zero?) && fields.fetch("NoNewPrivs") == "1"
            raise RuntimeUnavailableError, "process identity or capability policy is unsafe"
          end
          before.merge("gid" => ids.fetch("Gid").first,
            "groups" => fields.fetch("Groups", "").split.map { |v| Integer(v, 10) }.sort,
            "parent_pid" => Integer(fields.fetch("PPid"), 10))
        rescue SystemCallError, KeyError, ArgumentError
          raise RuntimeUnavailableError, "kernel process policy is unreadable"
        end

        def peer(socket)
          raise RuntimeUnavailableError, "protected socket peers require Linux" unless RUBY_PLATFORM.include?("linux")
          pid, uid, gid = socket.getsockopt(Socket::SOL_SOCKET, Socket::SO_PEERCRED).data.unpack("i!3")
          value = capture(pid)
          unless value["uid"] == uid && value["gid"] == gid
            raise RuntimeUnavailableError, "socket peer changed kernel identity"
          end
          value
        end

        def pin(identity)
          library = Fiddle.dlopen(nil)
          call = Fiddle::Function.new(library["pidfd_open"], [Fiddle::TYPE_INT, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
          fd = call.call(identity.fetch("pid"), 0)
          raise RuntimeUnavailableError, "exact pidfd is unavailable" if fd.negative?
          handle = IO.for_fd(fd, autoclose: true)
          begin
            unless same?(identity, capture(identity.fetch("pid")))
              raise RuntimeUnavailableError, "process changed while acquiring pidfd"
            end
            handle
          rescue Exception
            handle.close
            raise
          end
        rescue Fiddle::DLError
          raise RuntimeUnavailableError, "exact pidfd capability is unsupported"
        end

        def same?(left, right)
          %w[pid uid gid started_at host groups parent_pid].all? { |key| left[key] == right[key] }
        end

        # Socket peer ancestry, with every PID incarnation rechecked after the
        # walk. Same UID alone never attributes a sibling to the native child.
        def descendant?(identity, ancestor)
          observations = []
          current = identity.fetch("pid")
          64.times do
            return false if observations.any? { |item| item.fetch("pid") == current }
            observed = capture(current)
            return false unless observed["uid"] == ancestor["uid"]
            return false if observations.empty? && !same?(identity, observed)
            observations << observed
            if current == ancestor.fetch("pid")
              return same?(ancestor, observed) && observations.all? { |saved| same?(saved, capture(saved.fetch("pid"))) }
            end
            current = observed.fetch("parent_pid")
            return false unless current.is_a?(Integer) && current.positive?
          end
          false
        rescue RuntimeUnavailableError, KeyError
          false
        end

        def live!(identity)
          raise RuntimeUnavailableError, "exact process identity changed" unless same?(identity, capture(identity.fetch("pid")))
          true
        end

        def exited?(handle, timeout: 0)
          !IO.select([handle], nil, nil, timeout).nil?
        end
      end
    end
  end
end
