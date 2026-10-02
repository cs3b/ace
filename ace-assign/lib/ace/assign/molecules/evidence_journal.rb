# frozen_string_literal: true

require "digest"
require "digest"
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

        # Reserve a globally unique service request in the same evidence ref
        # as its owning attempt. The request index and attempt event are one
        # Git commit, so a ref race cannot admit two effects for one ID. An
        # exact authorization reference is consumed by its first live claim:
        # a second request presenting the same operation/project/target
        # authorization is rejected instead of dispatching a duplicate effect.
        # Dispatching callers claim directly as +uncertain+ so no commit
        # window exists where a stranded claim reads as accepted.
        def claim_service_request(binding, state: "accepted", guard: nil)
          guard ||= -> { authorization_conflict(binding) }
          update_service_request(binding.fetch("request_id"), expected: nil,
            replacement: binding.merge("state" => state, "claimed_at" => Time.now.utc.iso8601(9)),
            event_type: "service_claim", guard: guard)
        end

        # Reject a service request. A request not yet on file gets its
        # auditable rejection claim (which never consumed the authorization);
        # an existing live claim transitions to rejected but stays consuming:
        # only attributable evidence that the effect did not occur may free a
        # dispatched authorization, never a bare rejection.
        def reject_service_request(binding, reason:)
          request_id = binding.fetch("request_id")
          existing = service_request(request_id)
          if existing
            unless existing.except("state", "receipt", "reason", "claimed_at", "failed_at") == binding.except("state", "receipt", "reason", "claimed_at", "failed_at")
              raise AttemptErrors::Conflict, "Service request #{request_id} has different input"
            end
            return existing if existing["state"] == "rejected"
            return update_service_request(request_id, expected: existing,
              replacement: existing.merge("state" => "rejected", "reason" => reason),
              event_type: "service_transition")
          end
          update_service_request(request_id, expected: nil,
            replacement: binding.merge("state" => "rejected", "reason" => reason, "consumed" => false),
            event_type: "service_claim")
        end

        # Terminal writes are validated HERE at the journal boundary —
        # receipt schema, binding against the current record, and attested
        # outcome — so no caller-supplied flag decides trust. The
        # coordinator additionally performs content-level attestation and
        # file verification.
        def transition_service_request(request_id, state:, receipt: nil, validated: false)
          unless %w[succeeded failed uncertain rejected failed-settled].include?(state)
            raise ArgumentError, "invalid service request state"
          end
          current = service_request(request_id)
          raise AttemptErrors::NotFound, "Service request #{request_id} not found" unless current
          # Terminal states are immutable; failed-settled is reached only
          # from a dispatched (failed, uncertain, or consumed-rejected)
          # effect with a validated no-effect receipt.
          consumed_rejected = current["state"] == "rejected" && current["consumed"] != false
          if %w[succeeded failed-settled].include?(current["state"]) ||
              (current["state"] == "rejected" && !consumed_rejected) ||
              (consumed_rejected && state != "failed-settled")
            raise AttemptErrors::InvalidState, "Service request #{request_id} is terminal"
          end
          validate_terminal_receipt!(current, state, receipt) if terminal_state?(state)
          stamped = current.merge("state" => state, "receipt" => receipt)
          stamped["failed_at"] = Time.now.utc.iso8601(9) if state == "failed"
          update_service_request(request_id, expected: current,
            replacement: stamped,
            event_type: "service_transition")
        end

        TERMINAL_RECEIPT_FIELDS = %w[assignment_id attempt_id candidate_head evidence executor_uid
          input_digest operation outcome project_id request_id target transport].freeze
        TERMINAL_BINDING_FIELDS = %w[request_id assignment_id attempt_id project_id operation
          input_digest target candidate_head executor_uid transport].freeze

        def terminal_state?(state)
          %w[succeeded failed failed-settled].include?(state)
        end

        def validate_terminal_receipt!(current, state, receipt)
          unless receipt.is_a?(Hash) && receipt.keys.sort == TERMINAL_RECEIPT_FIELDS.sort
            raise AttemptErrors::ReceiptRejected,
              "Service terminal receipt has invalid fields"
          end
          TERMINAL_BINDING_FIELDS.each do |key|
            unless receipt[key] == current[key]
              raise AttemptErrors::ReceiptRejected, "Service terminal receipt does not match #{key}"
            end
          end
          expected_outcome = (state == "failed-settled") ? "failed" : state
          evidence_items = receipt["evidence"]
          valid_evidence = evidence_items.is_a?(Array) && !evidence_items.empty? &&
            evidence_items.all? do |item|
              item.is_a?(Hash) && item.keys.sort == %w[ref sha256] &&
                item["ref"].is_a?(String) && item["ref"].match?(/\A[a-zA-Z0-9_.:\/-]{1,256}\z/) &&
                item["sha256"].is_a?(String) && item["sha256"].match?(/\A[0-9a-f]{64}\z/)
            end
          executor_valid = receipt["executor_uid"].is_a?(Integer) && receipt["executor_uid"] >= 0
          unless receipt["outcome"] == expected_outcome && executor_valid && valid_evidence
            raise AttemptErrors::ReceiptRejected, "Service terminal receipt has invalid executor or evidence"
          end
          if state == "failed-settled" &&
              !receipt["evidence"].any? { |item| item["ref"].end_with?("no-effect") }
            raise AttemptErrors::ReceiptRejected,
              "Service settlement requires a no-effect attestation artifact"
          end
          repo_root = File.realpath(@repo_root)
          receipt["evidence"].each do |item|
            path = File.expand_path(item["ref"], repo_root)
            real = begin
              File.realpath(path)
            rescue Errno::ENOENT, Errno::EACCES, Errno::ELOOP
              raise AttemptErrors::ReceiptRejected,
                "Service terminal receipt evidence is unverifiable: #{item["ref"]}"
            end
            intact = begin
              real.start_with?(repo_root + File::SEPARATOR) &&
                Digest::SHA256.file(real).hexdigest == item["sha256"]
            rescue Errno::EACCES, Errno::ELOOP
              false
            end
            raise AttemptErrors::ReceiptRejected,
              "Service terminal receipt evidence is unverifiable: #{item["ref"]}" unless intact
            attestation = /^ace-service-attestation request:#{Regexp.escape(current["request_id"])} \
