# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "uri"
require_relative "ordinary_merge_request"
require_relative "../molecules/ordinary_receiver_config"
require_relative "../molecules/ordinary_admission_resolver"
require_relative "../molecules/ordinary_ff_merge"
require_relative "../molecules/forge_merge_config"
require_relative "../molecules/forgejo_merge_adapter"
require "ace/assign/atoms/fixed_merge_schemas"

module Ace
  module Lab
    module Organisms
      # The ordinary fixed merge RECEIVER/EXECUTOR (spec 8x3.t.xz9.4
      # execution clauses) — the execution side of the ordinary merge chain.
      # One mode of the maintained service vocabulary: `handle` performs the
      # authenticated admission (mutual-identity binding, canonical digest
      # re-derivation, scoped YAML authorization resolution, pre-effect
      # target verification, durable Assign admission) and returns the exact
      # wire envelope; `execute` then runs the authorized fixed operation as
      # the authorized executor — at most one fast-forward merge per admitted
      # request — and settles the exact terminal receipt into the canonical
      # Assign attempt/evidence journal. The receiver owns no ledger: every
      # durable write lives in Assign, and every refusal uses the closed
      # producer envelope vocabulary.
      #
      # Merge-method contract: the closed schema's literal `method=merge`
      # executes FAST-FORWARD-ONLY, on the forge wire as well (`Do:
      # fast-forward-only`): a candidate that is not a descendant of the
      # current base head refuses in the moved-target/needs-rebase family
      # (never a silent substitution, never a merge-commit fallback); the
      # terminal receipt proves the strategy by joining `merge_commit ==
      # resulting_target_head == merged_candidate_head`. The merge POST
      # additionally binds the approved candidate head SERVER-SIDE
      # (`head_commit_id`): the forge refuses to merge any head other than
      # the reviewed candidate, so a race between the state readback and
      # the merge POST can never merge an unreviewed head.
      #
      # Forge effect contract (spec 8x3.t.xz9.5 integration handoff): the
      # authorized effect is a REAL Forgejo pull request merge invoked under
      # the scoped service identity from the host-installed forge merge
      # configuration, and the terminal receipt records the REAL forge
      # readback (`merged`, `merge_commit_sha`) — a local git effect is
      # never presented as a forge result, and the receiver never updates
      # the checked-out canonical main locally. The local repository
      # (the producer's canonical checkout) serves read-only pre-effect
      # verification only. Missing host configuration is an immediate
      # actionable refusal naming the path and owner; ambiguous outcomes
      # (timeouts, 5xx, unavailable readback) reconcile by bounded readback
      # retry — never a blind re-dispatch — and leave the canonical record
      # uncertain with the escalation owner named when unresolved.
      class OrdinaryMergeReceiver
        SUBMISSION_KEYS = %w[project_id assignment_id attempt_id queue_entry operation
          authorization request_id input_digest request principal receiver_id
          configuration_sha256].freeze
        ID = Molecules::ServicePolicy::ID

        def initialize(config:, coordinator:, policy_document:, merge_factory: nil,
          forge_config: nil, forge_factory: nil, resolver: nil,
          readback_attempts: 3, readback_backoff_seconds: 1.0, owner_guard: nil)
          unless config.is_a?(Molecules::OrdinaryReceiverConfig)
            raise ArgumentError, "receiver needs validated OrdinaryReceiverConfig"
          end
          @config = config
          unless owner_guard.nil? || owner_guard.respond_to?(:call)
            raise ArgumentError, "ordinary installed owner guard must be callable"
          end
          @owner_guard = owner_guard
          @coordinator = coordinator
          @policy_document = policy_document
          @configuration_sha256 = Molecules::ServicePolicy.configuration_digest(policy_document)
          @merge_factory = merge_factory || ->(document) {
            Molecules::OrdinaryFfMerge.new(repo_path: config.repo_path,
              base_ref: document.fetch("base_ref"))
          }
          # The scoped service identity is host-installed; an absent
          # configuration refuses construction with the actionable path.
          @forge_config = forge_config || Molecules::ForgeMergeConfig.load(
            config.forge_config_path || Molecules::ForgeMergeConfig::DEFAULT_PATH
          )
          @forge_factory = forge_factory || ->(_document) {
            Molecules::ForgejoMergeAdapter.new(base_url: @forge_config.base_url,
              token: @forge_config.token, timeout_seconds: @forge_config.merge_timeout_seconds)
          }
          @resolver = resolver || Molecules::OrdinaryAdmissionResolver.new(
            policy_document, path: config.policy_path,
            proposal_resolver: coordinator.method(:proposal_authorization), caller_uid: config.principal_uid
          )
          @readback_attempts = readback_attempts
          @readback_backoff_seconds = readback_backoff_seconds
        end

        attr_reader :config, :forge_config

        # The listener handler entrypoint: admission only; the listener
        # invokes #execute after the acknowledgment is on the wire.
        def call(submission)
          handle(submission)
        end

        # Authenticated admission of one wire submission. Returns the exact
        # wire envelope: the durable acknowledgment after the canonical
        # Assign record exists, or a closed pre-effect refusal envelope that
        # proves no effect began. Never a receiver-local record.
        def handle(submission)
          @owner_guard&.call
          invalid!("submission is not a mapping") unless submission.is_a?(Hash)
          invalid!("submission has unknown selectors: #{unknown(submission)}") unless
            (submission.keys - SUBMISSION_KEYS).empty?
          invalid!("submission is missing selectors") unless (SUBMISSION_KEYS - submission.keys).empty?
          request_id = submission.fetch("request_id")
          unless submission.fetch("operation") == OrdinaryMergeRequest::OPERATION
            invalid!("operation must be merge", request_id)
          end
          identifiers!(submission)
          unless submission.fetch("receiver_id") == @config.receiver_id
            return selection_mismatch("submission does not target this receiver", request_id)
          end
          unless submission.fetch("project_id") == @config.project
            return selection_mismatch("submission does not target this receiver project", request_id)
          end
          unless submission.fetch("principal") == @config.principal
            return selection_mismatch("submission principal does not match the installed mapping", request_id)
          end
          unless submission.fetch("configuration_sha256") == @configuration_sha256
            return selection_mismatch("installed configuration differs from the submitting policy", request_id)
          end
          document = submission.fetch("request")
          begin
            Ace::Assign::Atoms::FixedMergeSchemas.validate_request!(document)
            Ace::Assign::Atoms::FixedMergeSchemas.require_request_joins!(document)
          rescue Ace::Assign::Atoms::FixedMergeSchemas::SchemaError => e
            invalid!(e.message, request_id)
          end
          digest = rederive_digest(submission, document)
          unless digest == submission.fetch("input_digest")
            invalid!("canonical request digest does not re-derive from the submission", request_id)
          end
          # Selection and evidence integrity before authorization: the PR
          # must target THIS receiver's configured forge repository, and the
          # handed-over review must be independent of the executor.
          forge_identity!(document, request_id)
          reviewer_independence!(document, request_id)
          decision = @resolver.decide(submission.fetch("authorization"), authorization_binding(submission))
          unless decision.authorized?
            return OrdinaryMergeRequest.refusal_envelope(decision.code, decision.message,
              request_id: request_id, input_digest: digest)
          end
          verify_pre_effect_target!(document, request_id)
          admitted = admit(submission)
          ack_envelope(admitted)
        rescue OrdinaryMergeRefusal => e
          OrdinaryMergeRequest.refusal_envelope(e.code, e.detail,
            request_id: e.request_id, input_digest: e.input_digest)
        rescue Ace::Assign::AttemptErrors::AuthorizationConflict, Ace::Assign::AttemptErrors::ReceiptRejected => e
          OrdinaryMergeRequest.refusal_envelope("ordinary_merge_authorization_invalid", e.message,
            request_id: submission.is_a?(Hash) ? submission.fetch("request_id", "unknown") : "unknown",
            input_digest: nil)
        rescue Ace::Assign::AttemptErrors::Conflict => e
          OrdinaryMergeRequest.refusal_envelope("ordinary_merge_request_conflict", e.message,
            request_id: submission.is_a?(Hash) ? submission.fetch("request_id", "unknown") : "unknown",
            input_digest: nil)
        rescue Molecules::OrdinaryFfMerge::GitUnavailable, Ace::Assign::Error,
          Ace::Lab::InvalidConfigurationError => e
          OrdinaryMergeRequest.refusal_envelope("ordinary_merge_unavailable", e.message,
            request_id: submission.is_a?(Hash) ? submission.fetch("request_id", "unknown") : "unknown",
            input_digest: nil)
        end

        # The executor lifecycle for one admitted request: the single
        # pending->uncertain CAS is the at-most-one-merge proof; a record
        # already begun by a lost lifecycle stays uncertain and is NEVER
        # re-executed or resubmitted. The effect is one REAL forge merge
        # invocation under the scoped service identity; settlement is one
        # journal CAS validated against the closed receipt schema from the
        # real forge readback. Any crash between begin and settle leaves the
        # canonical record uncertain with the original reference.
        def execute(request_id)
          @owner_guard&.call
          record = @coordinator.fixed_merge_record(request_id)
          return :unknown unless record
          return :skipped_terminal unless record.fetch("state") == "pending"
          begin
            @coordinator.begin_fixed_merge_effect(request_id)
          rescue Ace::Assign::AttemptErrors::ReceiptRejected, Ace::Assign::AttemptErrors::AuthorizationConflict
            merge = @merge_factory.call(record.fetch("request"))
            settle_no_effect(request_id, record, merge, "canonical proposal is no longer authorized before effect")
            return :refused
          end
          execute_effect(record)
          :executed
        rescue Ace::Assign::AttemptErrors::InvalidState, Ace::Assign::AttemptErrors::NotFound,
          Ace::Assign::AttemptErrors::Conflict
          # Another lifecycle won the CAS or the record is terminal: never a
          # second effect, never a resubmission.
          :skipped_terminal
        end

        # Receiver-restart reconciliation: adopt only records this exact
        # installed configuration owns, still pending, and drive each one to
        # a terminal state at most once. Already-uncertain records (a lost
        # lifecycle) are never re-executed — they reconcile by reference.
        def recover_pending!
          @owner_guard&.call
          records = @coordinator.fixed_merge_records
          records.filter_map do |record|
            next nil unless record.fetch("state") == "pending" &&
              record.fetch("receiver_id") == @config.receiver_id &&
              record.fetch("configuration_sha256") == @configuration_sha256 &&
              record.fetch("project_id") == @config.project
            [record.fetch("request_id"), execute(record.fetch("request_id"))]
          end
        end

        private

        # ---- admission -----------------------------------------------------

        def identifiers!(submission)
          %w[project_id assignment_id attempt_id queue_entry request_id].each do |key|
            value = submission.fetch(key)
            invalid!("invalid #{key}") unless value.is_a?(String) && value.match?(ID)
          end
        end

        def rederive_digest(submission, document)
          Ace::Assign::Atoms::FixedMergeSchemas.canonical_request_digest(
            project: submission.fetch("project_id"), assignment: submission.fetch("assignment_id"),
            attempt: submission.fetch("attempt_id"), queue_entry: submission.fetch("queue_entry"),
            authorization: submission.fetch("authorization"),
            request_id: submission.fetch("request_id"), input: document
          )
        end

        def authorization_binding(submission)
          document = submission.fetch("request")
          {
            "operation" => submission.fetch("operation"),
            "project_id" => submission.fetch("project_id"),
            "assignment_id" => submission.fetch("assignment_id"),
            "attempt_id" => submission.fetch("attempt_id"),
            "queue_entry" => submission.fetch("queue_entry"),
            "input_digest" => submission.fetch("input_digest"),
            "forge" => document.fetch("forge"),
            "pr_url" => document.fetch("pr_url"),
            "head_repository" => document.fetch("head_repository"),
            "head_ref" => document.fetch("head_ref"),
            "candidate_head" => document.fetch("candidate_head"),
            "base_repository" => document.fetch("base_repository"),
            "base_ref" => document.fetch("base_ref"),
            "expected_base_head" => document.fetch("expected_base_head")
          }
        end

        # Pre-effect target verification before any admission — read-only
        # against the canonical repository (the producer's canonical
        # checkout): the candidate object must exist and the base head must
        # still equal the immutable request. Moved targets answer the
        # moved-target/needs-rebase refusal family before any effect.
        def verify_pre_effect_target!(document, request_id)
          merge = @merge_factory.call(document)
          candidate = document.fetch("candidate_head")
          unless merge.candidate_commit?(candidate)
            target_changed!("candidate head is absent from the canonical repository", request_id)
          end
          observed = merge.base_head
          if observed != document.fetch("expected_base_head")
            target_changed!("base head moved from the immutable request", request_id)
          end
          # Merge-method contract: `method=merge` is FAST-FORWARD-ONLY. A
          # candidate that is not a descendant of the current base head is
          # the moved-target/needs-rebase refusal family — never a silent
          # method substitution, never a merge-commit fallback.
          unless merge.fast_forwardable?(candidate)
            target_changed!("candidate head is not fast-forwardable onto the base head", request_id)
          end
        end

        def admit(submission)
          record = submission.merge(
            "principal" => @config.principal,
            "caller_uid" => @config.principal_uid,
            "execution_identity" => @config.execution_identity
          )
          @coordinator.admit_fixed_merge_request(record)
        end

        def ack_envelope(record)
          {"status" => "ok", "data" => {
            "schema" => Ace::Assign::Atoms::FixedMergeSchemas::ACK_SCHEMA_ID,
            "type" => "accepted",
            "request_id" => record.fetch("request_id"),
            "input_digest" => record.fetch("input_digest"),
            "reference" => record.fetch("reference")
          }}
        end

        # The effect: re-verify the base head read-only, verify the forge PR
        # state readback (head == candidate, base == expected), attach the
        # independent final-head review when the host installed it, invoke
        # the fast-forward-only merge, and settle from the real readback —
        # reconciling ambiguity by bounded readback retry, never by
        # repeating the merge.
        def execute_effect(admitted_record)
          request_id = admitted_record.fetch("request_id")
          document = admitted_record.fetch("request")
          candidate = document.fetch("candidate_head")
          expected = document.fetch("expected_base_head")
          merge = @merge_factory.call(document)
          refusal = current_authorization_refusal(admitted_record)
          return settle_no_effect(request_id, admitted_record, merge, refusal) if refusal
          observed = merge.base_head
          if observed != expected
            return settle_no_effect(request_id, admitted_record, merge,
              "base head moved before the effect: #{observed[0, 12]}")
          end
          identity = forge_identity!(document, request_id)
          forge = @forge_factory.call(document)
          pr = readback(forge, identity)
          if pr.nil?
            return settle_no_effect(request_id, admitted_record, merge,
              "pull request is absent from the forge")
          end
          if pr["merged"]
            sha = pr["merge_commit_sha"]
            if sha == candidate
              return settle_merged(request_id, admitted_record, document, sha,
                outcome: "already_merged")
            end
            return leave_uncertain(request_id,
              "forge shows the pull request already merged at #{head_label(sha)}, " \
                "not the approved candidate #{candidate[0, 12]}",
              owner: @forge_config.escalation_owner)
          end
          unless pr.dig("head", "sha") == candidate
            return settle_no_effect(request_id, admitted_record, merge,
              "forge pull request head moved from the approved candidate")
          end
          unless pr.dig("base", "sha") == expected
            return settle_no_effect(request_id, admitted_record, merge,
              "forge base head moved from the immutable request")
          end
          refusal = current_authorization_refusal(admitted_record)
          return settle_no_effect(request_id, admitted_record, merge, refusal) if refusal
          refusal = attach_independent_review!(forge, identity, request_id,
            admitted_record, merge, document)
          return refusal if refusal
          # Exact-head contract: the merge POST binds the approved candidate
          # head server-side — the forge refuses to merge any head other
          # than the reviewed candidate (race between readback and POST can
          # never merge an unreviewed head).
          refusal = current_authorization_refusal(admitted_record)
          return settle_no_effect(request_id, admitted_record, merge, refusal) if refusal
          result = forge.merge_pull_request!(owner: identity.fetch("owner"),
            repo: identity.fetch("repo"), index: identity.fetch("index"),
            head_commit_id: candidate)
          case result.outcome
          when :invoked
            reconcile_invoked(forge, identity, request_id, admitted_record, merge,
              document, candidate)
          when :refused
            settle_no_effect(request_id, admitted_record, merge,
              "forge refused the merge: #{result.reason}")
          else
            reconcile_ambiguous(forge, identity, request_id, admitted_record, merge,
              document, candidate, result.reason)
          end
        rescue Molecules::OrdinaryFfMerge::GitUnavailable, Molecules::ForgejoMergeAdapter::Unavailable => e
          # The effect outcome is unprovable: the canonical record stays
          # uncertain with the original reference — never a resubmission.
          leave_uncertain(request_id, e.message)
        end

        # Recheck pending/recovered authority and again after slow forge calls,
        # immediately before each privileged effect. No cached decision is a lease.
        def current_authorization_refusal(record)
          @owner_guard&.call
          decision = @resolver.decide(record.fetch("authorization"), authorization_binding(record))
          decision.message unless decision.authorized?
        rescue Ace::Lab::InvalidConfigurationError, Ace::Assign::Error => e
          e.message
        end

        # The merge invocation was accepted: prove the terminal state by
        # readback before any settlement. A readback showing a merge at any
        # head other than the approved candidate is never a success. A 404
        # AFTER the invocation is never a no-effect proof either: the merge
        # POST was actually invoked, so the pull request's absence
        # (permission change, deletion, visibility loss) cannot prove
        # absence of effect — the record stays uncertain with the original
        # reference, the escalation owner named, no no-effect attestation
        # and no retry, never a re-invocation.
        def reconcile_invoked(forge, identity, request_id, admitted_record, merge,
          document, candidate)
          pr = readback(forge, identity)
          if pr.nil?
            return leave_uncertain(request_id,
              "pull request is absent from the forge after the merge invocation: absence " \
                "cannot prove no effect (permission change, deletion, or visibility loss " \
                "may hide an applied merge)",
              owner: @forge_config.escalation_owner)
          end
          if pr["merged"]
            sha = pr["merge_commit_sha"]
            return settle_merged(request_id, admitted_record, document, sha) if sha == candidate
            return leave_uncertain(request_id,
              "forge merged the pull request at #{head_label(sha)}, " \
                "not the approved candidate #{candidate[0, 12]}",
              owner: @forge_config.escalation_owner)
          end
          leave_uncertain(request_id,
            "forge accepted the merge invocation but the readback shows the pull request unmerged")
        end

        # The merge invocation outcome is ambiguous (timeout, reset, 5xx):
        # reconciliation is readback-only. A readback proving the merge
        # settles it; anything else stays uncertain — never a blind repeat,
        # never a fabricated no-effect claim while the forge may still be
        # applying the invocation. A 404 after the invocation stays in the
        # same uncertain family: absence cannot prove no effect.
        def reconcile_ambiguous(forge, identity, request_id, admitted_record, merge,
          document, candidate, reason)
          pr = readback(forge, identity)
          if pr.nil?
            return leave_uncertain(request_id,
              "merge invocation outcome ambiguous (#{reason}); the pull request is absent " \
                "from the forge after the invocation and absence cannot prove no effect",
              owner: @forge_config.escalation_owner)
          end
          if pr["merged"]
            sha = pr["merge_commit_sha"]
            return settle_merged(request_id, admitted_record, document, sha) if sha == candidate
            return leave_uncertain(request_id,
              "forge merged the pull request at #{head_label(sha)}, " \
                "not the approved candidate #{candidate[0, 12]}",
              owner: @forge_config.escalation_owner)
          end
          leave_uncertain(request_id,
            "merge invocation outcome ambiguous (#{reason}); forge readback after " \
              "reconciliation shows the pull request unmerged",
            owner: @forge_config.escalation_owner)
        end

        # Attach the INDEPENDENT final-head review body to the PR before the
        # merge when the host enabled review attachment. The body is composed
        # only of the reviewer-produced evidence handed over in the admitted
        # request — the receiver never composes an approval of its own. A
        # refused or ambiguous attachment settles failed_no_effect: the merge
        # was never invoked, so no effect provably occurred.
        def attach_independent_review!(forge, identity, request_id, admitted_record,
          merge, document)
          return nil unless @forge_config.review_attachment_enabled
          evidence = document.fetch("review_evidence")
          body = [
            "Independent final-head review evidence (reviewer-produced, attached verbatim " \
              "from the admitted merge request):",
            "- reviewer: #{evidence.fetch("reviewer")}",
            "- verdict: #{evidence.fetch("verdict")}",
            "- reviewed_head: #{evidence.fetch("reviewed_head")}",
            "- reference: #{evidence.fetch("reference")}",
            "- recorded_at: #{evidence.fetch("recorded_at")}",
            "- record_sha256: #{evidence.fetch("record_sha256")}"
          ].join("\n")
          result = forge.create_comment(owner: identity.fetch("owner"),
            repo: identity.fetch("repo"), index: identity.fetch("index"), body: body)
          case result.outcome
          when :invoked
            nil
          when :refused
            settle_no_effect(request_id, admitted_record, merge,
              "forge refused the independent review attachment: #{result.reason}")
          else
            settle_no_effect(request_id, admitted_record, merge,
              "independent review attachment outcome ambiguous; merge not invoked: #{result.reason}")
          end
        end

        # One authoritative readback; transient forge unavailability is
        # retried (reconciliation) a bounded number of times before
        # surfacing — the merge is never re-dispatched from here.
        def readback(forge, identity)
          attempts = @readback_attempts
          begin
            attempts -= 1
            forge.pull_request(owner: identity.fetch("owner"),
              repo: identity.fetch("repo"), index: identity.fetch("index"))
          rescue Molecules::ForgejoMergeAdapter::Unavailable
            raise if attempts.zero?
            sleep @readback_backoff_seconds
            retry
          end
        end

        def settle_merged(request_id, admitted_record, document, merge_commit_sha,
          outcome: "merged")
          receipt = {
            "schema" => Ace::Assign::Atoms::FixedMergeSchemas::RECEIPT_SCHEMA_ID,
            "reference" => admitted_record.fetch("reference"),
            "request_id" => admitted_record.fetch("request_id"),
            "input_digest" => admitted_record.fetch("input_digest"),
            "terminal_status" => "succeeded",
            "request" => {
              "project" => admitted_record.fetch("project_id"),
              "assignment" => admitted_record.fetch("assignment_id"),
              "attempt" => admitted_record.fetch("attempt_id"),
              "queue_entry" => admitted_record.fetch("queue_entry"),
              "operation" => admitted_record.fetch("operation"),
              "authorization" => admitted_record.fetch("authorization"),
              "input" => document
            },
            "producer" => {
              "receiver_id" => admitted_record.fetch("receiver_id"),
              "principal" => admitted_record.fetch("principal"),
              "configuration_sha256" => admitted_record.fetch("configuration_sha256")
            },
            "effect" => {
              "started_at" => Time.now.utc.iso8601,
              "finished_at" => Time.now.utc.iso8601,
              "outcome" => outcome,
              "failure_code" => nil,
              "no_effect_evidence" => nil
            },
            # The REAL forge readback: the merge proof is the forge-reported
            # merge commit (for the fast-forward-only strategy it equals the
            # merged candidate head), never a local git observation.
            "remote_observation" => {
              "forge_instance" => document.fetch("forge"),
              "pr_identity_url" => document.fetch("pr_url"),
              "target_repository_identity" => document.fetch("base_repository"),
              "target_ref_observed" => document.fetch("base_ref"),
              "merged_candidate_head" => document.fetch("candidate_head"),
              "admission_target_head" => document.fetch("expected_base_head"),
              "resulting_target_head" => merge_commit_sha,
              "merge_commit" => merge_commit_sha,
              "checkout_id" => admitted_record.dig("execution_identity", "checkout_id"),
              "worktree_id" => admitted_record.dig("execution_identity", "worktree_id"),
              "branch" => admitted_record.dig("execution_identity", "branch")
            }
          }
          settle(request_id, "succeeded", receipt)
        end

        # Terminal failure requires the immutable no-effect attestation: an
        # blob committed atomically with the terminal receipt in Assign's
        # canonical evidence ref. No caller checkout path is written.
        def settle_no_effect(request_id, admitted_record, merge, reason)
          record = @coordinator.fixed_merge_record(request_id)
          document = record.fetch("request")
          attestation = {
            "request_id" => request_id,
            "input_digest" => record.fetch("input_digest"),
            "reference" => record.fetch("reference"),
            "candidate_head" => document.fetch("candidate_head"),
            "expected_base_head" => document.fetch("expected_base_head"),
            "observed_base_head" => merge.base_head,
            "strategy" => Molecules::OrdinaryFfMerge::STRATEGY,
            "outcome" => "no_effect",
            "reason" => reason[0, 512],
            "recorded_at" => Time.now.utc.iso8601
          }
          receipt = {
            "schema" => Ace::Assign::Atoms::FixedMergeSchemas::RECEIPT_SCHEMA_ID,
            "reference" => record.fetch("reference"),
            "request_id" => record.fetch("request_id"),
            "input_digest" => record.fetch("input_digest"),
            "terminal_status" => "failed",
            "request" => {
              "project" => record.fetch("project_id"),
              "assignment" => record.fetch("assignment_id"),
              "attempt" => record.fetch("attempt_id"),
              "queue_entry" => record.fetch("queue_entry"),
              "operation" => record.fetch("operation"),
              "authorization" => record.fetch("authorization"),
              "input" => document
            },
            "producer" => {
              "receiver_id" => record.fetch("receiver_id"),
              "principal" => record.fetch("principal"),
              "configuration_sha256" => record.fetch("configuration_sha256")
            },
            "effect" => {
              "started_at" => Time.now.utc.iso8601,
              "finished_at" => Time.now.utc.iso8601,
              "outcome" => "failed_no_effect",
              "failure_code" => "merge_failed_no_effect",
              "no_effect_evidence" => nil
            },
            "remote_observation" => nil
          }
          settle(request_id, "failed", receipt, attestation: attestation)
        end

        def settle(request_id, terminal_status, receipt, attestation: nil)
          @coordinator.settle_fixed_merge_effect(request_id, terminal_status: terminal_status,
            receipt: receipt, attestation: attestation)
          terminal_status.to_sym
        rescue Ace::Assign::AttemptErrors::ReceiptRejected
          # The journal refused the receipt: the record stays uncertain with
          # its original reference. Never fabricate, never resubmit.
          :uncertain
        rescue Ace::Assign::AttemptErrors::InvalidState, Ace::Assign::AttemptErrors::NotFound
          # Another lifecycle already settled this record: exactly one
          # terminal settlement exists — never a second one.
          :skipped_terminal
        end

        def leave_uncertain(request_id, reason, owner: @forge_config.escalation_owner)
          # Intentionally no state change: uncertainty is the canonical
          # unproved-outcome state and reconciliation happens by reference
          # (never a re-dispatch). What is known is recorded on the service
          # log with the actionable owner named.
          warn(JSON.generate({"event" => "ordinary_merge_uncertain",
            "request_id" => request_id, "reason" => reason.to_s[0, 512],
            "owner" => owner}))
          nil
        end

        def target_changed!(message, request_id)
          raise OrdinaryMergeRefusal.new("ordinary_merge_target_changed", message,
            request_id: request_id)
        end

        # The forge PR identity from the immutable request's pr_url, validated
        # against the host-installed forge merge configuration: the PR must
        # belong to THIS receiver's configured forge, owner and repository —
        # anything else never targets this receiver (selection mismatch).
        def forge_identity!(document, request_id)
          forge_host = URI.parse(@forge_config.base_url).host.to_s.downcase
          uri = URI.parse(document.fetch("pr_url"))
          match = %r{\A/([^/]+)/([^/]+)/pulls/(\d+)\z}.match(uri.path.to_s)
          unless uri.is_a?(URI::HTTPS) && uri.host.to_s.downcase == forge_host && match
            selection_refusal!("pr_url does not target this receiver's configured forge repository",
              request_id)
          end
          unless match[1] == @forge_config.owner && match[2] == @forge_config.repo
            selection_refusal!("pr_url repository does not match the configured forge repository",
              request_id)
          end
          {"owner" => match[1], "repo" => match[2], "index" => match[3].to_i}
        end

        # The independent final-head review is handed over in the request;
        # the executor's own identity is never an independent reviewer.
        # Evidence naming the receiver or its principal refuses pre-effect —
        # it can never be attached as independent review and never grounds
        # the merge.
        def reviewer_independence!(document, request_id)
          reviewer = document.dig("review_evidence", "reviewer")
          return unless [config.receiver_id, config.principal].include?(reviewer)
          raise OrdinaryMergeRefusal.new("ordinary_merge_evidence_invalid",
            "review evidence names the receiver executor, not an independent reviewer",
            request_id: request_id)
        end

        def selection_refusal!(message, request_id)
          raise OrdinaryMergeRefusal.new("ordinary_merge_selection_mismatch", message,
            request_id: request_id)
        end

        def head_label(sha)
          (sha.is_a?(String) && sha.length >= 12) ? sha[0, 12] : sha.to_s
        end

        def selection_mismatch(message, request_id)
          OrdinaryMergeRequest.refusal_envelope("ordinary_merge_selection_mismatch", message,
            request_id: request_id, input_digest: nil)
        end

        def invalid!(message, request_id = "unknown")
          raise OrdinaryMergeRefusal.new("ordinary_merge_invalid_request", message,
            request_id: request_id)
        end

        def unknown(submission)
          (submission.keys - SUBMISSION_KEYS).sort.join(", ")
        end

        OrdinaryMergeRefusal = OrdinaryMergeRequest::OrdinaryMergeRefusal
      end
    end
  end
end
