# frozen_string_literal: true

require "fiddle"
require "socket"
require "ace/runtime/molecules/process_identity"
require "ace/runtime/molecules/systemd_scope_manager"
require "ace/runtime/molecules/protected_artifact_set"

module Ace
  module Lab
    module Molecules
      # Only trusted accepted-release composition constructs this observer.
      # Root policy is fixed here; ordinary ProtectedLinux stays all-zero.
      class ProtectedCleanupOwnerIdentity
        Runtime = Ace::Runtime::Molecules
        Unavailable = Ace::Runtime::RuntimeUnavailableError
        DISABLE = "--disable=gems,rubyopt,did_you_mean,error_highlight,syntax_suggest"
        UNIT_FIELDS = {"Id" => "s", "LoadState" => "s", "ActiveState" => "s", "SubState" => "s",
          "InvocationID" => "ay", "FragmentPath" => "s", "DropInPaths" => "as"}.freeze
        EMPTY_COMMANDS = %w[ExecConditionEx ExecStartPreEx ExecStartPostEx ExecReloadEx ExecStopEx ExecStopPostEx].freeze
        ENVIRONMENT = %w[PATH=/usr/bin:/bin LANG=C LC_ALL=C HOME=/root].freeze
        MANAGER_ENVIRONMENT = %w[PATH LANG LANGUAGE LC_ALL LC_CTYPE LC_NUMERIC LC_TIME LC_COLLATE LC_MONETARY
          LC_MESSAGES LC_PAPER LC_NAME LC_ADDRESS LC_TELEPHONE LC_MEASUREMENT LC_IDENTIFICATION].freeze
        ENVIRONMENT_FIELDS = {"Environment" => "as", "EnvironmentFiles" => "a(sb)", "PassEnvironment" => "as",
          "UnsetEnvironment" => "as", "PAMName" => "s"}.freeze
        SERVICE_FIELDS = {**ENVIRONMENT_FIELDS, **EMPTY_COMMANDS.to_h { |key| [key, "a(sasasttttuii)"] }, "Type" => "s", "MainPID" => "u", "ControlPID" => "u", "ExecStartEx" => "a(sasasttttuii)"}.freeze

        class Kernel
          def initialize(identity: Runtime::ProcessIdentity.new, pidfd_open: nil)
            @identity = identity
            @pidfd_open = pidfd_open || method(:open_pidfd)
          end

          def capture(pid)
            raise Unavailable, "root owner requires Linux" unless RUBY_PLATFORM.include?("linux") && File.binread("/proc/sys/kernel/yama/ptrace_scope", 128).strip == "2"
            unless pid.is_a?(Integer) && pid.positive?
              raise Unavailable, "root owner PID is unavailable"
            end
            birth = @identity.send(:native_birth, pid)
            raise Unavailable, "root owner birth is unavailable" unless birth
            bytes = File.binread("/proc/#{pid}/status", 65_537)
            raise Unavailable, "root owner status is oversized" if bytes.bytesize > 65_536
            fields = bytes.lines.to_h { |line| line.strip.split(/:\s*/, 2) }
            ids = %w[Uid Gid].map { |key| fields.fetch(key).split.map { |id| Integer(id, 10) } }
            caps = %w[CapInh CapPrm CapEff CapBnd CapAmb].map { |key| Integer(fields.fetch(key), 16) }
            groups = fields.fetch("Groups").split.map { |id| Integer(id, 10) }.sort
            unless ids.all? { |value| value == [0, 0, 0, 0] } && groups == [0] &&
                caps == [0, 2, 2, 2, 0] && fields.fetch("NoNewPrivs") == "1" &&
                @identity.send(:native_birth, pid) == birth
              raise Unavailable, "root owner kernel policy differs"
            end
            {"pid" => pid, "uid" => 0, "gid" => 0, "groups" => groups,
              "started_at" => birth, "host" => Socket.gethostname,
              "parent_pid" => Integer(fields.fetch("PPid"), 10)}
          rescue IOError, SystemCallError, KeyError, ArgumentError
            raise Unavailable, "root owner kernel policy is unavailable"
          end

          def pin(identity)
            handle = @pidfd_open.call(identity.fetch("pid"))
            unless handle.is_a?(IO) && !handle.closed?
              raise Unavailable, "root owner pidfd is unavailable"
            end
            unless capture(identity.fetch("pid")) == identity
              raise Unavailable, "root owner changed during pin acquisition"
            end
            handle
          rescue Fiddle::DLError, SystemCallError, IOError
            handle.close if handle.is_a?(IO) && !handle.closed?
            raise Unavailable, "root owner pidfd capability is unavailable"
          rescue Exception
            handle.close if handle.is_a?(IO) && !handle.closed?
            raise
          end

          def open_pidfd(pid)
            function = Fiddle::Function.new(Fiddle::Handle::DEFAULT["pidfd_open"],
              [Fiddle::TYPE_INT, Fiddle::TYPE_INT], Fiddle::TYPE_INT)
            fd = function.call(pid, 0)
            raise Unavailable, "root owner pidfd is unavailable" if fd.negative?
            IO.for_fd(fd, autoclose: true)
          end
          private :open_pidfd

          def exited?(handle) = !IO.select([handle], nil, nil, 0).nil?

          def peer(socket)
            raise Unavailable, "root peer requires Linux" unless RUBY_PLATFORM.include?("linux")
            socket.getsockopt(Socket::SOL_SOCKET, Socket::SO_PEERCRED).data.unpack("i!3")
          end
        end

        def initialize(unit:, entry:, interpreter:, closure:, load_paths:, manager:, kernel: Kernel.new, artifacts: nil)
          unless unit.is_a?(String) && Runtime::SystemdScopeManager::UNIT.match?(unit) && unit.end_with?(".service") &&
              closure.is_a?(Array) && closure.size.between?(1, 4094) &&
              load_paths.is_a?(Array) && load_paths.size.between?(1, 16) && load_paths.uniq == load_paths &&
              load_paths.all? { |path| path.is_a?(String) && path.start_with?("/") && !path.include?("\0") && !path.include?(":") && File.expand_path(path) == path }
            raise ArgumentError, "cleanup identity requires a fixed accepted-release selection"
          end
          @unit = unit.dup.freeze
          @references = [entry, interpreter, *closure].map { |ref| reference(ref) }.freeze
          unless @references.map { |ref| ref.fetch("path") }.uniq.size == @references.size
            raise ArgumentError, "cleanup closure has duplicate references"
          end
          unless load_paths.all? { |path| @references.any? { |ref| ref.fetch("path").start_with?(path + "/") } }
            raise ArgumentError, "cleanup load path is outside the held closure"
          end
          @entry, @interpreter = @references.first(2)
          @argv = [@interpreter.fetch("path"), DISABLE, "-I", load_paths.join(":"), @entry.fetch("path")].freeze
          @manager, @kernel = manager, kernel
          @verification = Mutex.new
          @artifacts = artifacts || Runtime::ProtectedArtifactSet.new(file_limit: 32 * 1_048_576,
            total_limit: 256 * 1_048_576, count_limit: 4096)
        end

        def observe!(socket:, deadline: Runtime::ProtectedSocket.deadline(5))
          with_verification do
            observe_held!(deadline: deadline, peer_join: ->(identity) {
              @kernel.peer(socket) == [identity.fetch("pid"), 0, 0]
            })
          end
        end

        # Only the immutable installed listener calls this entrypoint. Its
        # positive receiver peer is not the root process being measured.
        def observe_self!(deadline: Runtime::ProtectedSocket.deadline(5))
          pid = Process.pid
          with_verification do
            observe_held!(deadline: deadline, peer_join: ->(identity) {
              identity.fetch("pid") == pid
            })
          end
        end

        def with_verification
          unless @verification.try_lock
            raise Unavailable, "cleanup identity verification is busy"
          end
          begin
            yield
          ensure
            @verification.unlock
          end
        end
        private :with_verification

        def observe_held!(deadline:, peer_join:)
          now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          unless deadline.is_a?(Numeric) && deadline.finite? && deadline > now
            raise Unavailable, "cleanup identity observation deadline expired"
          end
          deadline = [deadline, now + 5].min
          before = snapshot(deadline)
          identity = @kernel.capture(before.fetch("MainPID"))
          handle = @kernel.pin(identity)
          @artifacts.with do |artifacts|
            @references.each { |ref| artifacts.read!(ref) }
            unless @references.any? { |ref| ref.fetch("path") == before.fetch("FragmentPath") }
              raise Unavailable, "installed cleanup unit is outside the held closure"
            end
            join = @manager.unit_for_pidfd(handle: handle, timeout: remaining(deadline))
            unless join == {"unit" => @unit, "invocation_id" => before.fetch("InvocationID")} &&
                peer_join.call(identity) && !@kernel.exited?(handle) &&
                @kernel.capture(identity.fetch("pid")) == identity && snapshot(deadline) == before
              raise Unavailable, "cleanup peer differs from the original installed invocation"
            end
            artifacts.verify_unchanged!
            unless !@kernel.exited?(handle) && @kernel.capture(identity.fetch("pid")) == identity &&
                @manager.unit_for_pidfd(handle: handle, timeout: remaining(deadline)) == join
              raise Unavailable, "cleanup owner changed after held source verification"
            end
            deep_freeze({"unit" => @unit, "invocation_id" => join.fetch("invocation_id"),
              "process_binding" => identity, "entry_sha256" => @entry.fetch("sha256")})
          end
        ensure
          handle&.close
        end
        private :observe_held!

        private

        def snapshot(deadline)
          unit = @manager.typed_properties(unit: @unit, interface: "Unit", signatures: UNIT_FIELDS, timeout: remaining(deadline))
          service = @manager.typed_properties(unit: @unit, interface: "Service", signatures: SERVICE_FIELDS, timeout: remaining(deadline))
          environment = @manager.manager_environment(timeout: remaining(deadline))
          unless environment.is_a?(Array) && environment.all? { |entry| entry.is_a?(String) && MANAGER_ENVIRONMENT.include?(entry.split("=", 2).first) } &&
              service.fetch("Environment").sort == ENVIRONMENT.sort &&
              %w[EnvironmentFiles PassEnvironment UnsetEnvironment].all? { |key| service.fetch(key) == [] } && service.fetch("PAMName") == ""
            raise Unavailable, "cleanup original startup environment differs"
          end
          start = service.fetch("ExecStartEx")
          unless unit.values_at("Id", "LoadState", "ActiveState", "SubState", "DropInPaths") == [@unit, "loaded", "active", "running", []] &&
              unit.fetch("InvocationID").match?(/\A[0-9a-f]{32}\z/) && unit.fetch("InvocationID") != "0" * 32 &&
              EMPTY_COMMANDS.all? { |key| service[key] == [] } && service.fetch("Type") == "exec" && service.fetch("MainPID").is_a?(Integer) && service.fetch("MainPID").positive? &&
              service.fetch("ControlPID") == 0 && start.is_a?(Array) && start.size == 1 &&
              start[0][0] == @interpreter.fetch("path") && start[0][1] == @argv && start[0][2] == [] &&
              start[0][3].positive? && start[0][7] == service.fetch("MainPID") && start[0][8..9] == [0, 0]
            raise Unavailable, "cleanup unit execution-start configuration differs"
          end
          unit.merge(service).merge("EffectiveManagerEnvironment" => environment)
        rescue KeyError, NoMethodError, TypeError
          raise Unavailable, "cleanup unit execution facts are unavailable"
        end

        def remaining(deadline)
          value = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
          raise Unavailable, "cleanup identity observation deadline expired" unless value.positive?
          [value, 5].min
        end

        def reference(ref)
          unless ref.is_a?(Hash) && ref.keys.sort == %w[bytes path sha256] &&
              ref["path"].is_a?(String) && ref["path"].start_with?("/") && !ref["path"].include?("\0") && File.expand_path(ref["path"]) == ref["path"] &&
              ref["sha256"].is_a?(String) && ref["sha256"].match?(/\A[0-9a-f]{64}\z/) &&
              ref["bytes"].is_a?(Integer) && ref["bytes"].between?(1, 32 * 1_048_576)
            raise ArgumentError, "cleanup closure reference is malformed"
          end
          deep_freeze(ref)
        end

        def deep_freeze(value)
          case value
          when Hash then value.to_h { |key, item| [key.dup.freeze, deep_freeze(item)] }.freeze
          when Array then value.map { |item| deep_freeze(item) }.freeze
          when String then value.dup.freeze
          else value.freeze
          end
        end
      end
    end
  end
end
