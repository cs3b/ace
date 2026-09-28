# frozen_string_literal: true

require "fileutils"
require "json"

module Ace
  module Assign
    module Molecules
      # Durable local attempt state: the single authority for attempt records
      # and active subtree ownership.
      #
      # Layout under the assignment cache directory (`.ace-local/assign` by
      # default, which remains disposable session/projection data):
      # - `<assignment-id>/attempts/records/<attempt-id>.json` — full attempt
      #   record, written atomically (temp file + rename).
      # - `<assignment-id>/attempts/active/<ownership-key>.json` — pointer to
      #   the one active attempt owning an assignment + normalized subtree.
      # - `<assignment-id>/attempts/.lock` — flock serialization for
      #   claim/release and record transitions.
      #
      # Only one active attempt owns a subtree; claim replaces the pointer
      # only for the identical binding, and release clears it only when it
      # still references the given attempt.
      class AttemptStore
        # @param cache_base [String] Base cache directory
        def initialize(cache_base: nil)
          @cache_base = cache_base || Ace::Assign.cache_dir
        end

        # @param assignment_id [String] Assignment ID
        # @return [String] Attempts directory for the assignment
        def attempts_dir(assignment_id)
          File.join(@cache_base, assignment_id, "attempts")
        end

        # Serialize a block under the assignment's exclusive attempt lock.
        #
        # @param assignment_id [String] Assignment ID
        # @yield Block executed while holding the lock
        def with_lock(assignment_id)
          FileUtils.mkdir_p(attempts_dir(assignment_id))
          File.open(lock_path(assignment_id), File::RDWR | File::CREAT) do |lock|
            lock.flock(File::LOCK_EX)
            begin
              yield
            ensure
              lock.flock(File::LOCK_UN)
            end
          end
        end

        # Persist an attempt record atomically.
        #
        # @param attempt [Models::Attempt] Attempt to persist
        def save(attempt)
          FileUtils.mkdir_p(records_dir(attempt.binding.assignment_id))
          atomic_write(
            record_path(attempt.binding.assignment_id, attempt.attempt_id),
            JSON.pretty_generate(attempt.to_h)
          )
        end

        # Load an attempt record.
        #
        # @param assignment_id [String] Assignment ID
        # @param attempt_id [String] Attempt ID
        # @return [Models::Attempt, nil] Attempt or nil when absent/corrupt
        def load(assignment_id, attempt_id)
          path = record_path(assignment_id, attempt_id)
          return nil unless File.exist?(path)

          Models::Attempt.from_h(JSON.parse(File.read(path)))
        rescue JSON::ParserError, KeyError, ArgumentError, TypeError => e
          warn "ace-assign: corrupt attempt record #{path}: #{e.message}" if Ace::Assign.debug?
          nil
        end

        # The active attempt owning an assignment + scope, if any.
        #
        # @param assignment_id [String] Assignment ID
        # @param scope [String] Step/subtree scope
        # @return [Models::Attempt, nil] Active attempt or nil
        def active(assignment_id, scope)
          pointer = active_path(assignment_id, scope)
          return nil unless File.exist?(pointer)

          entry = JSON.parse(File.read(pointer))
          attempt = load(assignment_id, entry["attempt_id"])
          return nil unless attempt&.active?

          attempt
        rescue JSON::ParserError, TypeError
          nil
        end

        # Claim subtree ownership for an attempt. Callers must hold
        # {with_lock} for read-modify-write atomicity.
        #
        # @param assignment_id [String] Assignment ID
        # @param scope [String] Canonical scope
        # @param attempt [Models::Attempt] Active attempt claiming the scope
        def claim(assignment_id, scope, attempt)
          FileUtils.mkdir_p(active_dir(assignment_id))
          atomic_write(
            active_path(assignment_id, scope),
            JSON.generate({"attempt_id" => attempt.attempt_id})
          )
        end

        # Release subtree ownership when it still references the attempt.
        #
        # @param assignment_id [String] Assignment ID
        # @param scope [String] Canonical scope
        # @param attempt_id [String] Attempt releasing ownership
        def release(assignment_id, scope, attempt_id)
          pointer = active_path(assignment_id, scope)
          return unless File.exist?(pointer)

          entry = JSON.parse(File.read(pointer))
          File.delete(pointer) if entry["attempt_id"] == attempt_id
        rescue JSON::ParserError, TypeError
          nil
        end

        # Locate an attempt record by ID across all assignments (used by
        # reconcile, which receives only the attempt ID).
        #
        # @param attempt_id [String] Attempt ID
        # @return [Models::Attempt, nil] Attempt or nil
        def find(attempt_id)
          path = Dir.glob(File.join(@cache_base, "*", "attempts", "records", "#{attempt_id}.json")).first
          return nil unless path

          assignment_id = File.basename(File.dirname(File.dirname(File.dirname(path))))
          load(assignment_id, attempt_id)
        end

        # All attempt records for an assignment, newest first. Ties (records
        # serialized within the same second) break deterministically by
        # attempt ID.
        #
        # @param assignment_id [String] Assignment ID
        # @return [Array<Models::Attempt>] Persisted attempts
        def list(assignment_id)
          Dir.glob(File.join(records_dir(assignment_id), "*.json"))
            .map { |path| load(assignment_id, File.basename(path, ".json")) }
            .compact
            .sort_by { |attempt| [attempt.updated_at.utc, attempt.attempt_id] }
            .reverse
        end

        private

        def records_dir(assignment_id)
          File.join(attempts_dir(assignment_id), "records")
        end

        def active_dir(assignment_id)
          File.join(attempts_dir(assignment_id), "active")
        end

        def lock_path(assignment_id)
          File.join(attempts_dir(assignment_id), ".lock")
        end

        def record_path(assignment_id, attempt_id)
          File.join(records_dir(assignment_id), "#{attempt_id}.json")
        end

        def active_path(assignment_id, scope)
          File.join(active_dir(assignment_id), Atoms::AssignmentScope.ownership_key(assignment_id, scope))
        end

        # Atomic same-filesystem write: temp file plus rename.
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
