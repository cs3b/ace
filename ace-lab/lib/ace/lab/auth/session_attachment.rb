# frozen_string_literal: true

require "fiddle"
require_relative "session_peer"

module Ace
  module Lab
    module Auth
      # The child writes 0 through a pinned cgroup.procs descriptor, so the
      # kernel moves the writer itself and no numeric PID can be recycled
      # into an unrelated process migration. The parent verifies the child
      # and session before releasing the child's exec gate.
      class SessionAttachment
        CGROUP_ROOT = "/sys/fs/cgroup"
        CGROUP2_MAGIC = 0x6367_7270

        def initialize(identity:, platform: Ace::Runtime::Molecules::ProtectedLinux.new,
          manager: nil, cgroup_opener: nil,
          namespace_matcher: ->(namespace, pid) { SessionNamespace.matches?(namespace, pid) })
          raise ArgumentError, "session attachment requires a root issuer" unless Process.euid.zero?
          unless identity.is_a?(SessionPeer::Identity) && SessionPeer::UNIT.match?(identity.unit) &&
              identity.pidfd.is_a?(IO) && !identity.pidfd.closed? &&
              identity.main_pidfd.is_a?(IO) && !identity.main_pidfd.closed? &&
              identity.mount_namespace.is_a?(IO) && !identity.mount_namespace.closed? &&
              identity.main_pid.is_a?(Integer) && identity.main_pid.positive?
            raise ArgumentError, "session attachment requires an authenticated identity"
          end
          @identity, @platform = identity, platform
          @namespace_matcher = namespace_matcher
          @manager = manager || Ace::Runtime::Molecules::SystemdScopeManager.new(
            slice_unit: SessionPeer::SLICE, service_unit: identity.unit)
          @cgroup_opener = cgroup_opener || method(:open_cgroup)
        end

        def prepare
          verify_session!
          group = verified_group!
          descriptor = @cgroup_opener.call(group)
          raise Error, "session cgroup is unavailable" unless descriptor.is_a?(IO) && !descriptor.closed?
          verify_session!
          raise Error, "session cgroup changed" unless verified_group! == group
          descriptor
        rescue Exception
          descriptor&.close unless descriptor&.closed?
          raise
        end

        def verify_child!(pid)
          raise ArgumentError, "child pid is invalid" unless pid.is_a?(Integer) && pid.positive?
          process = @platform.capture(pid)
          unless process["parent_pid"] == Process.pid && process["uid"] == @identity.uid &&
              process["gid"] == @identity.gid && process["groups"] == []
            raise Error, "session child identity differs"
          end
          child = @platform.pin(process)
          expected = {"unit" => @identity.unit, "invocation_id" => @identity.invocation_id}
          verify_session!
          verify!(child, expected)
          verify_session!
          true
        ensure
          child&.close unless child&.closed?
        end

        def verify_session!
          expected = {"unit" => @identity.unit, "invocation_id" => @identity.invocation_id}
          verify!(@identity.pidfd, expected)
          verify!(@identity.main_pidfd, expected)
          unless @namespace_matcher.call(@identity.mount_namespace, @identity.main_pid)
            raise Error, "session mount namespace changed"
          end
          verify!(@identity.main_pidfd, expected)
          true
        end

        private

        def verified_group!
          service = @manager.inspect_units.fetch("service")
          group = service["ControlGroup"]
          unless service["ActiveState"] == "active" && service["InvocationID"] == @identity.invocation_id &&
              service["Slice"] == SessionPeer::SLICE && group.is_a?(String) &&
              group.match?(%r{\A/(?:[A-Za-z0-9_.:-]+/)*#{Regexp.escape(@identity.unit)}\z}) &&
              !group.split("/").include?("..")
            raise Error, "session cgroup identity is unavailable"
          end
          group
        end

        def open_cgroup(group)
          path = File.join(CGROUP_ROOT, group.delete_prefix("/"), "cgroup.procs")
          raise Error, "session cgroup path is not canonical" unless File.realpath(path) == path
          descriptor = File.open(path, File::WRONLY | File::NOFOLLOW)
          descriptor.close_on_exec = true
          opened, named = descriptor.stat, File.lstat(path)
          unless opened.file? && !named.symlink? && [opened.dev, opened.ino] == [named.dev, named.ino] && cgroup2?(descriptor)
            raise Error, "session cgroup descriptor is unsafe"
          end
          descriptor
        rescue Exception
          descriptor&.close unless descriptor&.closed?
          raise
        end

        def cgroup2?(descriptor)
          function = Fiddle::Function.new(Fiddle::Handle::DEFAULT["fstatfs"],
            [Fiddle::TYPE_INT, Fiddle::TYPE_VOIDP], Fiddle::TYPE_INT)
          buffer = Fiddle::Pointer.malloc(256)
          function.call(descriptor.fileno, buffer).zero? && buffer[0, Fiddle::SIZEOF_LONG].unpack1("l!") == CGROUP2_MAGIC
        rescue Fiddle::DLError
          false
        end

        def verify!(handle, expected)
          if @platform.exited?(handle) || @manager.unit_for_pidfd(handle: handle) != expected
            raise Error, "session or child lifetime changed during attachment"
          end
        end
      end
    end
  end
end
