# frozen_string_literal: true
require_relative "protected_workspace_fixture"
require "ace/assign/molecules/protected_control_exclusion"

module Ace
  module Assign
    module ProtectedControlFixture
      # Installed UID/GID/filesystem/ACL and namespace ancestor observations are injected.
      # Selected state files, descriptors, flock, fsync and replacement use real temporary IO.
      class Files
        attr_accessor :bad_marker_owner
        attr_reader :opened
        def initialize(state, uid: 13003, gid: 13003, ancestor_root: nil)
          @state, @uid, @gid, @opened, @ancestor_root = state, uid, gid, [], ancestor_root
        end
        def owner(path)
          return [13004, 13004] if bad_marker_owner && path.end_with?(".state.json")
          path.start_with?(@state) ? [@uid, @gid] : [0, 0]
        end
        def actual(path)
          @ancestor_root && path != @state && !path.start_with?(@state + "/") ? @ancestor_root : path
        end
        def open(path, flags, mode = nil)
          file = mode ? File.open(actual(path), flags, mode) : File.open(actual(path), flags)
          handle = Ace::Assign::ProtectedWorkspaceFixture::Handle.new(file, owner(path))
          @opened << handle
          return handle unless block_given?
          begin
            yield handle
          ensure
            handle.close
          end
        end
        def lstat(path) = Ace::Assign::ProtectedWorkspaceFixture::StatView.new(File.lstat(actual(path)), owner(path))
      end
      class Mounts
        def mount_identity(_handle) = {"filesystem_type" => "ext4"}
      end

      def self.prepare!(authority:, project_id:)
        root = File.join(authority.fetch("state_root"), "lifecycle-exclusion", project_id, "control")
        FileUtils.mkdir_p(root, mode: 0o700)
        File.chmod(0o700, authority.fetch("state_root"))
        root
      end

      def self.registration(deployment:, journal:, mapping_id:, assignment_id:, task_id:)
        map = deployment.mapping(mapping_id)
        authority = deployment.authority(map.fetch("authority_id"))
        prepare!(authority: authority, project_id: map.fetch("project_id"))
        owner = factory.call(authority: authority, project_id: map.fetch("project_id"),
          descriptor_sha256: deployment.artifact_reference.fetch("sha256"))
        selection = owner.selection!
        owner.provision_keys!(keys: [owner.task_key(task_id), owner.assignment_key(assignment_id)])
        {"assignment_id" => assignment_id, "project_id" => map.fetch("project_id"), "mapping_id" => mapping_id,
          "phase" => "registered", "task_id" => task_id, "lifecycle_control" => selection}
      end

      def self.factory
        lambda do |**options|
          authority = options.fetch(:authority)
          files = Files.new(authority.fetch("state_root"), uid: authority.fetch("uid"), gid: authority.fetch("gid"), ancestor_root: authority.fetch("state_root"))
          protection = Molecules::LifecycleExclusion::ControlExclusion::Protection.new(
            authority_uid: authority.fetch("uid"), acl: ProtectedWorkspaceFixture::ACL.new, mounts: Mounts.new)
          Molecules::LifecycleExclusion.control_exclusion(**options, files: files, protection: protection)
        end
      end
    end
  end
end
