# frozen_string_literal: true

require "ace/runtime/molecules/cgroup_observation"
require "ace/runtime/molecules/systemd_scope_manager"
require "ace/runtime/molecules/linux_mount_info"
require "ace/runtime/molecules/execution_unit_installation"
require "ace/runtime/molecules/network_installation_evidence"
require "ace/runtime/molecules/execution_network_selection"
require "ace/runtime/molecules/execution_boot_baseline"
require "ace/runtime/molecules/kernel_view_topology"
require_relative "../molecules/execution_scope_lineage"
require_relative "posix_acl"
require "digest"
require "json"
require "ace/herdr/molecules/protected_native_control"

module Ace
  module Assign
    module Authority
      # Joins already canonical scope facts to current native owner objects.
      # This does not manufacture readiness, a network-policy assertion, or a
      # canonical no-writer event from a population snapshot.
      class ExecutionScopeObservation
        LOCAL_FILESYSTEMS = %w[ext4 xfs btrfs tmpfs].freeze
        BOUNDARY_SCHEMA = "ace.execution-boundary-manifest/v1"

        class Files
          def boot_id
            value = File.read("/proc/sys/kernel/random/boot_id", 128).strip
            unless value.match?(Molecules::ExecutionScopeLineage::BOOT)
              raise Ace::Runtime::RuntimeUnavailableError, "kernel boot identity is malformed"
            end
            value
          end

          def resource_identity(path)
            unless path.is_a?(String) && path.start_with?("/") && File.expand_path(path) == path && File.realpath(path) == path
              raise Ace::Runtime::RuntimeUnavailableError, "scope resource path is substituted"
            end
            File.open(path, File::RDONLY | File::NOFOLLOW) do |directory|
              stat = directory.stat
              raise Ace::Runtime::RuntimeUnavailableError, "scope resource is not a directory" unless stat.directory?
              info = File.read("/proc/self/fdinfo/#{directory.fileno}", 16_385)
              ids = info.lines.filter_map { |line| /\Amnt_id:\s+([0-9]+)\s*\z/.match(line)&.[](1) }
              raise Ace::Runtime::RuntimeUnavailableError, "resource mount identity is ambiguous" unless ids.size == 1
              bytes = File.read("/proc/self/mountinfo", Ace::Runtime::Molecules::LinuxMountInfo::LIMIT + 1)
              mount = Ace::Runtime::Molecules::LinuxMountInfo.new(bytes).by_id(Integer(ids.first, 10))
              current = File.stat(path)
              unless current.dev == stat.dev && current.ino == stat.ino && File.realpath(path) == path
                raise Ace::Runtime::RuntimeUnavailableError, "scope resource changed while observing it"
              end
              {"device" => stat.dev, "inode" => stat.ino, "uid" => stat.uid, "gid" => stat.gid,
                "filesystem_type" => mount.fetch("filesystem_type"), "mount_id" => mount.fetch("mount_id")}
            end
          end

          def namespace_identity
            File.open("/proc/self/ns/mnt", File::RDONLY) do |namespace|
              stat = namespace.stat
              {"device" => stat.dev, "inode" => stat.ino}
            end
          end

          def authority_socket_identity(authority)
            wire = Ace::Runtime::Molecules::ProtectedSocket
            wire.root_path!(File.dirname(authority.fetch("socket_path")), directory: true, owner: authority.fetch("uid"))
            identity = wire.socket_identity(authority.fetch("socket_path"))
            raise Ace::Runtime::RuntimeUnavailableError, "authority endpoint owner differs" unless identity.last == authority.fetch("uid")
            identity
          end

          def pin_network_namespace(path)
            unless RUBY_PLATFORM.include?("linux") && path.is_a?(String) && path.start_with?("/") &&
                path.bytesize.between?(1, 4096) && !path.include?("\0") && File.expand_path(path) == path && File.realpath(path) == path
              raise Ace::Runtime::RuntimeUnavailableError, "installed network namespace path is substituted"
            end
            parts = path.split("/").reject(&:empty?)
            paths = ["/"] + parts.each_index.map { |index| "/" + parts.take(index + 1).join("/") }
            paths.each do |ancestor|
              stat = File.lstat(ancestor)
              unless stat.uid.zero? && !stat.symlink? && (stat.mode & 0o022).zero? &&
                  (ancestor == path || stat.directory?)
                raise Ace::Runtime::RuntimeUnavailableError, "installed network namespace ancestry is writable"
              end
              # The leaf is authenticated as nsfs below. nsfs has no access
              # ACL/xattr owner and exposes only namespace ioctls, not writes.
              next if ancestor == path
              acl = PosixAcl.new.entries(ancestor)
              if acl && acl.any? { |tag, permissions, uid| (permissions & 2) != 0 && !(tag == 1 || tag == 2 && uid.zero?) }
                raise Ace::Runtime::RuntimeUnavailableError, "installed network namespace ACL permits untrusted mutation"
              end
            end
            handle = File.open(path, File::RDONLY | File::NOFOLLOW)
            stat = handle.stat
            info = File.read("/proc/self/fdinfo/#{handle.fileno}", 16_385)
            ids = info.lines.filter_map { |line| /\Amnt_id:\s+([0-9]+)\s*\z/.match(line)&.[](1) }
            table = Ace::Runtime::Molecules::LinuxMountInfo.new(File.read("/proc/self/mountinfo", Ace::Runtime::Molecules::LinuxMountInfo::LIMIT + 1))
            unless ids.size == 1 && table.by_id(Integer(ids.first, 10)).fetch("filesystem_type") == "nsfs" &&
                handle.ioctl(0xb703) == 0x40000000 && [File.stat(path).dev, File.stat(path).ino] == [stat.dev, stat.ino]
              raise Ace::Runtime::RuntimeUnavailableError, "installed object is not the exact nsfs network namespace"
            end
            {handle: handle, identity: {"device" => stat.dev, "inode" => stat.ino}}
          rescue StandardError
            handle&.close
            raise
          end

          def resource_topology(path, mount_id:)
            table = Ace::Runtime::Molecules::LinuxMountInfo.new(File.read("/proc/self/mountinfo", Ace::Runtime::Molecules::LinuxMountInfo::LIMIT + 1))
            record = table.by_id(mount_id)
            {"major_minor" => record.fetch("major_minor"), "filesystem_path" => table.filesystem_path(record, path)}
          end

          def resource_boundary_policy(path)
            stat = File.lstat(path)
            unless stat.directory? && File.realpath(path) == path
              raise Ace::Runtime::RuntimeUnavailableError, "protected root policy object is substituted"
            end
            {"device" => stat.dev, "inode" => stat.ino, "uid" => stat.uid, "gid" => stat.gid,
              "mode" => stat.mode & 0o7777, "acl" => PosixAcl.new.entries(path)}
          end

          def resource_aliases(path, identity:)
            table = Ace::Runtime::Molecules::LinuxMountInfo.new(File.read("/proc/self/mountinfo", Ace::Runtime::Molecules::LinuxMountInfo::LIMIT + 1))
            original = table.by_id(identity.fetch("mount_id"))
            physical = table.filesystem_path(original, path)
            table.records.filter_map do |mount|
              next unless mount.fetch("major_minor") == original.fetch("major_minor") && mount.fetch("options").include?("rw")
              root = mount.fetch("root")
              if physical == root || root == "/" || physical.start_with?(root + "/")
                suffix = physical.delete_prefix(root).delete_prefix("/")
                File.join(mount.fetch("mountpoint"), suffix)
              elsif root.start_with?(physical + "/")
                mount.fetch("mountpoint")
              end
            end
          end

          def worker_uid_quiescent!(uid)
            table = Ace::Runtime::Molecules::LinuxMountInfo.new(File.read("/proc/self/mountinfo", Ace::Runtime::Molecules::LinuxMountInfo::LIMIT + 1))
            proc_mounts = table.records.select { |record| record.fetch("mountpoint") == "/proc" }
            unless proc_mounts.size == 1 && proc_mounts.first.fetch("filesystem_type") == "proc" && proc_mounts.first.fetch("root") == "/" &&
                (proc_mounts.first.fetch("options") + proc_mounts.first.fetch("super_options")).none? { |option| option.start_with?("hidepid=") && option != "hidepid=0" }
              raise Ace::Runtime::RuntimeUnavailableError, "worker UID baseline requires a fully visible authority proc view"
            end
            pids = Dir.children("/proc").select { |name| name.match?(/\A[1-9][0-9]*\z/) }
            raise Ace::Runtime::RuntimeUnavailableError, "worker UID baseline is oversized" if pids.size > 100_000
            pids.each do |pid|
              begin
                bytes = File.open("/proc/#{pid}/status", File::RDONLY | File::NOFOLLOW) { |file| file.read(65_537) }
              rescue Errno::ENOENT, Errno::ESRCH
                next # A dead process cannot retain a writable userspace handle.
              end
              rows = bytes.lines.select { |line| line.start_with?("Uid:") }
              match = rows.size == 1 && /\AUid:\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s+([0-9]+)\s*\z/.match(rows.first)
              unless bytes.bytesize <= 65_536 && match
                raise Ace::Runtime::RuntimeUnavailableError, "worker UID baseline has unreadable credential evidence"
              end
              if match.captures.map { |value| Integer(value, 10) }.include?(uid)
                raise Ace::Runtime::RuntimeUnavailableError, "worker UID has a process outside the never-admitted generation"
              end
            end
            true
          end

          def resource_present?(path)
            File.lstat(path)
            true
          rescue Errno::ENOENT
            false
          end

          def boundary_manifest(scope)
            path = "/etc/ace/execution-slots/#{scope.fetch('slot_id')}/boundary-manifest.json"
            bytes = Ace::Runtime::Molecules::ExecutionUnitInstallation::Files.new.read(path, limit: 65_536)
            unless Digest::SHA256.hexdigest(bytes) == scope.fetch("boundary_manifest_sha256")
              raise Ace::Runtime::RuntimeUnavailableError, "boundary inventory differs from fixed deployment"
            end
            JSON.parse(bytes, create_additions: false, max_nesting: 8, allow_duplicate_key: false, allow_comments: false)
          rescue JSON::ParserError, EncodingError
            raise Ace::Runtime::RuntimeUnavailableError, "fixed boundary inventory is not strict UTF-8 JSON"
          end
        end

        def initialize(mapping_id:, deployment:, kernel:, manager: nil, cgroups: Ace::Runtime::Molecules::CgroupObservation.new, files: Files.new, network_evidence: Ace::Runtime::Molecules::NetworkInstallationEvidence.new, boot_evidence: Ace::Runtime::Molecules::ExecutionBootBaseline.new, network_selection: Ace::Runtime::Molecules::ExecutionNetworkSelection.new)
          @mapping_id, @deployment, @kernel, @cgroups, @files = mapping_id, deployment, kernel, cgroups, files
          @network_evidence = network_evidence
          @boot_evidence = boot_evidence
          @network_selection = network_selection
          @map = deployment.mapping(mapping_id)
          @scope = @map.fetch("execution_scope")
          @manager = manager || Ace::Runtime::Molecules::SystemdScopeManager.new(
            slice_unit: @scope.fetch("slice_unit"), service_unit: @scope.fetch("service_unit"))
        end

        def observe(lineage)
          @deployment.verify!(@mapping_id, kernel: @kernel, manager: @manager)
          binding = lineage.binding
          unless binding && binding.fetch("slot_id") == @scope.fetch("slot_id") && binding.fetch("boot_id") == @files.boot_id &&
              binding.fetch("deployment_digest") == Digest::SHA256.hexdigest(JSON.generate(canonical(@map))) &&
              binding.fetch("resource_mount_namespace_identity") == @files.namespace_identity
            unavailable!("retained scope deployment or boot changed")
          end
          network = @files.pin_network_namespace(@scope.fetch("network_namespace_path"))
          unless network.fetch(:identity) == binding.fetch("network_namespace_identity") &&
              network_selection! == binding.fetch("network_installation_selection")
            unavailable!("retained installed network namespace or selection changed")
          end
          boot_baseline!(binding)
          before = @manager.inspect_activation
          verify_parent!(binding, before.fetch("slice"))
          pinned = @cgroups.pin(binding.fetch("cgroup_identity").fetch("path"), expected: binding.fetch("cgroup_identity"))
          unless parent_resources! == binding.fetch("resource_identities")
            unavailable!("retained parent inventory changed")
          end
          verify_resources!(binding.fetch("resource_identities"))
          value = @cgroups.observe(pinned)
          after = @manager.inspect_activation
          unless before == after && @files.boot_id == binding.fetch("boot_id")
            unavailable!("scope activation changed while observing it")
          end
          {"populated" => value.fetch("populated"), "activation" => after}
        rescue SystemCallError, IOError, KeyError, TypeError, ArgumentError
          unavailable!("retained scope observation is unavailable")
        ensure
          pinned&.fetch(:handle)&.close
          network&.fetch(:handle)&.close
        end

        # Called only by the fresh reservation winner with slot exclusion held.
        # It creates no service or payload. Original activation facts are taken
        # after this exact successful StartUnit, never adopted on a later retry.
        def activate_parent!(context)
          @deployment.verify!(@mapping_id, kernel: @kernel, manager: @manager)
          inventory = parent_resources!
          selection = network_selection!
          network = @files.pin_network_namespace(@scope.fetch("network_namespace_path"))
          @files.worker_uid_quiescent!(@map.fetch("worker_uid"))
          boot = @files.boot_id
          digest = Digest::SHA256.hexdigest(JSON.generate(canonical(@map)))
          baseline = @boot_evidence.select!(expected: boot_baseline_expected(boot, digest, selection))
          namespace = @files.namespace_identity
          before = @manager.inspect_activation
          service = before.fetch("service")
          slice = before.fetch("slice")
          unless %w[inactive failed].include?(slice.fetch("ActiveState")) && slice.fetch("Job") == [0, "/"] &&
              %w[inactive failed].include?(service.fetch("ActiveState")) && service.fetch("Job") == [0, "/"] &&
              service.fetch("MainPID").zero? && service.fetch("ControlPID").zero?
            unavailable!("fresh parent activation has retained or pending native ownership")
          end
          @manager.start_slice
          activation = @manager.inspect_activation
          parent = activation.fetch("slice")
          unless parent.fetch("ActiveState") == "active" && parent.fetch("SubState") == "active" &&
              Molecules::ExecutionScopeLineage::INVOCATION.match?(parent.fetch("InvocationID")) && parent.fetch("Job") == [0, "/"] &&
              !parent.fetch("ControlGroup").empty? && activation.fetch("service") == service
            unavailable!("fresh parent job did not produce its exact independent activation")
          end
          pinned = @cgroups.pin(Ace::Runtime::Molecules::CgroupObservation::ROOT + parent.fetch("ControlGroup"))
          unless @cgroups.observe(pinned).fetch("populated").zero? && @files.boot_id == boot &&
              @files.namespace_identity == namespace && @manager.inspect_activation == activation
            unavailable!("fresh parent changed or acquired processes before binding")
          end
          verify_resources!(inventory)
          context.merge("slot_id" => @scope.fetch("slot_id"), "deployment_digest" => digest,
            "boot_id" => boot, "slice_invocation_id" => parent.fetch("InvocationID"), "cgroup_identity" => pinned.fetch(:identity),
            "resource_mount_namespace_identity" => namespace, "resource_identities" => inventory,
            "network_installation_selection" => selection, "network_namespace_identity" => network.fetch(:identity),
            "boot_baseline_selection" => baseline.fetch("selection"))
        rescue SystemCallError, IOError, KeyError, TypeError, ArgumentError, JSON::ParserError
          unavailable!("fresh parent inventory or activation is unavailable")
        ensure
          pinned&.fetch(:handle)&.close
          network&.fetch(:handle)&.close
        end

        def verify_closed!(lineage)
          value = observe(lineage)
          service = value.fetch("activation").fetch("service")
          unless lineage.sealed? && lineage.proof_event && value.fetch("populated").zero? &&
              %w[inactive failed].include?(service.fetch("ActiveState")) && service.fetch("MainPID").zero? &&
              service.fetch("ControlPID").zero? && service.fetch("Job") == [0, "/"]
            unavailable!("canonical closure has a live or pending native activation")
          end
          native_cleanup_complete!
          @files.worker_uid_quiescent!(@map.fetch("worker_uid"))
          if lineage.native_event
            native = lineage.native_event.fetch("payload")
            invocation = service.fetch("InvocationID")
            unless invocation.empty? || invocation == native.fetch("service_invocation_id")
              unavailable!("closed native incarnation was replaced")
            end
            verify_resources!(native.fetch("resource_identities"), allow_runtime_absence: true, same_namespace: false)
          end
          native_cleanup_complete!
          repeated = observe(lineage)
          unless repeated.fetch("populated").zero? && repeated.fetch("activation") == value.fetch("activation")
            unavailable!("scope activation changed during closure verification")
          end
          true
        end

        def readiness_peer!(lineage, peer)
          lineage.require_open!
          @deployment.verify!(@mapping_id, kernel: @kernel, manager: @manager)
          activation = observe(lineage).fetch("activation")
          service = activation.fetch("service")
          profile = @manager.inspect_profile
          command = profile.fetch("service").fetch("ExecStartPostEx").first
          unless service.fetch("ControlPID").positive? && peer.fetch("pid") == service.fetch("ControlPID") &&
              command.fetch(7) == peer.fetch("pid") && service.fetch("MainPID").positive? &&
              service.fetch("MainPID") != peer.fetch("pid") &&
              peer.values_at("uid", "gid", "groups") == @map.values_at("worker_uid", "worker_gid", "worker_groups")
            unavailable!("peer is not the exact fixed readiness actor")
          end
          server = @kernel.capture(service.fetch("MainPID"))
          unless server.values_at("uid", "gid", "groups") == peer.values_at("uid", "gid", "groups")
            unavailable!("native server principal differs")
          end
          @kernel.live!(peer)
          unavailable!("readiness activation changed") unless @manager.inspect_activation == activation
          server
        end

        def verify_readiness_report!(lineage, peer, report, challenge:)
          server = readiness_peer!(lineage, peer)
          unless report.is_a?(Hash) && report.keys.sort == %w[challenge_id kernel_view_topology mount_namespace_identity network_namespace_identity resource_identities resource_observer_identity resource_topology server_identity version] &&
              report["version"] == 1 && report["challenge_id"] == challenge.fetch("challenge_id") &&
              @kernel.same?(report.fetch("server_identity"), server) && @kernel.same?(report.fetch("resource_observer_identity"), peer)
            unavailable!("private readiness report binding differs")
          end
          network = report.fetch("network_namespace_identity")
          unless network.is_a?(Hash) && network.keys.sort == %w[device inode] &&
              network.values.all? { |value| value.is_a?(Integer) && value.positive? } &&
              network == lineage.binding.fetch("network_namespace_identity") &&
              network == lineage.admission_event.dig("payload", "data", "network_installation", "namespace_identity")
            unavailable!("original server network namespace differs from admitted installation")
          end
          entries = @files.boundary_manifest(@scope).fetch("resources").select { |entry| entry.fetch("worker_visible") }
          resources = report.fetch("resource_identities")
          unless resources.is_a?(Array) && resources.map { |entry| entry.values_at("host_path", "view_path") }.sort ==
              entries.map { |entry| entry.values_at("host_path", "view_path") }.sort
            unavailable!("readiness reachable resource union differs")
          end
          topology = report.fetch("resource_topology")
          unless topology.is_a?(Array) && topology.size == resources.size &&
              topology.map { |entry| entry.values_at("host_path", "view_path") }.sort ==
                entries.map { |entry| entry.values_at("host_path", "view_path") }.sort
            unavailable!("readiness resource mount topology differs")
          end
          resources.each do |resource|
            declaration = entries.find { |entry| entry.values_at("host_path", "view_path") == resource.values_at("host_path", "view_path") }
            view = topology.find { |entry| entry.values_at("host_path", "view_path") == resource.values_at("host_path", "view_path") }
            unless view.keys.sort == %w[host_path major_minor mountpoint options root view_path] &&
                view["options"].is_a?(Array) && view["options"].include?(declaration.fetch("read_only") ? "ro" : "rw") &&
                view["mountpoint"].is_a?(String) && (resource.fetch("view_path") == view["mountpoint"] ||
                  resource.fetch("view_path").start_with?(view["mountpoint"].delete_suffix("/") + "/"))
              unavailable!("readiness mount flags or projection differ")
            end
            host_identity = @files.resource_identity(resource.fetch("host_path"))
            host = @files.resource_topology(resource.fetch("host_path"), mount_id: host_identity.fetch("mount_id"))
            physical = File.expand_path(File.join(view.fetch("root"), resource.fetch("view_path").delete_prefix(view.fetch("mountpoint")).delete_prefix("/")))
            unless host.fetch("major_minor") == view.fetch("major_minor") && host.fetch("filesystem_path") == physical
              unavailable!("readiness mounted source or subtree differs")
            end
          end
          verify_resources!(resources, same_namespace: false)
          binding = lineage.binding
          baseline = boot_baseline!(binding)
          authority = @deployment.authority(@map.fetch("authority_id"))
          endpoint = @files.authority_socket_identity(authority)
          writable = entries.reject { |entry| entry.fetch("read_only") }.map do |entry|
            host = @files.resource_identity(entry.fetch("host_path"))
            @files.resource_topology(entry.fetch("host_path"), mount_id: host.fetch("mount_id"))
              .merge("view_path" => entry.fetch("view_path"), "filesystem_type" => host.fetch("filesystem_type"))
          end
          Ace::Runtime::Molecules::KernelViewTopology.new.verify!(topology: report.fetch("kernel_view_topology"),
            host_ipc: baseline.fetch("host_ipc_namespace_identity"), authority_socket: endpoint, writable_resources: writable,
            host_devpts: baseline.fetch("host_devpts_identity"), selected_devpts: baseline.fetch("selected_devpts"))
          unavailable!("authority endpoint changed during view verification") unless endpoint == @files.authority_socket_identity(authority)
          report.slice("server_identity", "resource_observer_identity", "mount_namespace_identity", "resource_identities").merge(
            "scope_generation" => binding.fetch("scope_generation"), "scope_binding_event_id" => lineage.binding_event.fetch("digest"),
            "service_invocation_id" => @manager.inspect_activation.fetch("service").fetch("InvocationID"),
            "workspace_id" => @map.fetch("native").fetch("workspace_id"),
            "network_namespace_identity" => network.dup,
            "network_admission_event_id" => lineage.admission_event.fetch("digest"))
        end

        def complete_native_readiness!(lineage, payload)
          unavailable!("completed activation lacks authenticated readiness") unless payload.is_a?(Hash)
          activation = observe(lineage).fetch("activation")
          service = activation.fetch("service")
          unless service.fetch("ActiveState") == "active" && service.fetch("ControlPID").zero? && service.fetch("Job") == [0, "/"] &&
              service.fetch("MainPID") == payload.dig("server_identity", "pid") &&
              service.fetch("InvocationID") == payload.fetch("service_invocation_id")
            unavailable!("native service has not completed the exact admitted activation")
          end
          @kernel.live!(payload.fetch("server_identity"))
          socket = Ace::Runtime::Molecules::ProtectedSocket.socket_identity(@map.fetch("native").fetch("socket_path"))
          value = payload.merge("socket_identity" => socket)
          native_map = @map.merge("native" => @map.fetch("native").merge(value.slice("server_identity", "socket_identity")))
          Ace::Herdr::Molecules::ProtectedNativeControl.new(mapping: native_map, kernel: @kernel).preflight!
          verify_resources!(value.fetch("resource_identities"), same_namespace: false)
          unavailable!("native activation changed during preflight") unless @manager.inspect_activation == activation
          value
        end

        def native_admission_ready!(lineage)
          value = observe(lineage)
          service = value.fetch("activation").fetch("service")
          unless value.fetch("populated").zero? && %w[inactive failed].include?(service.fetch("ActiveState")) &&
              service.fetch("MainPID").zero? && service.fetch("ControlPID").zero? && service.fetch("Job") == [0, "/"]
            unavailable!("native admission has an occupied or pending generation")
          end
          binding = lineage.binding
          selection = binding.fetch("network_installation_selection")
          @network_evidence.verify!(selection: selection, expected: {
            "slot_id" => @scope.fetch("slot_id"), "namespace_path" => @scope.fetch("network_namespace_path"),
            "boot_id" => binding.fetch("boot_id"), "namespace_identity" => binding.fetch("network_namespace_identity"),
            "installer_artifact_sha256" => selection.fetch("installer_artifact").fetch("sha256")})
        end

        def start_admitted_service!
          @manager.start_service
        end

        def sealed_service_stop_required?(lineage)
          unavailable!("service stop requires the canonical original seal") unless lineage.sealed?
          service = observe(lineage).fetch("activation").fetch("service")
          !(%w[inactive failed].include?(service.fetch("ActiveState")) && service.fetch("Job") == [0, "/"] &&
            service.fetch("MainPID").zero? && service.fetch("ControlPID").zero?)
        end

        def stop_sealed_service!
          @manager.stop_service
        end

        # Read-only original owner check used before all-root retirement.
        def verify_maintenance_closed!(lineages)
          @deployment.verify!(@mapping_id, kernel: @kernel, manager: @manager)
          activation = @manager.inspect_activation
          service, slice = activation.values_at("service", "slice")
          unless %w[inactive failed].include?(service.fetch("ActiveState")) &&
              service.fetch("Job") == [0, "/"] && service.fetch("MainPID").zero? && service.fetch("ControlPID").zero? &&
              slice.fetch("Job") == [0, "/"]
            unavailable!("maintenance has live or pending fixed-unit activation")
          end
          parent_resources!
          @files.worker_uid_quiescent!(@map.fetch("worker_uid"))
          if %w[inactive failed].include?(slice.fetch("ActiveState"))
            unless slice.fetch("InvocationID").empty? || lineages.any? { |lineage| lineage.binding.fetch("slice_invocation_id") == slice.fetch("InvocationID") }
              unavailable!("stopped maintenance parent is unknown")
            end
            unless slice.fetch("ControlGroup").empty?
              pinned = @cgroups.pin(Ace::Runtime::Molecules::CgroupObservation::ROOT + slice.fetch("ControlGroup"))
              unavailable!("stopped maintenance parent has writers") unless @cgroups.observe(pinned).fetch("populated").zero?
            end
          else
            exact = lineages.select { |lineage| lineage.binding.fetch("slice_invocation_id") == slice.fetch("InvocationID") }
            unavailable!("maintenance parent has no unique canonical released owner") unless exact.size == 1
            verify_closed!(exact.first)
          end
          unless @manager.inspect_activation == activation
            unavailable!("maintenance fixed activation changed during observation")
          end
          true
        ensure
          pinned&.fetch(:handle)&.close
        end

        def retire_released_parent!(lineages)
          verify_maintenance_closed!(lineages)
          @deployment.verify!(@mapping_id, kernel: @kernel, manager: @manager)
          activation = @manager.inspect_activation
          service = activation.fetch("service")
          unless %w[inactive failed].include?(service.fetch("ActiveState")) && service.fetch("Job") == [0, "/"] &&
              service.fetch("MainPID").zero? && service.fetch("ControlPID").zero?
            unavailable!("released parent retirement has a live or pending service")
          end
          slice = activation.fetch("slice")
          unless slice.fetch("Job") == [0, "/"]
            unavailable!("released parent retirement has a pending parent job")
          end
          if %w[inactive failed].include?(slice.fetch("ActiveState"))
            unless slice.fetch("InvocationID").empty? || lineages.any? { |lineage| lineage.binding.fetch("slice_invocation_id") == slice.fetch("InvocationID") }
              unavailable!("stopped parent metadata belongs to an unknown generation")
            end
            return {"state" => "already_retired"}
          end
          exact = lineages.select { |lineage| lineage.binding.fetch("slice_invocation_id") == slice.fetch("InvocationID") }
          unavailable!("active parent has no unique released canonical owner") unless exact.size == 1
          verify_closed!(exact.first)
          @manager.stop_slice
          after = @manager.inspect_activation
          unless %w[inactive failed].include?(after.fetch("slice").fetch("ActiveState")) &&
              after.fetch("slice").fetch("Job") == [0, "/"] && after.fetch("service") == service
            unavailable!("released parent retirement outcome is unavailable")
          end
          {"state" => "retired", "scope_binding_event_id" => exact.first.binding_event.fetch("digest")}
        end

        def closed_observation_for_proof!(lineage, events:)
          value = observe(lineage)
          service = value.fetch("activation").fetch("service")
          unless lineage.sealed? && value.fetch("populated").zero? && %w[inactive failed].include?(service.fetch("ActiveState")) &&
              service.fetch("MainPID").zero? && service.fetch("ControlPID").zero? && service.fetch("Job") == [0, "/"]
            unavailable!("sealed parent still has writers or pending activation")
          end
          native_cleanup_complete!
          # A stopped admitted-but-unbound start can have executed. Its proof
          # therefore uses the same positive writer baseline as a native bound
          # generation; absence of a binding is never a no-execution assertion.
          if lineage.native_event
            native = lineage.native_event.fetch("payload")
            invocation = service.fetch("InvocationID")
            unless invocation.empty? || invocation == native.fetch("service_invocation_id")
              unavailable!("closed native incarnation was replaced")
            end
            verify_resources!(native.fetch("resource_identities"), allow_runtime_absence: true, same_namespace: false)
          end
          current = parent_resources!
          unless current == lineage.binding.fetch("resource_identities") &&
              @files.namespace_identity == lineage.binding.fetch("resource_mount_namespace_identity")
            unavailable!("sealed parent resources or observation namespace changed")
          end
          @files.worker_uid_quiescent!(@map.fetch("worker_uid"))
          native_cleanup_complete!
          # Rejoin object and population after the credential baseline, keeping
          # the snapshot bounded by the same retained activation and exclusion.
          repeated = observe(lineage)
          unless repeated.fetch("populated").zero? && repeated.fetch("activation") == value.fetch("activation")
            unavailable!("sealed parent acquired a writer or pending activation during baseline observation")
          end
          lineage.binding.slice("scope_generation", "boot_id", "slice_invocation_id", "cgroup_identity").merge(
            "scope_binding_event_id" => lineage.binding_event.fetch("digest"), "seal_event_id" => lineage.seal_event.fetch("digest"), "populated" => 0)
        end

        # Declaration bytes are selected by this original observer's pinned
        # deployment digest. A workspace cannot inherit eligibility merely
        # because another parent resource has the same host pathname.
        def maintenance_workspace_resource!(lineage)
          manifest = @files.boundary_manifest(@scope)
          declarations = manifest.fetch("resources").select { |entry| entry.fetch("host_path") == @map.fetch("worker_cwd") }
          unless declarations.one? && declarations.first.values_at("stage", "worker_visible", "read_only") == ["parent", true, false]
            unavailable!("workspace original declaration is not a writable parent view")
          end
          declaration = declarations.first
          resources = lineage.binding.fetch("resource_identities").select do |entry|
            entry.values_at("host_path", "view_path") == declaration.values_at("host_path", "view_path")
          end
          unless resources.one? && %w[mount_id device inode].all? { |key| resources.first.fetch(key).is_a?(Integer) && resources.first.fetch(key).positive? }
            unavailable!("workspace original parent identity is unavailable")
          end
          resources.first
        rescue KeyError, TypeError, ArgumentError, Ace::Runtime::RuntimeUnavailableError
          unavailable!("workspace original boundary is unavailable")
        end

        def maintenance_parent_resource_declarations!(lineage)
          declarations = @files.boundary_manifest(@scope).fetch("resources").select { |entry| entry.fetch("stage") == "parent" }.map do |entry|
            entry.slice("host_path", "view_path", "stage", "worker_visible", "read_only")
          end
          identities = lineage.binding.fetch("resource_identities")
          selectors = declarations.map { |entry| entry.values_at("host_path", "view_path") }
          bound = identities.map { |entry| entry.values_at("host_path", "view_path") }
          unless selectors.uniq == selectors && bound.uniq == bound && selectors.sort == bound.sort &&
              declarations.all? { |entry| entry.keys.sort == %w[host_path read_only stage view_path worker_visible] } &&
              identities.all? { |entry| entry.keys.sort == Molecules::ExecutionScopeLineage::RESOURCE_FIELDS.sort }
            unavailable!("original parent declarations differ from bound identities")
          end
          declarations
        rescue KeyError, TypeError, ArgumentError, Ace::Runtime::RuntimeUnavailableError
          unavailable!("original parent resource declarations are unavailable")
        end

        private

        def boot_baseline!(binding)
          @boot_evidence.verify!(selection: binding.fetch("boot_baseline_selection"), expected:
            boot_baseline_expected(binding.fetch("boot_id"), binding.fetch("deployment_digest"),
              binding.fetch("network_installation_selection")))
        end

        def boot_baseline_expected(boot, digest, selection)
          {"slot_id" => @scope.fetch("slot_id"), "boot_id" => boot, "deployment_digest" => digest,
            "installer_artifact" => selection.fetch("installer_artifact")}
        end

        # Inventory only: no configurable security booleans or alternative
        # policy backend. Native-only objects are observed at their later stage.
        def native_cleanup_complete!
          @files.boundary_manifest(@scope).fetch("resources").each do |entry|
            next unless entry.fetch("stage") == "native"
            if @files.resource_present?(entry.fetch("host_path"))
              unavailable!("fixed service cleanup retained a service-created resource")
            end
          end
          true
        end

        def network_selection!
          manifest = @files.boundary_manifest(@scope)
          @network_selection.select!(static_selection: manifest.fetch("network_installation"), slot_id: @scope.fetch("slot_id"))
        end

        def parent_resources!
          manifest = @files.boundary_manifest(@scope)
          unless manifest.is_a?(Hash) && manifest.keys.sort == %w[network_installation resources schema slot_id] &&
              manifest["schema"] == BOUNDARY_SCHEMA && manifest["slot_id"] == @scope.fetch("slot_id") &&
              manifest["resources"].is_a?(Array) && manifest["resources"].size.between?(1, 64)
            unavailable!("fixed boundary resource inventory differs")
          end
          pairs = []
          resources = manifest.fetch("resources").filter_map do |resource|
            unless resource.is_a?(Hash) && resource.keys.sort == %w[host_path read_only stage view_path worker_visible] &&
                [true, false].include?(resource["worker_visible"]) && [true, false].include?(resource["read_only"]) &&
                (resource["worker_visible"] || resource["stage"] == "parent" && resource["read_only"]) &&
                (resource["stage"] != "native" || resource["worker_visible"]) && %w[parent native].include?(resource["stage"])
              unavailable!("boundary resource inventory is not closed")
            end
            paths = resource.values_at("host_path", "view_path")
            unless paths.all? { |path| path.is_a?(String) && path.bytesize.between?(1, 4096) && path.start_with?("/") &&
                !path.include?("\0") && File.expand_path(path) == path } && !pairs.include?(paths)
              unavailable!("boundary resource paths are substituted or repeated")
            end
            pairs << paths
            next if resource.fetch("stage") == "native"
            actual = @files.resource_identity(resource.fetch("host_path"))
            unless LOCAL_FILESYSTEMS.include?(actual.fetch("filesystem_type"))
              unavailable!("parent resource backing is not local kernel-managed storage")
            end
            resource.slice("host_path", "view_path").merge(actual)
          end
          unavailable!("parent resource inventory is empty") if resources.empty?
          verify_parent_access_boundary!(resources)
          resources
        end

        def verify_parent_access_boundary!(resources)
          worker = @map.fetch("worker_uid")
          authority = @deployment.authority(@map.fetch("authority_id")).fetch("uid")
          readers = @deployment.project(@map.fetch("project_id")).fetch("supervisor_uids")
          trusted = [worker, authority, @map.fetch("launcher_uid"), *readers].uniq
          policies = resources.to_h do |resource|
            path = resource.fetch("host_path")
            policy = @files.resource_boundary_policy(path)
            unless %w[device inode uid gid].all? { |key| policy.fetch(key) == resource.fetch(key) }
              unavailable!("parent access policy belongs to a replaced object")
            end
            [path, policy]
          end
          barriers = policies.select do |_path, policy|
            next false unless policy.fetch("uid").zero? && (policy.fetch("mode") & 0o7022).zero?
            acl = policy.fetch("acl")
            if acl.nil?
              next (policy.fetch("mode") & 0o077).zero?
            end
            acl.all? do |tag, permissions, uid|
              case tag
              when 1 then permissions == 7
              when 2 then trusted.include?(uid) && (permissions & 2).zero?
              when 4, 8, 32 then permissions.zero?
              when 16 then (permissions & 2).zero?
              else false
              end
            end
          end
          unless resources.any? { |resource| resource.fetch("uid") == worker } && resources.all? { |resource|
              path = resource.fetch("host_path")
              [0, worker].include?(resource.fetch("uid")) && barriers.keys.any? { |ancestor| path == ancestor || path.start_with?(ancestor + "/") } }
            unavailable!("parent roots lack an immutable exclusive host traversal boundary")
          end
          resources.each do |resource|
            aliases = @files.resource_aliases(resource.fetch("host_path"), identity: resource)
            unless aliases.all? { |path| barriers.keys.any? { |ancestor| path == ancestor || path.start_with?(ancestor + "/") } }
              unavailable!("protected parent backing is exposed through an outside writable mount")
            end
          end
        end

        def verify_parent!(binding, slice)
          expected = binding.fetch("cgroup_identity").fetch("path").delete_prefix(Ace::Runtime::Molecules::CgroupObservation::ROOT)
          unless slice.fetch("Id") == @scope.fetch("slice_unit") && slice.fetch("ActiveState") == "active" && slice.fetch("SubState") == "active" &&
              slice.fetch("InvocationID") == binding.fetch("slice_invocation_id") && slice.fetch("ControlGroup") == expected &&
              slice.fetch("Job") == [0, "/"]
            unavailable!("retained exact parent slice changed")
          end
        end

        def verify_resources!(resources, allow_runtime_absence: false, same_namespace: true)
          resources.each do |resource|
            path = resource.fetch("host_path")
            begin
              actual = @files.resource_identity(path)
            rescue Errno::ENOENT
              runtime = @scope.fetch("runtime_directory")
              # Fixed stopped RuntimeDirectoryPreserve=no cleanup may remove
              # native-stage descendants. Absence never supplies the proof:
              # parent identity/population and settled activation did above.
              next if allow_runtime_absence && (path == runtime || path.start_with?(runtime + "/"))
              raise
            end
            unless LOCAL_FILESYSTEMS.include?(actual.fetch("filesystem_type")) &&
                (%w[device inode uid gid filesystem_type] + (same_namespace ? ["mount_id"] : [])).all? { |key| actual.fetch(key) == resource.fetch(key) }
              unavailable!("retained resource backing object changed")
            end
          end
        end

        def canonical(value)
          case value
          when Hash then value.sort.to_h.transform_values { |item| canonical(item) }
          when Array then value.map { |item| canonical(item) }
          else value
          end
        end

        def unavailable!(message)
          raise Ace::Runtime::RuntimeUnavailableError, message
        end
      end
    end
  end
end
