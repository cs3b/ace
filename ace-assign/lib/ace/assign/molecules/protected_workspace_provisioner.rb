# frozen_string_literal: true

require_relative "protected_workspace_exclusion"

module Ace
  module Assign
    module Molecules
      class LifecycleExclusion
        # Original full-privilege operator phase, before publication/start.
        # It only provisions derived exclusion artifacts, never a workspace.
        class WorkspaceProvisioner
          class Protection < WorkspaceHostReader::Protection
            private
            def root_path(_root) = nil
          end

          def initialize(mapping_id:, project_id:, authority:, cwd_resource:, files: File, directories: Dir, protection: nil)
            @selection = LifecycleExclusion.workspace_selection(mapping_id: mapping_id, project_id: project_id,
              authority: authority, cwd_resource: cwd_resource)
            @authority = authority.slice("state_root", "uid", "gid").freeze
            @files, @directories = files, directories
            @protection = protection || Protection.new(projection: {"authority_uid" => authority.fetch("uid"),
              "authority_gid" => authority.fetch("gid"), "root_resource" => {}})
            @handles = {}
          end

          def provision!
            root = @authority.fetch("state_root")
            parts = root.split("/").reject(&:empty?)
            (["/"] + parts.each_index.map { |index| "/" + parts.take(index + 1).join("/") }).each do |path|
              hold_directory!(path)
            end
            selected_directory!(@handles.fetch(root), mode: 0o700)
            relative = @selection.fetch("host_path").delete_prefix(root + "/").split("/")
            parent = root
            relative.each_with_index do |part, index|
              path = File.join(parent, part)
              mode = index == relative.length - 1 ? 0o755 : 0o700
              created = begin
                @directories.mkdir(path, 0o700)
                true
              rescue Errno::EEXIST
                false
              end
              handle = hold_directory!(path)
              if created
                handle.chown(@authority.fetch("uid"), @authority.fetch("gid"))
                handle.chmod(mode)
                handle.fsync
                @handles.fetch(parent).fsync
              end
              selected_directory!(handle, mode: mode)
              verify_unchanged!
              parent = path
            end
            root_stat = @handles.fetch(@selection.fetch("host_path")).stat
            host_identity = {"device" => root_stat.dev, "inode" => root_stat.ino,
              "uid" => root_stat.uid, "gid" => root_stat.gid}.freeze
            # Resource mount identity is observed by the existing boundary owner;
            # provision returns only association/host inode, not a namespace pin.
            provision_file!("lock", "")
            marker = provision_file!("state.json", LifecycleExclusion.workspace_initial_marker(key: @selection.fetch("key")))
            bytes = marker.read(8193)
            state = LifecycleExclusion.workspace_marker!(bytes: bytes, key: @selection.fetch("key"))
            raise AttemptErrors::Conflict, "Original lifecycle workspace is already fenced" if state.fetch("removed")
            unless [marker.stat.uid, marker.stat.gid] == @authority.values_at("uid", "gid")
              raise AttemptErrors::EvidenceUnavailable, "Initial lifecycle marker owner differs"
            end
            verify_unchanged!
            result = @selection.merge("host_identity" => host_identity)
            result.fetch("host_identity").freeze
            result.each_value(&:freeze)
            result.freeze
          rescue Ace::Runtime::RuntimeUnavailableError, SystemCallError, IOError
            raise AttemptErrors::EvidenceUnavailable, "Original lifecycle provisioning is unavailable"
          ensure
            close!
          end

          private

          def hold_directory!(path)
            handle = @files.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
            unless handle.stat.directory? && identity(handle.stat) == identity(@files.lstat(path))
              raise AttemptErrors::EvidenceUnavailable, "Lifecycle provisioning directory differs"
            end
            @protection.verify!(path, handle, directory: true)
            @handles[path] = handle
          ensure
            handle&.close unless @handles[path] == handle
          end

          def selected_directory!(handle, mode:)
            stat = handle.stat
            unless [stat.uid, stat.gid, stat.mode & 0o7777] == @authority.values_at("uid", "gid") + [mode]
              raise AttemptErrors::EvidenceUnavailable, "Lifecycle provisioning selected directory differs"
            end
          end

          def provision_file!(suffix, bytes)
            root = @selection.fetch("host_path")
            path = File.join(root, "#{Digest::SHA256.hexdigest(@selection.fetch('key'))}.#{suffix}")
            created = true
            handle = begin
              @files.open(path, File::RDWR | File::CREAT | File::EXCL | File::NOFOLLOW | File::NONBLOCK, 0o600)
            rescue Errno::EEXIST
              created = false
              @files.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK)
            end
            if created
              handle.write(bytes)
              handle.flush
              handle.chown(@authority.fetch("uid"), @authority.fetch("gid"))
              handle.chmod(0o644)
              handle.fsync
              @handles.fetch(root).fsync
            end
            stat = handle.stat
            unless stat.file? && stat.nlink == 1 && (stat.mode & 0o7777) == 0o644 &&
                identity(stat) == identity(@files.lstat(path)) && stat.size <= 8192 &&
                (suffix != "lock" || stat.size.zero? && [stat.uid, stat.gid] == @authority.values_at("uid", "gid"))
              raise AttemptErrors::EvidenceUnavailable, "Lifecycle provisioning file differs"
            end
            @protection.verify!(path, handle, directory: false)
            handle.rewind
            @handles[path] = handle
          ensure
            handle&.close unless @handles[path] == handle
          end

          def verify_unchanged!
            @handles.each do |path, handle|
              unless identity(handle.stat) == identity(@files.lstat(path))
                raise AttemptErrors::EvidenceUnavailable, "Lifecycle provisioned object was replaced"
              end
              @protection.verify!(path, handle, directory: handle.stat.directory?)
            end
          end

          def identity(stat) = [stat.dev, stat.ino, stat.uid, stat.gid, stat.mode]

          def close!
            error = nil
            @handles.values.reverse_each do |handle|
              begin
                handle.close unless handle.closed?
              rescue SystemCallError, IOError => caught
                error ||= caught
              end
            end
            @handles.clear
            raise error if error
          end
        end
      end
    end
  end
end
