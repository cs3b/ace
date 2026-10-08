# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../support/endcap_result_owner_fixture"
require "ace/assign/authority/server"
require "ace/assign/authority/client"
module Ace
  module Assign
    class ProtectedCandidateReplayTest < AceAssignTestCase
      include EndcapResultOwnerFixture

      # This case admits every candidate via the real public transfer, rather
      # than the fixture's metadata-only candidate convenience.
      def candidate(_number); end

      def start_candidate_server
        @kernel.peer_identity = @worker
        @server = Authority::Server.new(authority_id: "authority", lifecycle: @router,
          deployment: @deployment, kernel: @kernel, composition: "services")
        wire = Object.new
        wire.define_singleton_method(:root_path!) { |*_, **_| true }
        %i[socket_identity read write deadline].each do |name|
          wire.define_singleton_method(name) { |*args, **options| WIRE.public_send(name, *args, **options) }
        end
        @server.define_singleton_method(:wire) { wire }
        @owner = Thread.new { @server.serve }
        Timeout.timeout(3) { sleep 0.005 until File.socket?(@service.fetch("socket_path")) }
        client_kernel = Kernel.new
        client_kernel.peer_identity = @service.slice("uid", "gid", "groups")
        @client = Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: client_kernel)
      end

      def test_actual_candidate_counter_replay_revalidates_original_caller_and_exact_raw_and_normalized_bytes
        fixture do
          start_candidate_server
          path = File.join(@root, "candidate.bundle")
          git(@journal.repo_root, "bundle", "create", path, "HEAD")
          bytes = File.binread(path)
          params = {"assignment_id" => "assignment", "attempt_id" => @attempt, "head" => @head,
            "candidate_generation" => 0, "expected_generation" => generation}
          send_candidate = ->(id, selected, body = bytes) {
            @client.call("submit_candidate", selected, mutation_id: id, upload_parts: [body], purpose: :candidate, timeout: 30)
          }
          first = send_candidate.call("first", params)
          assert_equal 1, first.data.fetch("candidate_generation")
          first_ref = @journal.ref_value
          replay = send_candidate.call("first", params)
          assert replay.replayed
          assert_equal first.data, replay.data
          assert_equal first_ref, @journal.ref_value
          assert_raises(AttemptErrors::EvidenceUnavailable) { send_candidate.call("first", params, bytes + "changed") }
          assert_equal first_ref, @journal.ref_value
          assert_raises(AttemptErrors::EvidenceUnavailable) { send_candidate.call("stale", params.merge("expected_generation" => generation)) }
          assert_equal first_ref, @journal.ref_value
          next_params = params.merge("candidate_generation" => 1, "expected_generation" => generation)
          second = send_candidate.call("second", next_params)
          assert_equal 2, second.data.fetch("candidate_generation")
          selected = @journal.ref_value
          assert_equal first.data, send_candidate.call("first", params).data
          assert_equal selected, @journal.ref_value
          @kernel.peer_identity = @kernel.capture(92)
          assert_raises(AttemptErrors::EvidenceUnavailable) { send_candidate.call("first", params) }
          assert_equal selected, @journal.ref_value
          @kernel.peer_identity = @worker
          @kernel.dead << @worker.fetch("pid")
          assert_raises(AttemptErrors::EvidenceUnavailable) { send_candidate.call("first", params) }
          assert_equal selected, @journal.ref_value
        end
      end
    end
  end
end
