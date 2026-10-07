# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/launch_driver"

module Ace
  module Assign
    class ReviewDriverTest < AceAssignTestCase
      WIRE = Ace::Runtime::Molecules::ProtectedSocket
      def fixture
        @driver = Authority::LaunchDriver.allocate
        @driver.instance_variable_set(:@mapping_id, "mapping")
        @driver.instance_variable_set(:@map, {"worker_uid" => 13001})
        @state = {"assignment_id" => "assignment", "attempt_id" => "attempt"}
        @ready = {"original_binding_digest" => "c" * 64}
        @frame = @ready.merge("version" => 1, "type" => "launch_review_delegate", "attempt_id" => "attempt",
          "mutation_id" => "request", "request_event_id" => "a" * 64, "journal_commit" => "b" * 40)
        peer = {"pid" => 123, "uid" => 13003, "gid" => 13003, "groups" => [13003], "parent_pid" => 1,
          "host" => "fixture", "started_at" => "linux:11111111-1111-4111-8111-111111111111:123"}
        @params = @state.merge("mapping_id" => "mapping", "head" => "d" * 40, "candidate_generation" => 2,
          "expected_generation" => 8, "reviewer_uid" => 13003, "reviewer_process_binding" => peer)
        @intent = @ready.merge("request_event_id" => "a" * 64, "assignment_params" => @params)
        @accepted = @params.slice("head", "candidate_generation", "reviewer_uid", "reviewer_process_binding").merge(
          "generation" => 9, "review_id" => "e" * 32, "assignment_event_id" => "f" * 64, "journal_commit" => "1" * 40)
        @calls = []
        owner = self
        client = Object.new
        client.define_singleton_method(:call) do |operation, params, **options|
          owner.instance_variable_get(:@calls) << [operation, params, options]
          if operation == "assign_review" && owner.instance_variable_get(:@conflict)
            raise AttemptErrors::Conflict, "intervening canonical mutation"
          end
          Authority::Client::Reply.new(data: owner.instance_variable_get(operation == "launch_review_intent" ? :@intent : :@accepted))
        end
        @driver.instance_variable_set(:@client, client)
        @left, @right = UNIXSocket.pair
        yield
      ensure
        @left&.close
        @right&.close
      end

      def invoke
        @driver.send(:original_review_delegate!, @left, @state, @ready, @frame, WIRE.deadline(2))
      end

      def test_driver_uses_exact_canonical_params_generation_and_stable_mutation_on_retry
        fixture do
          2.times do
            invoke
            result = WIRE.read(@right, deadline: WIRE.deadline(2))
            assert_equal "launch_review_assigned", result.fetch("type")
            assert_equal @accepted.fetch("assignment_event_id"), result.fetch("assignment_event_id")
          end
          assignments = @calls.select { |call| call.first == "assign_review" }
          assert_equal 2, assignments.length
          assignments.each do |_, params, options|
            assert_equal @params, params
            assert_equal "review-delegate.#{@frame.fetch('request_event_id')}", options.fetch(:mutation_id)
            assert_operator options.fetch(:timeout), :>, 0
            assert_operator options.fetch(:timeout), :<=, 2
          end
          lookups = @calls.select { |call| call.first == "launch_review_intent" }
          assert_equal @frame.fetch("journal_commit"), lookups.first[1].fetch("journal_commit")
          assert_nil lookups.first[2].fetch(:mutation_id)
        end
      end

      def test_foreign_frame_or_canonical_intent_refuses_before_assignment
        fixture do
          @frame["attempt_id"] = "foreign"
          assert_raises(AttemptErrors::EvidenceUnavailable) { invoke }
          assert_empty @calls
          @frame["attempt_id"] = "attempt"
          @params["reviewer_uid"] = 13001
          assert_raises(AttemptErrors::EvidenceUnavailable) { invoke }
          assert_equal ["launch_review_intent"], @calls.map(&:first)
          assert_nil IO.select([@right], nil, nil, 0)
        end
      end

      def test_generation_conflict_is_not_refreshed_and_invalid_assignment_has_no_reply
        fixture do
          @conflict = true
          assert_raises(AttemptErrors::Conflict) { invoke }
          assert_equal %w[launch_review_intent assign_review], @calls.map(&:first)
          assert_nil IO.select([@right], nil, nil, 0)
          @conflict = false
          @accepted["generation"] = 10
          assert_raises(AttemptErrors::EvidenceUnavailable) { invoke }
          assert_nil IO.select([@right], nil, nil, 0)
        end
      end
    end
  end
end
