# frozen_string_literal: true
module Ace
  module Assign
    module ExecutionScopeObservationFixtures
      BOOT = "12345678-1234-1234-1234-123456789abc"
      NETWORK_SELECTION = %w[profile policy_export report installer_artifact].to_h { |key| [key, {"path" => "/etc/ace/network/#{key}", "sha256" => "c" * 64, "bytes" => 1}] }.freeze
      NETWORK_OUTPUT = {"report_id" => BOOT, "boot_id" => BOOT, "slot_id" => "slot", "namespace_path" => "/run/netns/slot",
        "namespace_identity" => {"device" => 7, "inode" => 88}, "profile_sha256" => "c" * 64,
        "policy_export_sha256" => "c" * 64, "report_sha256" => "c" * 64, "installer_artifact_sha256" => "c" * 64}.freeze
      class Files
        attr_accessor :native_resource, :native_present, :namespace, :resource, :manifest, :outside_alias, :outside_acl, :outside_worker, :network
        def initialize
          @network = {"device" => 7, "inode" => 88}
          @namespace = {"device" => 4, "inode" => 77}
          @resource = {"device" => 8, "inode" => 99, "uid" => 13001, "gid" => 13001, "filesystem_type" => "ext4", "mount_id" => 23}
          @manifest = {"schema" => Authority::ExecutionScopeObservation::BOUNDARY_SCHEMA, "slot_id" => "slot", "network_installation" => NETWORK_SELECTION, "resources" => [
            {"host_path" => "/private", "view_path" => "/host-private", "stage" => "parent", "worker_visible" => false, "read_only" => true},
            {"host_path" => "/private/scratch", "view_path" => "/scratch", "stage" => "parent", "worker_visible" => true, "read_only" => false},
            {"host_path" => "/run/slot/native", "view_path" => "/run/slot/native", "stage" => "native", "worker_visible" => true, "read_only" => false}]}
        end
        def boot_id; BOOT; end
        def namespace_identity; namespace.dup; end
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
