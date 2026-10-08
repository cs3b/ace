# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "open3"
require "time"
require "securerandom"
require_relative "../atoms/evidence_digest"

module Ace
  module Assign
    module Molecules
      # Durable start/prune exclusion for assignment and worktree identities.
      #
      # Lock files live OUTSIDE every deletion target — under the shared Git
      # common dir — so they survive removal of the assignment cache, the
      # worktree, or a recreated lock pathname. Prune holds the exclusive
      # side from its final evidence reads through completion of removal;
      # every supported start path (attempt registration, fork/driver
      # session launch, worktree provisioning) holds the shared side while
      # registering a writer.
      #
      # A `removed` marker recorded by prune makes post-deletion starts fail
      # closed instead of recreating the deleted identity: acquiring the
      # shared side raises {AttemptErrors::Conflict} when the marker is
      # present. Legitimate fresh provisioning (a new worktree for a task)
      # clears the marker explicitly via `reset_removed`.
      class LifecycleExclusion
        autoload :ControlExclusion, File.expand_path("protected_control_exclusion", __dir__)

        def self.control_exclusion(authority:, project_id:, descriptor_sha256:, root_identity: nil, **boundaries)
          ControlExclusion.new(authority: authority, project_id: project_id,
            descriptor_sha256: descriptor_sha256, root_identity: root_identity, **boundaries)
        end

        autoload :WorkspaceReader, File.expand_path("protected_workspace_exclusion", __dir__)

        autoload :WorkspaceWriter, File.expand_path("protected_workspace_exclusion", __dir__)

        autoload :WorkspaceFenceReader, File.expand_path("protected_workspace_exclusion", __dir__)

        def self.workspace_fence_reader(projection:, protection: nil, files: File)
          WorkspaceFenceReader.new(projection: projection, protection: protection, files: files)
        end

        def self.workspace_writer(projection:, protection: nil, files: File)
          WorkspaceWriter.new(projection: projection, protection: protection, files: files)
        end

        autoload :WorkspaceProvisioner, File.expand_path("protected_workspace_provisioner", __dir__)

        def self.provision_workspace!(mapping_id:, project_id:, authority:, cwd_resource:, **boundaries)
          WorkspaceProvisioner.new(mapping_id: mapping_id, project_id: project_id,
            authority: authority, cwd_resource: cwd_resource, **boundaries).provision!
        end

        def self.workspace_reader(projection:, protection: nil, files: File)
          WorkspaceReader.new(projection: projection, protection: protection, files: files)
        end

        def self.workspace_selection(mapping_id:, project_id:, authority:, cwd_resource:)
          fields = %w[device filesystem_type gid host_path inode mount_id uid view_path]
          unless authority.is_a?(Hash) && cwd_resource.is_a?(Hash) && cwd_resource.keys.sort == fields &&
              %w[device gid inode uid].all? { |field| cwd_resource[field].is_a?(Integer) && cwd_resource[field] >= 0 } &&
              cwd_resource["mount_id"].is_a?(Integer) && cwd_resource["mount_id"].positive? &&
              %w[host_path view_path].all? { |field| cwd_resource[field].is_a?(String) &&
                cwd_resource[field].valid_encoding? && cwd_resource[field].bytesize.between?(1, 4096) &&
                !cwd_resource[field].include?("\0") && cwd_resource[field].start_with?("/") &&
                File.expand_path(cwd_resource[field]) == cwd_resource[field] } &&
              %w[ext4 xfs btrfs tmpfs].include?(cwd_resource["filesystem_type"]) &&
              [mapping_id, project_id].all? { |value| value.is_a?(String) && value.match?(/\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/) } &&
              %w[uid gid].all? { |field| authority[field].is_a?(Integer) && authority[field].positive? } &&
              authority["state_root"].is_a?(String) && authority["state_root"].valid_encoding? &&
              authority["state_root"].bytesize.between?(1, 4096) && !authority["state_root"].include?("\0") &&
              authority["state_root"].start_with?("/") &&
              File.expand_path(authority["state_root"]) == authority["state_root"]
            raise AttemptErrors::EvidenceUnavailable, "Original lifecycle workspace selection is malformed"
          end
          digest = Atoms::EvidenceDigest.digest(cwd_resource)
          selection = {"key" => "workspace:#{mapping_id}:#{digest}",
            "host_path" => File.join(authority.fetch("state_root"), "lifecycle-exclusion", project_id,
              "workspaces", mapping_id, digest), "view_path" => "/run/ace/lifecycle-exclusion/#{mapping_id}"}
          unless selection.fetch("host_path").bytesize <= 4096
            raise AttemptErrors::EvidenceUnavailable, "Original lifecycle workspace path is oversized"
          end
          selection.each_value(&:freeze)
          selection.freeze
        end

        def self.workspace_initial_marker(key:)
          unless key.is_a?(String) && key.match?(/\Aworkspace:[A-Za-z0-9][A-Za-z0-9._-]{0,127}:[0-9a-f]{64}\z/)
            raise AttemptErrors::EvidenceUnavailable, "Original lifecycle workspace key is malformed"
          end
          Atoms::EvidenceDigest.canonical_json({"key" => key, "removed" => false, "removed_at" => nil}).freeze
        end

        def self.workspace_marker!(bytes:, key:)
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, 8192)
            raise AttemptErrors::EvidenceUnavailable, "Lifecycle marker bytes differ"
          end
          bytes = bytes.dup.force_encoding(Encoding::UTF_8)
          unless bytes.valid_encoding?
            raise AttemptErrors::EvidenceUnavailable, "Lifecycle marker is not bounded UTF8"
          end
          state = JSON.parse(bytes, create_additions: false, max_nesting: 4, allow_duplicate_key: false)
          unless state.is_a?(Hash) && state.keys.sort == %w[key removed removed_at] && state.fetch("key") == key &&
              (state.values_at("removed", "removed_at") == [false, nil] || state["removed"] == true &&
                state["removed_at"].is_a?(String) && Time.iso8601(state["removed_at"]).utc.iso8601 == state["removed_at"])
            raise AttemptErrors::EvidenceUnavailable, "Lifecycle marker schema differs"
          end
          state.each_value { |value| value.freeze }
          state.freeze
        rescue JSON::ParserError, ArgumentError, KeyError
          raise AttemptErrors::EvidenceUnavailable, "Lifecycle marker schema differs"
        end

        # @param repo_root [String, nil] Repository used to resolve the
        #   shared Git common dir (default: project root)
        # @param root [String, nil] Explicit exclusion root (tests)
        def initialize(repo_root: nil, root: nil)
          @root = root || self.class.default_root(repo_root)
        end

        # The exclusion root shared by every writer and prune for this repo.
        # Assignment cache configuration does not select this repository
        # identity. The Git common dir survives linked worktree removal.
        def self.default_root(repo_root = nil)
          repo_root ||= Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          common_dir, _stderr, status = Open3.capture3(
            "git", "-C", repo_root, "rev-parse", "--path-format=absolute", "--git-common-dir"
          )
          unless status.success? && !common_dir.to_s.strip.empty? && File.absolute_path(common_dir.strip) == common_dir.strip
            raise AttemptErrors::Conflict, "Repository lifecycle root is unavailable"
          end
          File.join(common_dir.strip, "ace", "lifecycle-exclusion")
        end

        def assignment_key(assignment_id)
          "assignment:#{assignment_id}"
        end

        def slot_key(slot_id)
          "execution-slot:#{slot_id}"
        end

        # Task identity is the canonical worktree identity: work-on derives
        # the worktree path from the task ref, and prune candidates carry
        # the same task id.
        def task_key(task_id)
          "task:#{task_id}"
        end

        def worktree_key(worktree_path)
          canonical = begin
            File.realpath(worktree_path.to_s)
          rescue Errno::ENOENT, Errno::EACCES
            File.expand_path(worktree_path.to_s)
          end
          "worktree:#{canonical}"
        end

        # Hold the exclusive side while recomputing proofs and removing the
        # target. Start paths block for the whole block.
        #
        # @param key [String] Identity key
        # @yield Required block executed under exclusive exclusion
        def with_exclusive(key, deadline: nil)
          raise ArgumentError, "exclusion key is required" if key.to_s.empty?

          maintenance_deadline!(deadline) unless deadline.nil?
          lock = open_lock(key, nonblock: !deadline.nil?)
          begin
            mode = File::LOCK_EX | (deadline ? File::LOCK_NB : 0)
            unless lock.flock(mode)
              raise AttemptErrors::MaintenanceBusy, "maintenance exclusion is busy"
            end
            maintenance_deadline!(deadline) unless deadline.nil?
            yield
          ensure
            lock.flock(File::LOCK_UN)
            lock.close
          end
        end

        # Hold the shared side while registering a writer or creating a
        # resource. Fails closed when the identity was pruned.
        #
        # @param key [String] Identity key
        # @param reset_removed [Boolean] Clear a stale removed marker instead
        #   of raising (legitimate fresh provisioning of the same pathname)
        def with_shared(key, reset_removed: false)
          raise ArgumentError, "exclusion key is required" if key.to_s.empty?

          lock = open_lock(key)
          lock.flock(File::LOCK_SH)
          begin
            if removed?(key)
              unless reset_removed
                raise AttemptErrors::Conflict, removed_message(key)
              end

              clear_removed!(key)
            end
            yield
          ensure
            lock.flock(File::LOCK_UN)
            lock.close
          end
        end

        # Hold the shared side on several identities at once (acquired in the
        # given order, released in reverse — callers must use one consistent
        # global order, task before assignment, to avoid deadlock). Fails
        # closed when any identity was pruned.
        def with_shared_multi(keys, reset_removed: false)
          ordered = Array(keys).compact.reject { |key| key.to_s.empty? }.uniq
          raise ArgumentError, "exclusion keys are required" if ordered.empty?

          locks = []
          begin
            ordered.each { |key| locks << open_lock(key) }
            locks.each { |lock| lock.flock(File::LOCK_SH) }
            ordered.each do |key|
              if removed?(key)
                unless reset_removed
                  raise AttemptErrors::Conflict, removed_message(key)
                end

                clear_removed!(key)
              end
            end
            yield
          ensure
            locks.reverse_each do |lock|
              lock.flock(File::LOCK_UN)
              lock.close
            end
          end
        end

        # Record that the identity was removed. Call while holding the
        # exclusive side, BEFORE deleting the target.
        def record_removed!(key)
          atomic_write(
            state_path(key),
            JSON.generate({"removed" => true, "removed_at" => Time.now.utc.iso8601, "key" => key})
          )
        end

        def removed?(key)
          path = state_path(key)
          opened = false
          File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) do |file|
            opened = true
            before = file.stat
            unless before.file? && before.nlink == 1 && before.size.between?(1, 8192) && (before.mode & 0022).zero?
              raise AttemptErrors::Conflict, "Lifecycle marker is unsafe"
            end
            content = file.read(8193).force_encoding(Encoding::UTF_8)
            unless content.valid_encoding? && content.bytesize == before.size && same_file?(before, file.stat) && same_file?(before, File.lstat(path))
              raise AttemptErrors::Conflict, "Lifecycle marker changed"
            end
            state = JSON.parse(content, create_additions: false, max_nesting: 4, allow_duplicate_key: false)
            unless state.is_a?(Hash) && state.keys.sort == %w[key removed removed_at] &&
                state["key"] == key && state["removed"] == true && state["removed_at"].is_a?(String)
              raise AttemptErrors::Conflict, "Lifecycle marker is malformed"
            end
            Time.iso8601(state.fetch("removed_at"))
            true
          end
        rescue Errno::ENOENT
          raise AttemptErrors::Conflict, "Lifecycle marker disappeared during read" if opened
          false
        rescue JSON::ParserError, ArgumentError, TypeError, SystemCallError, IOError
          raise AttemptErrors::Conflict, "Lifecycle marker is unavailable or malformed"
        end

        def clear_removed!(key)
          return unless removed?(key)
          File.delete(state_path(key))
          sync_directory(root)
        end

        private

        attr_reader :root

        def open_lock(key, nonblock: false)
          retained = false
          FileUtils.mkdir_p(root)
          flags = File::RDWR | File::CREAT | File::NONBLOCK | File::NOFOLLOW
          file = File.open(lock_path(key), flags, 0600)
          unless file.stat.file? && file.stat.nlink == 1 && (file.stat.mode & 0022).zero? &&
              same_file?(file.stat, File.lstat(lock_path(key)))
            raise AttemptErrors::MaintenanceBusy, "maintenance exclusion is not a regular file"
          end
          retained = true
          file
        rescue SystemCallError
          raise AttemptErrors::Conflict, "Lifecycle lock is unavailable"
        ensure
          file&.close unless retained
        end

        def maintenance_deadline!(deadline)
          unless (deadline.is_a?(Integer) || deadline.is_a?(Float)) && deadline.finite?
            raise ArgumentError, "maintenance deadline must be finite"
          end
          if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
            raise AttemptErrors::MaintenanceBusy, "maintenance admission deadline expired"
          end
        end

        def lock_path(key)
          File.join(root, "#{Digest::SHA256.hexdigest(key)}.lock")
        end

        def state_path(key)
          File.join(root, "#{Digest::SHA256.hexdigest(key)}.state.json")
        end

        def removed_message(key)
          identity = key.to_s.sub(/\A[^:]+:/, "")
          case key
          when /\Aassignment:/
            "Assignment #{identity} was pruned; refusing to start a writer on a removed identity"
          when /\Atask:/
            "Task #{identity} worktree was pruned; refusing to start a writer on a removed identity"
          else
            "Worktree #{identity} was pruned; refusing to start a writer on a removed identity"
          end
        end

        def same_file?(left, right)
          [left.dev, left.ino, left.size, left.mtime, left.ctime] == [right.dev, right.ino, right.size, right.mtime, right.ctime]
        end

        def sync_directory(path)
          File.open(path, File::RDONLY | File::NOFOLLOW | File::NONBLOCK) { |directory| directory.fsync }
        end

        def atomic_write(path, content)
          dir = File.dirname(path)
          FileUtils.mkdir_p(dir, mode: 0700)
          temp = File.join(dir, ".tmp-#{SecureRandom.hex(16)}")
          File.open(temp, File::WRONLY | File::CREAT | File::EXCL | File::NOFOLLOW | File::NONBLOCK, 0600) do |file|
            file.write(content)
            file.flush
            file.fsync
          end
          if File.exist?(path) || File.symlink?(path)
            removed?(JSON.parse(content).fetch("key"))
          end
          File.rename(temp, path)
          sync_directory(dir)
        ensure
          File.delete(temp) if temp && File.exist?(temp)
        end

      end
    end
  end
end
