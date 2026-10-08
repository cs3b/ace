# frozen_string_literal: true
require_relative "protected_workspace_fixture"
require "ace/assign/molecules/protected_control_exclusion"

module Ace
  module Assign
    module ProtectedControlFixture
      # Only installed UID/GID/filesystem/ACL observations are injected. Paths,
      # regular file descriptors, flock, fsync and replacement are real temporary OS IO.
      class Files
        attr_accessor :bad_marker_owner
        attr_reader :opened
        def initialize(state, uid: 13003, gid: 13003)
          @state, @uid, @gid, @opened = state, uid, gid, []
        end
        def owner(path)
          return [13004, 13004] if bad_marker_owner && path.end_with?(".state.json")
          path.start_with?(@state) ? [@uid, @gid] : [0, 0]
        end
        def open(path, flags, mode = nil)
          file = mode ? File.open(path, flags, mode) : File.open(path, flags)
          handle = Ace::Assign::ProtectedWorkspaceFixture::Handle.new(file, owner(path))
          @opened << handle
          return handle unless block_given?
          begin
            yield handle
          ensure
            handle.close
          end
        end
        def lstat(path) = Ace::Assign::ProtectedWorkspaceFixture::StatView.new(File.lstat(path), owner(path))
      end
      class Mounts
        def mount_identity(_handle) = {"filesystem_type" => "ext4"}
      end

      def self.factory
        lambda do |**options|
          authority = options.fetch(:authority)
          files = Files.new(authority.fetch("state_root"), uid: authority.fetch("uid"), gid: authority.fetch("gid"))
          protection = Molecules::LifecycleExclusion::ControlExclusion::Protection.new(
            authority_uid: authority.fetch("uid"), acl: ProtectedWorkspaceFixture::ACL.new, mounts: Mounts.new)
          Molecules::LifecycleExclusion.control_exclusion(**options, files: files, protection: protection)
        end
      end
    end
  end
end
