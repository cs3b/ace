# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "open3"
require "time"

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
        # @param repo_root [String, nil] Repository used to resolve the
        #   shared Git common dir (default: project root)
        # @param root [String, nil] Explicit exclusion root (tests)
        def initialize(repo_root: nil, root: nil)
          @root = root || self.class.default_root(repo_root)
        end

        # The exclusion root shared by every writer and prune for this repo.
        # Sandboxed environments (CACHE_BASE) scope it under the cache base,
        # which itself is never a deletion target; otherwise it lives under
        # the shared Git common dir, which survives worktree removal.
        def self.default_root(_repo_root = nil)
          cache_base = ENV["CACHE_BASE"]
          if cache_base && !cache_base.empty?
            return File.join(File.expand_path(cache_base), ".exclusion")
          end

          repo_root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          common_dir, _stderr, status = Open3.capture3(
            "git", "-C", repo_root, "rev-parse", "--path-format=absolute", "--git-common-dir"
          )
          base = status.success? && !common_dir.to_s.strip.empty? ? common_dir.strip : File.join(repo_root, ".git")
          File.join(base, "ace", "lifecycle-exclusion")
        end

        def assignment_key(assignment_id)
          "assignment:#{assignment_id}"
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
        def with_exclusive(key)
          raise ArgumentError, "exclusion key is required" if key.to_s.empty?

          lock = open_lock(key)
          lock.flock(File::LOCK_EX)
          begin
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

        # Record that the identity was removed. Call while holding the
        # exclusive side, BEFORE deleting the target.
        def record_removed!(key)
          atomic_write(
            state_path(key),
            JSON.generate({"removed" => true, "removed_at" => Time.now.utc.iso8601, "key" => key})
          )
        end

        def removed?(key)
          state = JSON.parse(File.read(state_path(key)))
          state["removed"] == true
        rescue Errno::ENOENT, JSON::ParserError, TypeError
          false
        end

        def clear_removed!(key)
          File.delete(state_path(key))
        rescue Errno::ENOENT
          nil
        end

        private

        attr_reader :root

        def open_lock(key)
          FileUtils.mkdir_p(root)
          File.open(lock_path(key), File::RDWR | File::CREAT)
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

        def atomic_write(path, content)
          dir = File.dirname(path)
          FileUtils.mkdir_p(dir)
          temp = File.join(dir, ".tmp-#{Process.pid}-#{rand(1_000_000)}")
          File.write(temp, content)
          File.rename(temp, path)
        ensure
          File.delete(temp) if temp && File.exist?(temp)
        end
      end
    end
  end
end
