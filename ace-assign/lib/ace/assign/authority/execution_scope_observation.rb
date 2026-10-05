# frozen_string_literal: true

require "ace/runtime/molecules/cgroup_observation"
require "ace/runtime/molecules/systemd_scope_manager"
require "ace/runtime/molecules/linux_mount_info"
require "ace/runtime/molecules/execution_unit_installation"
require_relative "../molecules/execution_scope_lineage"
require_relative "posix_acl"
require "digest"
require "json"

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
            stat = File.stat("/proc/self/ns/mnt")
            {"device" => stat.dev, "inode" => stat.ino}
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

        def initialize(mapping_id:, deployment:, kernel:, manager: nil, cgroups: Ace::Runtime::Molecules::CgroupObservation.new, files: Files.new)
          @mapping_id, @deployment, @kernel, @cgroups, @files = mapping_id, deployment, kernel, cgroups, files
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
          context.merge("slot_id" => @scope.fetch("slot_id"), "deployment_digest" => Digest::SHA256.hexdigest(JSON.generate(canonical(@map))),
            "boot_id" => boot, "slice_invocation_id" => parent.fetch("InvocationID"), "cgroup_identity" => pinned.fetch(:identity),
            "resource_mount_namespace_identity" => namespace, "resource_identities" => inventory,
            "network_installation_selection" => selection, "network_namespace_identity" => network.fetch(:identity))
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
          if lineage.native_event
            native = lineage.native_event.fetch("payload")
            invocation = service.fetch("InvocationID")
            unless invocation.empty? || invocation == native.fetch("service_invocation_id")
              unavailable!("closed native incarnation was replaced")
            end
            verify_resources!(native.fetch("resource_identities"), allow_runtime_absence: true, same_namespace: false)
          end
          true
        end

        def native_admission_ready!(lineage)
          value = observe(lineage)
          service = value.fetch("activation").fetch("service")
          unless value.fetch("populated").zero? && %w[inactive failed].include?(service.fetch("ActiveState")) &&
              service.fetch("MainPID").zero? && service.fetch("ControlPID").zero? && service.fetch("Job") == [0, "/"]
            unavailable!("native admission has an occupied or pending generation")
          end
          # Effective firewall evidence cannot be obtained through this fixed
          # unprivileged owner. The reviewed evidence/lifetime contract is still
          # open: unit hashes and /proc routes must never substitute for it.
          unavailable!("required effective network boundary evidence is unavailable")
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

        def retire_released_parent!(lineages)
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
          admitted = events.any? { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "scope_service_admission" }
          if admitted && !lineage.native_event
            unavailable!("admitted native activation lacks verified writer-boundary evidence")
          end
          if admitted || lineage.native_event || lineage.child_event || events.any? { |event|
              %w[process_start service_claim service_transition inbox_binding].include?(event["type"]) ||
                event["type"] == "authority_mutation" && %w[record_launch bind_process release_launch].include?(event.dig("payload", "operation")) }
            unavailable!("post-native writer-boundary revalidation is unavailable")
          end
          # This bounded path proves a generation that never admitted native,
          # child or effect creation. It is not post-native readiness proof.
          current = parent_resources!
          unless current == lineage.binding.fetch("resource_identities") &&
              @files.namespace_identity == lineage.binding.fetch("resource_mount_namespace_identity")
            unavailable!("never-admitted parent resources or observation namespace changed")
          end
          @files.worker_uid_quiescent!(@map.fetch("worker_uid"))
          # Rejoin object and population after the credential baseline, keeping
          # the snapshot bounded by the same retained activation and exclusion.
          unless observe(lineage).fetch("populated").zero?
            unavailable!("never-admitted parent acquired a writer during baseline observation")
          end
          lineage.binding.slice("scope_generation", "boot_id", "slice_invocation_id", "cgroup_identity").merge(
            "scope_binding_event_id" => lineage.binding_event.fetch("digest"), "seal_event_id" => lineage.seal_event.fetch("digest"), "populated" => 0)
        end

        private

        # Inventory only: no configurable security booleans or alternative
        # policy backend. Native-only objects are observed at their later stage.
        def network_selection!
          manifest = @files.boundary_manifest(@scope)
          Molecules::ExecutionScopeLineage.validate_network_selection!(manifest.fetch("network_installation"))
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
            unless resource.is_a?(Hash) && resource.keys.sort == %w[host_path stage view_path] && %w[parent native].include?(resource["stage"])
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
