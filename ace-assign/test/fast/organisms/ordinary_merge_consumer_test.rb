# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../support/ordinary_merge_fixture"
require "delegate"
require "fileutils"
require "json"

module Ace
  module Assign
    module Organisms
      class OrdinaryMergeConsumerTest < AceAssignTestCase
        include OrdinaryMergeFixture

        # Scripted producer double: records every invocation and enforces
        # at-most-one merge effect per request ID (identical recovery
        # re-invocations never dispatch a second effect).
        class ScriptedProducer
          attr_reader :requests, :statuses

          def initialize
            @requests = []
            @statuses = []
            @queue = []
            @effects = {}
          end

          def enqueue(envelope)
            @queue << envelope
          end

          def request(project:, assignment:, attempt:, queue_entry:, input_path:, authorization:, request_id:)
            @requests << {project: project, assignment: assignment, attempt: attempt, queue_entry: queue_entry,
              input_bytes: File.read(input_path), authorization: authorization, request_id: request_id}
            @effects[request_id] = true
            shift("request")
          end

          def status(**selectors)
            @statuses << selectors
            shift("status")
          end

          def merge_effect?(request_id)
            @effects.fetch(request_id, false)
          end

          private

          def shift(kind)
            envelope = @queue.shift
            raise "no scripted #{kind} envelope" unless envelope
            envelope
          end
        end

        # Journal double that fails the first record matching the predicate,
        # simulating a crash between durable admission and reference
        # persistence. Reads pass through unchanged.
        class FlakyJournal < SimpleDelegator
          def initialize(target, &fail_on)
            super(target)
            @fail_on = fail_on
          end

          def record(**keywords)
            raise SystemCallError, "simulated crash before the reference was persisted" if @fail_on.call(keywords)
            __getobj__.record(**keywords)
          end
        end

        def setup
          super
          with_temp_cache do |cache_dir|
            @cache_dir = cache_dir
            @repo = File.join(cache_dir, "candidate")
            FileUtils.mkdir_p(@repo)
            git_in(@repo, "init", "-b", "main")
            git_in(@repo, "config", "user.name", "test")
            git_in(@repo, "config", "user.email", "test@example.com")
            File.write(File.join(@repo, "work.txt"), "candidate work\n")
            git_in(@repo, "add", "work.txt")
            git_in(@repo, "commit", "-m", "candidate base")
          end
          @identity = Molecules::ExecutionIdentityResolver::Identity.new(
            actor: "overseer", role: "coordinator", runtime: "local:test", adapter: "local", process_pid: Process.pid
          )
          @journal = Molecules::EvidenceJournal.new(repo_root: @repo,
            ref: "refs/ace/execution", checkout_root: File.join(@cache_dir, "evidence-co"))
          @coordinator = Organisms::AttemptCoordinator.new(cache_base: @cache_dir, repo_root: @repo,
            journal: @journal, identity_resolver: stub_resolver,
            lifecycle_exclusion: Molecules::LifecycleExclusion.new(root: File.join(@cache_dir, ".exclusion")))
          assignment = Molecules::AssignmentManager.new(cache_base: @cache_dir).create(
            name: "ordinary-merge-consumer", source_config: "job.yaml", task_id: "8wr.t.qkb.1", project_id: PROJECT
          )
          @attempt = @coordinator.start(assignment_id: assignment.id, step: "010", project_id: PROJECT)
          @input = valid_input
          @selectors = {project: PROJECT, assignment: assignment.id, attempt: @attempt.attempt_id,
                        queue_entry: QUEUE_ENTRY, authorization: AUTHORIZATION, request_id: REQUEST_ID}
          @digest = ruled_digest
          @producer = ScriptedProducer.new
        end

        def build_consumer(producer: @producer, journal: @journal)
          OrdinaryMergeConsumer.new(repo_root: @repo, journal: journal, coordinator: @coordinator,
            identity_resolver: stub_resolver, producer: producer)
        end

        def stub_resolver
          resolver = Molecules::ExecutionIdentityResolver.new(adapter: "local")
          resolver.define_singleton_method(:resolve) { @fixed_identity }
          resolver.define_singleton_method(:fixed_identity=) { |value| @fixed_identity = value }
          resolver.fixed_identity = @identity
          resolver
        end

        def dispatch(consumer: build_consumer, overrides: {})
          defaults = {assignment_id: @selectors[:assignment], attempt_id: @selectors[:attempt],
                      project: PROJECT, queue_entry: QUEUE_ENTRY, input: @input,
                      authorization: AUTHORIZATION, request_id: REQUEST_ID}
          consumer.dispatch(**defaults.merge(overrides))
        end

        def poll(consumer: build_consumer)
          consumer.poll(assignment_id: @selectors[:assignment], attempt_id: @selectors[:attempt])
        end

        def ack_envelope(reference: REQUEST_REFERENCE, request_id: REQUEST_ID, input_digest: @digest)
          {"status" => "ok", "data" => valid_ack(input_digest, request_id: request_id, reference: reference)}
        end

        # The canonical request digest per spec ruling r4: the full
        # eight-field immutable binding, never the input document alone.
        # The canonical request digest per spec ruling r4, computed by the
        # SHARED producer/consumer implementation (FixedMergeSchemas).
        def ruled_digest(selectors: @selectors, input: @input)
          Atoms::FixedMergeSchemas.canonical_request_digest(project: selectors[:project],
            assignment: selectors[:assignment], attempt: selectors[:attempt],
            queue_entry: selectors[:queue_entry], authorization: selectors[:authorization],
            request_id: selectors[:request_id], input: input)
        end

        def binding_document
          {reference: REQUEST_REFERENCE, request_id: REQUEST_ID, input_digest: @digest,
           request: {project: PROJECT, assignment: @selectors[:assignment], attempt: @selectors[:attempt],
                     queue_entry: QUEUE_ENTRY, authorization: AUTHORIZATION, input: @input}}
        end

        def delivery_events
          @journal.read_events(@selectors[:assignment]).select do |event|
            event["type"] == "delivery" && event["attempt_id"] == @selectors[:attempt] &&
              event.dig("payload", "stage").to_s.start_with?("ordinary-merge-")
          end
        end

        def result_events
          delivery_events.select { |event| event.dig("payload", "stage") == OrdinaryMergeConsumer::RESULT_STAGE }
        end

        def test_dispatch_records_binding_and_accepts_exact_acknowledgment
          @producer.enqueue(ack_envelope)
          result = dispatch
          assert_equal({state: "accepted", reference: REQUEST_REFERENCE, request_id: REQUEST_ID,
            input_digest: @digest}, result)
          invoked = @producer.requests.first
          assert_equal({project: PROJECT, assignment: @selectors[:assignment], attempt: @selectors[:attempt],
            queue_entry: QUEUE_ENTRY, input_bytes: Atoms::EvidenceDigest.canonical_json(@input),
            authorization: AUTHORIZATION, request_id: REQUEST_ID}, invoked)
          events = delivery_events
          intent = events.find { |event| event.dig("payload", "stage") == OrdinaryMergeConsumer::INTENT_STAGE }
          refute_nil intent
          assert_equal REQUEST_ID, intent.dig("payload", "request_id")
          assert_equal @digest, intent.dig("payload", "input_digest")
          assert_equal @input, intent.dig("payload", "input")
          ack = events.find { |event| event.dig("payload", "stage") == OrdinaryMergeConsumer::ACK_STAGE }
          assert_equal REQUEST_REFERENCE, ack.dig("payload", "reference")
          assert @producer.merge_effect?(REQUEST_ID)
        end

        def test_dispatch_rejects_contract_violating_requests_without_producer_contact
          assert_raises(AttemptErrors::ReceiptRejected) do
            dispatch(overrides: {input: @input.merge("unexpected" => true)})
          end
          assert_raises(AttemptErrors::ReceiptRejected) { dispatch(overrides: {request_id: "bad id!"}) }
          assert_raises(AttemptErrors::ReceiptRejected) { dispatch(overrides: {authorization: ""}) }
          assert_empty @producer.requests
          assert_empty delivery_events
        end

        def test_redispatch_with_identical_binding_reconciles_without_new_intent
          @producer.enqueue(ack_envelope)
          dispatch
          @producer.enqueue(ack_envelope)
          result = dispatch
          assert_equal "accepted", result[:state]
          assert_equal 2, @producer.requests.length
          assert_equal @producer.requests.first, @producer.requests.last
          intents = delivery_events.count { |event| event.dig("payload", "stage") == OrdinaryMergeConsumer::INTENT_STAGE }
          assert_equal 1, intents
          assert @producer.merge_effect?(REQUEST_ID)
        end

        def test_redispatch_with_different_binding_is_forbidden_resubmission
          @producer.enqueue(ack_envelope)
          dispatch
          assert_raises(AttemptErrors::Conflict) do
            dispatch(overrides: {request_id: "req-0002"})
          end
          assert_equal 1, @producer.requests.length
        end

        def test_proven_refusal_closes_intent_and_permits_new_reviewed_request
          @producer.enqueue({"status" => "error",
            "error" => valid_refusal("ordinary_merge_provenance_mismatch", input_digest: @digest)})
          result = dispatch
          assert_equal({state: "refused", code: "ordinary_merge_provenance_mismatch",
            message: "receiver refused the request"}, result)
          closures = result_events.count { |event| event.dig("payload", "outcome") == "refused_no_effect" }
          assert_equal 1, closures
          @producer.enqueue(ack_envelope(reference: "receiver/ordinary/ref-2", request_id: "req-0002",
            input_digest: ruled_digest(selectors: @selectors.merge(request_id: "req-0002"))))
          retried = dispatch(overrides: {request_id: "req-0002"})
          assert_equal({state: "accepted", reference: "receiver/ordinary/ref-2",
            request_id: "req-0002", input_digest: ruled_digest(selectors: @selectors.merge(request_id: "req-0002"))}, retried)
        end

        def test_unavailable_receiver_is_a_blocker_and_never_a_proven_refusal
          @producer.enqueue({"status" => "error", "error" => valid_refusal("ordinary_merge_unavailable")})
          assert_raises(AttemptErrors::EvidenceUnavailable) { dispatch }
          assert_empty result_events
          assert_raises(AttemptErrors::Conflict) { dispatch(overrides: {request_id: "req-0009"}) }
          assert_equal 1, @producer.requests.length
        end

        def test_lost_acknowledgment_after_durable_acceptance_recovers_by_identical_request
          flaky = FlakyJournal.new(@journal) do |keywords|
            keywords.dig(:payload, "stage") == OrdinaryMergeConsumer::ACK_STAGE
          end
          crashing = OrdinaryMergeConsumer.new(repo_root: @repo, journal: flaky, coordinator: @coordinator,
            identity_resolver: stub_resolver, producer: @producer)
          @producer.enqueue(ack_envelope)
          assert_raises(AttemptErrors::EvidenceUnavailable) { dispatch(consumer: crashing) }
          assert_equal 1, @producer.requests.length

          restarted = build_consumer
          @producer.enqueue(ack_envelope)
          @producer.enqueue(valid_status("pending", selectors: {reference: REQUEST_REFERENCE,
                                                                request_id: REQUEST_ID, input_digest: @digest}))
          assert_equal({state: "pending"}, poll(consumer: restarted))
          assert_equal 2, @producer.requests.length
          assert_equal @producer.requests.first, @producer.requests.last
          assert @producer.merge_effect?(REQUEST_ID)
          ack = delivery_events.find { |event| event.dig("payload", "stage") == OrdinaryMergeConsumer::ACK_STAGE }
          refute_nil ack
          assert_equal REQUEST_REFERENCE, ack.dig("payload", "reference")
        end

        def test_poll_recovers_reference_after_restart_and_accepts_exact_terminal_receipt
          @producer.enqueue(ack_envelope)
          dispatch
          restarted = build_consumer
          @producer.enqueue(valid_status("succeeded", receipt: valid_receipt(binding_document), selectors: binding_document))
          result = poll(consumer: restarted)
          assert_equal({state: "succeeded", synchronization_required: false,
            receipt: valid_receipt(binding_document)}, result)
          observed = @producer.statuses.first
          assert_equal({reference: REQUEST_REFERENCE, request_id: REQUEST_ID, project: PROJECT,
            assignment: @selectors[:assignment], attempt: @selectors[:attempt],
            queue_entry: QUEUE_ENTRY, input_digest: @digest}, observed)
          receipts = result_events.count { |event| event.dig("payload", "terminal_status") == "succeeded" }
          assert_equal 1, receipts
        end

        def test_poll_after_terminal_is_read_only_and_idempotent
          @producer.enqueue(ack_envelope)
          dispatch
          @producer.enqueue(valid_status("succeeded", receipt: valid_receipt(binding_document), selectors: binding_document))
          first = poll
          assert_equal "succeeded", first[:state]
          assert_equal 1, @producer.statuses.length
          assert_equal first, poll
          assert_equal 1, @producer.statuses.length
        end

        def test_pending_and_uncertain_never_resubmit_or_repair
          @producer.enqueue(ack_envelope)
          dispatch
          @producer.enqueue(valid_status("pending", selectors: binding_document))
          assert_equal({state: "pending"}, poll)
          @producer.enqueue(valid_status("uncertain", selectors: binding_document))
          assert_equal({state: "uncertain"}, poll)
          assert_raises(AttemptErrors::Conflict) { dispatch(overrides: {request_id: "req-0003"}) }
          assert_equal 1, @producer.requests.length
          assert_equal 2, @producer.statuses.length
          assert_empty result_events
        end

        def test_status_never_presents_refusal_as_a_state
          @producer.enqueue(ack_envelope)
          dispatch
          @producer.enqueue(valid_status("refused", selectors: binding_document))
          assert_raises(AttemptErrors::ReceiptRejected) { poll }
          assert_empty result_events
          @producer.enqueue(valid_status("uncertain", selectors: binding_document))
          assert_equal({state: "uncertain"}, poll)
        end

        def test_altered_receipts_are_rejected_without_journal_mutation
          @producer.enqueue(ack_envelope)
          dispatch
          mutations = {
            "wrong repository identity" => ["remote_observation", "target_repository_identity"],
            "moved remote target" => ["remote_observation", "admission_target_head"],
            "wrong candidate head" => ["remote_observation", "merged_candidate_head"],
            "unjoined merge commit" => ["remote_observation", "resulting_target_head"],
            "unjoined target ref" => ["remote_observation", "target_ref_observed"],
            "unjoined forge" => ["remote_observation", "forge_instance"],
            "unjoined PR identity" => ["remote_observation", "pr_identity_url"]
          }
          mutations.each do |label, path|
            receipt = with_deep_value(valid_receipt(binding_document), path, "e" * 40)
            @producer.enqueue(valid_status("succeeded", receipt: receipt, selectors: binding_document))
            assert_raises(AttemptErrors::ReceiptRejected, label) { poll }
          end
          @producer.enqueue(valid_status("succeeded",
            receipt: with_deep_value(valid_receipt(binding_document), %w[request project], "other"), selectors: binding_document))
          assert_raises(AttemptErrors::ReceiptRejected) { poll }
          @producer.enqueue(valid_status("succeeded",
            receipt: with_deep_value(valid_receipt(binding_document), ["input_digest"], "e" * 64), selectors: binding_document))
          assert_raises(AttemptErrors::ReceiptRejected) { poll }
          @producer.enqueue(valid_status("failed",
            receipt: with_deep_value(valid_receipt(binding_document, outcome: "failed_no_effect"), %w[request attempt], "other-attempt"),
            selectors: binding_document))
          assert_raises(AttemptErrors::ReceiptRejected) { poll }
          assert_empty result_events
          @producer.enqueue(valid_status("succeeded", receipt: valid_receipt(binding_document), selectors: binding_document))
          assert_equal "succeeded", poll[:state]
        end

        def test_already_merged_requires_synchronization_not_another_merge
          @producer.enqueue(ack_envelope)
          dispatch
          @producer.enqueue(valid_status("succeeded",
            receipt: valid_receipt(binding_document, outcome: "already_merged"), selectors: binding_document))
          result = poll
          assert_equal "succeeded", result[:state]
          assert_equal true, result[:synchronization_required]
          assert_raises(AttemptErrors::InvalidState) { dispatch(overrides: {request_id: "req-0004"}) }
          assert_equal 1, @producer.requests.length
        end

        def test_status_command_error_is_never_a_durable_state
          @producer.enqueue(ack_envelope)
          dispatch
          @producer.enqueue(status_error("ordinary_merge_selection_mismatch"))
          assert_raises(AttemptErrors::EvidenceUnavailable) { poll }
          assert_empty result_events
          @producer.enqueue(valid_status("uncertain", selectors: binding_document))
          assert_equal({state: "uncertain"}, poll)
        end

        def test_poll_requires_a_recorded_request
          assert_raises(AttemptErrors::NotFound) { poll }
        end

        def test_dispatch_requires_an_active_managed_attempt
          assert_raises(AttemptErrors::NotFound) do
            dispatch(overrides: {attempt_id: "missing-attempt"})
          end
        end

        def test_poll_rejects_altered_status_envelopes
          @producer.enqueue(ack_envelope)
          dispatch
          @producer.enqueue(with_deep_value(valid_status("succeeded", receipt: valid_receipt(binding_document),
            selectors: binding_document), %w[data reference], "receiver/other/ref"))
          assert_raises(AttemptErrors::ReceiptRejected) { poll }
        end

        # Review r1 Finding A shape tests: the closed outer envelope admits
        # exactly {status, data} for ok and {status, error} for error; every
        # malformed shape is a classified EvidenceUnavailable blocker with no
        # journal mutation beyond the recorded intent.

        def test_outer_unknown_field_is_rejected_without_journal_mutation
          @producer.enqueue(ack_envelope.merge("error" => valid_refusal("ordinary_merge_forbidden")))
          assert_raises(AttemptErrors::EvidenceUnavailable) { dispatch }
          assert_equal 1, @producer.requests.length
          assert_empty delivery_events.select { |event| event.dig("payload", "stage") == OrdinaryMergeConsumer::ACK_STAGE }
          assert_empty result_events
          @producer.enqueue(ack_envelope)
          assert_equal "accepted", dispatch[:state]
          intents = delivery_events.count { |event| event.dig("payload", "stage") == OrdinaryMergeConsumer::INTENT_STAGE }
          assert_equal 1, intents
        end

        def test_ack_data_unknown_field_is_rejected_without_journal_mutation
          @producer.enqueue({"status" => "ok", "data" => valid_ack(@digest).merge("outcome" => "spurious")})
          assert_raises(AttemptErrors::EvidenceUnavailable) { dispatch }
          assert_empty delivery_events.select { |event| event.dig("payload", "stage") == OrdinaryMergeConsumer::ACK_STAGE }
          assert_empty result_events
        end

        def test_pending_with_error_is_malformed_and_never_a_proven_refusal
          @producer.enqueue({"status" => "pending",
            "error" => valid_refusal("ordinary_merge_forbidden", input_digest: @digest)})
          assert_raises(AttemptErrors::EvidenceUnavailable) { dispatch }
          assert_empty result_events
          @producer.enqueue(ack_envelope)
          @producer.enqueue(valid_status("pending", selectors: binding_document))
          assert_equal({state: "pending"}, poll)
          assert_equal 2, @producer.requests.length
          assert_equal @producer.requests.first, @producer.requests.last
        end

        def test_missing_branch_keys_are_classified_blockers
          @producer.enqueue({"status" => "ok"})
          assert_raises(AttemptErrors::EvidenceUnavailable) { dispatch }
          @producer.enqueue({"status" => "error"})
          assert_raises(AttemptErrors::EvidenceUnavailable) { dispatch }
          assert_equal 2, @producer.requests.length
          assert_empty delivery_events.select { |event| event.dig("payload", "stage") == OrdinaryMergeConsumer::ACK_STAGE }
          assert_empty result_events
        end

        def test_status_error_branch_requires_the_error_object
          @producer.enqueue(ack_envelope)
          dispatch
          @producer.enqueue({"status" => "error"})
          assert_raises(AttemptErrors::EvidenceUnavailable) { poll }
          assert_empty result_events
        end

        # Spec ruling r4: the digest covers the full eight-field binding.

        def test_binding_digest_is_key_order_independent_across_redispatch
          @producer.enqueue(ack_envelope)
          dispatch
          @producer.enqueue(ack_envelope)
          result = dispatch(overrides: {input: reverse_keys(@input)})
          assert_equal "accepted", result[:state]
          assert_equal @digest, result[:input_digest]
          assert_equal 2, @producer.requests.length
          intents = delivery_events.count { |event| event.dig("payload", "stage") == OrdinaryMergeConsumer::INTENT_STAGE }
          assert_equal 1, intents
        end

        # Byte-compat proof (PR49 unification): the consumer's recorded digest
        # equals the SHARED producer/consumer implementation
        # (Atoms::FixedMergeSchemas.canonical_request_digest) for identical
        # bindings, and matches an independent inline recomputation over the
        # canonical r4 preimage — the same independent check the producer's
        # fixed_merge_schemas_test applies to its own vectors.
        def test_consumer_digest_is_byte_compatible_with_the_producer_digest
          @producer.enqueue(ack_envelope)
          result = dispatch
          binding_args = {project: PROJECT, assignment: @selectors[:assignment],
                          attempt: @selectors[:attempt], queue_entry: QUEUE_ENTRY,
                          authorization: AUTHORIZATION, request_id: REQUEST_ID}
          shared = Atoms::FixedMergeSchemas.canonical_request_digest(**binding_args.merge(input: @input))
          assert_equal shared, result[:input_digest]
          intent = delivery_events.find { |event| event.dig("payload", "stage") == OrdinaryMergeConsumer::INTENT_STAGE }
          assert_equal shared, intent.dig("payload", "input_digest")
          sort_keys = lambda do |value|
            case value
            when Hash then value.keys.sort.each_with_object({}) { |key, out| out[key] = sort_keys.call(value[key]) }
            when Array then value.map { |item| sort_keys.call(item) }
            else value
            end
          end
          preimage = JSON.generate(sort_keys.call(
            "project" => PROJECT, "assignment" => @selectors[:assignment],
            "attempt" => @selectors[:attempt], "queue_entry" => QUEUE_ENTRY,
            "operation" => "merge", "authorization" => AUTHORIZATION,
            "request_id" => REQUEST_ID, "input" => JSON.parse(JSON.generate(@input))
          ))
          assert_equal Digest::SHA256.hexdigest(preimage), result[:input_digest]
        end

        def test_acknowledgment_with_document_only_digest_is_rejected
          document_only = Atoms::EvidenceDigest.digest(@input)
          refute_equal @digest, document_only
          @producer.enqueue(ack_envelope(input_digest: document_only))
          assert_raises(AttemptErrors::EvidenceUnavailable) { dispatch }
          assert_empty delivery_events.select { |event| event.dig("payload", "stage") == OrdinaryMergeConsumer::ACK_STAGE }
        end

        def test_refusal_with_mismatched_digest_echo_is_never_a_proven_refusal
          document_only = Atoms::EvidenceDigest.digest(@input)
          @producer.enqueue({"status" => "error",
            "error" => valid_refusal("ordinary_merge_forbidden", input_digest: document_only)})
          assert_raises(AttemptErrors::EvidenceUnavailable) { dispatch }
          assert_empty result_events
          @producer.enqueue(ack_envelope)
          @producer.enqueue(valid_status("pending", selectors: binding_document))
          assert_equal({state: "pending"}, poll)
          assert_equal 2, @producer.requests.length
        end

        def test_receipt_with_document_only_digest_is_rejected
          @producer.enqueue(ack_envelope)
          dispatch
          document_only = Atoms::EvidenceDigest.digest(@input)
          @producer.enqueue(valid_status("succeeded",
            receipt: valid_receipt(binding_document, input_digest: document_only), selectors: binding_document))
          assert_raises(AttemptErrors::ReceiptRejected) { poll }
          assert_empty result_events
          @producer.enqueue(valid_status("succeeded", receipt: valid_receipt(binding_document), selectors: binding_document))
          assert_equal "succeeded", poll[:state]
        end
      end
    end
  end
end
