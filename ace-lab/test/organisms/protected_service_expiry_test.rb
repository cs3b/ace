# frozen_string_literal: true
require_relative "../support/protected_service_boundary_fixture"

class ProtectedServiceExpiryTest < Minitest::Test
  include ProtectedServiceBoundaryFixture

  def test_actual_original_completion_after_lease_expiry_records_truth_without_new_permission
    fixture do
      submission, bytes = prepared_submission
      client = start_service_server
      invocations = Queue.new
      handler = controlled_handler(invocations, expire: true)
      Ace::Lab::Molecules::GrantResolver.stub(:trusted_document, @document) do
        result = receiver(client, handler).execute(submission: submission, peer: @worker, input_bytes: bytes,
          mutation_id: "original-before-expiry")
        assert_equal "succeeded", result.fetch("state")
        assert_equal 1, invocations.size
        assert_equal "succeeded", @journal.service_request("service-request").fetch("state")
        assert_raises(SecurityError) { @policy.prepare!(@journal.service_request("service-request"), input_bytes: bytes) }
        before = @journal.ref_value
        replay = receiver(client, handler).execute(submission: submission, peer: @worker, input_bytes: bytes,
          mutation_id: "original-before-expiry")
        assert_equal "succeeded", replay.fetch("state")
        assert_equal before, @journal.ref_value
        assert_equal 1, invocations.size
        denied = receiver(client, handler).execute(submission: submission.merge("request_id" => "new-after-expiry",
          "expected_generation" => generation), peer: @worker, input_bytes: bytes, mutation_id: "fresh-after-expiry")
        assert_equal "uncertain", denied.fetch("state")
        assert_nil @journal.service_request("new-after-expiry")
        assert_equal before, @journal.ref_value
        assert_equal 1, invocations.size
        assert @owner.alive?, "an authenticated policy refusal must not terminate the authority listener"
        status = client.call("service_status", submission.slice("assignment_id", "attempt_id", "candidate_generation", "head", "request_id"), timeout: 60)
        assert_equal "succeeded", status.data.fetch("state")
      end
    end
  end

end
