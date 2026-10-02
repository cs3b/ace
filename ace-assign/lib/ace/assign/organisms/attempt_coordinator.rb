# frozen_string_literal: true

require "digest"
require "json"
require "open3"
require "pathname"

module Ace
  module Assign
    module Organisms
      # Authoritative coordinator for assignment attempts.
      #
      # The coordinator is the only authority allowed to reserve and start
      # attempts, accept authoritative receipts, transition attempt state,
      # invalidate stale candidate evidence, and write accepted journal
      # events. It composes the attempt store (local ownership), the evidence
      # journal (managed Git-ref evidence), the identity resolver (trusted
      # boundary), and the receipt verifier (acceptance rules).
      #
      # Guarantee: only one active attempt owns an assignment + subtree;
      # `base_head` is captured exactly once at start; `candidate_head` is
      # pinned only when candidate-bound evidence is accepted and any change
      # to the candidate revision invalidates prior candidate authorization;
      # `journal_commit` is tracked separately from both.
      class AttemptCoordinator
        SERVICE_RECEIPT_FIELDS = %w[assignment_id attempt_id candidate_head evidence executor_uid
          input_digest operation outcome project_id request_id target transport].freeze
        SERVICE_BINDING_FIELDS = %w[request_id assignment_id attempt_id project_id operation
          input_digest target candidate_head executor_uid transport].freeze
        # @param cache_base [String, nil] Assignment cache base
        # @param repo_root [String, nil] Candidate repository root (default: project root)
        # @param journal [Molecules::EvidenceJournal, nil] Evidence journal (default built per repo)
        # @param identity_resolver [Molecules::ExecutionIdentityResolver, nil] Trust boundary
        # @param verifier [Molecules::ReceiptVerifier, nil] Receipt verifier
        def initialize(cache_base: nil, repo_root: nil, journal: nil, identity_resolver: nil, verifier: nil,
          lifecycle_exclusion: nil)
          @manager = Molecules::AssignmentManager.new(cache_base: cache_base)
          @store = @manager.attempt_store
          @repo_root = repo_root || Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
          @journal = journal
          @identity_resolver = identity_resolver || Molecules::ExecutionIdentityResolver.new
          @verifier = verifier || Molecules::ReceiptVerifier.new(identity_resolver: @identity_resolver)
          @lifecycle_exclusion = lifecycle_exclusion
        end

        attr_reader :store

        # Claim an external service effect before dispatch. Only a managed,
        # active attempt for the exact project and candidate may own it. The
        # guard re-runs inside the journal lock per CAS attempt, so a
        # terminal event landing between validation and commit still blocks
        # the claim.
        def claim_service_request(binding)
          attempt = service_attempt(binding)
          head = candidate_head!
          valid_head = binding["candidate_head"] == head && [nil, head].include?(attempt.candidate_head)
          unless valid_head
            raise AttemptErrors::ReceiptRejected, "Service request candidate head is stale"
          end
          require_review_evidence(attempt, head) if @verifier.external_effect?(binding["operation"])
          # Dispatching claims record uncertain directly: the effect may
          # happen as soon as the claim lands, and a crash before the
          # executor response must leave uncertainty, not a stranded
          # accepted state that a retry would return without dispatching.
          journal_for.claim_service_request(binding, state: "uncertain", guard: -> { claim_guard(binding) })
        end

        # Rechecked against the authoritative ref for every locked claim
        # attempt: the attempt must still be journal-active and the exact
        # authorization must still be unconsumed.
        def claim_guard(binding)
          derived = journal_for.derived_attempts(binding.fetch("assignment_id"))
            .find { |candidate| candidate.attempt_id == binding.fetch("attempt_id") }
          unless derived&.active?
            raise AttemptErrors::ReceiptRejected, "Attempt is no longer active in the authoritative journal"
          end
          journal_for.authorization_conflict(binding)
        end

        def service_attempt(binding)
          attempt = authoritative_attempt(binding)
          raise AttemptErrors::NotFound, "Attempt not found" unless attempt
          unless attempt.managed? && attempt.active? &&
              attempt.binding.assignment_id == binding["assignment_id"] &&
              attempt.binding.project_id == binding["project_id"]
            raise AttemptErrors::ReceiptRejected, "Service request does not match an active managed attempt"
          end
          attempt
        end

        # The authoritative journal wins for managed assignments, and a
        # managed service claim REQUIRES the journal-derived attempt: a lost
        # or unavailable evidence ref fails closed instead of trusting a
        # local cache record that the journal cannot corroborate.
        def authoritative_attempt(binding)
          assignment_id = binding.fetch("assignment_id")
          assignment = @manager.load(assignment_id)
          if assignment&.managed?
            journal_for.derived_attempts(assignment_id)
              .find { |candidate| candidate.attempt_id == binding.fetch("attempt_id") }
          else
            @store.find(binding.fetch("attempt_id")) ||
              recover_managed_attempt(assignment_id, binding.fetch("attempt_id"))
          end
        end

        def reject_service_request(binding, reason:)
          service_attempt(binding)
          journal_for.reject_service_request(binding, reason: reason)
        end

        def service_request_status(request_id)
          journal_for.service_request(request_id)
        end

        def transition_service_request(request_id, state:, receipt: nil)
          if %w[succeeded failed].include?(state)
            request = journal_for.service_request(request_id)
            raise AttemptErrors::NotFound, "Service request #{request_id} not found" unless request
            validate_service_receipt!(request, state, receipt)
          elsif receipt
            raise AttemptErrors::ReceiptRejected, "Non-terminal service transition cannot carry a receipt"
          end
          journal_for.transition_service_request(request_id, state: state, receipt: receipt, validated: true)
        end

        # Settle a failed effect as "no effect occurred". The settlement is
        # evidence-validated like a terminal receipt — the executor must
        # attest this request with outcome:failed and attributable evidence
        # — and the original failure event stays in the journal history.
        def reconcile_service_failure(request_id, receipt:)
          request = journal_for.service_request(request_id)
          raise AttemptErrors::NotFound, "Service request #{request_id} not found" unless request
          unless request["state"] == "failed"
            raise AttemptErrors::InvalidState, "Only failed service requests can be reconciled"
          end
          settle_no_effect(request_id, request, receipt)
        end

        # Settle an uncertain claim whose handler was never invoked (a
        # pre-dispatch refusal observed by the trusted local service). Same
        # evidence rules as a failure settlement: a distinct, executor-owned
        # no-effect attestation bound to this request.
        def reconcile_service_no_effect(request_id, receipt:)
          request = journal_for.service_request(request_id)
          raise AttemptErrors::NotFound, "Service request #{request_id} not found" unless request
          unless request["state"] == "uncertain"
            raise AttemptErrors::InvalidState, "Only uncertain service requests can settle as no-effect"
          end
          settle_no_effect(request_id, request, receipt)
        end

        def settle_no_effect(request_id, request, receipt)
          # The settlement must be a distinct, later executor attestation:
          # replaying the already-recorded failure receipt proves nothing
          # about whether the effect took place.
          if request["receipt"] && Atoms::EvidenceDigest.digest(receipt) ==
              Atoms::EvidenceDigest.digest(request["receipt"])
            raise AttemptErrors::ReceiptRejected,
              "Service failure settlement requires a new attestation, not the recorded receipt"
          end
          validate_service_receipt!(request, "failed", receipt, require_no_effect: true)
          journal_for.transition_service_request(request_id, state: "failed-settled",
            receipt: receipt, validated: true)
        end

        def validate_service_receipt!(request, state, receipt, require_no_effect: false)
          unless receipt.is_a?(Hash) && receipt.keys.sort == SERVICE_RECEIPT_FIELDS.sort
            raise AttemptErrors::ReceiptRejected, "Service receipt has invalid fields"
          end
          SERVICE_BINDING_FIELDS.each do |key|
            unless receipt[key] == request[key]
              raise AttemptErrors::ReceiptRejected, "Service receipt does not match #{key}"
            end
          end
          unless receipt["outcome"] == state && receipt["executor_uid"].is_a?(Integer) &&
              receipt["executor_uid"] >= 0 && valid_service_evidence?(receipt["evidence"])
            raise AttemptErrors::ReceiptRejected, "Service receipt has invalid executor or evidence"
          end
          unless receipt["executor_uid"] == request["executor_uid"]
            raise AttemptErrors::ReceiptRejected, "Service receipt executor does not match the claimed executor"
          end
          # Local transport runs the executor in the submitting process, so
          # the submitter must be the configured executor identity itself.
          if request["transport"] == "local" && Process.uid != request["executor_uid"]
            raise AttemptErrors::ReceiptRejected, "Service receipt submitter is not the configured executor"
          end
          verify_service_evidence!(receipt["evidence"], request, state, require_no_effect: require_no_effect)
        end

        def valid_service_evidence?(evidence)
          evidence.is_a?(Array) && !evidence.empty? && evidence.all? do |item|
            item.is_a?(Hash) && item.keys.sort == %w[ref sha256] &&
              item["ref"].is_a?(String) && item["ref"].match?(/\A[a-zA-Z0-9_.:\/-]{1,256}\z/) &&
              item["sha256"].is_a?(String) && item["sha256"].match?(/\A[0-9a-f]{64}\z/)
          end
        end

        # Evidence must live inside the candidate repository (symlinks
        # resolved), be owned by — and not writable by anyone but — the
        # claimed executor identity, postdate the claim, and carry a
        # structured attestation naming the claimed request, input digest,
        # and attested outcome. All checks read one open handle, so a swap
        # on a caller-writable path cannot mix files between checks.
        def verify_service_evidence!(evidence, request, state, require_no_effect: false)
          repo_root = File.realpath(@repo_root)
          claimed_at = parse_claimed_at(request)
          evidence.each do |item|
            ref = item["ref"]
            unless Pathname.new(ref).relative?
              raise AttemptErrors::ReceiptRejected, "Service receipt evidence must be repository-relative: #{ref}"
            end
            path = File.expand_path(ref, repo_root)
            unless path.start_with?(repo_root + File::SEPARATOR)
              raise AttemptErrors::ReceiptRejected, "Service receipt evidence must live inside the repository: #{ref}"
            end
            begin
              file = File.open(path, "rb")
            rescue Errno::ENOENT
              raise AttemptErrors::ReceiptRejected, "Service receipt evidence is unavailable: #{ref}"
            end
            begin
              real = File.realpath(path)
              unless real.start_with?(repo_root + File::SEPARATOR)
                raise AttemptErrors::ReceiptRejected, "Service receipt evidence must live inside the repository: #{ref}"
              end
              stat = file.stat
              # The open handle must still be the file at the validated
              # location: a swap between resolution and open fails here.
              opened = File.stat(real)
              unless opened.dev == stat.dev && opened.ino == stat.ino
                raise AttemptErrors::ReceiptRejected, "Service receipt evidence changed during verification: #{ref}"
              end
              unless stat.uid == request["executor_uid"] && (stat.mode & 0o022).zero?
                raise AttemptErrors::ReceiptRejected, "Service receipt evidence is not executor-owned: #{ref}"
              end
              unless claimed_at.nil? || stat.mtime >= claimed_at
                raise AttemptErrors::ReceiptRejected, "Service receipt evidence predates the claim: #{ref}"
              end
              failed_at = parse_failed_at(request)
              unless failed_at.nil? || stat.mtime >= failed_at
                raise AttemptErrors::ReceiptRejected, "Service receipt evidence predates the failure: #{ref}"
              end
              content = file.read
              unless attestation_line(content, request, state, require_no_effect: require_no_effect)
                raise AttemptErrors::ReceiptRejected,
                  "Service receipt evidence does not bind the claimed request: #{ref}"
              end
              unless Digest::SHA256.hexdigest(content) == item["sha256"]
                raise AttemptErrors::ReceiptRejected, "Service receipt evidence digest mismatch: #{ref}"
              end
            ensure
              file.close
            end
          end
        end

        # The evidence artifact must carry a structured attestation line
        # naming the claimed request, input digest, and attested outcome
        # exactly: an unrelated executor-owned file cannot attest this
        # effect, prose cannot substitute for the attested outcome, and its
        # result cannot be recorded under another terminal state.
        def attestation_line(content, request, state, require_no_effect: false)
          attestation = /^ace-service-attestation request:#{Regexp.escape(request.fetch("request_id"))} \
