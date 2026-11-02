# frozen_string_literal: true

require "socket"
require "fcntl"
require "etc"
require "ace/runtime"
require "ace/runtime/molecules/protected_linux"
require "ace/runtime/molecules/systemd_scope_manager"

module Ace
  module Lab
    module Auth
      # Authenticate a Unix socket peer against its live, root-created
      # DynamicUser unit. The returned pidfd remains open until the caller
      # closes the identity. No UID, role, unit or cwd comes from a request.
      class SessionPeer
        SO_PEERPIDFD = 77 # Linux >= 6.5
        UNIT = /\Aace-auth-session-([a-z][a-z0-9-]{0,19})-([0-9a-f]{16})\.service\z/
        DYNAMIC_UIDS = (61_184..65_519)
        SLICE = "ace-auth-sessions.slice"
        PROPERTIES = {"User" => "s", "DynamicUser" => "b", "NoNewPrivileges" => "b",
                      "CapabilityBoundingSet" => "t", "KillMode" => "s", "Delegate" => "b",
                      "RuntimeDirectory" => "as", "RuntimeDirectoryPreserve" => "s"}.freeze

        Identity = Struct.new(:uid, :gid, :role, :invocation_id, :unit, :cwd, :runtime_dir, :pidfd, keyword_init: true) do
          def close
            pidfd.close unless pidfd.closed?
          end
        end

        def initialize(platform: Ace::Runtime::Molecules::ProtectedLinux.new,
          manager_factory: ->(unit) { Ace::Runtime::Molecules::SystemdScopeManager.new(slice_unit: SLICE, service_unit: unit) },
          proc_root: "/proc", runtime_root: "/run", etc_root: "/etc", owner_uid: 0, account_lookup: ->(uid) { Etc.getpwuid(uid) })
          @platform, @manager_factory = platform, manager_factory
          @proc_root, @runtime_root, @owner_uid, @account_lookup = proc_root, runtime_root, owner_uid, account_lookup
          @etc_root = etc_root
        end

        def authenticate(socket)
          @platform.supported!
          # Unlike opening a pidfd by numeric PID, this descriptor is tied to
          # the process that originally connected even if its PID is reused.
          fd = socket.getsockopt(Socket::SOL_SOCKET, SO_PEERPIDFD).int
          handle = IO.for_fd(fd, autoclose: true)
          handle.fcntl(Fcntl::F_SETFD, Fcntl::FD_CLOEXEC)
          raise Error, "session peer has exited" if @platform.exited?(handle)

          peer = @platform.peer(socket)
          unless DYNAMIC_UIDS.cover?(peer.fetch("uid")) && peer.fetch("gid") == peer.fetch("uid") &&
              peer.fetch("groups").all? { |group| group == peer.fetch("gid") }
            raise Error, "session requires a dedicated dynamic uid and gid"
          end
          cgroup = File.read(File.join(@proc_root, peer.fetch("pid").to_s, "cgroup"))
          lines = cgroup.lines.grep(/\A0::/)
          raise Error, "session control group is ambiguous" unless lines.size == 1
          path = lines.first.delete_prefix("0::").strip
          unit = File.basename(path)
          match = UNIT.match(unit)
          raise Error, "session unit is not an ACE session" unless match && path.end_with?("/#{unit}")

          manager = @manager_factory.call(unit)
          manager_identity = manager.unit_for_pidfd(handle: handle)
          units = manager.inspect_units
          observed = units.fetch("service")
          unless observed["ActiveState"] == "active" && observed["ControlGroup"] == path && observed["Slice"] == SLICE &&
              manager_identity.fetch("unit") == unit && manager_identity.fetch("invocation_id") == observed["InvocationID"]
            raise Error, "session unit or invocation changed"
          end
          properties = manager.typed_properties(unit: unit, interface: "Service", signatures: PROPERTIES)
          begin
            account = @account_lookup.call(peer.fetch("uid"))
          rescue ArgumentError
            raise Error, "session dynamic account is unavailable"
          end
          verify_dynamic_account!(account)
          directory_name = "ace-auth-#{match[2]}"
          unless account.uid == peer["uid"] && account.name == properties["User"] && account.gid == peer["gid"] &&
              properties["DynamicUser"] == true && properties["NoNewPrivileges"] == true &&
              properties["CapabilityBoundingSet"] == 0 && properties["KillMode"] == "control-group" &&
              properties["Delegate"] == true && properties["RuntimeDirectory"] == [directory_name] &&
              properties["RuntimeDirectoryPreserve"] == "no"
            raise Error, "session systemd isolation policy differs"
          end
          runtime_dir = File.join(@runtime_root, directory_name)
          @platform.live!(peer)
          raise Error, "session peer has exited" if @platform.exited?(handle)
          claim_runtime_directory!(runtime_dir, peer)
          cwd = File.realpath(File.join(@proc_root, peer.fetch("pid").to_s, "cwd"))
          @platform.live!(peer)
          raise Error, "session peer has exited" if @platform.exited?(handle)
          unless manager.unit_for_pidfd(handle: handle) == manager_identity
            raise Error, "session unit or invocation changed"
          end

          Identity.new(uid: peer.fetch("uid"), gid: peer.fetch("gid"), role: match[1],
            invocation_id: manager_identity.fetch("invocation_id"), unit: unit,
            cwd: cwd, runtime_dir: runtime_dir, pidfd: handle)
        rescue Exception
          handle&.close unless handle&.closed?
          raise
        end

        private

        # DynamicUser alone can reuse an existing static account. Accept only
        # the known local NSS configuration and reject any static name or ID.
        # Other identity providers require an explicit implementation, not an
        # assumption that their accounts are isolated systemd users.
        def verify_dynamic_account!(account)
          configuration = File.readlines(File.join(@etc_root, "nsswitch.conf"), chomp: true)
          %w[passwd group].each do |database|
            entries = configuration.filter_map do |line|
              line = line.sub(/#.*/, "")
              match = /\A\s*#{database}\s*:\s*(.*?)\s*\z/.match(line)
              match && match[1].split
            end
            raise Error, "unsupported session identity sources" unless entries == [["files", "systemd"]]
          end
          {"passwd" => account.uid, "group" => account.gid}.each do |database, id|
            File.foreach(File.join(@etc_root, database)) do |line|
              name, _, number = line.chomp.split(":", 4)
              next if name.nil? || name.start_with?("#")
              raise Error, "session identity collides with static account" if name == account.name || number == id.to_s
            end
          end
        rescue SystemCallError
          raise Error, "session identity sources unavailable"
        end

        # systemd initially gives RuntimeDirectory to DynamicUser. Claim the
        # reserved empty directory through a no-follow descriptor before any
        # credential is written. The /run parent is root-controlled; after
        # fchown the session cannot replace or add entries in the directory.
        # systemd still owns its lifecycle and removes it on unit stop.
        def claim_runtime_directory!(path, peer)
          File.open(path, File::RDONLY | File::NOFOLLOW) do |directory|
            before = directory.stat
            raise Error, "session runtime path is not a directory" unless before.directory?

            if before.uid == peer.fetch("uid")
              raise Error, "session runtime group differs" unless before.gid == peer.fetch("gid")
              directory.chown(@owner_uid, 0)
              directory.chmod(0o711)
              raise Error, "session runtime directory was not empty" unless Dir.empty?(path)
            end
            after = directory.stat
            named = File.lstat(path)
            unless named.directory? && !named.symlink? && [after.dev, after.ino] == [named.dev, named.ino] &&
                after.uid == @owner_uid && (after.mode & 0o777) == 0o711
              raise Error, "session runtime directory is not root-controlled and searchable"
            end
          end
        end
      end
    end
  end
end