input:#{Regexp.escape(current["input_digest"])} outcome:(\S+)( no-effect:(\S+))?$/
            attested = File.read(real).scan(attestation).first
            attested_outcome = state == "failed-settled" ? "failed" : state
            unless attested && attested.first == attested_outcome &&
                (state == "failed-settled" ? attested[2] == "true" : true)
              raise AttemptErrors::ReceiptRejected,
                "Service terminal receipt evidence does not attest #{attested_outcome}: #{item["ref"]}"
            end
          end
        end

        def service_request(request_id)
          validate_request_id!(request_id)
          value = ref_value
          return nil unless value
          out, stderr, status = git("show", "#{value}:#{service_request_path(request_id)}")
          return JSON.parse(out) if status.success?
          return nil if stderr.include?("does not exist") || stderr.include?("exists on disk")
          raise AttemptErrors::EvidenceUnavailable, "Cannot read service request: #{stderr}"
        rescue JSON::ParserError
          raise AttemptErrors::EvidenceUnavailable, "Corrupt service request #{request_id}"
        end

        # Every service request recorded in this evidence ref, whatever the
        # owning assignment. Backs the journal-wide request-ID and
        # authorization-consumption checks.
        # Another live request holding the same exact authorization for the
        # same operation, project and target. Only requests that were born
        # rejected (never claimed, never dispatched) leave the decision
        # unconsumed: a withdrawn or failed claim keeps it consumed until
        # attributable evidence proves the effect did not occur.
        def authorization_conflict(binding)
          authorization = binding["authorization"]
          return nil unless authorization.is_a?(String) && !authorization.empty?
          service_request_records.find do |other|
            next false if other["request_id"] == binding.fetch("request_id")
            next false if other["state"] == "rejected" && other["consumed"] == false
            # A settled failure frees the exact authorization only while its
            # no-effect evidence remains verifiable in the repository.
            next false if other["state"] == "failed-settled" && settlement_evidence_intact?(other)
            other["authorization"] == authorization &&
              other["operation"] == binding.fetch("operation") &&
              other["project_id"] == binding.fetch("project_id") &&
              other["target"] == binding.fetch("target")
          end
        end

        def settlement_evidence_intact?(record)
          receipt = record["receipt"]
          return false unless receipt.is_a?(Hash)
          repo_root = File.realpath(@repo_root)
          Array(receipt["evidence"]).all? do |item|
            path = File.expand_path(item["ref"].to_s, repo_root)
            real = begin
              File.realpath(path)
            rescue Errno::ENOENT, Errno::EACCES, Errno::ELOOP
              next false
            end
            begin
              real.start_with?(repo_root + File::SEPARATOR) &&
                Digest::SHA256.file(real).hexdigest == item["sha256"]
            rescue Errno::EACCES, Errno::ELOOP
              false
            end
          end
        end

        def service_request_records
          value = ref_value
          return [] unless value
          paths, stderr, status = git("ls-tree", "-r", "--name-only", value, "--", "execution/requests/")
          raise AttemptErrors::EvidenceUnavailable, "Cannot read service request index: #{stderr}" unless status.success?
          paths.lines.map(&:strip).select { |path| path.end_with?(".json") }.filter_map do |path|
            content, error, read_status = git("show", "#{value}:#{path}")
            unless read_status.success?
              raise AttemptErrors::EvidenceUnavailable, "Cannot read service request #{path}: #{error}"
            end
            JSON.parse(content)
          end
        rescue JSON::ParserError
          raise AttemptErrors::EvidenceUnavailable, "Corrupt service request index"
        end

        def service_requests(assignment_id)
          request_ids = read_events(assignment_id)
            .select { |event| event["type"] == "service_claim" }
            .map { |event| event.dig("payload", "request_id") }.compact.uniq
          request_ids.filter_map { |request_id| service_request(request_id) }
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

          paths, stderr, status = git("ls-tree", "-d", "--name-only", value, "--", "execution/")
          raise AttemptErrors::EvidenceUnavailable, "Cannot discover journal assignments: #{stderr}" unless status.success?
          paths.lines.map { |path| path.strip.delete_prefix("execution/") }
            .reject { |id| id == "requests" }.sort
        end

        private

        def update_service_request(request_id, expected:, replacement:, event_type:, guard: nil)
          validate_request_id!(request_id)
          with_lock do
            CAS_ATTEMPTS.times do
              old = ref_value
              ensure_checkout!
              old = ref_value if old.nil?
              sync_checkout(old)
              # Guards (for example authorization consumption) re-run inside
              # the lock against the ref being committed, so a racing claim
              # cannot slip through between the check and the CAS.
              if guard
                conflict = guard.call
                if conflict
                  raise AttemptErrors::Conflict,
                    "Authorization reference already consumed by request #{conflict.fetch("request_id")}"
                end
              end
              path = File.join(checkout_dir, service_request_path(request_id))
              existing = File.exist?(path) ? JSON.parse(File.read(path)) : nil
              if expected.nil? && existing
                return existing if existing.except("state", "receipt", "reason", "claimed_at") ==
                  replacement.except("state", "receipt", "reason", "claimed_at")
                raise AttemptErrors::Conflict, "Service request #{request_id} has different input"
              end
              if expected && existing != expected
                raise AttemptErrors::Conflict, "Service request #{request_id} changed during transition"
              end
              terminal = existing && %w[succeeded failed rejected].include?(existing["state"])
              settlement = existing && existing["state"] == "failed" && replacement["state"] == "failed-settled"
              if expected && existing && terminal && !settlement
                raise AttemptErrors::InvalidState, "Service request #{request_id} is terminal"
              end

              FileUtils.mkdir_p(File.dirname(path))
              File.write(path, JSON.pretty_generate(replacement))
              assignment_id = replacement.fetch("assignment_id")
              attempt_id = replacement.fetch("attempt_id")
              prior = read_events(assignment_id).reverse
                .find { |entry| entry["attempt_id"] == attempt_id }&.fetch("digest")
              payload = {"request_id" => request_id, "state" => replacement.fetch("state"),
                         "input_digest" => replacement.fetch("input_digest"),
                         "receipt_digest" => replacement["receipt"] &&
                           Atoms::EvidenceDigest.digest(replacement["receipt"])}
              event = Models::EvidenceEvent.build(type: event_type, attempt_id: attempt_id,
                payload: payload, previous_digest: prior)
              write_event_files(assignment_id, [event])
              git!("-C", checkout_dir, "add", "--", service_request_path(request_id),
                "execution/#{assignment_id}/events")
              state = replacement.fetch("state")
              git!("-C", checkout_dir, "-c", "user.name=ace-assign", "-c", "user.email=ace-assign@localhost",
                "commit", "-m", "evidence: service request #{request_id} #{state}")
              commit = git!("-C", checkout_dir, "rev-parse", "HEAD").first
              return replacement.merge("journal_commit" => commit) if update_ref_cas(commit, old)
            end
            raise AttemptErrors::EvidenceUnavailable, "Service request ref stayed conflicting"
          end
        end

        def service_request_path(request_id)
          "execution/requests/#{request_id}.json"
        end

        def validate_request_id!(request_id)
          return if request_id.is_a?(String) && request_id.match?(/\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/)
          raise ArgumentError, "invalid service request ID"
        end

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
            raise AttemptErrors::EvidenceUnavailable, "git #{argv.join(" ")} failed: #{stderr}"
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
