# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../support/prepared_registration_fixture"
require_relative "../../support/ordinary_native_observation"
require "ace/assign/authority/ordinary_lifecycle"
require "ace/assign/authority/ordinary_server"
require "ace/assign/authority/ordinary_client"
require "ace/assign/authority/router"
require "ace/assign/authority/command_execution"

module Ace
  module Assign
    # ordinary_release_artifacts_test also reopens this class to reuse the
    # real native-start/candidate/review fixture without a second evidence owner.
    class OrdinaryReviewsTest < AceAssignTestCase
      Admission = OrdinaryNativeObservation

      # Root launcher/policy observation is controlled here; the command
      # state machine, imported candidate and exact-prefix proof are real.
      class CommandAdmission
        attr_accessor :definition, :enabled, :scope_owner, :before_admit
        def initialize = @enabled = true
        def command_request!(**)
          @view.read!(reference: @definition.fetch("candidate").fetch("reference")) if @definition["candidate"]
          hook, @before_admit = @before_admit, nil
          hook&.call
          @definition
        end
        def with_command_scope(reference:, deadline:)
          @scope_owner.with_candidate_reference_scope(reference: reference, deadline: deadline) do |view|
            @view = view
            begin
              yield
            ensure
              @view = nil
            end
          end
        end
        def command_launcher!(peer:, **) = peer
        def command_claim!(**)
          command_request!
          true
        end
        def command_child!(child:, **) = child
        def command_test_evidence!(definition:, deadline:, historical: false)
          raise AttemptErrors::ReceiptRejected unless @enabled && definition == @definition
          @scope_owner.with_candidate_reference(reference: definition.fetch("candidate").fetch("reference"),
            deadline: deadline, historical: historical) do |candidate, *|
            raise AttemptErrors::ReceiptRejected unless candidate.slice("head", "tree") == definition.fetch("source")
          end
          true
        end
      end

      class CampaignPolicy
        attr_accessor :enabled
        POLICY = {"revision" => "fixture-v1", "minimum_rounds" => 3, "clean_rounds" => 2,
          "required_scopes" => ["full"], "required_checks" => ["tests"]}.freeze
        def initialize = @enabled = true
        def verify_unchanged!
          raise AttemptErrors::EvidenceUnavailable, "installed campaign policy revoked" unless @enabled
          true
        end
        def with(_reference)
          verify_unchanged!
          value = yield({"delivery" => POLICY}, self)
          verify_unchanged!
          value
        end
      end

      def test_canonical_campaign_start_pin_and_restart_preserve_original_contract_and_budget
        fixture(campaign: true) do
          register_and_start(producer_start: @base_head)
          submit_candidate
          params = selection.merge("pane" => "w1:pS", "expected_generation" => 2,
            "contract" => "Preserve exact candidate and independently review it.", "profile" => "delivery")
          @admission.selected = "producer"
          assert_raises(AttemptErrors::EvidenceUnavailable) { @client.call("campaign_start", params, mutation_id: "campaign-start") }
          @admission.selected = "supervisor"
          started = @client.call("campaign_start", params, mutation_id: "campaign-start")
          assert_equal started.data, @client.call("campaign_start", params, mutation_id: "campaign-start").data
          # A campaign-associated candidate cannot satisfy merge admission by
          # consuming an ordinary direct review: strict refusal applies until
          # complete canonical campaign acceptance exists. The read transport
          # surfaces the server's rejection as evidence_unavailable.
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            @client.call("merge_evidence", selection.merge("test_execution_ids" => ["tests-1"]))
          end
          pin = selection.merge("pane" => "w1:pS", "expected_generation" => 3, "round_id" => "round-1",
            "scope_identity" => {"full" => {"preset" => "code-valid", "subjects" => ["diff:#{@base_head}..#{@head}"]}})
          pinned = @client.call("campaign_pin", pin, mutation_id: "pin-1")
          assert_equal false, pinned.data.fetch("recorded_complete")
          assert_equal 0, pinned.data.fetch("completed_rounds")
          assert_equal pinned.data, @client.call("campaign_pin", pin, mutation_id: "pin-1").data
          assert @client.call("campaign_pin", pin, mutation_id: "pin-1").replayed
          @owner.instance_variable_set(:@campaign, make_campaign_owner)
          status = @client.call("campaign_status", selection).data
          assert_equal started.data.fetch("campaign_id"), status.fetch("campaign_id")
          assert_equal 0, status.fetch("completed_rounds")
          refute status.fetch("accepted")
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            @client.call("campaign_start", params.merge("expected_generation" => 4), mutation_id: "new-campaign")
          end
          review = selection.merge("pane" => "w1:pS", "expected_generation" => 4,
            "reviewer_assignment_id" => "reviewer", "reviewer_attempt_id" => "reviewer-run")
          assert_raises(AttemptErrors::EvidenceUnavailable) { @client.call("assign_review", review, mutation_id: "unbudgeted-review") }
          assigned = @client.call("assign_review", review.merge("campaign" => {"round_id" => "round-1", "scope" => "full"}),
            mutation_id: "campaign-review").data
          assert_equal "execution-1", assigned.fetch("campaign").fetch("execution_id")
          start = selection.merge("pane" => "w1:p2", "expected_generation" => 5, "review_id" => assigned.fetch("review_id"))
          assert_raises(AttemptErrors::EvidenceUnavailable) { @client.call("campaign_begin", start, mutation_id: "provider-begin") }
          @admission.selected = "reviewer"
          @admission.head = @base_head
          assert_raises(AttemptErrors::EvidenceUnavailable) { @client.call("campaign_begin", start, mutation_id: "provider-begin") }
          @admission.head = @head
          begun = @client.call("campaign_begin", start, mutation_id: "provider-begin")
          refute begun.replayed
          assert_equal assigned.fetch("campaign").fetch("session_binding"), begun.data.fetch("session_binding")
          replay = @client.call("campaign_begin", start, mutation_id: "provider-begin")
          assert replay.replayed
          assert_equal begun.data, replay.data
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            @client.call("campaign_begin", start.merge("expected_generation" => 6), mutation_id: "second-provider-begin")
          end
          prefix = @journal.ref_value
          assert_equal 1, @journal.read_events("producer", commit: prefix).count { |event| event.dig("payload", "operation") == "campaign_begin" }
          @campaign_policy.enabled = false
          assert_raises(AttemptErrors::EvidenceUnavailable) { @client.call("campaign_status", selection) }
        end
      end

      def test_review_context_ingestion_binds_campaign_selection_and_matching_begin
        fixture(campaign: true) do
          register_and_start(producer_start: @base_head)
          submit_candidate
          params = selection.merge("pane" => "w1:pS", "expected_generation" => 2,
            "contract" => "Preserve exact candidate and independently review it.", "profile" => "delivery")
          @admission.selected = "producer"
          assert_raises(AttemptErrors::EvidenceUnavailable) { @client.call("campaign_start", params, mutation_id: "campaign-start") }
          @admission.selected = "supervisor"
          started = @client.call("campaign_start", params, mutation_id: "campaign-start")
          assert_equal started.data, @client.call("campaign_start", params, mutation_id: "campaign-start").data
          pin = selection.merge("pane" => "w1:pS", "expected_generation" => 3, "round_id" => "round-1",
            "scope_identity" => {"full" => {"preset" => "code-valid", "subjects" => ["diff:#{@base_head}..#{@head}"]}})
          pinned = @client.call("campaign_pin", pin, mutation_id: "pin-1")
          assert_equal false, pinned.data.fetch("recorded_complete")
          @owner.instance_variable_set(:@campaign, make_campaign_owner)
          status = @client.call("campaign_status", selection).data
          refute status.fetch("accepted")
          review = selection.merge("pane" => "w1:pS", "expected_generation" => 4,
            "reviewer_assignment_id" => "reviewer", "reviewer_attempt_id" => "reviewer-run")
          assert_raises(AttemptErrors::EvidenceUnavailable) { @client.call("assign_review", review, mutation_id: "unbudgeted-review") }
          assigned = @client.call("assign_review", review.merge("campaign" => {"round_id" => "round-1", "scope" => "full"}),
            mutation_id: "campaign-review").data
          start = selection.merge("pane" => "w1:p2", "expected_generation" => 5, "review_id" => assigned.fetch("review_id"))
          assert_raises(AttemptErrors::EvidenceUnavailable) { @client.call("campaign_begin", start, mutation_id: "provider-begin") }
          @admission.selected = "reviewer"
          @admission.head = @base_head
          assert_raises(AttemptErrors::EvidenceUnavailable) { @client.call("campaign_begin", start, mutation_id: "provider-begin") }
          @admission.head = @head
          @client.call("campaign_begin", start, mutation_id: "provider-begin")
          own = {"assignment_id" => "reviewer", "attempt_id" => "reviewer-run", "pane" => "w1:p2"}
          prompt = "complete campaign context " * 20_000
          assert prompt.bytesize > 64 * 1024, "fixture prompt must exceed the ordinary artifact budget"
          campaign_ref = assigned.fetch("campaign").slice("campaign_id", "round_id", "scope", "execution_id")
          bytes = review_bytes("assignment_id" => "reviewer", "attempt_id" => "reviewer-run",
            "operation" => "review-collect",
            "review" => {"head" => @head, "verdict" => "approved", "reviewer" => {"actor" => Etc.getpwuid.name},
              "review_id" => assigned.fetch("review_id"), "campaign" => campaign_ref},
            "checks" => [{"name" => "review-execution", "verdict" => "passed"}],
            "artifacts" => [{"path" => "system-prompt.md", "sha256" => Digest::SHA256.hexdigest(prompt)}])
          context = own.merge("head" => @head, "receipt_sha256" => Digest::SHA256.hexdigest(bytes),
            "review_id" => assigned.fetch("review_id"), "producer_assignment_id" => "producer")
          @client.call("queue_finish", own.merge("expected_generation" => 1, "step" => "010.01"),
            mutation_id: "reviewer-progress", upload_parts: ["Collected campaign context."], purpose: :artifacts)
          submitted = @client.call("submit_review_context", context.merge("expected_generation" => 2),
            mutation_id: "reviewer-context", upload_parts: [bytes, prompt], purpose: :review_context).data
          assert submitted.fetch("result_id")
          assert_equal "running", submitted.fetch("state")
          duplicate = @client.call("submit_review_context", context.merge("expected_generation" => 2),
            mutation_id: "reviewer-context", upload_parts: [bytes, prompt], purpose: :review_context)
          assert duplicate.replayed
          refused = assert_raises(AttemptErrors::EvidenceUnavailable) do
            @client.call("submit_review_context", context.merge("expected_generation" => 3),
              mutation_id: "second-context", upload_parts: [bytes, prompt], purpose: :review_context)
          end
          assert refused.message.include?("conflict"), "fresh second submission must conflict, got: #{refused.message}"
          @admission.selected = "supervisor"
          @client.call("finish", own.merge("pane" => "w1:pS", "head" => @head, "expected_generation" => 3,
            "result_id" => submitted.fetch("result_id"), "receipt_digest" => submitted.fetch("receipt_digest")), mutation_id: "finish-reviewer")
          reference = {"review_id" => assigned.fetch("review_id"),
            "reviewer_assignment_id" => "reviewer", "reviewer_attempt_id" => "reviewer-run",
            "result_id" => submitted.fetch("result_id"), "receipt_digest" => submitted.fetch("receipt_digest")}
          prefix = @journal.ref_value
          producer_events = @journal.read_events("producer", commit: prefix).select { |event| event["attempt_id"] == "producer-run" }
          read_context = nil
          @owner.with_review_collection!(events: producer_events, commit: prefix, reference: reference) do |proof, reader|
            assert_equal "review-collect", proof.fetch("operation")
            artifact = proof.fetch("artifacts").first
            read_context = reader.call(artifact)
          end
          assert_equal prompt, read_context, "round ingestion must reuse the exact canonical prompt bytes"
        end
      end

      def test_cancelled_campaign_selection_settles_authorization_failure_and_allows_reselection
        fixture(campaign: true) do
          register_and_start(producer_start: @base_head)
          submit_candidate
          @admission.selected = "supervisor"
          @client.call("campaign_start", selection.merge("pane" => "w1:pS", "expected_generation" => 2,
            "contract" => "Preserve exact candidate and independently review it.", "profile" => "delivery"), mutation_id: "campaign-start")
          @client.call("campaign_pin", selection.merge("pane" => "w1:pS", "expected_generation" => 3, "round_id" => "round-1",
            "scope_identity" => {"full" => {"preset" => "code-valid", "subjects" => ["diff:#{@base_head}..#{@head}"]}}), mutation_id: "pin-1")
          @owner.instance_variable_set(:@campaign, make_campaign_owner)
          review = selection.merge("pane" => "w1:pS", "expected_generation" => 4,
            "reviewer_assignment_id" => "reviewer", "reviewer_attempt_id" => "reviewer-run",
            "campaign" => {"round_id" => "round-1", "scope" => "full"})
          first = @client.call("assign_review", review, mutation_id: "campaign-review").data
          cancelled = @client.call("cancel_review", selection.merge("pane" => "w1:pS", "expected_generation" => 5,
            "review_id" => first.fetch("review_id")), mutation_id: "cancel-first").data
          assert_equal first.fetch("review_id"), cancelled.fetch("review_id")
          reassigned = @client.call("assign_review", review.merge("expected_generation" => 6), mutation_id: "campaign-review-2").data
          assert reassigned.fetch("review_id")
          assert_equal first.fetch("campaign").fetch("campaign_id"), reassigned.fetch("campaign").fetch("campaign_id")
          refute_equal first.fetch("campaign").fetch("execution_id"), reassigned.fetch("campaign").fetch("execution_id"),
            "a revoked selection must not inherit the cancelled execution reservation"
          status = @client.call("campaign_status", selection).data
          assert_equal 0, status.fetch("completed_rounds")
        end
      end

      def test_merge_requires_canonical_successful_test_execution_and_rechecks_before_effect
        fixture do
          register_and_start
          submit_candidate
          @admission.selected = "supervisor"
          assigned = assign_review
          @admission.selected = "reviewer"
          accept_review(assigned)
          @admission.selected = "supervisor"
          params = selection.merge("test_execution_ids" => ["tests-1"])
          assert_raises(AttemptErrors::EvidenceUnavailable) { @client.call("merge_evidence", params) }
          execute_test_command
          projection = @client.call("merge_evidence", params).data
          assert_equal "tests-1", projection.fetch("test_evidence").first.fetch("reference")
          record = fixed_record(projection)
          coordinator = Organisms::AttemptCoordinator.new(repo_root: @journal.repo_root,
            journal: @journal, ordinary_merge_evidence: @owner)
          forged = Marshal.load(Marshal.dump(record))
          forged.fetch("request").fetch("review_evidence")["record_sha256"] = "f" * 64
          assert_raises(AttemptErrors::ReceiptRejected) { coordinator.admit_fixed_merge_request(forged) }
          assert_nil coordinator.fixed_merge_record("merge-1")
          missing = Marshal.load(Marshal.dump(record))
          missing.fetch("request").fetch("test_evidence").first["reference"] = "missing-command"
          assert_raises(AttemptErrors::ReceiptRejected) { coordinator.admit_fixed_merge_request(missing) }
          assert_nil coordinator.fixed_merge_record("merge-1")
          accepted = coordinator.admit_fixed_merge_request(record)
          assert_equal accepted.fetch("reference"), coordinator.admit_fixed_merge_request(record).fetch("reference")
          @command_admission.enabled = false
          assert_raises(AttemptErrors::ReceiptRejected) { coordinator.admit_fixed_merge_request(record) }
          assert_raises(AttemptErrors::ReceiptRejected) { coordinator.begin_fixed_merge_effect("merge-1") }
          assert_equal "pending", coordinator.fixed_merge_record("merge-1").fetch("state")
          @command_admission.enabled = true
          coordinator.begin_fixed_merge_effect("merge-1")
          @command_admission.enabled = false
          effects = 0
          assert_raises(AttemptErrors::ReceiptRejected) { coordinator.with_fixed_merge_evidence(accepted) { effects += 1 } }
          assert_equal 0, effects
        end
      end

      def test_candidate_reference_resolves_only_current_authentic_canonical_selection
        fixture do
          register_and_start
          submit_candidate
          prefix = @journal.ref_value
          events = @journal.read_events("producer", commit: prefix).select { |event| event["attempt_id"] == "producer-run" }
          reference = @owner.candidate_reference_at!(events: events, commit: prefix, head: @head, generation: 1)
          response = @client.call("candidate_reference", {"assignment_id" => "producer", "attempt_id" => "producer-run"})
          assert_equal reference, response.data
          assert_equal prefix, @journal.ref_value
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            @client.call("candidate_reference", {"assignment_id" => "producer", "attempt_id" => "producer-run"}, mutation_id: "not-a-read")
          end
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 10
          @owner.with_candidate_reference(reference: reference, deadline: deadline) do |candidate, origin, commit|
            assert_equal @head, candidate.fetch("head")
            assert_equal prefix, commit
            assert_equal "producer", origin.fetch("assignment_id")
            bytes = @journal.bounded_blob(candidate.fetch("bundle_ref"), commit: commit, max_bytes: Authority::CandidateTransfer::MAX_BYTES)
            assert_equal candidate.fetch("sha256"), Digest::SHA256.hexdigest(bytes)
          end
          escaped = nil
          @owner.with_candidate_reference_scope(reference: reference, deadline: deadline) do |view|
            escaped = view
            other = Thread.new do
              assert_raises(AttemptErrors::EvidenceUnavailable) { view.read!(reference: reference) }
            end
            assert other.join(2), "reader must refuse another thread without waiting on lifecycle locks"
            @owner.with_candidate_reference(reference: reference, deadline: deadline) { |candidate, *| assert_equal @head, candidate.fetch("head") }
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              @owner.with_merge_scope(record: reference, deadline: deadline, exclusive: true) { flunk }
            end
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { escaped.read!(reference: reference) }
          assert_raises(ArgumentError) do
            @owner.with_candidate_reference(reference: reference.merge("head" => @head), deadline: deadline) { flunk }
          end
          assert_raises(AttemptErrors::Conflict) do
            @owner.with_candidate_reference(reference: reference.merge("acceptance_event_digest" => "f" * 64), deadline: deadline) { flunk }
          end
          assert_raises(AttemptErrors::Conflict) do
            @owner.with_candidate_reference(reference: reference.merge("candidate_generation" => 2), deadline: deadline) { flunk }
          end
          @admission.revoked = true
          assert_raises(AttemptErrors::UnauthorizedIdentity) do
            @owner.with_candidate_reference(reference: reference, deadline: deadline) { flunk }
          end
        end
      end

      def test_concurrent_candidate_change_refuses_admit_and_later_claim_without_reversed_locks
        fixture do
          register_and_start
          submit_candidate
          reference = candidate_reference
          @command_admission.definition = {"candidate" => {"reference" => reference}, "argv" => ["bin/ace-test", "feat"]}
          entered, proceed = Queue.new, Queue.new
          @command_admission.before_admit = -> { entered << true; Timeout.timeout(30) { proceed.pop } }
          request = {"project_id" => "atlas", "operation" => "command_admit", "mutation_id" => "race-admit",
            "params" => {"execution_id" => "race", "selection" => {"candidate" => reference}}}
          command = Thread.new do
            begin
              @commands.dispatch(request: request, peer: {"uid" => 0}, role: :worker,
                deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30)
            rescue StandardError => error
              error
            end
          end
          Timeout.timeout(30) { entered.pop }
          submit_candidate(generation: 2, candidate_generation: 1, mutation: "candidate-race2")
          proceed << true
          assert command.join(30), "candidate change and command admission deadlocked"
          assert_instance_of AttemptErrors::Conflict, command.value
          assert_empty @journal.read_events("command-race", commit: @journal.ref_value)
          reference = candidate_reference(generation: 2)
          @command_admission.definition["candidate"]["reference"] = reference
          request["params"]["selection"]["candidate"] = reference
          admitted = @commands.dispatch(request: request, peer: {"uid" => 0}, role: :worker,
            deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30)
          assert_equal "admitted", admitted.fetch(:data).fetch("phase")
          submit_candidate(generation: 3, candidate_generation: 2, mutation: "candidate-race3")
          assert_raises(AttemptErrors::Conflict) do
            @commands.dispatch(request: request.merge("operation" => "command_claim", "mutation_id" => "race-claim",
              "params" => {"execution_id" => "race", "caller" => {}}), peer: {"uid" => 0}, role: :worker,
              deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30)
          end
          assert_equal 1, @journal.read_events("command-race", commit: @journal.ref_value).size
        ensure
          proceed << true if proceed
          command&.join(1)
        end
      end

      def test_historical_test_proof_keeps_exact_original_candidate_while_current_merge_refuses_it
        fixture do
          register_and_start
          submit_candidate
          @admission.selected = "supervisor"
          assigned = assign_review
          @admission.selected = "reviewer"
          accept_review(assigned)
          execute_test_command
          original = candidate_reference
          source = @command_admission.definition.fetch("source")
          @admission.selected = "supervisor"
          params = selection.merge("test_execution_ids" => ["tests-1"])
          assert @client.call("merge_evidence", params).data.fetch("test_evidence").any?
          submit_candidate(generation: 4, candidate_generation: 1, mutation: "advance-after-test")
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30
          proof = @commands.test_evidence_at!(execution_id: "tests-1", commit: @journal.ref_value,
            head: source.fetch("head"), tree: source.fetch("tree"), candidate_reference: original,
            deadline: deadline, historical: true)
          assert_equal "tests-1", proof.fetch("reference")
          assert_raises(AttemptErrors::Conflict) do
            @commands.test_evidence_at!(execution_id: "tests-1", commit: @journal.ref_value,
              head: source.fetch("head"), tree: source.fetch("tree"), candidate_reference: original, deadline: deadline)
          end
          assert_raises(AttemptErrors::ReceiptRejected) do
            @commands.test_evidence_at!(execution_id: "tests-1", commit: @journal.ref_value,
              head: source.fetch("head"), tree: source.fetch("tree"), candidate_reference: candidate_reference(generation: 2),
              deadline: deadline, historical: true)
          end
          @admission.selected = "supervisor"
          assert_raises(AttemptErrors::EvidenceUnavailable) { @client.call("merge_evidence", params) }
          @admission.revoked = true
          assert_raises(AttemptErrors::UnauthorizedIdentity) do
            @commands.test_evidence_at!(execution_id: "tests-1", commit: @journal.ref_value,
              head: source.fetch("head"), tree: source.fetch("tree"), candidate_reference: original,
              deadline: deadline, historical: true)
          end
        end
      end

      def test_same_agent_session_or_native_process_cannot_be_relabelled_independent
        fixture do
          producer = @admission.bindings.fetch("producer")
          reviewer = @admission.bindings.fetch("reviewer")
          assert @owner.send(:ordinary_independent_agents!, producer, reviewer)
          assert_raises(AttemptErrors::ReceiptRejected) do
            @owner.send(:ordinary_independent_agents!, producer, reviewer.merge("process_identity" => producer.fetch("process_identity")))
          end
          assert_raises(AttemptErrors::ReceiptRejected) do
            session = producer.fetch("agent_session").merge("value" => producer.dig("agent_session", "value").upcase)
            @owner.send(:ordinary_independent_agents!, producer, reviewer.merge("agent_session" => session))
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            @owner.send(:ordinary_independent_agents!, producer, reviewer.except("agent_session"))
          end
        end
      end

      def test_two_real_starts_same_account_accept_exact_review_and_restart_revalidates_bytes
        fixture do
          register_and_start
          candidate = submit_candidate
          assert_equal candidate, submit_candidate
          @admission.head = @base_head
          @admission.selected = "supervisor"
          assigned = assign_review
          assert_equal Etc.getpwuid.name, assigned.fetch("reviewer_actor")
          @admission.selected = "reviewer"
          exported = @client.call("export_candidate", selection.merge("pane" => "w1:p2", "review_id" => assigned.fetch("review_id")), download: true, purpose: :candidate)
          assert_equal candidate.fetch("sha256"), Digest::SHA256.hexdigest(exported.parts.fetch(0))
          @admission.head = @head
          accepted = accept_review(assigned)
          assert accepted.data.fetch("receipt_digest")
          assert accept_review(assigned).replayed
          prefix = @journal.ref_value
          events = @journal.read_events("producer", commit: prefix).select { |event| event["attempt_id"] == "producer-run" }
          proof = @owner.review_at!(events: events, commit: prefix, head: @head, generation: 1)
          assert_equal assigned.fetch("reviewer_origin"), proof.dig("review_binding", "reviewer_origin")
          assert_equal review_bytes, @journal.blob(proof.fetch("original_receipt_ref"), commit: prefix)
          assert_equal "running", @journal.derived_attempts("producer").first.state
          @admission.selected = "supervisor"
          @client.call("cancel_review", selection.merge("pane" => "w1:pS", "review_id" => assigned.fetch("review_id"), "expected_generation" => 4), mutation_id: "cancel")
          assert_raises(AttemptErrors::ReceiptRejected) do
            prefix = @journal.ref_value
            @owner.review_at!(events: @journal.read_events("producer", commit: prefix).select { |event| event["attempt_id"] == "producer-run" }, commit: prefix, head: @head, generation: 1)
          end
          @admission.selected = "reviewer"
          assert_raises(AttemptErrors::EvidenceUnavailable) { accept_review(assigned) }
        end
      end

      def test_self_review_missing_agent_session_wrong_attempt_and_wrong_caller_refuse
        fixture do
          register_and_start
          submit_candidate
          @admission.selected = "supervisor"
          assert_raises(AttemptErrors::EvidenceUnavailable) { assign_review(reviewer: "producer") }
          assert_raises(AttemptErrors::EvidenceUnavailable) { assign_review(reviewer: "missing") }
          assigned = assign_review
          @admission.selected = "producer"
          assert_raises(AttemptErrors::EvidenceUnavailable) { accept_review(assigned, pane: "w1:p1") }
          @admission.selected = "reviewer"
          assert_raises(AttemptErrors::EvidenceUnavailable) { accept_review(assigned, changes: {"head" => "f" * 40}) }
          assert_raises(AttemptErrors::EvidenceUnavailable) { accept_review(assigned, changes: {"review" => {"head" => @head, "verdict" => "approved", "reviewer" => {"actor" => "invented"}}}) }
          before = @journal.ref_value
          original_execution = @admission.method(:execution!)
          @admission.define_singleton_method(:execution!) do |**options|
            @bindings["reviewer"] = @bindings.fetch("reviewer").merge("agent_session" => {"agent" => "pi", "kind" => "id", "value" => SecureRandom.uuid})
            original_execution.call(**options)
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { accept_review(assigned) }
          assert_equal before, @journal.ref_value
          assert_equal 3, @journal.authority_generation(@journal.read_events("producer").select { |event| event["attempt_id"] == "producer-run" })
        end
      end

      def test_missing_or_changed_canonical_report_refuses_and_new_candidate_revokes_old_review
        fixture do
          register_and_start
          submit_candidate
          @admission.selected = "supervisor"
          assigned = assign_review
          @admission.selected = "reviewer"
          accepted = accept_review(assigned).data
          path = accepted.fetch("review_receipt").fetch("artifacts").first.fetch("path")
          original = @journal.method(:blob)
          @journal.define_singleton_method(:blob) { |name, **options| name == path ? "corrupt" : original.call(name, **options) }
          assert_raises(AttemptErrors::EvidenceUnavailable) { @client.call("review_status", selection) }
          @journal.define_singleton_method(:blob, original)
          assert @client.call("review_status", selection).data.fetch("accepted")
          @admission.selected = "producer"
          submit_candidate(generation: 4, candidate_generation: 1, mutation: "candidate2")
          prefix = @journal.ref_value
          events = @journal.read_events("producer", commit: prefix).select { |event| event["attempt_id"] == "producer-run" }
          historical = @owner.review_at_reference!(events: events, commit: prefix, review_id: assigned.fetch("review_id"), head: @head)
          assert_equal 1, historical.fetch("candidate_generation")
          assert_equal accepted.fetch("receipt_digest"), historical.fetch("receipt_digest")
          assert_raises(AttemptErrors::ReceiptRejected) do
            @owner.review_at_reference!(events: events, commit: prefix, review_id: assigned.fetch("review_id"), head: "f" * 40)
          end
          @admission.selected = "reviewer"
          assert_raises(AttemptErrors::EvidenceUnavailable) { accept_review(assigned) }
          @admission.selected = "supervisor"
          @client.call("cancel_review", selection.merge("pane" => "w1:pS", "review_id" => assigned.fetch("review_id"),
            "expected_generation" => 5), mutation_id: "revoke-historical")
          prefix = @journal.ref_value
          events = @journal.read_events("producer", commit: prefix).select { |event| event["attempt_id"] == "producer-run" }
          assert_raises(AttemptErrors::ReceiptRejected) do
            @owner.review_at_reference!(events: events, commit: prefix, review_id: assigned.fetch("review_id"), head: @head)
          end
        end
      end

      def test_collection_reads_only_assigned_terminal_execution_and_never_implies_approval
        fixture do
          register_and_start
          submit_candidate
          @admission.selected = "supervisor"
          assigned = assign_review
          @admission.selected = "reviewer"
          own = {"assignment_id" => "reviewer", "attempt_id" => "reviewer-run", "pane" => "w1:p2"}
          @client.call("queue_finish", own.merge("expected_generation" => 1, "step" => "010.01"),
            mutation_id: "reviewer-progress", upload_parts: ["Collected independent reports."], purpose: :artifacts)
          bytes = review_bytes("assignment_id" => "reviewer", "attempt_id" => "reviewer-run", "operation" => "review-collect",
            "review" => nil, "checks" => [{"name" => "review-execution", "verdict" => "passed"}])
          submitted = @client.call("submit_result", own.merge("head" => @head, "expected_generation" => 2,
            "receipt_sha256" => Digest::SHA256.hexdigest(bytes)), mutation_id: "reviewer-result",
            upload_parts: [bytes, "Independent review report."], purpose: :receipt_artifacts).data
          reference = assigned.slice("review_id", "reviewer_assignment_id", "reviewer_attempt_id")
            .merge(submitted.slice("result_id", "receipt_digest"))
          read = lambda do |&block|
            prefix = @journal.ref_value
            events = @journal.read_events("producer", commit: prefix).select { |event| event["attempt_id"] == "producer-run" }
            @owner.with_review_collection!(events: events, commit: prefix, reference: reference, &block)
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { read.call { flunk } }
          @admission.selected = "supervisor"
          @client.call("finish", own.merge("pane" => "w1:pS", "head" => @head, "expected_generation" => 3,
            "result_id" => submitted.fetch("result_id"), "receipt_digest" => submitted.fetch("receipt_digest")), mutation_id: "finish-reviewer")
          escaped = nil
          artifact = nil
          read.call do |proof, reader|
            assert_equal "review-collect", proof.fetch("operation")
            assert_equal assigned.fetch("reviewer_origin"), proof.dig("execution_binding", "reviewer_origin")
            assert_equal "running", @journal.derived_attempts("producer").first.state
            artifact = proof.fetch("artifacts").first
            assert_equal "Independent review report.", reader.call(artifact)
            assert_raises(AttemptErrors::EvidenceUnavailable) { reader.call(artifact.merge("sha256" => "f" * 64)) }
            escaped = reader
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { escaped.call(artifact) }
          [KeyError, TypeError].each do |type|
            error = type.new("consumer contract bug")
            caught = assert_raises(type) { read.call { |_proof, reader| escaped = reader; raise error } }
            assert_same error, caught
            assert_raises(AttemptErrors::EvidenceUnavailable) { escaped.call(artifact) }
          end
          refute @client.call("review_status", selection).data.fetch("accepted")
          original = @journal.method(:blob)
          @journal.define_singleton_method(:blob) { |name, **options| name == artifact.fetch("path") ? "corrupt" : original.call(name, **options) }
          assert_raises(AttemptErrors::EvidenceUnavailable) { read.call { flunk } }
          @journal.define_singleton_method(:blob, original)
          reference["reviewer_attempt_id"] = "forged"
          assert_raises(AttemptErrors::ReceiptRejected) { read.call { flunk } }
          reference["reviewer_attempt_id"] = "reviewer-run"
          %w[result_id receipt_digest].each do |key|
            original_value = reference.fetch(key)
            reference[key] = key == "receipt_digest" ? "f" * 64 : "wrong-result"
            assert_raises(AttemptErrors::ReceiptRejected) { read.call { flunk } }
            reference[key] = original_value
          end
          @client.call("cancel_review", selection.merge("pane" => "w1:pS", "review_id" => assigned.fetch("review_id"),
            "expected_generation" => 3), mutation_id: "cancel-collected")
          assert_raises(AttemptErrors::ReceiptRejected) { read.call { flunk } }
        end
      end

      private

      def candidate_reference(generation: 1)
        prefix = @journal.ref_value
        events = @journal.read_events("producer", commit: prefix).select { |event| event["attempt_id"] == "producer-run" }
        @owner.candidate_reference_at!(events: events, commit: prefix, head: @head, generation: generation)
      end

      def execute_test_command
        prefix = @journal.ref_value
        events = @journal.read_events("producer", commit: prefix).select { |event| event["attempt_id"] == "producer-run" }
        reference = @owner.candidate_reference_at!(events: events, commit: prefix, head: @head, generation: 1)
        @command_admission.definition = {"purpose" => "test", "source" => {"head" => @head, "tree" => git(@journal.repo_root, "rev-parse", "HEAD^{tree}").strip},
          "candidate" => {"reference" => reference},
          "argv" => ["bin/ace-test", "fast"], "executable_sha256" => "a" * 64,
          "executor" => {"uid" => 1002, "cwd" => "/immutable/candidate"}}
        launcher = {"pid" => 22, "uid" => 0, "started_at" => "launcher-birth", "host" => "fixture"}
        kernel = {"pid" => 33, "uid" => 1002, "started_at" => "child-birth", "host" => "fixture"}
        child = {"kernel_identity" => kernel, "root_witness" => kernel.merge("cwd" => "/immutable/candidate"), "witnessed_by" => launcher}
        {"command_admit" => {"selection" => {"candidate" => reference}}, "command_claim" => {"caller" => {}}, "command_bind" => {"child" => child},
          "command_complete" => {"result" => {"exit_status" => 0, "signal" => nil}}}.each do |operation, extra|
          @commands.dispatch(request: {"project_id" => "atlas", "operation" => operation, "mutation_id" => operation,
            "params" => {"execution_id" => "tests-1"}.merge(extra)}, peer: launcher, role: :worker,
            deadline: Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30)
        end
      end
      def fixed_record(projection)
        document = {"schema" => "ace.lab.service.ordinary-merge-request/v1", "forge" => "forgejo",
          "pr_url" => "https://forge.invalid/atlas/code/pulls/1", "head_repository" => "atlas/code", "head_ref" => "refs/heads/worker",
          "candidate_head" => @head, "base_repository" => "atlas/code", "base_ref" => "refs/heads/main", "expected_base_head" => @head,
          "method" => "merge"}.merge(projection.slice("review_evidence", "test_evidence"))
        digest = Atoms::FixedMergeSchemas.canonical_request_digest(project: "atlas", assignment: "producer", attempt: "producer-run",
          queue_entry: "010.01", authorization: "decision-1", request_id: "merge-1", input: document)
        {"request_id" => "merge-1", "project_id" => "atlas", "assignment_id" => "producer", "attempt_id" => "producer-run",
          "queue_entry" => "010.01", "operation" => "merge", "authorization" => "decision-1", "input_digest" => digest,
          "request" => document, "principal" => "supervisor", "caller_uid" => Process.uid, "receiver_id" => "ordinary",
          "configuration_sha256" => "e" * 64, "execution_identity" => {"checkout_id" => "canonical", "worktree_id" => "main", "branch" => "main"}}
      end

      def selection
        {"assignment_id" => "producer", "attempt_id" => "producer-run", "head" => @head, "candidate_generation" => 1}
      end
      def submit_candidate(generation: 1, candidate_generation: 0, mutation: "candidate")
        @admission.selected = "producer"
        @client.call("submit_candidate", selection.merge("candidate_generation" => candidate_generation,
          "pane" => "w1:p1", "expected_generation" => generation), mutation_id: mutation,
          upload_parts: [@candidate], purpose: :candidate).data
      end
      def assign_review(reviewer: "reviewer")
        @client.call("assign_review", selection.merge("pane" => "w1:pS", "expected_generation" => 2,
          "reviewer_assignment_id" => reviewer, "reviewer_attempt_id" => "#{reviewer}-run"), mutation_id: "assign-#{reviewer}").data
      end
      def review_bytes(changes = {})
        JSON.generate({"assignment_id" => "producer", "attempt_id" => "producer-run", "project_id" => "atlas", "scope" => "010.01",
          "operation" => "review", "producer" => {"actor" => Etc.getpwuid.name, "role" => "worker", "runtime" => "herdr"},
          "head" => @head, "verdict" => "succeeded", "checks" => [{"name" => "review executed", "verdict" => "passed"}],
          "review" => {"head" => @head, "verdict" => "approved", "reviewer" => {"actor" => Etc.getpwuid.name}},
          "artifacts" => [{"path" => "report.md", "sha256" => Digest::SHA256.hexdigest("Independent review report.")}]}.merge(changes))
      end
      def accept_review(assigned, pane: "w1:p2", changes: {})
        bytes = review_bytes(changes)
        @client.call("accept_review", selection.merge("pane" => pane, "review_id" => assigned.fetch("review_id"),
          "expected_generation" => 3, "receipt_sha256" => Digest::SHA256.hexdigest(bytes)), mutation_id: "accept",
          upload_parts: [bytes, "Independent review report."], purpose: :receipt_artifacts)
      end
      def register_and_start(producer_start: @head)
        %w[producer reviewer].each do |name|
          @admission.selected = "supervisor"
          work = PreparedRegistrationFixture.build(root: @inputs, scope: "010.01", definition: {
            "session_id" => name, "project_id" => "atlas", "task_id" => "8xf.t.ei9.0", "name" => name,
            "created_at" => "2026-10-16T00:00:00Z", "source_config" => "job.yaml"})
          @client.call("register_assignment", work.header(expected_generation: 0).merge("pane" => "w1:pS"),
            mutation_id: "register-#{name}", upload_parts: [work.bundle], purpose: :candidate)
          @admission.selected = name
          @admission.head = name == "reviewer" ? @base_head : producer_start
          @client.call("start_attempt", {"assignment_id" => name, "attempt_id" => "#{name}-run", "expected_generation" => 0,
            "head" => @admission.head, "pane" => @admission.bindings.fetch(name).fetch("pane"), "scope" => "010.01"}, mutation_id: "start-#{name}")
        end
        @admission.head = @head
      end
      def fixture(campaign: false, **owner_options)
        Dir.mktmpdir("ordinary-review-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0700, root)
          repository, @inputs, scratch = %w[journal inputs scratch].map { |part| File.join(root, part) }
          FileUtils.mkdir_p([repository, @inputs, scratch], mode: 0700)
          git(repository, "init", "-b", "main")
          git(repository, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-m", "candidate")
          @base_head = git(repository, "rev-parse", "HEAD").strip
          if campaign
            File.write(File.join(repository, "example.txt"), "Candidate context.\n")
            git(repository, "add", "example.txt")
          end
          git(repository, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "--allow-empty", "-m", "candidate change")
          @head = git(repository, "rev-parse", "HEAD").strip
          git(repository, "bundle", "create", File.join(root, "candidate.bundle"), "refs/heads/main")
          @candidate = File.binread(File.join(root, "candidate.bundle"))
          @journal = Molecules::EvidenceJournal.new(repo_root: repository, checkout_root: File.join(root, "checkout"))
          service = {"uid" => Process.uid, "gid" => Process.gid, "socket_path" => File.join(root, "owner.sock"), "state_root" => root}
          @admission = Admission.new(service)
          @admission.head = @head
          child = Process.spawn("/bin/sleep", "60")
          process = Ace::Runtime::Molecules::ProcessIdentity.new
          @admission.bindings = %w[producer reviewer supervisor].each_with_index.to_h do |name, index|
            [name, {"runtime" => "herdr", "session" => "w1", "pane" => ["w1:p1", "w1:p2", "w1:pS"][index],
              "agent" => "pi", "agent_session" => {"agent" => "pi", "kind" => "id", "value" => SecureRandom.uuid},
              "process_identity" => process.capture(index == 1 ? child : Process.pid)}]
          end
          @command_admission = CommandAdmission.new
          @commands = Authority::CommandExecution.new(project: "atlas", journal: @journal, admission: @command_admission)
          if campaign
            @campaign_root = File.join(root, "campaign-repository")
            @campaign_store = File.join(root, "campaign-store")
            FileUtils.mkdir_p([@campaign_root, @campaign_store], mode: 0o700)
            @campaign_policy = CampaignPolicy.new
          end
          @owner = Authority::OrdinaryLifecycle.new(project: "atlas", admission: @admission, journal: @journal,
            exclusion: Molecules::LifecycleExclusion.new(root: File.join(root, "exclusion")), input_root: @inputs, command_evidence: @commands,
            campaign: campaign ? make_campaign_owner : nil, **owner_options)
          @command_admission.scope_owner = @owner
          server = Authority::OrdinaryServer.new(admission: @admission, lifecycle: Authority::Router.new(handlers: [@owner]))
          thread = Thread.new { server.serve }
          Timeout.timeout(3) { sleep 0.005 until File.socket?(service.fetch("socket_path")) }
          @client = Authority::OrdinaryClient.new(project_id: "atlas", service: service, scratch_root: scratch, verify_selection: -> {})
          yield
        ensure
          server&.request_stop
          server&.stop
          assert thread.join(3), "ordinary review server must drain" if thread
          Process.kill("TERM", child) if child
          Process.wait(child) if child
        end
      end
      def make_campaign_owner
        Authority::OrdinaryCampaignOwner.new(repository: @campaign_root, store_root: @campaign_store,
          policy: {"path" => "/etc/lab/campaign-policy.json", "bytes" => 100, "sha256" => "a" * 64},
          verify_selection: -> { raise AttemptErrors::UnauthorizedIdentity if @admission.revoked }, consumer: @campaign_policy)
      end
      def git(path, *arguments)
        output, error, status = Open3.capture3("/usr/bin/git", "-C", path, *arguments)
        raise error unless status.success?
        output
      end
    end
  end
end
