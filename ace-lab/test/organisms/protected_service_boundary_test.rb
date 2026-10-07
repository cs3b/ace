# frozen_string_literal: true
require_relative "../support/protected_service_boundary_fixture"

class ProtectedServiceBoundaryTest < Minitest::Test
  include ProtectedServiceBoundaryFixture

  def test_actual_concurrent_first_claim_has_one_dispatch_and_one_effect
    fixture do
      submission, bytes = prepared_submission
      original = start_service_server
      ready, release, invocations = Queue.new, Queue.new, Queue.new
      client = Object.new
      client.define_singleton_method(:call) do |name, params, **options|
        if name == "request_service"
          ready << true
          release.pop
        end
        original.call(name, params, **options.merge(timeout: 60))
      end
      handler = controlled_handler(invocations)
      threads = []
      Ace::Lab::Molecules::GrantResolver.stub(:trusted_document, @document) do
        threads = 2.times.map do
          Thread.new { receiver(client, handler).execute(submission: submission, peer: @worker,
            input_bytes: bytes, mutation_id: "same-original-request") }
        end
        Timeout.timeout(10) { 2.times { ready.pop } }
        2.times { release << true }
        results = Timeout.timeout(120) { threads.map(&:value) }
        assert results.any? { |result| result["state"] == "succeeded" }, results.inspect
        assert_equal 1, invocations.size
        assert_equal "succeeded", @journal.service_request("service-request").fetch("state")
        chain = @journal.read_events("assignment")
        assert_equal 1, chain.count { |event| event["type"] == "service_claim" }
        assert_equal 1, chain.count { |event| event["type"] == "service_transition" && event.dig("payload", "state") == "uncertain" }
        assert_equal 1, chain.count { |event| event["type"] == "authority_mutation" && event.dig("payload", "operation") == "begin_dispatch" && event.dig("payload", "data", "invocation") == "permitted" }
        changed = receiver(original, handler).execute(submission: submission.merge("target" => {"resource" => "other"}),
          peer: @worker, input_bytes: bytes, mutation_id: "same-original-request")
        assert_equal "refused", changed.fetch("state")
        assert_equal 1, invocations.size
      end
    ensure
      threads&.each { |thread| thread.kill if thread.alive? }
    end
  end

  def test_second_listener_refuses_without_changing_active_endpoint
    fixture do
      client = start_service_server
      before = Ace::Runtime::Molecules::ProtectedSocket.socket_identity(@service.fetch("socket_path"))
      second = Ace::Assign::Authority::Server.new(authority_id: "authority", lifecycle: @router,
        deployment: @deployment, kernel: @kernel, composition: "services")
      original_wire = @server.send(:wire)
      second.define_singleton_method(:wire) { original_wire }
      assert_raises(Ace::Assign::AttemptErrors::Conflict) { second.serve }
      assert_equal before, Ace::Runtime::Molecules::ProtectedSocket.socket_identity(@service.fetch("socket_path"))
      assert @owner.alive?
      refusal = assert_raises(Ace::Assign::AttemptErrors::EvidenceUnavailable) do
        client.call("service_status", {"assignment_id" => "assignment", "attempt_id" => @attempt,
          "candidate_generation" => 1, "head" => @head, "request_id" => "missing-service"}, timeout: 60)
      end
      assert_match(/refused \(unauthorized\)/, refusal.message)
      assert_equal before, Ace::Runtime::Molecules::ProtectedSocket.socket_identity(@service.fetch("socket_path"))
    end
  end
end
