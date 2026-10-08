# frozen_string_literal: true
require_relative "protected_workspace_fixture"
require "ace/assign/authority/execution_scope_observation"

module Ace
  module Assign
    # Same maintained operator provisioning and original observer projection.
    # Installed namespace/ACL/filesystem observations remain controlled.
    module PreparedWorkspaceResourceFixture
      def configure_original_workspace_resource
        authority = @deployment.authority(@map.fetch("authority_id"))
        cwd = {"host_path" => @map.fetch("worker_cwd"), "view_path" => @map.fetch("worker_cwd"),
          "device" => 8, "inode" => 42, "mount_id" => 10, "filesystem_type" => "ext4", "uid" => 13001, "gid" => 13001}
        selection = Molecules::LifecycleExclusion.workspace_selection(mapping_id: "mapping", project_id: "project",
          authority: authority, cwd_resource: cwd)
        mounts = ProtectedWorkspaceFixture::Mounts.new(selection.fetch("view_path"), selection.fetch("host_path"))
        acl = ProtectedWorkspaceFixture::ACL.new
        protection = Molecules::LifecycleExclusion::WorkspaceProvisioner::Protection.new(
          projection: {"authority_uid" => authority.fetch("uid"), "authority_gid" => authority.fetch("gid"), "root_resource" => {}},
          mounts: mounts, acl: acl)
        association = Molecules::LifecycleExclusion.provision_workspace!(mapping_id: "mapping", project_id: "project",
          authority: authority, cwd_resource: cwd, protection: protection)
        root = selection.slice("host_path", "view_path").merge(association.fetch("host_identity"),
          "mount_id" => 10, "filesystem_type" => "ext4")
        @prepared_workspace_resources = [cwd, root]
        @prepared_workspace_declarations = [cwd.merge("stage" => "parent", "worker_visible" => true, "read_only" => false),
          root.merge("stage" => "parent", "worker_visible" => true, "read_only" => true)].map do |entry|
          entry.slice("host_path", "view_path", "stage", "worker_visible", "read_only")
        end
        declarations = @prepared_workspace_declarations
        files = Object.new
        files.define_singleton_method(:boundary_manifest) { |_scope| {"resources" => declarations} }
        @prepared_workspace_observer = Authority::ExecutionScopeObservation.new(mapping_id: "mapping", deployment: @deployment,
          kernel: @kernel, files: files, manager: Object.new)
      end

      def controlled_workspace_reader(projection)
        root = projection.fetch("root_resource")
        files = ProtectedWorkspaceFixture::Files.new(root.fetch("host_path"), root.fetch("view_path"))
        mounts = ProtectedWorkspaceFixture::Mounts.new(root.fetch("view_path"), root.fetch("host_path"))
        protection = Molecules::LifecycleExclusion::WorkspaceReader::Protection.new(projection: projection, mounts: mounts,
          acl: ProtectedWorkspaceFixture::ACL.new)
        Molecules::LifecycleExclusion.workspace_reader(projection: projection, protection: protection, files: files)
      end

    end
  end
end
