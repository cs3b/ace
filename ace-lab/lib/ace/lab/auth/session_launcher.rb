# frozen_string_literal: true

require_relative "session_unit"
require "rbconfig"
require "ace/runtime/molecules/protected_socket"

module Ace
  module Lab
    module Auth
      # Trusted host entry, not a general command endpoint. The caller obtains
      # SessionUnit from protected configuration and owns the resulting process
      # until systemd lifecycle verification and terminal handoff complete.
      class SessionLauncher
        Launch = Data.define(:unit, :transport_pid)
        Identity = Data.define(:unit, :invocation_id, :process, :pidfd)
        ENTRY = File.expand_path("../../../../libexec/session-entry", __dir__).freeze

        def initialize(privileged: Process.euid.zero?, platform: Ace::Runtime::Molecules::ProtectedLinux.new,
          verify_path: nil, spawn: Process.method(:spawn), manager_factory: nil)
          @privileged, @platform, @spawn = privileged, platform, spawn
          @verify_path = verify_path || Ace::Runtime::Molecules::ProtectedSocket.method(:root_path!)
          @manager_factory = manager_factory || lambda { |unit|
            Ace::Runtime::Molecules::SystemdScopeManager.new(slice_unit: SessionPeer::SLICE, service_unit: unit)
          }
        end

        # Capture the actual service process, never the systemd-run transport.
        # This proves process identity only; Pi first-turn/eyes readiness is a
        # separate product observation. The caller owns the returned pidfd.
        def identify(launch)
          raise Error, "session identity requires the root host endpoint" unless @privileged
          unless launch.is_a?(Launch) && SessionPeer::UNIT.match?(launch.unit)
            raise ArgumentError, "invalid session launch"
          end
          manager = @manager_factory.call(launch.unit)
          state = manager.inspect_units.fetch("service")
          pid = state.fetch("MainPID")
          unless state["ActiveState"] == "active" && pid.is_a?(String) && pid.match?(/\A[1-9][0-9]*\z/)
            raise Error, "session process has not started"
          end
          process = @platform.capture(Integer(pid, 10))
          unless SessionPeer::DYNAMIC_UIDS.cover?(process.fetch("uid")) && process["gid"] == process["uid"] &&
              process.fetch("groups").all? { |group| group == process["gid"] }
            raise Error, "session process is not an isolated dynamic identity"
          end
          handle = @platform.pin(process)
          binding = manager.unit_for_pidfd(handle: handle)
          after = manager.inspect_units.fetch("service")
          unless binding["unit"] == launch.unit && binding["invocation_id"] == state["InvocationID"] &&
              after["InvocationID"] == state["InvocationID"] && after["MainPID"] == pid &&
              after["ActiveState"] == "active" && !@platform.exited?(handle)
            raise Error, "session process changed during terminal handoff"
          end
          identity = Identity.new(unit: launch.unit, invocation_id: binding.fetch("invocation_id"),
            process: process.freeze, pidfd: handle)
          handle = nil
          identity
        rescue Ace::Runtime::Error, SystemCallError, IOError, KeyError, ArgumentError => error
          raise Error, "session identity is unavailable (#{error.class})"
        ensure
          handle&.close
        end

        # Only the trusted launch owner retains this identity. Unit names are
        # random, single-use and never exposed as an arbitrary stop endpoint.
        # Stop the whole systemd cgroup, not the transport or a recycled PID.
        def stop(identity)
          raise Error, "session stop requires the root host endpoint" unless @privileged
          unless identity.is_a?(Identity) && SessionPeer::UNIT.match?(identity.unit) &&
              identity.invocation_id.is_a?(String) && identity.invocation_id.match?(/\A[0-9a-f]{32}\z/) &&
              identity.invocation_id != "0" * 32 && identity.pidfd.is_a?(IO) && !identity.pidfd.closed?
            raise ArgumentError, "authenticated session identity required"
          end
          manager = @manager_factory.call(identity.unit)
          before = manager.inspect_units.fetch("service")
          unless before["InvocationID"] == identity.invocation_id
            raise Error, "session invocation changed before stop"
          end
          unless @platform.exited?(identity.pidfd)
            binding = manager.unit_for_pidfd(handle: identity.pidfd)
            unless binding == {"unit" => identity.unit, "invocation_id" => identity.invocation_id}
              raise Error, "session process binding changed before stop"
            end
          end
          manager.stop_service
          after = manager.inspect_units.fetch("service")
          unless after["InvocationID"] == identity.invocation_id &&
              %w[inactive failed].include?(after["ActiveState"]) && after["MainPID"] == "0" &&
              @platform.exited?(identity.pidfd)
            raise Error, "session termination was not confirmed"
          end
          true
        rescue Ace::Runtime::Error, SystemCallError, IOError, KeyError => error
          raise Error, "session stop is unconfirmed (#{error.class})"
        end

        def start(unit:, terminal:)
          raise Error, "session launch requires the root host endpoint" unless @privileged
          raise ArgumentError, "configured session unit required" unless unit.is_a?(SessionUnit)
          @platform.supported!
          unless terminal.is_a?(IO) && !terminal.closed? && terminal.stat.chardev? && terminal.tty?
            raise Error, "session launch requires an open terminal descriptor"
          end
          @verify_path.call("/usr/bin/systemd-run")
          @verify_path.call(unit.executable)
          @verify_path.call(RbConfig.ruby)
          @verify_path.call(ENTRY)
          gated_unit = unit.with_preparation_entry(ruby: RbConfig.ruby, entry: ENTRY)
          # An inherited Bundler, loader, credential or Ruby environment must
          # never reach the privileged systemd client. SessionUnit supplies
          # the configured child environment separately.
          pid = @spawn.call({"PATH" => "/usr/bin:/bin", "LANG" => "C", "LC_ALL" => "C"},
            *gated_unit.argv, in: terminal, out: terminal, err: terminal,
            unsetenv_others: true, close_others: true)
          Launch.new(unit: unit.name, transport_pid: pid)
        rescue Ace::Runtime::Error, SystemCallError, IOError => error
          raise Error, "session launch failed (#{error.class})"
        end
      end
    end
  end
end
