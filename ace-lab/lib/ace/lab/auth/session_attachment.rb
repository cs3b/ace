# frozen_string_literal: true

require_relative "session_peer"

module Ace
  module Lab
    module Auth
      # Attach a stopped-at-the-gate child to the authenticated peer's unit.
      # The child PID is selected by the trusted issuer after fork, never by
      # the socket client. Verify both lifetimes against systemd after the
      # migration before the parent allows the child to drop privileges.
      class SessionAttachment
        def initialize(identity:, platform: Ace::Runtime::Molecules::ProtectedLinux.new,
          manager: nil, command: Ace::Runtime::Molecules::SystemdScopeManager::Command.new)
          raise ArgumentError, "session attachment requires a root issuer" unless Process.euid.zero?
          unless identity.is_a?(SessionPeer::Identity) && SessionPeer::UNIT.match?(identity.unit) &&
              identity.pidfd.is_a?(IO) && !identity.pidfd.closed?
            raise ArgumentError, "session attachment requires an authenticated identity"
          end
          @identity, @platform, @command = identity, platform, command
          @manager = manager || Ace::Runtime::Molecules::SystemdScopeManager.new(
            slice_unit: SessionPeer::SLICE, service_unit: identity.unit)
        end

        def call(pid)
          raise ArgumentError, "child pid is invalid" unless pid.is_a?(Integer) && pid.positive?
          child = @platform.pin(@platform.capture(pid))
          expected = {"unit" => @identity.unit, "invocation_id" => @identity.invocation_id}
          verify!(@identity.pidfd, expected)
          @command.call([Ace::Runtime::Molecules::SystemdScopeManager::BUSCTL, "--system", "--no-pager",
            "--auto-start=no", "--allow-interactive-authorization=no", "call", "org.freedesktop.systemd1",
            "/org/freedesktop/systemd1", "org.freedesktop.systemd1.Manager", "AttachProcessesToUnit",
            "ssau", @identity.unit, "", "1", pid.to_s], timeout: 5)
          verify!(child, expected)
          verify!(@identity.pidfd, expected)
          true
        ensure
          child&.close unless child&.closed?
        end

        private

        def verify!(handle, expected)
          if @platform.exited?(handle) || @manager.unit_for_pidfd(handle: handle) != expected
            raise Error, "session or child lifetime changed during attachment"
          end
        end
      end
    end
  end
end
