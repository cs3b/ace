# frozen_string_literal: true

require "socket"
require "fcntl"
require "etc"
require "ace/runtime"
require "ace/runtime/molecules/protected_linux"
require "ace/runtime/molecules/systemd_scope_manager"
require_relative "error"
require_relative "session_namespace"

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
                      "RuntimeDirectory" => "as", "RuntimeDirectoryPreserve" => "s", "Environment" => "as"}.freeze

        Identity = Struct.new(:uid, :gid, :role, :invocation_id, :unit, :cwd, :runtime_dir, :pidfd, :main_pidfd,
          :main_pid, :mount_namespace, :project_root, keyword_init: true) do
          def close
            pidfd.close unless pidfd.closed?
            main_pidfd.close unless main_pidfd.closed?
            mount_namespace&.close unless mount_namespace&.closed?
          end
        end

        def initialize(platform: Ace::Runtime::Molecules::ProtectedLinux.new,
          manager_factory: ->(unit) { Ace::Runtime::Molecules::SystemdScopeManager.new(slice_unit: SLICE, service_unit: unit) },
          proc_root: "/proc", runtime_root: "/run", etc_root: "/etc", owner_uid: 0, account_lookup: ->(uid) { Etc.getpwuid(uid) },
          namespace_factory: nil, namespace_matcher: nil)
          @platform, @manager_factory = platform, manager_factory
          @proc_root, @runtime_root, @owner_uid, @account_lookup = proc_root, runtime_root, owner_uid, account_lookup
          @etc_root = etc_root
          @namespace_factory = namespace_factory || ->(pid) { SessionNamespace.capture(pid, proc_root: @proc_root) }
          @namespace_matcher = namespace_matcher || ->(namespace, pid) { SessionNamespace.matches?(namespace, pid, proc_root: @proc_root) }
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
          main_pid = observed["MainPID"]
          unless main_pid.is_a?(String) && main_pid.match?(/\A[1-9][0-9]*\z/)
            raise Error, "session main process is unavailable"
          end
          main = @platform.capture(Integer(main_pid, 10))
          unless main["uid"] == peer["uid"] && main["gid"] == peer["gid"] &&
              main.fetch("groups").all? { |group| group == peer["gid"] }
            raise Error, "session main process identity differs"
          end
          main_handle = @platform.pin(main)
          unless manager.unit_for_pidfd(handle: main_handle) == manager_identity
            raise Error, "session main process invocation differs"
          end
          properties = manager.typed_properties(unit: unit, interface: "Service", signatures: PROPERTIES)
          environment = properties.fetch("Environment", [])
          fixed = %w[ACE_TOOLCHAIN ACE_LAB_SESSION ACE_LAB_PROJECT_ROOT].to_h do |key|
            entries = environment.grep(/\A#{key}=/)
            raise Error, "session configured environment is ambiguous" unless entries.size == 1
            [key, entries.first.delete_prefix("#{key}=")]
          end
          project_root = fixed.fetch("ACE_LAB_PROJECT_ROOT")
          unless fixed["ACE_TOOLCHAIN"] == "installed" && fixed["ACE_LAB_SESSION"] == "1" &&
              project_root.start_with?("/") && File.expand_path(project_root) == project_root &&
              !project_root.match?(/[[:cntrl:]]/)
            raise Error, "session configured project or runtime differs"
          end
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
              properties["Delegate"] == false && properties["RuntimeDirectory"] == [directory_name] &&
              properties["RuntimeDirectoryPreserve"] == "no"
            raise Error, "session systemd isolation policy differs"
          end
          namespace = @namespace_factory.call(Integer(main_pid, 10))
          raise Error, "session mount namespace is unavailable" unless namespace.is_a?(IO) && !namespace.closed?
          runtime_dir = File.join(@runtime_root, directory_name)
          @platform.live!(peer)
          raise Error, "session peer has exited" if @platform.exited?(handle)
          claim_runtime_directory!(runtime_dir, peer)
          cwd = File.realpath(File.join(@proc_root, peer.fetch("pid").to_s, "cwd"))
          @platform.live!(peer)
          raise Error, "session peer has exited" if @platform.exited?(handle)
          unless manager.unit_for_pidfd(handle: handle) == manager_identity &&
              !@platform.exited?(main_handle) && manager.unit_for_pidfd(handle: main_handle) == manager_identity &&
              @namespace_matcher.call(namespace, Integer(main_pid, 10)) && !@platform.exited?(main_handle)
            raise Error, "session unit or invocation changed"
          end

          Identity.new(uid: peer.fetch("uid"), gid: peer.fetch("gid"), role: match[1],
            invocation_id: manager_identity.fetch("invocation_id"), unit: unit,
            cwd: cwd, runtime_dir: runtime_dir, pidfd: handle, main_pidfd: main_handle,
            main_pid: Integer(main_pid, 10), mount_namespace: namespace, project_root: project_root).freeze
        rescue Exception => error
          handle&.close unless handle&.closed?
          main_handle&.close unless main_handle&.closed?
          namespace&.close unless namespace&.closed?
          if error.is_a?(Ace::Runtime::Error) || error.is_a?(SystemCallError) || error.is_a?(IOError) || error.is_a?(ArgumentError)
            raise Error, "session identity could not be verified (#{error.class})"
          end
          raise
        end

        # The same runtime-directory owner serves authenticated lease calls
        # and pre-exec preparation. Claim it before adding HOME/Pi contents;
        # otherwise the first lease would rightly reject a nonempty directory
        # still owned by the DynamicUser.
        def prepare_runtime(identity)
          raise Error, "session preparation requires root" unless Process.euid.zero?
          unless identity.is_a?(SessionLauncher::Identity) && UNIT.match?(identity.unit) &&
              DYNAMIC_UIDS.cover?(identity.process["uid"]) && identity.process["gid"] == identity.process["uid"]
            raise Error, "session preparation requires a verified launch identity"
          end
          @platform.live!(identity.process)
          binding = @manager_factory.call(identity.unit).unit_for_pidfd(handle: identity.pidfd)
          unless !@platform.exited?(identity.pidfd) &&
              binding == {"unit" => identity.unit, "invocation_id" => identity.invocation_id}
            raise Error, "session preparation identity changed"
          end
          path = File.join(@runtime_root, "ace-auth-#{UNIT.match(identity.unit)[2]}")
          claim_runtime_directory!(path, identity.process)
          path
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
              # A failed emptiness check must not leave a searchable,
              # root-owned directory that a later authentication trusts.
              directory.chmod(0o000)
              directory.chown(@owner_uid, 0)
              directory.chmod(0o000)
              raise Error, "session runtime directory was not empty" unless empty_directory?(directory)
              directory.chmod(0o711)
            end
            after = directory.stat
            named = File.lstat(path)
            unless named.directory? && !named.symlink? && [after.dev, after.ino] == [named.dev, named.ino] &&
                after.uid == @owner_uid && (after.mode & 0o777) == 0o711
              raise Error, "session runtime directory is not root-controlled and searchable"
            end
          end
        end

        def empty_directory?(directory)
          raise Error, "session runtime verification requires descriptor-based directory support" unless Dir.respond_to?(:for_fd)
          duplicate = directory.dup
          stream = Dir.for_fd(duplicate.fileno)
          duplicate.autoclose = false # fdopendir owns and closes this descriptor
          stream.each_child.none?
        ensure
          if stream
            stream.close
          elsif duplicate && !duplicate.closed?
            duplicate.close
          end
        end
      end
    end
  end
end
