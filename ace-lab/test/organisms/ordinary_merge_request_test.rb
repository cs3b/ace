# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../../ace-assign/test/support/fixed_merge_evidence_fixture"
require "digest"
require "open3"
require "ace/assign/atoms/fixed_merge_schemas"

module Ace
  module Lab
    class OrdinaryMergeRequestTest < Minitest::Test
      HEAD_A = "a" * 40
      HEAD_B = "b" * 40

      def setup
        @dir = File.realpath(Dir.mktmpdir("ordinary-merge", Dir.home))
        @repo = File.join(@dir, "repo")
        FileUtils.mkdir_p(@repo)
        git(@repo, "init", "-b", "main")
        git(@repo, "config", "user.name", "test")
        git(@repo, "config", "user.email", "test@example.com")
        File.write(File.join(@repo, "feature.txt"), "candidate")
        git(@repo, "add", "feature.txt")
        git(@repo, "commit", "-m", "candidate")
        @head = git(@repo, "rev-parse", "HEAD")

        cache = File.join(@dir, "cache")
        @coordinator = Ace::Assign::Organisms::AttemptCoordinator.new(cache_base: cache,
          repo_root: @repo, ordinary_merge_evidence: (@merge_evidence = Ace::Assign::FixedMergeEvidenceFixture.new), journal: Ace::Assign::Molecules::EvidenceJournal.new(repo_root: @repo,
            checkout_root: File.join(@dir, "journal")),
          lifecycle_exclusion: Ace::Assign::Molecules::LifecycleExclusion.new(
            root: File.join(@dir, "exclusion")
          ))
        assignment = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache).create(
          name: "ordinary-merge-test", source_config: "job.yaml", task_id: "8x3.t.xz9",
          project_id: "atlas"
        )
        @attempt = @coordinator.start(assignment_id: assignment.id, step: "010", project_id: "atlas")
        @assignment_id = assignment.id
        @attempt_id = @attempt.attempt_id

        # The installed ordinary receiver mapping and admission policy: the
        # verified local process owner is the configured overseer principal.
        @policy = Molecules::ServicePolicy.new(policy_document)
        config = authorized_for_local(topology_config, ["atlas"])
        @topology = Organisms::TopologyService.from_config(config)

        File.write(input_path, JSON.generate(valid_request))
      end

      def teardown
        FileUtils.rm_rf(@dir)
      end

      def test_admission_produces_the_exact_durable_acknowledgment
        producer = new_producer(ingress: controlled_receiver)
        envelope = producer.request(**request_args)
        assert_equal "ok", envelope.fetch("status")
        data = envelope.fetch("data")
        assert_equal %w[input_digest reference request_id schema type], data.keys.sort
        assert_equal "ace.lab.service.ordinary-merge-ack/v1", data.fetch("schema")
        assert_equal "accepted", data.fetch("type")
        assert_equal "request-1", data.fetch("request_id")
        assert_equal expected_digest, data.fetch("input_digest")
        assert_match(/\Afmr1-[A-Za-z0-9_-]{40,86}\z/, data.fetch("reference"))
        # The reference exists only after the canonical record is durable.
        record = @coordinator.fixed_merge_status(reference: data.fetch("reference"),
          request_id: "request-1", project_id: "atlas", assignment_id: @assignment_id,
          attempt_id: @attempt.attempt_id, queue_entry: "010", input_digest: data.fetch("input_digest"))
        assert_equal "pending", record.fetch("state")
      end

      def test_identical_resubmission_replays_the_original_acknowledgment
        producer = new_producer(ingress: controlled_receiver)
        first = producer.request(**request_args)
        second = producer.request(**request_args)
        assert_equal first.fetch("data").fetch("reference"), second.fetch("data").fetch("reference")
      end

      def test_installed_journal_is_selected_without_requester_cache_and_status_survives_receiver_downtime
        producer = Organisms::OrdinaryMergeRequest.new(topology: @topology, policy: @policy,
          repo_root: @repo, ingress: controlled_receiver)
        accepted = producer.request(**request_args)
        assert_equal "ok", accepted["status"], accepted.inspect
        assert_equal accepted, producer.request(**request_args), "new observation sees admission after its prior pinned tip"
        document = policy_document
        document["ordinary"]["projects"]["atlas"]["admission"] = "disabled"
        status_reader = Organisms::OrdinaryMergeRequest.new(topology: @topology,
          policy: Molecules::ServicePolicy.new(document), repo_root: @dir,
          ingress: ->(**_) { flunk "status contacted receiver" })
        original = ENV["GIT_DIR"]
        ENV["GIT_DIR"] = "/nonexistent/poisoned"
        status = status_reader.status(project: "atlas", assignment: @assignment_id,
          attempt: @attempt_id, queue_entry: "010", reference: accepted.dig("data", "reference"),
          request: "request-1", input_digest: expected_digest, format: "json")
        assert_equal "ok", status["status"], status.inspect
        assert_equal "pending", status.dig("data", "state")
        refute File.exist?(File.join(@repo, ".unused-reader"))
      ensure
        ENV["GIT_DIR"] = original
      end

      def test_missing_installed_journal_never_falls_back_to_cwd_evidence
        accepted = new_producer(ingress: controlled_receiver).request(**request_args)
        document = policy_document
        document["ordinary"]["projects"]["atlas"].delete("journal_repository")
        producer = Organisms::OrdinaryMergeRequest.new(topology: @topology,
          policy: Molecules::ServicePolicy.new(document), repo_root: @repo,
          ingress: ->(**_) { flunk "missing installed source dispatched" })
        status = producer.status(project: "atlas", assignment: @assignment_id, attempt: @attempt_id,
          queue_entry: "010", reference: accepted.dig("data", "reference"), request: "request-1",
          input_digest: expected_digest, format: "json")
        assert_equal "ordinary_merge_unavailable", status.dig("error", "code")
      end

      def test_unknown_or_protected_selectors_refuse_before_effect
        producer = new_producer(ingress: controlled_receiver)
        ["mapping", "scope", "service", "candidate_head", "candidate_generation",
          "expected_generation", "dry_run", "argv", "uid", "socket", "evidence_path",
          "credential_path", "token"].each do |selector|
          envelope = producer.request(**request_args, selector.to_sym => "x")
          assert_equal "error", envelope.fetch("status"), selector
          assert_equal "ordinary_merge_invalid_request", envelope.dig("error", "code"), selector
          assert_nil envelope.dig("error", "input_digest")
        end
        assert_nil @coordinator.fixed_merge_record("request-1")
      end

      def test_operation_other_than_merge_and_malformed_input_refuse
        producer = new_producer(ingress: controlled_receiver)
        envelope = producer.request(**request_args.merge(operation: "publish"))
        assert_equal "ordinary_merge_invalid_request", envelope.dig("error", "code")

        File.write(input_path, "{\"schema\": 1}")
        envelope = producer.request(**request_args)
        assert_equal "ordinary_merge_invalid_request", envelope.dig("error", "code")

        File.write(input_path, "{not json")
        envelope = producer.request(**request_args)
        assert_equal "ordinary_merge_invalid_request", envelope.dig("error", "code")

        File.write(input_path, JSON.generate(valid_request.merge("candidate_head" => "z" * 40)))
        envelope = producer.request(**request_args)
        assert_equal "ordinary_merge_invalid_request", envelope.dig("error", "code")
      end

      def test_evidence_bound_to_another_head_refuses_as_invalid_request
        producer = new_producer(ingress: controlled_receiver)
        document = valid_request
        document["review_evidence"]["reviewed_head"] = "9" * 40
        File.write(input_path, JSON.generate(document))
        envelope = producer.request(**request_args)
        assert_equal "ordinary_merge_invalid_request", envelope.dig("error", "code")
        assert_includes envelope.dig("error", "message"), "reviewed_head"
      end

      def test_non_overseer_principal_is_forbidden_and_unauthenticated_without_identity
        producer = new_producer(ingress: controlled_receiver)
        Molecules::CallerAuthorizer.stub(:local_identity, ["someone-else", "9999"]) do
          envelope = producer.request(**request_args)
          assert_equal "ordinary_merge_forbidden", envelope.dig("error", "code")
        end
        Molecules::CallerAuthorizer.stub(:local_identity, []) do
          envelope = producer.request(**request_args)
          assert_equal "ordinary_merge_unauthenticated", envelope.dig("error", "code")
        end
      end

      def test_rollback_disables_admission_but_preserves_read_only_status
        admitted = new_producer(ingress: controlled_receiver).request(**request_args)
        reference = admitted.fetch("data").fetch("reference")
        document = policy_document
        document["ordinary"]["projects"]["atlas"]["admission"] = "disabled"
        producer = new_producer(ingress: controlled_receiver,
          policy: Molecules::ServicePolicy.new(document))
        envelope = producer.request(**request_args.merge(request_id: "request-2"))
        assert_equal "ordinary_merge_unavailable", envelope.dig("error", "code")
        assert_equal "request-2", envelope.dig("error", "request_id")
        assert envelope.dig("error", "input_digest")
        refute envelope["error"].key?("reference")
        # Read-only status survives rollback for every accepted reference.
        status = producer.status(format: "json", mode: "ordinary-merge",
          reference: reference, request: "request-1", project: "atlas",
          assignment: @assignment_id, attempt: @attempt_id, queue_entry: "010",
          input_digest: admitted.fetch("data").fetch("input_digest"))
        assert_equal "ok", status.fetch("status")
        assert_equal "pending", status.dig("data", "state")
        assert_nil status.dig("data", "receipt")
      end

      def test_lost_receiver_response_is_a_blocker_never_a_refusal
        producer = new_producer(ingress: ->(submission:) {
          raise Molecules::OrdinarySocket::OrdinaryUnavailable, "receiver endpoint unreachable"
        })
        envelope = producer.request(**request_args)
        assert_equal "ordinary_merge_unavailable", envelope.dig("error", "code")
        assert_equal expected_digest, envelope.dig("error", "input_digest")
      end

      def test_valid_receiver_refusals_are_relayed_and_invalid_ones_are_blockers
        refusal = {"status" => "error", "error" => {"schema" =>
          "ace.lab.service.ordinary-merge-refusal/v1", "code" => "ordinary_merge_evidence_invalid",
                                                    "message" => "review reference is stale", "request_id" => "request-1",
                                                    "input_digest" => expected_digest}}
        producer = new_producer(ingress: ->(submission:) { refusal })
        envelope = producer.request(**request_args)
        assert_equal "ordinary_merge_evidence_invalid", envelope.dig("error", "code")
        assert_equal "ace.lab.service.ordinary-merge-refusal/v1", envelope.dig("error", "schema")

        unknown_code = deep_copy(refusal)
        unknown_code["error"]["code"] = "receiver_exploded"
        producer = new_producer(ingress: ->(submission:) { unknown_code })
        envelope = producer.request(**request_args)
        assert_equal "ordinary_merge_unavailable", envelope.dig("error", "code")

        malformed = {"status" => "ok", "data" => {"schema" => "ace.lab.service.ordinary-merge-ack/v1",
                                                  "type" => "accepted", "request_id" => "request-1", "input_digest" => expected_digest,
                                                  "reference" => "../../../etc/passwd"}}
        producer = new_producer(ingress: ->(submission:) { malformed })
        envelope = producer.request(**request_args)
        assert_equal "ordinary_merge_unavailable", envelope.dig("error", "code")
      end

      def test_conflicting_request_id_refuses_and_target_move_refuses
        controlled = controlled_receiver
        producer = new_producer(ingress: controlled)
        producer.request(**request_args)
        envelope = producer.request(**request_args.merge(input: other_input_path))
        assert_equal "ordinary_merge_request_conflict", envelope.dig("error", "code")

        git(@repo, "commit", "--allow-empty", "-m", "advance candidate")
        moved_decision = policy_document.merge("authorizations" =>
          policy_document.fetch("authorizations").merge("decision-9" =>
            policy_document.fetch("authorizations").fetch("decision-1").merge(
              "request_id" => nil, "input_digest" => expected_digest(request_id: "request-9", authorization: "decision-9")
            )))
        moved_producer = new_producer(ingress: controlled, policy: Molecules::ServicePolicy.new(moved_decision))
        envelope = moved_producer.request(**request_args.merge(request_id: "request-9",
          authorization: "decision-9"))
        assert_equal "ordinary_merge_target_changed", envelope.dig("error", "code")
      end

      def test_unknown_attempt_refuses_as_selection_mismatch
        producer = new_producer(ingress: controlled_receiver)
        envelope = producer.request(**request_args.merge(attempt: "atj9999"))
        assert_equal "ordinary_merge_selection_mismatch", envelope.dig("error", "code")
      end

      def test_malformed_receiver_responses_are_classified_without_crashing
        [{"status" => "error"}, {"status" => "error", "error" => {}},
          {"status" => "ok", "data" => nil}, {"status" => "ok", "data" => "invalid"},
          {"status" => "ok", "data" => []}].each do |response|
          producer = new_producer(ingress: ->(submission:) { response })
          envelope = producer.request(**request_args)
          assert_equal "ordinary_merge_unavailable", envelope.dig("error", "code"), response.inspect
          refute envelope.key?("data")
        end
      end

      def test_authorization_mapping_is_exhaustive_before_effect
        producer = new_producer(ingress: controlled_receiver)
        envelope = producer.request(**request_args.merge(authorization: "unrecorded"))
        assert_equal "ordinary_merge_authorization_invalid", envelope.dig("error", "code")

        expired = Molecules::ServicePolicy.new(policy_document.merge("authorizations" =>
          policy_document.fetch("authorizations").merge("decision-1" =>
            policy_document.fetch("authorizations").fetch("decision-1").merge(
              "expires_at" => "2020-01-01T00:00:00Z"
            ))))
        envelope = new_producer(ingress: controlled_receiver, policy: expired).request(**request_args)
        assert_equal "ordinary_merge_authorization_invalid", envelope.dig("error", "code")

        # Review r1 finding A / ruling r4: a decision bound to another
        # operation/project/PR/head — and a decision that is not an ordinary
        # merge decision at all (shape) — is authorization_invalid.
        # Authorization-decision mismatches never map to provenance_mismatch.
        {
          "project_id" => "borealis",
          "pr_url" => "https://forge.example.com/acme/widget/pulls/8",
          "head_ref" => "refs/heads/other-branch",
          "candidate_head" => "9" * 40,
          "base_repository" => "acme/other",
          "queue_entry" => "020"
        }.each do |key, value|
          decision = Molecules::ServicePolicy.new(policy_document.merge("authorizations" =>
            policy_document.fetch("authorizations").merge("decision-1" =>
              policy_document.fetch("authorizations").fetch("decision-1").merge(key => value))))
          envelope = new_producer(ingress: controlled_receiver, policy: decision).request(**request_args)
          assert_equal "ordinary_merge_authorization_invalid", envelope.dig("error", "code"), key
        end

        shape = Molecules::ServicePolicy.new(policy_document.merge("authorizations" =>
          policy_document.fetch("authorizations").merge("decision-1" =>
            policy_document.fetch("authorizations").fetch("decision-1").except("queue_entry"))))
        envelope = new_producer(ingress: controlled_receiver, policy: shape).request(**request_args)
        assert_equal "ordinary_merge_authorization_invalid", envelope.dig("error", "code")
      end

      def test_read_only_status_returns_exact_envelope_and_terminal_receipt
        controlled = controlled_receiver
        producer = new_producer(ingress: controlled)
        ack = producer.request(**request_args)
        reference = ack.fetch("data").fetch("reference")
        digest = ack.fetch("data").fetch("input_digest")
        status_args = {format: "json", mode: "ordinary-merge", reference: reference,
                       request: "request-1", project: "atlas", assignment: @assignment_id,
                       attempt: @attempt_id, queue_entry: "010", input_digest: digest}

        status = producer.status(**status_args)
        assert_equal %w[input_digest receipt reference request_id schema state],
          status.fetch("data").keys.sort
        assert_equal "ace.lab.service.ordinary-merge-status/v1", status.dig("data", "schema")
        assert_equal "pending", status.dig("data", "state")
        assert_nil status.dig("data", "receipt")

        # The receiver begins and settles the fixed effect; status only reads.
        record = @coordinator.fixed_merge_record("request-1")
        @coordinator.begin_fixed_merge_effect("request-1")
        @coordinator.settle_fixed_merge_effect("request-1", terminal_status: "succeeded",
          receipt: build_receipt(record, reference: reference, input_digest: digest))
        status = producer.status(**status_args)
        assert_equal "succeeded", status.dig("data", "state")
        assert_equal "ace.assign.fixed-effect-receipt/v1", status.dig("data", "receipt", "schema")
        assert_equal "merged", status.dig("data", "receipt", "effect", "outcome")
      end

      def test_status_mismatches_answer_identically_without_disclosure
        controlled = controlled_receiver
        producer = new_producer(ingress: controlled)
        ack = producer.request(**request_args)
        digest = ack.fetch("data").fetch("input_digest")
        base = {format: "json", mode: "ordinary-merge", reference: ack.fetch("data").fetch("reference"),
                request: "request-1", project: "atlas", assignment: @assignment_id,
                attempt: @attempt.attempt_id, queue_entry: "010", input_digest: digest}
        mismatches = [
          base.merge(reference: "fmr1-#{"Z" * 40}"),
          base.merge(request: "other-request"),
          base.merge(assignment: "other-assignment"),
          base.merge(attempt: "other-attempt"),
          base.merge(queue_entry: "020"),
          base.merge(input_digest: "9" * 64)
        ]
        envelopes = mismatches.map { |arguments| producer.status(**arguments) }
        envelopes.each do |envelope|
          assert_equal "error", envelope.fetch("status")
          assert_equal "ordinary_merge_selection_mismatch", envelope.dig("error", "code")
          assert_equal "ace.lab.service.ordinary-merge-status-error/v1", envelope.dig("error", "schema")
        end
        assert_equal 1, envelopes.map { |e| e.dig("error", "message") }.uniq.size
        unknown_selector = producer.status(**base.merge(mapping: "m"))
        assert_equal "ordinary_merge_invalid_request", unknown_selector.dig("error", "code")
        wrong_digest_shape = producer.status(**base.merge(input_digest: "XYZ"))
        assert_equal "ordinary_merge_invalid_request", wrong_digest_shape.dig("error", "code")
      end

      def test_immutable_digest_binds_selectors_input_authorization_and_request_id
        producer = new_producer(ingress: controlled_receiver)
        envelope = producer.request(**request_args)
        assert_equal expected_digest, envelope.dig("data", "input_digest")
        # Spec ruling r4: key-order independence — a value-identical input
        # document in any key order digests identically.
        shuffled = deep_copy(valid_request)
        shuffled = shuffled.to_a.reverse.to_h
        File.write(input_path, JSON.generate(shuffled))
        replay = producer.request(**request_args)
        assert_equal expected_digest, replay.dig("data", "input_digest")
        File.write(input_path, JSON.generate(valid_request))
        # Selector/authorization/request-ID sensitivity via the shared
        # canonical implementation (the one the consumer re-derives with).
        refute_equal expected_digest, expected_digest(request_id: "request-2")
        refute_equal expected_digest, expected_digest(authorization: "decision-2")
        refute_equal expected_digest, expected_digest(project: "borealis")
      end

      def test_infra_failures_emit_the_unavailable_envelope_never_a_crash
        # Review r1 finding B: an unreadable canonical evidence ref is a
        # caller-side blocker with the exact unavailable envelope.
        broken = Object.new
        broken.define_singleton_method(:fixed_merge_record) do |_request_id|
          raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "canonical evidence ref is unreadable"
        end
        broken.define_singleton_method(:fixed_merge_status) do |**_|
          raise Ace::Assign::AttemptErrors::EvidenceUnavailable, "canonical evidence ref is unreadable"
        end
        broken.define_singleton_method(:service_attempt) { |_binding| flunk "must fail before selection" }
        envelope = Organisms::OrdinaryMergeRequest.new(topology: @topology, policy: @policy,
          coordinator: broken, repo_root: @repo, ingress: controlled_receiver).request(**request_args)
        assert_equal "ordinary_merge_unavailable", envelope.dig("error", "code")
        assert_equal "ace.lab.service.ordinary-merge-refusal/v1", envelope.dig("error", "schema")
        refute envelope["error"].key?("reference")
        status = Organisms::OrdinaryMergeRequest.new(topology: @topology, policy: @policy,
          coordinator: broken, repo_root: @repo, ingress: controlled_receiver).status(
            format: "json", mode: "ordinary-merge", reference: "fmr1-#{"A" * 40}",
            request: "request-1", project: "atlas", assignment: @assignment_id,
            attempt: @attempt_id, queue_entry: "010", input_digest: "e" * 64
          )
        assert_equal "ordinary_merge_unavailable", status.dig("error", "code")
        assert_equal "ace.lab.service.ordinary-merge-status-error/v1", status.dig("error", "schema")

        # A malformed installed ordinary section is configuration failure.
        malformed = Molecules::ServicePolicy.new(policy_document.merge("ordinary" =>
          {"projects" => {"atlas" => {"receiver_id" => "r"}}}))
        envelope = new_producer(ingress: controlled_receiver, policy: malformed).request(**request_args)
        assert_equal "ordinary_merge_unavailable", envelope.dig("error", "code")
        assert envelope.dig("error", "message").is_a?(String)
        refute envelope.dig("error", "message").empty?
      end

      private

      def new_producer(ingress:, policy: @policy)
        Organisms::OrdinaryMergeRequest.new(topology: @topology, policy: policy,
          coordinator: @coordinator, repo_root: @repo, ingress: ingress)
      end

      # A controlled receiver: the production composition (installed by
      # gad.b) authenticates and admits through the public Assign coordinator
      # API and owns no ledger; the controlled receiver here does exactly
      # that, so tests prove the producer against the real primitive.
      def controlled_receiver
        coordinator = @coordinator
        policy = @policy
        ->(submission:) do
          receiver = policy.ordinary_receiver!(submission.fetch("project_id"))
          identities = Molecules::CallerAuthorizer.local_identity
          unless receiver.is_a?(Hash) && identities.include?(receiver.fetch("principal"))
            return {"status" => "error", "error" => {"schema" =>
              "ace.lab.service.ordinary-merge-refusal/v1", "code" => "ordinary_merge_forbidden",
                                                     "message" => "not the configured ordinary overseer",
                                                     "request_id" => submission.fetch("request_id"), "input_digest" => nil}}
          end
          admitted = coordinator.admit_fixed_merge_request(submission.merge(
            "principal" => receiver.fetch("principal"),
            "caller_uid" => Process.uid,
            "execution_identity" => {"checkout_id" => "checkout-1",
                                     "worktree_id" => "worktree-1", "branch" => "feat/x"}
          ))
          {"status" => "ok", "data" => {
            "schema" => "ace.lab.service.ordinary-merge-ack/v1", "type" => "accepted",
            "request_id" => admitted.fetch("request_id"),
            "input_digest" => admitted.fetch("input_digest"),
            "reference" => admitted.fetch("reference")
          }}
        end
      end

      def request_args
        {project: "atlas", assignment: @assignment_id, attempt: @attempt_id,
         queue_entry: "010", operation: "merge", input: input_path,
         authorization: "decision-1", request_id: "request-1"}
      end

      def input_path
        File.join(@dir, "input.json")
      end

      def other_input_path
        path = File.join(@dir, "other-input.json")
        File.write(path, JSON.generate(valid_request.merge("forge" => "other-forge")))
        path
      end

      def expected_digest(request_id: "request-1", authorization: "decision-1", project: "atlas")
        Ace::Assign::Atoms::FixedMergeSchemas.canonical_request_digest(
          project: project, assignment: @assignment_id, attempt: @attempt_id,
          queue_entry: "010", authorization: authorization,
          request_id: request_id, input: JSON.parse(JSON.generate(valid_request))
        )
      end

      def policy_document
        @policy_document ||= {
          "operations" => {},
          "authorizations" => {
            "decision-1" => {
              "operation" => "merge", "project_id" => "atlas",
              "assignment_id" => @assignment_id, "attempt_id" => @attempt_id,
              "queue_entry" => "010", "input_digest" => expected_digest,
              "forge" => "forgejo", "pr_url" => "https://forge.example.com/acme/widget/pulls/7",
              "head_repository" => "acme/widget", "head_ref" => "refs/heads/feat/x",
              "candidate_head" => @head, "base_repository" => "acme/widget",
              "base_ref" => "refs/heads/main", "expected_base_head" => HEAD_B,
              "expires_at" => (Time.now.utc + 3600).iso8601
            }
          },
          "ordinary" => {
            "projects" => {
              "atlas" => {"receiver_id" => "ordinary-receiver", "socket_path" => "/fixture/ordinary.sock",
                          "journal_repository" => @repo, "journal_ref" => "refs/ace/execution",
                          "receiver_uid" => Process.uid, "principal" => Molecules::CallerAuthorizer.local_identity.first, "admission" => "enabled"}
            }
          }
        }
      end

      def valid_request
        {
          "schema" => "ace.lab.service.ordinary-merge-request/v1",
          "forge" => "forgejo",
          "pr_url" => "https://forge.example.com/acme/widget/pulls/7",
          "head_repository" => "acme/widget",
          "head_ref" => "refs/heads/feat/x",
          "candidate_head" => @head,
          "base_repository" => "acme/widget",
          "base_ref" => "refs/heads/main",
          "expected_base_head" => HEAD_B,
          "method" => "merge",
          "review_evidence" => {
            "schema" => "ace.review.acceptance-reference/v1",
            "reference" => "review-123", "reviewer" => "independent-reviewer",
            "verdict" => "approved", "reviewed_head" => @head,
            "recorded_at" => "2026-10-12T10:00:00Z", "record_sha256" => "c" * 64
          },
          "test_evidence" => [{
            "schema" => "ace.test.execution-reference/v1",
            "reference" => "test-run-9", "candidate_head" => @head,
            "command" => "bin/ace-test ace-lab fast", "result" => "passed",
            "recorded_at" => "2026-10-12T10:30:00Z", "receipt_sha256" => "d" * 64
          }]
        }
      end

      def build_receipt(record, reference:, input_digest:)
        document = record.fetch("request")
        {
          "schema" => "ace.assign.fixed-effect-receipt/v1",
          "reference" => reference,
          "request_id" => "request-1",
          "input_digest" => input_digest,
          "terminal_status" => "succeeded",
          "request" => {
            "project" => record.fetch("project_id"), "assignment" => record.fetch("assignment_id"),
            "attempt" => record.fetch("attempt_id"), "queue_entry" => record.fetch("queue_entry"),
            "operation" => "merge", "authorization" => record.fetch("authorization"),
            "input" => document
          },
          "producer" => {"receiver_id" => record.fetch("receiver_id"),
                         "principal" => record.fetch("principal"),
                         "configuration_sha256" => record.fetch("configuration_sha256")},
          "effect" => {"started_at" => "2026-10-12T11:00:00Z", "finished_at" => "2026-10-12T11:01:00Z",
                       "outcome" => "merged", "failure_code" => nil, "no_effect_evidence" => nil},
          "remote_observation" => {
            "forge_instance" => document.fetch("forge"),
            "pr_identity_url" => document.fetch("pr_url"),
            "target_repository_identity" => document.fetch("base_repository"),
            "target_ref_observed" => document.fetch("base_ref"),
            "merged_candidate_head" => document.fetch("candidate_head"),
            "admission_target_head" => document.fetch("expected_base_head"),
            "resulting_target_head" => "1" * 40,
            "merge_commit" => "1" * 40,
            "checkout_id" => record.dig("execution_identity", "checkout_id"),
            "worktree_id" => record.dig("execution_identity", "worktree_id"),
            "branch" => record.dig("execution_identity", "branch")
          }
        }
      end

      def deep_copy(value)
        JSON.parse(JSON.generate(value))
      end

      def git(dir, *argv)
        out, stderr, status = Open3.capture3("git", *argv, chdir: dir)
        raise "git failed: #{stderr}" unless status.success?
        out.strip
      end
    end
  end
end