input:#{Regexp.escape(request.fetch("input_digest"))} outcome:(\S+)( no-effect:(\S+))?$/
          line = content.scan(attestation).first
          return false unless line
          return false if require_no_effect && line[2] != "true"
          %w[succeeded failed].include?(state) ? line.first == state : true
        end

        def parse_claimed_at(request)
          return nil if request["claimed_at"].nil?
          Time.iso8601(request["claimed_at"])
        rescue ArgumentError
          raise AttemptErrors::ReceiptRejected, "Service request has an invalid claim timestamp"
        end

        def parse_failed_at(request)
          return nil if request["failed_at"].nil?
          Time.iso8601(request["failed_at"])
        rescue ArgumentError
          raise AttemptErrors::ReceiptRejected, "Service request has an invalid failure timestamp"
        end

        # Read-only eligibility check for dry-run: applies the same review
        # evidence and candidate-head requirements as the claim without
        # reserving anything.
        def request_eligible!(binding)
          attempt = service_attempt(binding)
          head = candidate_head!
          valid_head = binding["candidate_head"] == head && [nil, head].include?(attempt.candidate_head)
          unless valid_head
            raise AttemptErrors::ReceiptRejected, "Service request candidate head is stale"
          end
          require_review_evidence(attempt, head) if @verifier.external_effect?(binding["operation"])
          true
        end

        # Start a scoped attempt for an assignment.
        #
        # A repeated identical start returns the existing active attempt; a
        # conflicting or scope-overlapping binding raises
        # {AttemptErrors::Conflict} without ever launching a second writer.
        # Active attempts are resolved from the local store AND, for managed
        # assignments, from the authoritative journal, so a lost local record
        # cannot admit a competing writer.
        #
        # @param assignment_id [String] Assignment ID
        # @param step [String] Step/subtree scope
        # @param project_id [String] Project the attempt executes in
        # @param identity [ExecutionIdentityResolver::Identity, nil] Resolved when nil
        # @return [Models::Attempt] Active attempt (reused, recovered, or newly reserved)
        def start(assignment_id:, step:, project_id:, identity: nil)
          assignment = @manager.load(assignment_id)
          raise AssignmentErrors::NotFound, "Assignment '#{assignment_id}' not found" unless assignment

          scope = Atoms::AssignmentScope.canonicalize(step)
          project = project_id.to_s.strip
          raise Error, "attempt start requires --project ID" if project.empty?

          identity ||= @identity_resolver.resolve
          base_head = candidate_head!

          # Serialize writer registration against prune: prune holds the
          # exclusive exclusion from its final evidence reads through removal.
          # A worktree-backed task identity shares the same protocol (task
          # key first, then assignment key — the one consistent global
          # order), so a worktree prune and an attempt start cannot interleave.
          start_keys = []
          unless assignment.task_id.to_s.strip.empty?
            start_keys << lifecycle_exclusion.task_key(assignment.task_id)
          end
          start_keys << lifecycle_exclusion.assignment_key(assignment_id)
          lifecycle_exclusion.with_shared_multi(start_keys) do
            @store.with_lock(assignment_id) do
              journal_actives = assignment.managed? ? active_journal_attempts(assignment) : []

              existing = @store.active(assignment_id, scope) ||
                journal_actives.find { |attempt| Atoms::AssignmentScope.equal?(attempt.binding.scope, scope) }
              if existing
                if existing.binding.project_id == project && existing.binding.task_id == assignment.task_id &&
                    existing.binding.actor == identity.actor && existing.binding.role == identity.role
                  return existing
                end

                raise AttemptErrors::Conflict,
                  "Active attempt #{existing.attempt_id} already owns #{assignment_id}@#{scope} " \
                  "(project #{existing.binding.project_id}); refusing to launch a second writer"
              end

              active_scopes = @store.list(assignment_id).select(&:active?).map(&:binding)
              active_scopes.concat(journal_actives.map(&:binding))
              blocker = active_scopes.find { |binding| scopes_overlap?(binding.scope, scope) }
              if blocker
                raise AttemptErrors::Conflict,
                  "Active attempt scope #{blocker.scope} overlaps requested scope #{scope} on #{assignment_id}; " \
                  "refusing overlapping writers"
              end

              attempt_id = unique_attempt_id(assignment_id, journal_actives.map(&:attempt_id))
              events = start_events(assignment_id, assignment, scope, project, identity, base_head, attempt_id)
              attempt = reserve(assignment, scope, project, identity, base_head, attempt_id)
              if attempt.managed?
                commit = journal_for.append(
                  assignment_id: assignment_id,
                  attempt_id: attempt.attempt_id,
                  events: events
                )
                attempt = attempt.with(journal_commit: commit)
                attempt = yield_lost_ownership_race(attempt, assignment_id, scope)
              else
                attempt = attempt.with(events: events)
              end

              @store.save(attempt)
              @store.claim(assignment_id, scope, attempt)
              attempt
            end
          end
        end

        # Accept a receipt for an attempt and transition it.
        #
        # @param attempt_id [String] Attempt ID
        # @param receipt_path [String] Path to the receipt JSON file
        # @param identity [ExecutionIdentityResolver::Identity, nil] Resolved when nil
        # @return [Models::Attempt] Updated attempt
        def finish(attempt_id:, receipt_path:, identity: nil)
          data = read_receipt_file(receipt_path)
          assignment_id = data["assignment_id"].to_s

          # Serialize load-validate-accept so concurrent finishes observe one
          # consistent state and cannot persist contradictory terminal outcomes.
          @store.with_lock(assignment_id) do
            attempt = @store.load(assignment_id, attempt_id) || recover_managed_attempt(assignment_id, attempt_id)
            raise AttemptErrors::NotFound, "Attempt '#{attempt_id}' not found" unless attempt

            ensure_journal_consistent!(attempt) if attempt.managed?
            raise AttemptErrors::InvalidState, "Attempt #{attempt_id} is terminal; accepted history is immutable" if attempt.terminal?
            raise AttemptErrors::InvalidState, "Attempt #{attempt_id} is uncertain; reconcile before finishing" if attempt.uncertain?

            identity ||= @identity_resolver.resolve
            live_head = candidate_head!

            attempt = invalidate_stale_candidate(attempt, live_head)

            receipt = @verifier.verify!(
              data,
              attempt: attempt,
              identity: identity,
              live_head: live_head,
              repo_root: @repo_root
            )
            if @verifier.external_effect?(receipt.operation)
              unless attempt.managed?
                raise AttemptErrors::InvalidState,
                  "Taskless attempts cannot record external effects without managed evidence"
              end

              require_review_evidence(attempt, live_head)
            end

            accept(attempt, receipt, live_head)
          end
        end

        # Active-attempt projection for status surfaces.
        #
        # @param assignment_id [String] Assignment ID
        # @return [Hash, nil] Projection fields or nil when no attempt exists
        def status(assignment_id)
          attempts = @store.list(assignment_id)
          attempt = attempts.find(&:active?) || attempts.first
          return nil unless attempt

          attempt.projection
        end

        # Read accepted check evidence without transitions, locks, cache writes
        # or audit checkout creation. Managed history comes from the Git ref.
        def evidence(attempt_id:, receipt_digest:, kind: "check", check_name: "tests", historical_head: nil)
          unless %w[check review-collection review-approval].include?(kind) && check_name.is_a?(String) && !check_name.strip.empty?
            raise AttemptErrors::ReceiptRejected, "Invalid evidence kind or check name"
          end
          if !historical_head.nil? && (!%w[review-collection review-approval].include?(kind) || !historical_head.is_a?(String) ||
              !historical_head.match?(/\A[0-9a-f]{40,64}\z/))
            raise AttemptErrors::ReceiptRejected, "Historical evidence requires review collection/approval and an exact recorded head"
          end
          unless attempt_id.to_s.match?(/\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/) &&
              receipt_digest.to_s.match?(/\A[0-9a-f]{64}\z/)
            raise AttemptErrors::ReceiptRejected, "Invalid attempt ID or receipt digest"
          end
          attempt = @store.find(attempt_id) || recover_managed_attempt(nil, attempt_id)
          raise AttemptErrors::NotFound, "Attempt #{attempt_id} not found" unless attempt
          raise AttemptErrors::ReceiptRejected, "Execution evidence requires managed immutable journal history" unless attempt.managed?
          attempt = recover_managed_attempt(attempt.binding.assignment_id, attempt_id)
          raise AttemptErrors::ReceiptRejected, "No succeeded accepted attempt" unless attempt&.state == "succeeded"
          accepted = journal_for.accepted_receipts(attempt.binding.assignment_id)
          data = accepted.find { |r| r["attempt_id"] == attempt_id && r["digest"] == receipt_digest }
          raise AttemptErrors::ReceiptRejected, "Receipt was not accepted by coordinator" unless data
          if kind == "check" && (%w[review review-collect].include?(data["operation"]) || @verifier.external_effect?(data["operation"]))
            raise AttemptErrors::ReceiptRejected, "Review or external-effect operations cannot be check evidence"
          end
          expected_operation = case kind
          when "review-collection" then "review-collect"
          when "review-approval" then "review"
          else (check_name == "tests") ? "test" : check_name
          end
          unless data["campaign"].nil? && data["operation"] == expected_operation
            raise AttemptErrors::ReceiptRejected, "Accepted receipt operation does not prove #{kind}: #{expected_operation}"
          end
          required_check = (kind == "review-collection") ? "review-execution" : check_name
          has_required_check = Array(data["checks"]).any? { |check| check["name"] == required_check && check["verdict"] == "passed" }
          unless kind == "review-approval" || has_required_check
            raise AttemptErrors::ReceiptRejected, "Accepted receipt does not prove the required check #{required_check}"
          end
          receipt = Models::ExecutionReceipt.from_h(data)
          unless receipt.digest == Atoms::EvidenceDigest.digest(receipt.digest_payload)
            raise AttemptErrors::ReceiptRejected, "Accepted receipt digest is corrupt"
          end
          evidence_head = historical_head || candidate_head!
          unless data["verdict"] == "succeeded" && data["head"] == evidence_head && attempt.candidate_head == evidence_head
            raise AttemptErrors::ReceiptRejected, "Accepted execution evidence is stale or unsuccessful"
          end
          @verifier.verify_accepted_evidence!(data, live_head: evidence_head, repo_root: @repo_root)
          {"attempt_id" => attempt_id, "receipt_digest" => receipt_digest, "head" => evidence_head, "kind" => kind,
           "historical" => !historical_head.nil?,
           "operation" => data["operation"], "checks" => data["checks"], "producer" => data["producer"], "review" => data["review"],
           "artifacts" => data["artifacts"], "assignment_id" => data["assignment_id"],
           "project_id" => data["project_id"], "scope" => data["scope"],
           "evidence_git_ref" => attempt.binding.evidence_git_ref, "journal_commit" => attempt.journal_commit}
        end

        # Reconcile an interrupted attempt.
        #
        # Running attempts are classified conservatively (stopped before
        # process start, uncertain when an effect cannot be proven either
        # way, still running only for verifiably live processes). Uncertain
        # attempts resolve only against a verified receipt attributed to the
        # recorded execution boundary. Reconciliation never replays merge,
        # publish, or deploy effects.
        #
        # @param attempt_id [String] Attempt ID
        # @param receipt_path [String, nil] Receipt JSON for resolving uncertainty
        # @param identity [ExecutionIdentityResolver::Identity, nil] Resolved when nil
        # @return [Models::Attempt] Updated attempt
        def reconcile(attempt_id:, receipt_path: nil, identity: nil)
          probe = @store.find(attempt_id) || recover_managed_attempt(nil, attempt_id)
          raise AttemptErrors::NotFound, "Attempt '#{attempt_id}' not found" unless probe

          @store.with_lock(probe.binding.assignment_id) do
            attempt = @store.load(probe.binding.assignment_id, attempt_id) ||
              recover_managed_attempt(probe.binding.assignment_id, attempt_id)
            raise AttemptErrors::NotFound, "Attempt '#{attempt_id}' not found" unless attempt

            derived = ensure_journal_consistent!(attempt, allow_uncertain: true) if attempt.managed?
            # The journal is authoritative for managed attempts: uncertainty
            # journaled after the local save drives reconciliation.
            attempt = attempt.with(state: derived.state) if derived&.state == "uncertain" && attempt.state == "running"

            if attempt.terminal?
              raise AttemptErrors::InvalidState, "Attempt #{attempt_id} is terminal; accepted history is immutable"
            end

            return classify_running(attempt) if attempt.state == "running"

            identity ||= @identity_resolver.resolve
            resolve_uncertain(attempt, receipt_path, identity)
          end
        end

        private

        # Attempt IDs must be unique per assignment AND globally: records,
        # journal events, and reconciliation lookups key on them. Allocation
        # runs under the assignment lock, avoids journal-known IDs, and
        # claims the ID atomically in the cross-assignment registry.
        def unique_attempt_id(assignment_id, taken_ids = [])
          base = Ace::B36ts.now
          suffix = 0
          100.times do
            candidate = suffix.zero? ? base : "#{base}#{suffix.to_s(36)}"
            suffix += 1
            next if taken_ids.include?(candidate)
            next unless @store.load(assignment_id, candidate).nil?
            return candidate if @store.reserve_id(candidate)
          end

          raise Error, "Failed to generate a unique attempt ID for #{assignment_id} after 100 attempts"
        end

        # Ancestors and descendants overlap: an active attempt for 010 owns
        # its 010.01 subtree, and vice versa.
        def scopes_overlap?(left, right)
          return true if Atoms::AssignmentScope.equal?(left, right)

          left.start_with?("#{right}.") || right.start_with?("#{left}.")
        end

        # Active attempts derived from the authoritative journal, used when
        # the local record may be missing (lost or wiped cache). Derivation
        # lives in the journal (owner of attempt-state interpretation).
        def active_journal_attempts(assignment)
          journal_for.active_attempts(assignment.id)
        end

        # Recover a managed attempt from the journal when the local record is
        # missing. With an assignment ID only that journal is consulted;
        # without one, assignment IDs are discovered from the evidence ref
        # itself, so a fully lost cache still reconciles.
        def recover_managed_attempt(assignment_id, attempt_id)
          if assignment_id
            assignment = @manager.load(assignment_id)
            # A surviving taskless record never consults the journal; a lost
            # record falls through to journal evidence (only managed attempts
            # are journaled).
            return nil if assignment && !assignment.managed?

            return journal_for.derived_attempts(assignment_id)
                .find { |candidate| candidate.attempt_id == attempt_id }
          end

          journal_for.assignment_ids.each do |journal_assignment_id|
            attempt = journal_for.derived_attempts(journal_assignment_id)
              .find { |candidate| candidate.attempt_id == attempt_id }
            return attempt if attempt
          end

          nil
        end

        # The journal is authoritative for managed attempts: a crash after a
        # journaled terminal/uncertain event but before the local save must
        # not admit contradictory transitions.
        def ensure_journal_consistent!(attempt, allow_uncertain: false)
          derived = journal_for.derived_attempts(attempt.binding.assignment_id)
            .find { |candidate| candidate.attempt_id == attempt.attempt_id }
          return if derived.nil?

          journal_state = derived.state
          if %w[succeeded failed stopped].include?(journal_state)
            raise AttemptErrors::InvalidState,
              "Journal shows attempt #{attempt.attempt_id} is #{journal_state}; accepted history is immutable"
          end
          return derived if allow_uncertain || journal_state != "uncertain" || attempt.uncertain?

          raise AttemptErrors::InvalidState,
            "Journal shows attempt #{attempt.attempt_id} is uncertain; reconcile before finishing"
        end

        # After appending our start events, revalidate ownership: a
        # coordinator with a separate cache directory may have claimed the
        # same scope between our read and our append (journal CAS replay
        # merges both). The loser records a stopped transition and refuses.
        def yield_lost_ownership_race(attempt, assignment_id, scope)
          rival = journal_for.active_attempts(assignment_id).find do |other|
            other.attempt_id != attempt.attempt_id && scopes_overlap?(other.binding.scope, scope)
          end
          return attempt if rival.nil?

          stopped = append_events(attempt, [transition_event(attempt, "stopped", "lost ownership race to #{rival.attempt_id}")])
          stopped = stopped.transition("stopped")
          @store.save(stopped)
          raise AttemptErrors::Conflict,
            "Active attempt #{rival.attempt_id} owns overlapping scope #{rival.binding.scope} on #{assignment_id}; " \
            "our start #{attempt.attempt_id} was recorded stopped without executing"
        end

        # Conservative classification of a running attempt after interruption.
        def classify_running(attempt)
          case reconciler.classify(attempt)
          when :live
            raise AttemptErrors::InvalidState,
              "Attempt #{attempt.attempt_id} process is verifiably live; reconcile after it exits"
          when :stopped
            attempt = append_events(attempt, [transition_event(attempt, "stopped", "interrupted before process start")])
            attempt = attempt.transition("stopped")
            @store.save(attempt)
            @store.release(attempt.binding.assignment_id, attempt.binding.scope, attempt.attempt_id)
            attempt
          else
            attempt = append_events(attempt, [transition_event(attempt, "uncertain", "effect completion cannot be proven or excluded")])
            attempt = attempt.transition("uncertain")
            @store.save(attempt)
            attempt
          end
        end

        # Resolve an uncertain attempt against a verified, boundary-attributed
        # receipt. Never resolves by assumption.
        def resolve_uncertain(attempt, receipt_path, identity)
          unless attempt.uncertain?
            raise AttemptErrors::InvalidState,
              "Attempt #{attempt.attempt_id} is #{attempt.state}; reconciliation targets uncertain attempts"
          end
          unless receipt_path
            raise AttemptErrors::InvalidState,
              "Reconciliation requires --receipt FILE; uncertain attempts are never resolved by assumption"
          end

          data = read_receipt_file(receipt_path)
          live_head = candidate_head!
          attempt = invalidate_stale_candidate(attempt, live_head)

          recorded = reconciler.recorded_runtime(attempt)
          unless data.dig("producer", "runtime") == recorded
            raise AttemptErrors::ReceiptRejected,
              "Receipt runtime #{data.dig("producer", "runtime").inspect} does not match the recorded " \
              "execution boundary #{recorded.inspect}"
          end

          receipt = @verifier.verify!(
            data,
            attempt: attempt,
            identity: identity,
            live_head: live_head,
            repo_root: @repo_root
          )
          if @verifier.external_effect?(receipt.operation)
            unless attempt.managed?
              raise AttemptErrors::InvalidState,
                "Taskless attempts cannot record external effects without managed evidence"
            end

            require_review_evidence(attempt, live_head)
          end

          reconciliation = Models::EvidenceEvent.build(
            type: "reconciliation",
            attempt_id: attempt.attempt_id,
            payload: {"resolution" => receipt.verdict, "receipt_digest" => receipt.digest},
            previous_digest: last_event_digest(attempt)
          )
          accept(attempt, receipt, live_head, [reconciliation])
        end

        def transition_event(attempt, to, reason)
          Models::EvidenceEvent.build(
            type: "transition",
            attempt_id: attempt.attempt_id,
            payload: {"from" => attempt.state, "to" => to, "reason" => reason},
            previous_digest: last_event_digest(attempt)
          )
        end

        def reconciler
          @reconciler ||= Molecules::AttemptReconciler.new(journal: journal_for, verifier: @verifier)
        end

        def reserve(assignment, scope, project, identity, base_head, attempt_id)
          binding = Models::AttemptBinding.new(
            attempt_id: attempt_id,
            assignment_id: assignment.id,
            scope: scope,
            project_id: project,
            task_id: assignment.task_id,
            actor: identity.actor,
            role: identity.role,
            runtime: identity.runtime,
            base_head: base_head,
            evidence_git_ref: assignment.managed? ? journal_for.ref : nil,
            created_at: Time.now.utc
          )
          Models::Attempt.new(binding: binding, state: "reserved").transition("running")
        end

        def start_events(assignment_id, assignment, scope, project, identity, base_head, attempt_id)
          intent = Models::EvidenceEvent.build(
            type: "intent",
            attempt_id: attempt_id,
            payload: {
              "assignment_id" => assignment_id,
              "scope" => scope,
              "project_id" => project,
              "task_id" => assignment.task_id,
              "base_head" => base_head
            }
          )
          process_start = Models::EvidenceEvent.build(
            type: "process_start",
            attempt_id: attempt_id,
            payload: {
              "actor" => identity.actor,
              "role" => identity.role,
              "runtime" => identity.runtime,
              "pid" => Process.pid
            },
            previous_digest: intent["digest"]
          )
          [intent, process_start]
        end

        # A changed candidate SHA invalidates prior candidate evidence and
        # authorizations; the change itself is journaled before anything else.
        def invalidate_stale_candidate(attempt, live_head)
          return attempt if attempt.candidate_head.nil? || attempt.candidate_head == live_head

          event = Models::EvidenceEvent.build(
            type: "candidate_invalidated",
            attempt_id: attempt.attempt_id,
            payload: {"previous_candidate_head" => attempt.candidate_head, "current_head" => live_head}
          )
          attempt = append_events(attempt, [event])
          attempt = attempt.with(candidate_head: nil, accepted_receipts: [])
          @store.save(attempt)
          attempt
        end

        def accept(attempt, receipt, live_head, pre_events = [])
          previous = pre_events.last&.dig("digest") || last_event_digest(attempt)
          event = Models::EvidenceEvent.build(
            type: "receipt_accepted",
            attempt_id: attempt.attempt_id,
            payload: {"receipt" => receipt.to_h},
            previous_digest: previous
          )
          attempt = append_events(attempt, pre_events + [event])

          receipts = attempt.accepted_receipts + [receipt.to_h]
          effects = attempt.effects
          if @verifier.external_effect?(receipt.operation)
            effects += [{"operation" => receipt.operation, "receipt_digest" => receipt.digest}]
          end

          attempt = attempt.with(
            candidate_head: attempt.candidate_head || receipt.head,
            accepted_receipts: receipts,
            effects: effects,
            state: attempt.state,
            updated_at: Time.now.utc
          )
          attempt = attempt.transition(receipt.verdict) if %w[succeeded failed].include?(receipt.verdict)

          @store.save(attempt)
          @store.release(attempt.binding.assignment_id, attempt.binding.scope, attempt.attempt_id) if attempt.terminal?

          attempt
        end

        def require_review_evidence(attempt, live_head)
          receipts = if attempt.managed?
            journal_for.read_events(attempt.binding.assignment_id)
              .select { |event| event["type"] == "receipt_accepted" }
              .map { |event| event.dig("payload", "receipt") }
              .compact
          else
            attempt.accepted_receipts
          end
          approved = receipts.any? do |candidate|
            candidate["operation"] == Molecules::ReceiptVerifier::REVIEW_OPERATION &&
              candidate["verdict"] == "succeeded" &&
              candidate["head"] == live_head &&
              candidate.dig("review", "verdict") == Molecules::ReceiptVerifier::APPROVED_VERDICT
          end
          return if approved

          raise AttemptErrors::ReceiptRejected,
            "External effect requires an executed independent review receipt for candidate #{live_head}"
        end

        def read_receipt_file(path)
          raise AttemptErrors::ReceiptRejected, "Receipt file not found: #{path}" unless File.exist?(path.to_s)

          data = JSON.parse(File.read(path))
          raise AttemptErrors::ReceiptRejected, "Receipt must be a JSON object" unless data.is_a?(Hash)

          data
        rescue JSON::ParserError => e
          raise AttemptErrors::ReceiptRejected, "Receipt file is not valid JSON: #{e.message}"
        end

        def append_events(attempt, events)
          if attempt.managed?
            commit = journal_for.append(
              assignment_id: attempt.binding.assignment_id,
              attempt_id: attempt.attempt_id,
              events: events
            )
            attempt.with(journal_commit: commit)
          else
            attempt.with(events: attempt.events + events)
          end
        end

        # Digest chain continuation: managed attempts chain through the
        # authoritative journal; taskless attempts chain through the local
        # event trail.
        def last_event_digest(attempt)
          if attempt.managed?
            journal_for.read_events(attempt.binding.assignment_id).last&.dig("digest")
          else
            attempt.events.last&.dig("digest")
          end
        end

        def journal_for
          @journal ||= Molecules::EvidenceJournal.new(repo_root: @repo_root)
          @journal
        end

        # Prune/writer exclusion shared with overseer prune (durable, outside
        # every deletion target).
        def lifecycle_exclusion
          @lifecycle_exclusion ||= Molecules::LifecycleExclusion.new(repo_root: @repo_root)
        end

        def candidate_head!
          out, status = Open3.capture2("git", "rev-parse", "HEAD", chdir: @repo_root, stdin_data: "")
          head = out.to_s.strip
          return head if status.success? && !head.empty?

          raise AttemptErrors::EvidenceUnavailable, "Cannot resolve candidate HEAD in #{@repo_root}"
        end
      end
    end
  end
end
