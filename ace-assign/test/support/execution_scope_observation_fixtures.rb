# frozen_string_literal: true
require "ace/runtime/molecules/kernel_view_topology"
module Ace
  module Assign
    module ExecutionScopeObservationFixtures
      BOOT = "12345678-1234-1234-1234-123456789abc"
      BOOT_BASELINE_SELECTION = {"path" => "/etc/ace/boot/original.json", "sha256" => "d" * 64, "bytes" => 1}.freeze
      def self.kernel_topology(resources: [], readonly_views: [])
        verifier = Ace::Runtime::Molecules::KernelViewTopology
        paths = ["/"] + verifier::VIEWS + ["/dev/pts/ptmx"] + resources.map { |entry| entry.fetch("view_path") }
        text = paths.each_with_index.map do |path, index|
          resource = resources.find { |entry| entry.fetch("view_path") == path }
          filesystem = path == "/dev/pts/ptmx" ? "devpts" : resource ? resource.fetch("filesystem_type") : verifier::APIS.fetch(path, path == "/dev" ? "tmpfs" : "ext4")
          flags = readonly_views.include?(path) ? "ro" : resource || verifier::APIS.key?(path) ? "rw" : "ro"
          root = path == "/dev/pts/ptmx" ? "/ptmx" : resource ? resource.fetch("host_path") : "/"
          "#{index + 1} 0 8:1 #{root} #{path} #{flags} - #{filesystem} fixture #{flags}\n"
        end.join
        mounts = Ace::Runtime::Molecules::LinuxMountInfo.new(text).records.map { |row| row.slice(*Ace::Runtime::Molecules::ServerResourceObservation::MOUNT_FIELDS) }
        views = verifier::VIEWS.map { |path| {"path" => path, "mount_id" => mounts.find { |row| row["mountpoint"] == path }.fetch("mount_id"),
          "device" => 8, "inode" => paths.index(path) + 100, "type" => "directory"} }
        {"ipc_namespace_identity" => {"device" => 4, "inode" => 20}, "hook_ipc_namespace_identity" => {"device" => 4, "inode" => 20},
          "mounts" => mounts, "views" => views, "authority_socket_identity" => [1, 2, 13000], "ptmx_link" => "pts/ptmx",
          "ptmx_identity" => {"device" => 8, "inode" => 500, "mount_id" => paths.index("/dev/pts/ptmx") + 1, "type" => "character", "rdev_major" => 5, "rdev_minor" => 2}}
      end
      DEVPTS_HOST = {"device" => 9, "inode" => 1, "major_minor" => "9:1"}.freeze
      DEVPTS_SELECTED = {"path" => "/run/ace/execution-slots/slot/devpts", "device" => 8, "inode" => 106, "major_minor" => "8:1", "ptmx_inode" => 500}.freeze
      def self.boot_baseline
        {"host_ipc_namespace_identity" => {"device" => 4, "inode" => 900}, "host_devpts_identity" => DEVPTS_HOST, "selected_devpts" => DEVPTS_SELECTED, "host_ptmx_link" => "pts/ptmx"}
      end
      class BootEvidence
        attr_accessor :unavailable, :selected
        attr_reader :selections, :verifications
        def initialize
          @selected, @selections, @verifications = BOOT_BASELINE_SELECTION, [], []
        end
        def select!(expected:)
          raise Ace::Runtime::RuntimeUnavailableError, "boot baseline unavailable" if unavailable
          @selections << expected
          {"selection" => selected, "baseline" => ExecutionScopeObservationFixtures.boot_baseline}
        end
        def verify!(selection:, expected:)
          raise Ace::Runtime::RuntimeUnavailableError, "original boot baseline unavailable" if unavailable || selection != BOOT_BASELINE_SELECTION
          @verifications << {"selection" => selection, "expected" => expected}
          ExecutionScopeObservationFixtures.boot_baseline
        end
      end
      NETWORK_SELECTION = %w[profile policy_export report installer_artifact].to_h { |key| [key, {"path" => "/etc/ace/network/#{key}", "sha256" => "c" * 64, "bytes" => 1}] }.freeze
      NETWORK_STATIC = NETWORK_SELECTION.slice("profile", "installer_artifact").merge("current_selection_path" => "/etc/ace/execution-slots/slot/network-installation-selection.json").freeze
      class NetworkSelection
        attr_accessor :selection
        def initialize; @selection = NETWORK_SELECTION; end
        def select!(static_selection:, slot_id:)
          Ace::Runtime::Molecules::ExecutionNetworkSelection.validate_static!(static_selection, slot_id: slot_id)
          selection
        end
      end
      NETWORK_OUTPUT = {"report_id" => BOOT, "boot_id" => BOOT, "slot_id" => "slot", "namespace_path" => "/run/netns/slot",
        "namespace_identity" => {"device" => 7, "inode" => 88}, "profile_sha256" => "c" * 64,
        "policy_export_sha256" => "c" * 64, "report_sha256" => "c" * 64, "installer_artifact_sha256" => "c" * 64}.freeze
      class Files
        attr_accessor :native_resource, :native_present, :namespace, :resource, :manifest, :outside_alias, :outside_acl, :outside_worker, :network
        def initialize
          @network = {"device" => 7, "inode" => 88}
          @namespace = {"device" => 4, "inode" => 77}
          @resource = {"device" => 8, "inode" => 99, "uid" => 13001, "gid" => 13001, "filesystem_type" => "ext4", "mount_id" => 23}
          @manifest = {"schema" => Authority::ExecutionScopeObservation::BOUNDARY_SCHEMA, "slot_id" => "slot", "network_installation" => NETWORK_STATIC, "resources" => [
            {"host_path" => "/private", "view_path" => "/host-private", "stage" => "parent", "worker_visible" => false, "read_only" => true},
            {"host_path" => "/private/scratch", "view_path" => "/scratch", "stage" => "parent", "worker_visible" => true, "read_only" => false},
            {"host_path" => "/run/slot/native", "view_path" => "/run/slot/native", "stage" => "native", "worker_visible" => true, "read_only" => false}]}
        end
        def boot_id; BOOT; end
        def namespace_identity; namespace.dup; end
        def authority_socket_identity(authority)
          raise "unexpected authority endpoint" unless authority.values_at("socket_path", "uid") == ["/run/authority/socket", 13000]
          [1, 2, 13000]
        end
        def pin_network_namespace(path)
          raise Ace::Runtime::RuntimeUnavailableError, "network namespace unavailable" unless path == "/run/netns/slot" && network
          {handle: Cgroups::Handle.new(false), identity: network.dup}
        end
        def resource_identity(path)
          return resource.merge("uid" => 0, "gid" => 0, "inode" => 98) if path == "/private"
          return native_resource.dup if path == "/run/slot/native" && native_resource
          raise Errno::ENOENT, "native object not created" if path == "/run/slot/native"
          raise "unknown backing resource" unless path == "/private/scratch"
          resource.dup
        end
        def resource_boundary_policy(path)
          identity = resource_identity(path)
          acl = path == "/private" ? [[1, 7, 0xffffffff], [2, 1, 13001], [2, 5, 13000], [2, 5, 13002],
            [4, 0, 0xffffffff], [16, 5, 0xffffffff], [32, outside_acl ? 1 : 0, 0xffffffff]] : nil
          identity.slice("device", "inode", "uid", "gid").merge("mode" => path == "/private" ? 0o750 : 0o700, "acl" => acl)
        end
        def resource_aliases(path, identity:); outside_alias ? [path, "/public/alias"] : [path]; end
        def worker_uid_quiescent!(_uid)
          raise Ace::Runtime::RuntimeUnavailableError, "outside UID writer" if outside_worker
          true
        end
        def resource_topology(path, mount_id:); {"major_minor" => "8:1", "filesystem_path" => path}; end
        def resource_present?(_path); !!native_present; end
        def boundary_manifest(_scope); manifest; end
      end
      class Manager
        attr_accessor :profile, :slice, :service, :lost_start
        attr_reader :starts, :service_starts, :slice_stops
        def initialize
          @starts, @service_starts, @slice_stops = 0, 0, 0
          @slice = {"Id" => "ace-slot.slice", "ActiveState" => "inactive", "SubState" => "dead", "InvocationID" => "", "ControlGroup" => "", "Job" => [0, "/"]}
          @service = {"Id" => "ace-slot.service", "ActiveState" => "inactive", "SubState" => "dead", "InvocationID" => "", "MainPID" => 0, "ControlPID" => 0, "Job" => [0, "/"]}
        end
        def inspect_profile; profile; end
        def inspect_activation; JSON.parse(JSON.generate("slice" => slice, "service" => service)); end
        def start_slice
          @starts += 1
          slice.merge!("ActiveState" => "active", "SubState" => "active", "InvocationID" => "b" * 32, "ControlGroup" => "/ace-slot.slice")
          raise Ace::Runtime::RuntimeUnavailableError, "job reply lost" if lost_start
        end
        def start_service; @service_starts += 1; end
        def stop_service; end
        def stop_slice; @slice_stops += 1; slice.merge!("ActiveState" => "inactive", "SubState" => "dead"); end
      end
      class Cgroups
        Handle = Struct.new(:closed) { def close; self.closed = true; end }
        attr_accessor :populated, :inode
        attr_reader :handles
        def initialize; @populated = 0; @inode = 66; @handles = []; end
        def pin(path, expected: nil)
          identity = {"path" => path, "mount_id" => 20, "filesystem_type" => "cgroup2", "device" => 5, "inode" => inode}
          raise Ace::Runtime::RuntimeUnavailableError, "parent replaced" unless expected.nil? || expected == identity
          handle = Handle.new(false)
          handles << handle
          {handle: handle, identity: identity}
        end
        def observe(_pinned); {"populated" => populated}; end
      end

    end
  end
end
