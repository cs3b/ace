# frozen_string_literal: true

require_relative "session_unit"
require "rbconfig"
require "socket"
require "json"
require "ace/runtime/molecules/protected_socket"
require "ace/runtime/molecules/cgroup_observation"

module Ace
  module Lab
    module Auth
      # Trusted host entry, not a general command endpoint. The caller obtains
      # SessionUnit from protected configuration and owns the resulting process
      # until systemd lifecycle verification and terminal handoff complete.
      class SessionLauncher
        Launch = Data.define(:unit, :transport_pid)
        Identity = Data.define(:unit, :invocation_id, :process, :pidfd, :cgroup) do
          def close
            pidfd.close unless pidfd.closed?
            cgroup.fetch(:handle).close unless cgroup.fetch(:handle).closed?
          end
        end
        ENTRY = File.expand_path("../../../../libexec/session-entry", __dir__).freeze

        def initialize(privileged: Process.euid.zero?, platform: Ace::Runtime::Molecules::ProtectedLinux.new,
          cgroups: Ace::Runtime::Molecules::CgroupObservation.new, verify_path: nil, spawn: Process.method(:spawn), manager_factory: nil)
          @privileged, @platform, @spawn, @cgroups = privileged, platform, spawn, cgroups
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
          units = manager.inspect_units
          state = units.fetch("service")
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
          cgroup_path = state.fetch("ControlGroup")
          unless cgroup_path == "#{units.fetch("slice").fetch("ControlGroup")}/#{launch.unit}"
            raise Error, "session cgroup is outside its configured slice"
          end
          cgroup = @cgroups.pin(Ace::Runtime::Molecules::CgroupObservation::ROOT + cgroup_path)
          @cgroups.member!(process, pinned: cgroup, kernel: @platform)
          binding = manager.unit_for_pidfd(handle: handle)
          after = manager.inspect_units.fetch("service")
          unless binding["unit"] == launch.unit && binding["invocation_id"] == state["InvocationID"] &&
              after["InvocationID"] == state["InvocationID"] && after["MainPID"] == pid &&
              after["ActiveState"] == "active" && after["ControlGroup"] == cgroup_path && !@platform.exited?(handle)
            raise Error, "session process changed during terminal handoff"
          end
          identity = Identity.new(unit: launch.unit, invocation_id: binding.fetch("invocation_id"),
            process: process.freeze, pidfd: handle, cgroup: cgroup)
          handle = cgroup = nil
          identity
        rescue Ace::Runtime::Error, SystemCallError, IOError, KeyError, ArgumentError => error
          raise Error, "session identity is unavailable (#{error.class})"
        ensure
          handle&.close
          cgroup&.fetch(:handle)&.close
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
          # An operator or systemd may already have stopped and collected the
          # transient unit. Only retirement of the pinned original cgroup AND
          # process exit can confirm that case; absence of unit metadata cannot.
          return true if @platform.exited?(identity.pidfd) && @cgroups.retired?(identity.cgroup)
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
          # StopUnit waits for the control-group stop job. A successfully
          # stopped transient unit may already be garbage-collected; asking
          # for its properties again is not a reliable termination check.
          unless @platform.exited?(identity.pidfd)
            raise Error, "session termination was not confirmed"
          end
          true
        rescue Ace::Runtime::Error, SystemCallError, IOError, KeyError => error
          # Collection can race the first observation or StopUnit itself.
          # Retry only the original retained objects, never the missing name.
          return true if @platform.exited?(identity.pidfd) && @cgroups.retired?(identity.cgroup)
          raise Error, "session stop is unconfirmed (#{error.class})"
        end

        # One framed handoff on an already authenticated launch connection.
        # The launch owner retains its descriptors and lifecycle connection;
        # SCM_RIGHTS duplicates the terminal and pinned process into Herdr.
        def handoff(identity, terminal:, channel:, rows:, cols:, directory:)
          raise Error, "session handoff requires the root host endpoint" unless @privileged
          unless identity.is_a?(Identity) && SessionPeer::UNIT.match?(identity.unit) &&
              identity.process["pid"].is_a?(Integer) && identity.process["pid"].positive? &&
              identity.invocation_id.is_a?(String) && identity.invocation_id.match?(/\A[0-9a-f]{32}\z/) &&
              identity.invocation_id != "0" * 32 && identity.pidfd.is_a?(IO) && !identity.pidfd.closed? &&
              terminal.is_a?(IO) && !terminal.closed? && terminal.tty? &&
              channel.is_a?(BasicSocket) && !channel.closed? && channel.local_address.unix? &&
              channel.local_address.socktype == Socket::SOCK_STREAM &&
              directory.is_a?(String) && (directory.match?(%r{\A/lab/[a-zA-Z0-9][a-zA-Z0-9_.-]*(?:/\.ace-wt/[a-zA-Z0-9_.-]+)?\z}) && File.expand_path(directory) == directory ||
                (directory == "/lab" && SessionPeer::UNIT.match(identity.unit)[1] == "lab-overseer")) &&
              [rows, cols].all? { |size| size.is_a?(Integer) && size.between?(1, 65_535) }
            raise ArgumentError, "invalid authenticated terminal handoff"
          end
          @platform.live!(identity.process)
          raise Error, "session exited before handoff" if @platform.exited?(identity.pidfd)
          expected = {"unit" => identity.unit, "invocation_id" => identity.invocation_id}
          unless @manager_factory.call(identity.unit).unit_for_pidfd(handle: identity.pidfd) == expected
            raise Error, "session binding changed before handoff"
          end
          payload = JSON.generate("protocol" => "ace.session-launch/v1", "unit" => identity.unit,
            "invocation" => identity.invocation_id, "pid" => identity.process.fetch("pid"),
            "rows" => rows, "cols" => cols, "directory" => directory)
          frame = [payload.bytesize].pack("N") + payload
          rights = Socket::AncillaryData.unix_rights(terminal, identity.pidfd)
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 5
          sent = 0
          while sent < frame.bytesize
            remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)
            unless remaining.positive? && IO.select(nil, [channel], nil, remaining)
              raise Error, "session handoff deadline expired"
            end
            count = if sent.zero?
              channel.sendmsg_nonblock(frame, 0, nil, rights, exception: false)
            else
              channel.write_nonblock(frame.byteslice(sent..), exception: false)
            end
            next if count == :wait_writable
            raise Error, "session handoff channel closed" unless count.is_a?(Integer) && count.positive?
            sent += count
          end
          true
        rescue Ace::Runtime::Error, SystemCallError, IOError, KeyError => error
          raise Error, "session terminal handoff failed (#{error.class})"
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
