# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require_relative "ordinary_merge_request"
require_relative "../molecules/ordinary_receiver_config"
require_relative "../molecules/ordinary_admission_resolver"
require_relative "../molecules/ordinary_ff_merge"
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
      # executes fast-forward-only. A candidate that is not a descendant of
      # the current base head refuses in the moved-target/needs-rebase family
      # (never a silent substitution, never a merge-commit fallback); the
      # terminal receipt proves the strategy by joining `merge_commit ==
      # resulting_target_head == merged_candidate_head` and records the
      # post-merge main sha. A non-ff strategy would be a separate reviewed
      # contract extension.
      class OrdinaryMergeReceiver
        SUBMISSION_KEYS = %w[project_id assignment_id attempt_id queue_entry operation
          authorization request_id input_digest request principal receiver_id
          configuration_sha256].freeze
        ID = Molecules::ServicePolicy::ID
        NO_EFFECT_DIR = ".ace/ordinary-no-effect"

        def initialize(config:, coordinator:, policy_document:, merge_factory: nil,
          resolver: nil)
          unless config.is_a?(Molecules::OrdinaryReceiverConfig)
            raise ArgumentError, "receiver needs validated OrdinaryReceiverConfig"
          end
          @config = config
          @coordinator = coordinator
          @policy_document = policy_document
          @configuration_sha256 = Ace::Lab::Atoms::ServiceInput.digest(policy_document)
          @merge_factory = merge_factory || ->(document) {
            Molecules::OrdinaryFfMerge.new(repo_path: config.repo_path,
              base_ref: document.fetch("base_ref"))
          }
          @resolver = resolver || Molecules::OrdinaryAdmissionResolver.new(policy_document)
        end

        attr_reader :config

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
        rescue Ace::Assign::AttemptErrors::AuthorizationConflict => e
          OrdinaryMergeRequest.refusal_envelope("ordinary_merge_authorization_invalid", e.message,
            request_id: submission.is_a?(Hash) ? submission.fetch("request_id", "unknown") : "unknown",
            input_digest: nil)
        rescue Ace::Assign::AttemptErrors::Conflict => e
          OrdinaryMergeRequest.refusal_envelope("ordinary_merge_request_conflict", e.message,
            request_id: submission.is_a?(Hash) ? submission.fetch("request_id", "unknown") : "unknown",
            input_digest: nil)
        rescue Molecules::OrdinaryFfMerge::GitUnavailable, Ace::Assign::AttemptErrors::EvidenceUnavailable,
          Ace::Lab::InvalidConfigurationError => e
          OrdinaryMergeRequest.refusal_envelope("ordinary_merge_unavailable", e.message,
            request_id: submission.is_a?(Hash) ? submission.fetch("request_id", "unknown") : "unknown",
            input_digest: nil)
        end

        # The executor lifecycle for one admitted request: the single
        # pending->uncertain CAS is the at-most-one-merge proof; a record
        # already begun by a lost lifecycle stays uncertain and is NEVER
        # re-executed or resubmitted. The effect is one atomic ref
        # compare-and-swap; settlement is one journal CAS validated against
        # the closed receipt schema. Any crash between begin and settle
        # leaves the canonical record uncertain with the original reference.
        def execute(request_id)
          record = @coordinator.fixed_merge_record(request_id)
          return :unknown unless record
          return :skipped_terminal unless record.fetch("state") == "pending"
          @coordinator.begin_fixed_merge_effect(request_id)
          execute_effect(record)
          :executed
        rescue Ace::Assign::AttemptErrors::InvalidState, Ace::Assign::AttemptErrors::NotFound
          # Another lifecycle won the CAS or the record is terminal: never a
          # second effect, never a resubmission.
          :skipped_terminal
        end

        # Receiver-restart reconciliation: adopt only records this exact
        # installed configuration owns, still pending, and drive each one to
        # a terminal state at most once. Already-uncertain records (a lost
        # lifecycle) are never re-executed — they reconcile by reference.
        def recover_pending!
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

        # Pre-effect target verification against the configured canonical
        # repository: the candidate object must exist and the base head must
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

        # ---- execution -----------------------------------------------------

        def execute_effect(admitted_record)
          request_id = admitted_record.fetch("request_id")
          document = admitted_record.fetch("request")
          candidate = document.fetch("candidate_head")
          expected = document.fetch("expected_base_head")
          merge = @merge_factory.call(document)
          observed = merge.base_head
          if observed != expected
            return settle_no_effect(request_id, admitted_record, merge,
              "base head moved before the effect: #{observed[0, 12]}")
          end
          result = merge.merge!(candidate, expected)
          case result.outcome
          when :merged, :already_merged
            settle_merged(request_id, admitted_record, result)
          else
            settle_no_effect(request_id, admitted_record, merge, result.reason.to_s)
          end
        rescue Molecules::OrdinaryFfMerge::GitUnavailable => e
          # The effect outcome is unprovable: the canonical record stays
          # uncertain with the original reference — never a resubmission.
          leave_uncertain(request_id, e.message)
        end

        def settle_merged(request_id, admitted_record, result)
          record = @coordinator.fixed_merge_record(request_id)
          document = record.fetch("request")
          receipt = {
            "schema" => Ace::Assign::Atoms::FixedMergeSchemas::RECEIPT_SCHEMA_ID,
            "reference" => record.fetch("reference"),
            "request_id" => record.fetch("request_id"),
            "input_digest" => record.fetch("input_digest"),
            "terminal_status" => "succeeded",
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
              "outcome" => result.outcome == :merged ? "merged" : "already_merged",
              "failure_code" => nil,
              "no_effect_evidence" => nil
            },
            "remote_observation" => {
              "forge_instance" => document.fetch("forge"),
              "pr_identity_url" => document.fetch("pr_url"),
              "target_repository_identity" => document.fetch("base_repository"),
              "target_ref_observed" => document.fetch("base_ref"),
              "merged_candidate_head" => document.fetch("candidate_head"),
              "admission_target_head" => document.fetch("expected_base_head"),
              "resulting_target_head" => result.resulting_head,
              "merge_commit" => result.resulting_head,
              "checkout_id" => record.dig("execution_identity", "checkout_id"),
              "worktree_id" => record.dig("execution_identity", "worktree_id"),
              "branch" => record.dig("execution_identity", "branch")
            }
          }
          settle(request_id, "succeeded", receipt)
        end

        # Terminal failure requires the immutable no-effect attestation: an
        # executor-owned file inside the canonical repository whose SHA-256
        # binds the no-merge proof to this exact request.
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
          evidence = write_no_effect_attestation(request_id, attestation)
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
              "no_effect_evidence" => evidence
            },
            "remote_observation" => nil
          }
          settle(request_id, "failed", receipt)
        end

        def settle(request_id, terminal_status, receipt)
          @coordinator.settle_fixed_merge_effect(request_id, terminal_status: terminal_status,
            receipt: receipt)
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

        def leave_uncertain(request_id, reason)
          # Intentionally no state change: uncertainty is the canonical
          # unproved-outcome state and reconciliation happens by reference.
          nil
        end

        def write_no_effect_attestation(request_id, attestation)
          dir = File.join(@config.repo_path, NO_EFFECT_DIR)
          FileUtils.mkdir_p(dir)
          path = File.join(dir, "#{request_id}.json")
          File.write(path, JSON.generate(attestation))
          {"reference" => "#{NO_EFFECT_DIR}/#{request_id}.json",
           "sha256" => Digest::SHA256.file(path).hexdigest}
        end

        def target_changed!(message, request_id)
          raise OrdinaryMergeRefusal.new("ordinary_merge_target_changed", message,
            request_id: request_id)
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
