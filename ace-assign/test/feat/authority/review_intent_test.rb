# frozen_string_literal: true
require_relative "../../test_helper"
require_relative "../../support/endcap_result_owner_fixture"

module Ace
  module Assign
    class ReviewIntentTest < AceAssignTestCase
      include EndcapResultOwnerFixture

      def record_request(change: nil)
        origin = @journal.read_events("assignment").find { |event| event.dig("payload", "operation") == "record_launch" }
        data = {"head" => @head, "candidate_generation" => 1, "original_binding_digest" => origin.fetch("digest"),
          "reviewer_uid" => @reviewer.fetch("uid"), "reviewer_process_binding" => @reviewer,
          "requester" => @reviewer.slice("uid", "gid", "groups").merge("role" => "reviewer")}
        change.call(data) if change
        # Real canonical event fixture; public request admission is a separate
        # pending implementation and is not claimed by this projection test.
        result = @journal.mutate(assignment_id: "assignment", attempt_id: @attempt, mutation_id: "request",
          operation: "request_review", parameters_digest: "a" * 64, expected_generation: generation) { {data: data} }
        event = @journal.read_events("assignment").find { |item| item.dig("payload", "operation") == "request_review" }
        @selectors = {"mutation_id" => "request", "request_event_id" => event.fetch("digest"),
          "journal_commit" => result.fetch("journal_commit"), "original_binding_digest" => origin.fetch("digest")}
        result
      end

      def lookup(params = @selectors, peer: @launcher, role: :launcher)
        call("launch_review_intent", params, peer: peer, role: role)
      end

      def test_pinned_request_returns_exact_original_assignment_generation_after_current_candidate_changes
        fixture do
          accepted = record_request
          first = lookup
          assert_equal accepted.fetch("generation"), first.dig(:data, "assignment_params", "expected_generation")
          assert_equal @reviewer, first.dig(:data, "assignment_params", "reviewer_process_binding")
          candidate(2)
          before = @journal.ref_value
          assert_equal first, lookup
          assert_equal before, @journal.ref_value
          assert_equal 1, lookup.dig(:data, "assignment_params", "candidate_generation")
        end
      end

      def test_malformed_canonical_requester_types_refuse_even_when_numeric_values_compare_equal
        fixture do
          record_request(change: ->(data) { data["requester"]["uid"] = data["reviewer_uid"].to_f })
          before = @journal.ref_value
          assert_raises(AttemptErrors::EvidenceUnavailable) { lookup }
          assert_equal before, @journal.ref_value
        end
      end

      def test_wrong_original_selectors_or_later_prefix_refuse_without_writes
        fixture do
          record_request
          candidate(2)
          before = @journal.ref_value
          [@selectors.merge("request_event_id" => "f" * 64), @selectors.merge("mutation_id" => "foreign"),
            @selectors.merge("original_binding_digest" => "e" * 64), @selectors.merge("journal_commit" => before)].each do |bad|
            assert_raises(AttemptErrors::EvidenceUnavailable) { lookup(bad) }
          end
          assert_raises(AttemptErrors::UnauthorizedIdentity) { lookup(peer: @worker, role: :worker) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { lookup(peer: @launcher.merge("pid" => 999)) }
          assert_equal before, @journal.ref_value
        end
      end
    end
  end
end
