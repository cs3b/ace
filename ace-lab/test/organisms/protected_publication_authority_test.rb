# frozen_string_literal: true
require_relative "../support/protected_service_boundary_fixture"

class ProtectedPublicationAuthorityTest < Minitest::Test
  include ProtectedServiceBoundaryFixture

  def test_actual_original_dispatch_challenge_and_one_continuation
    fixture do
      submission, input = prepared_submission
      transport = start_service_server
      original = Object.new
      original.define_singleton_method(:call) { |name, params, **options| transport.call(name, params, **options.merge(timeout: 60)) }
      params = submission.merge("mapping_id" => "mapping", "service_id" => "executor", "worker_process_binding" => @worker)
      claim = original.call("request_service", params, mutation_id: "publication-claim", upload_parts: [input], purpose: :service_input).data
      binding = submission.slice("assignment_id", "attempt_id", "candidate_generation", "head", "request_id").merge("mapping_id" => "mapping",
        "claim_binding" => claim.fetch("claim_binding"), "expected_generation" => claim.fetch("generation"))
      started = original.call("begin_dispatch", binding, mutation_id: "publication-begin", upload_parts: [input], purpose: :service_input).data
      assert_equal @executor, started.fetch("executor_process_binding")
      need = {"schema" => "ace.publication-otp-need/v1", "classification" => "otp-required",
        "request_id" => submission.fetch("request_id"), "input_digest" => submission.fetch("input_digest"),
        "claim_binding" => claim.fetch("claim_binding"), "candidate_generation" => submission.fetch("candidate_generation"),
        "head" => @head, "registry" => "https://rubygems.org", "gem_name" => "ace-hitl", "version" => "1.2.3",
        "artifact_digest" => "b" * 64, "dispatch_event_digest" => started.fetch("dispatch_event_digest"), "previous_challenge_digest" => nil}
      bytes = JSON.generate(need)
      binding = binding.merge("input_digest" => submission.fetch("input_digest"), "expected_generation" => started.fetch("generation"))
      challenge = original.call("publication_challenge", binding.merge("receipt_sha256" => Digest::SHA256.hexdigest(bytes)),
        mutation_id: "publication-need", upload_parts: [bytes], purpose: :receipt_artifacts).data
      assert_equal "otp_pending", challenge.fetch("dispatch_phase")
      continued = original.call("publication_continue", binding.merge("expected_generation" => challenge.fetch("generation"),
        "challenge_digest" => challenge.fetch("publication_challenge_digest")), mutation_id: "publication-continue").data
      assert_equal "issuing", continued.fetch("dispatch_phase")
      assert_equal "permitted", continued.fetch("invocation")
      duplicate = original.call("publication_continue", binding.merge("expected_generation" => challenge.fetch("generation"),
        "challenge_digest" => challenge.fetch("publication_challenge_digest")), mutation_id: "publication-continue").data
      assert_equal "already_issued", duplicate.fetch("invocation")
      assert_equal 1, @journal.read_events("assignment").count { |event| event["type"] == "service_publication_issuing" }
      record = @journal.service_request(submission.fetch("request_id"))
      artifact = {"schema" => "ace.publication-result/v1", "publication" => JSON.parse(input).fetch("publication"),
        "target" => record.fetch("target"), "classification" => "succeeded", "code" => "registry_exact_artifact",
        "request_id" => record.fetch("request_id"), "input_digest" => record.fetch("input_digest"), "claim_binding" => record.fetch("claim_binding")}
      evidence = JSON.generate(artifact)
      receipt = record.slice(*Ace::Assign::Molecules::EvidenceJournal::TERMINAL_BINDING_FIELDS).merge("outcome" => "succeeded",
        "evidence" => [{"ref" => "publication-result", "sha256" => Digest::SHA256.hexdigest(evidence)}])
      receipt_bytes = JSON.generate(receipt)
      completed = original.call("complete_service", binding.except("expected_generation", "input_digest").merge(
        "receipt_sha256" => Digest::SHA256.hexdigest(receipt_bytes)), mutation_id: "publication-complete",
        upload_parts: [receipt_bytes, evidence], purpose: :receipt_artifacts).data
      assert_equal "succeeded", completed.fetch("state")
      assert_equal "succeeded", completed.fetch("receipt").fetch("outcome")
      assert_equal 1, completed.fetch("receipt").fetch("evidence").size
      assert_equal "succeeded", @journal.service_request(record.fetch("request_id")).fetch("state")
    end
  end
end
