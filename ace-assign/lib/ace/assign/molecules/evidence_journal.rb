# frozen_string_literal: true

require "fileutils"
require "json"
require "open3"

module Ace
  module Assign
    module Molecules
      # Append-only execution evidence journal backed by a dedicated Git ref.
      #
      # Accepted evidence for assignment attempts is committed to a separate
      # configured evidence ref (default `refs/ace/execution`) in canonical,
      # non-secret paths `execution/<assignment-id>/events/`. The ref lives
      # outside the deliverable candidate branch: appending evidence never
      # advances or changes the reviewed candidate. Working state uses an
      # isolated, disposable detached worktree under the configured checkout
      # root.
      #
      # Concurrency: all ref updates serialize on a checkout-root flock, and
      # every update is additionally guarded by an expected-old-value
      # `git update-ref` compare-and-swap. On a CAS conflict the journal
      # reloads the authoritative ref and replays only still-valid,
      # non-duplicate events.
      class EvidenceJournal
        CAS_ATTEMPTS = 3

        # @param repo_root [String] Git repository root holding the evidence ref
        # @param ref [String, nil] Evidence ref (default from config)
        # @param checkout_root [String, nil] Isolated checkout root (default from config)
        def initialize(repo_root:, ref: nil, checkout_root: nil)
          @repo_root = repo_root
          @ref = ref || default_config("evidence_git_ref") || "refs/ace/execution"
          root = checkout_root || default_config("evidence_checkout_root") || ".ace-local/assign/evidence-checkout"
          @checkout_root = Pathname.new(root).absolute? ? root : File.join(repo_root, root)
        end

        attr_reader :repo_root, :ref, :checkout_root

        # @return [Boolean] True when the repo can hold the evidence ref
        def available?
          git_ok?("rev-parse", "--git-dir")
        end

        # Current value of the evidence ref.
        #
        # @return [String, nil] Commit SHA or nil when the ref does not exist
        def ref_value
          out, stderr, status = git("rev-parse", "--verify", "--quiet", @ref)
          return out if status.success?

          raise AttemptErrors::EvidenceUnavailable, "Cannot read evidence ref #{@ref}: #{stderr}" if git_broken?(stderr)

          nil
        end

        # Append accepted events to the journal under lock + CAS.
        #
        # @param assignment_id [String] Assignment ID (journal path segment)
        # @param attempt_id [String] Attempt ID (commit message + dedupe scope)
        # @param events [Array<Hash>] Event payloads from Models::EvidenceEvent.build
        # @return [String] Journal commit SHA after the append
        # @raise [AttemptErrors::EvidenceUnavailable] when the ref stays conflicting
        def append(assignment_id:, attempt_id:, events:)
          return ref_value if events.empty?

          with_lock do
            CAS_ATTEMPTS.times do
              # Re-read the authoritative value every attempt. nil means the
              # ref does not exist yet; ensure_checkout! seeds it, so re-read
              # before computing the compare-and-swap baseline.
              old = ref_value
              ensure_checkout!
              old = ref_value if old.nil?
              sync_checkout(old)
              written = write_event_files(assignment_id, events)
              new_commit = written.zero? ? old : commit_events(assignment_id, attempt_id, events)
              return new_commit if update_ref_cas(new_commit, old)

              # CAS conflict: another writer advanced the ref. The next pass
              # resets the checkout to the authoritative tree and replays
              # only the events that are still missing (duplicates skipped).
            end

            raise AttemptErrors::EvidenceUnavailable,
              "Evidence ref #{@ref} stayed conflicting after #{CAS_ATTEMPTS} compare-and-swap attempts"
          end
        end

        # Read all journal events recorded for an assignment, ordered by the
        # digest chain (never by filename: same-second events sort
        # alphabetically, which can invert lifecycle order).
        #
        # @param assignment_id [String] Assignment ID
        # @return [Array<Hash>] Parsed events in journal order
        def read_events(assignment_id)
          value = ref_value
          return [] if value.nil?

          paths, stderr, status = git("ls-tree", "-r", "--name-only", value, "--",
            "execution/#{assignment_id}/events/")
          raise AttemptErrors::EvidenceUnavailable, "Cannot read journal events: #{stderr}" unless status.success?
          events = paths.lines.map(&:strip).select { |path| path.end_with?(".json") }.map do |path|
            content, error, read_status = git("show", "#{value}:#{path}")
            raise AttemptErrors::EvidenceUnavailable, "Cannot read journal event: #{error}" unless read_status.success?
            JSON.parse(content)
          end
          order_by_chain(events)
        rescue JSON::ParserError => e
          raise AttemptErrors::EvidenceUnavailable, "Corrupt journal event for #{assignment_id}: #{e.message}"
        end

        # Accepted receipt payloads recorded for an assignment.
        #
        # @param assignment_id [String] Assignment ID
        # @return [Array<Hash>] Accepted receipt payloads (digest included)
        def accepted_receipts(assignment_id)
          read_events(assignment_id)
            .select { |event| event["type"] == "receipt_accepted" }
            .map { |event| event.dig("payload", "receipt") }
            .compact
        end

        # All attempts derivable from the journal, reconstructed from intent
        # and process_start facts with journal-authoritative state. The
        # journal is the owner of attempt-state interpretation.
        #
        # @param assignment_id [String] Assignment ID
        # @return [Array<Models::Attempt>] Derived attempts
        def derived_attempts(assignment_id)
          events = read_events(assignment_id)
          by_attempt = events.group_by { |event| event["attempt_id"] }
          by_attempt.delete(nil)

          by_attempt.filter_map do |attempt_id, attempt_events|
            intent = attempt_events.find { |event| event["type"] == "intent" }
            next unless intent

            state = derive_state(attempt_events)
            next if state.nil?

            build_attempt(assignment_id, attempt_id, intent["payload"], attempt_events, state)
          end
        end

        # Non-terminal attempts derived from the journal.
        #
        # @param assignment_id [String] Assignment ID
        # @return [Array<Models::Attempt>] Active attempts
        def active_attempts(assignment_id)
          derived_attempts(assignment_id).reject(&:terminal?)
        end

        # Assignment IDs present in the journal, discovered from the evidence
        # ref itself (works even when the local assignment cache is gone).
        #
        # @return [Array<String>] Assignment IDs with journal evidence
        def assignment_ids
          value = ref_value
          return [] if value.nil?

          paths, stderr, status = git("ls-tree", "--name-only", "#{value}:execution")
          raise AttemptErrors::EvidenceUnavailable, "Cannot discover journal assignments: #{stderr}" unless status.success?
          paths.lines.map(&:strip).sort

        end

        private

        # Latest lifecycle state implied by the events, or nil when the
        # events do not describe a full attempt (intent missing).
        def derive_state(events)
          return nil unless events.any? { |event| event["type"] == "intent" }

          state = "running"
          events.each do |event|
            case event["type"]
            when "receipt_accepted"
              state = event.dig("payload", "receipt", "verdict") || state
            when "transition"
              state = event.dig("payload", "to") || state
            when "reconciliation"
              state = event.dig("payload", "resolution") || state
            end
          end
          state
        end

        def build_attempt(assignment_id, attempt_id, intent_payload, events, state)
          process_start = events.reverse.find do |event|
            event["type"] == "process_start" && event["attempt_id"] == attempt_id
          end
          candidate_head = events.select { |event| event["type"] == "receipt_accepted" }
            .map { |event| event.dig("payload", "receipt", "head") }
            .compact
            .first
          binding = Models::AttemptBinding.new(
            attempt_id: attempt_id,
            assignment_id: assignment_id,
            scope: intent_payload["scope"],
            project_id: intent_payload["project_id"],
            task_id: intent_payload["task_id"],
            actor: process_start&.dig("payload", "actor") || "recovered",
            role: process_start&.dig("payload", "role") || "coordinator",
            runtime: process_start&.dig("payload", "runtime") || "recovered",
            base_head: intent_payload["base_head"],
            evidence_git_ref: ref,
            created_at: parse_event_time(intent_time(events, attempt_id))
          )
          Models::Attempt.new(
            binding: binding,
            state: state,
            candidate_head: candidate_head,
            journal_commit: ref_value
          )
        end

        def intent_time(events, attempt_id)
          intent = events.find { |event| event["type"] == "intent" && event["attempt_id"] == attempt_id }
          intent&.dig("recorded_at")
        end

        def parse_event_time(value)
          return Time.now.utc if value.nil?

          require "time"
          Time.parse(value)
        rescue ArgumentError
          Time.now.utc
        end

        private

        def event_files(assignment_id)
          Dir.glob(File.join(checkout_dir, "execution", assignment_id, "events", "*.json")).sort
        end

        # Order events by following previous_digest links from chain roots;
        # orphaned events (unknown predecessor) keep filename order after the
        # resolved chains.
        def order_by_chain(events)
          by_digest = {}
          events.each { |event| by_digest[event["digest"]] = event }

          next_of = {}
          events.each do |event|
            previous = event["previous_digest"]
            next_of[previous] = event if previous && by_digest.key?(previous)
          end

          roots = events.reject do |event|
            previous = event["previous_digest"]
            previous && by_digest.key?(previous)
          end

          ordered = []
          visited = {}
          roots.each do |root|
            cursor = root
            while cursor && !visited[cursor["digest"]]
              visited[cursor["digest"]] = true
              ordered << cursor
              cursor = next_of[cursor["digest"]]
            end
          end

          ordered + events.reject { |event| visited[event["digest"]] }
        end

        def event_filename(event)
          "#{event["recorded_at"].to_s.tr("-:T Z", "")}-#{event["type"]}-#{event["digest"][0, 12]}.json"
        end

        def write_event_files(assignment_id, events)
          written = 0
          events.each do |event|
            path = File.join(checkout_dir, "execution", assignment_id, "events", event_filename(event))
            next if File.exist?(path)

            FileUtils.mkdir_p(File.dirname(path))
            File.write(path, JSON.pretty_generate(event))
            written += 1
          end
          written
        end

        def commit_events(assignment_id, attempt_id, events)
          types = events.map { |event| event["type"] }.uniq.join(",")
          git!("-C", checkout_dir, "add", "-A", "execution/#{assignment_id}")
          git!(
            "-C", checkout_dir,
            "-c", "user.name=ace-assign", "-c", "user.email=ace-assign@localhost",
            "commit", "-m", "evidence: #{assignment_id} #{attempt_id} (#{types})"
          )
          git!("-C", checkout_dir, "rev-parse", "HEAD").first
        end

        # Expected-old-value compare-and-swap; returns false on conflict.
        # A nil expectation is the create case: the ref must not exist.
        def update_ref_cas(new_commit, expected_old)
          return true if !expected_old.nil? && new_commit == expected_old

          expected = expected_old || ("0" * 40)
          _out, stderr, status = git("update-ref", @ref, new_commit, expected)
          return true if status.success?

          raise AttemptErrors::EvidenceUnavailable, "Cannot update evidence ref #{@ref}: #{stderr}" if git_broken?(stderr)

          false
        end

        def checkout_dir
          File.join(@checkout_root, "journal")
        end

        def lock_path
          File.join(@checkout_root, ".evidence.lock")
        end

        def with_lock
          FileUtils.mkdir_p(@checkout_root)
          File.open(lock_path, File::RDWR | File::CREAT) do |lock|
            lock.flock(File::LOCK_EX)
            begin
              yield
            ensure
              lock.flock(File::LOCK_UN)
            end
          end
        end

        def ensure_checkout!
          return if detached_worktree_at?(checkout_dir)

          FileUtils.rm_rf(checkout_dir)
          git!("worktree", "prune")
          value = ref_value
          if value.nil?
            seed_ref
            value = ref_value
          end
          git!("worktree", "add", "--detach", checkout_dir, value)
        end

        # Seed the evidence ref with an empty-tree commit so a worktree can
        # attach before any real evidence exists. The create is a
        # compare-and-swap against the zero SHA: a writer that loses the
        # race keeps the winner's ref instead of resetting it.
        def seed_ref
          empty_tree = git!("mktree").first
          seed = git!("-c", "user.name=ace-assign", "-c", "user.email=ace-assign@localhost",
            "commit-tree", empty_tree, "-m", "seed: ace-assign execution evidence").first
          _out, stderr, status = git("update-ref", @ref, seed, "0" * 40)
          return if status.success?

          raise AttemptErrors::EvidenceUnavailable, "Cannot seed evidence ref #{@ref}: #{stderr}" if git_broken?(stderr)
        end

        def detached_worktree_at?(path)
          dot_git = File.join(path, ".git")
          return false unless File.exist?(dot_git)

          out, _s = git("-C", path, "rev-parse", "--abbrev-ref", "HEAD")
          out.to_s.strip == "HEAD"
        end

        # Sync the disposable checkout to an authoritative ref value.
        def sync_checkout(target)
          return if target.nil?

          git!("-C", checkout_dir, "reset", "--hard", target)
        rescue AttemptErrors::EvidenceUnavailable
          # Stale, broken, or unregistered worktree: rebuild from scratch.
          FileUtils.rm_rf(checkout_dir)
          git!("worktree", "prune")
          git!("worktree", "add", "--detach", checkout_dir, target)
        end

        def git(*argv)
          unless File.directory?(@repo_root)
            return ["", "repository root missing: #{@repo_root}", FAILED_RESULT]
          end

          out, stderr, status = Open3.capture3("git", *argv, chdir: @repo_root, stdin_data: "")
          [out.to_s.strip, stderr.to_s.strip, status]
        end

        def git!(*argv)
          out, stderr, status = git(*argv)
          unless status.success?
            raise AttemptErrors::EvidenceUnavailable, "git #{argv.join(' ')} failed: #{stderr}"
          end

          [out, stderr, status]
        end

        def git_ok?(*argv)
          git(*argv)[2].success?
        end

        # Distinguish "ref missing" (normal, quiet, no stderr) and expected
        # compare-and-swap conflicts (retryable) from a broken repository or
        # ref store.
        def git_broken?(stderr)
          message = stderr.to_s.strip
          return false if message.empty?
          return false if message.include?("unknown revision") || message.include?("not a valid ref")
          return false if message.include?("cannot lock ref") || message.include?("but expected")

          true
        end

        # Stand-in status for commands that cannot run at all.
        FailedResult = Struct.new(:success?)
        FAILED_RESULT = FailedResult.new(false).freeze

        def default_config(key)
          section = Ace::Assign.config["attempt"]
          section && section[key]
        end
      end
    end
  end
end
