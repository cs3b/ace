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

      def assign_delegated(params = lookup.dig(:data, "assignment_params"), id: "review-delegate.#{@selectors.fetch('request_event_id')}", peer: @launcher, role: :launcher)
        call("assign_review", params, id: id, peer: peer, role: role)
      end

      def test_canonical_request_reserves_slot_and_exact_original_delegation_replays
        fixture do
          record_request
          params = lookup.dig(:data, "assignment_params")
          before = @journal.ref_value
          assert_raises(AttemptErrors::Conflict) { assign_delegated(params, id: "direct") }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { assign_delegated(params, id: "review-delegate.#{'f' * 64}") }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { assign_delegated(params.merge("reviewer_process_binding" => @reviewer.merge("pid" => @reviewer.fetch("pid").to_f))) }
          assert_raises(AttemptErrors::UnauthorizedIdentity) { assign_delegated(params, peer: @launcher.merge("pid" => 999)) }
          assert_equal before, @journal.ref_value
          result = assign_delegated(params)
          assert_match(/\A[0-9a-f]{64}\z/, result.dig(:data, "assignment_event_id"))
          assert_equal result.fetch(:data), assign_delegated(params).fetch(:data)
          assert assign_delegated(params).fetch(:replayed)
          candidate(2)
          assert_equal result.fetch(:data), assign_delegated(params).fetch(:data)
        end
      end

      def cancel_requested(event = @selectors.fetch("request_event_id"), peer: @reviewer, role: :reviewer, id: "cancel-request")
        call("cancel_review", {"head" => @head, "candidate_generation" => 1,
          "review_event_id" => event, "expected_generation" => generation}, id: id, peer: peer, role: role)
      end

      def test_cancelled_unassigned_request_cannot_assign_and_restarted_requester_can_cancel
        fixture do
          record_request
          params = lookup.dig(:data, "assignment_params")
          assert_raises(AttemptErrors::UnauthorizedIdentity) { cancel_requested(peer: @worker, role: :worker) }
          result = cancel_requested(peer: @reviewer.merge("pid" => 182, "started_at" => @reviewer.fetch("started_at").sub(/82\z/, "182")))
          assert_equal "cancelled", result.dig(:data, "state")
          assert_nil result.dig(:data, "review_id")
          before = @journal.ref_value
          assert_raises(AttemptErrors::Conflict) { assign_delegated(params) }
          assert_equal before, @journal.ref_value
        end
      end

      def test_delegated_child_is_not_cancellation_root_and_historical_assignment_does_not_restore_permission
        fixture do
          record_request
          params = lookup.dig(:data, "assignment_params")
          assigned = assign_delegated(params)
          assert_raises(AttemptErrors::UnauthorizedIdentity) do
            cancel_requested(assigned.dig(:data, "assignment_event_id"), peer: @launcher, role: :launcher)
          end
          cancelled = cancel_requested
          assert_equal assigned.dig(:data, "review_id"), cancelled.dig(:data, "review_id")
          assert_equal assigned.fetch(:data), assign_delegated(params).fetch(:data)
          before = @journal.ref_value
          assert_raises(AttemptErrors::UnauthorizedIdentity) do
            call("export_candidate", {"head" => @head, "candidate_generation" => 1,
              "purpose_id" => assigned.dig(:data, "review_id")}, peer: @reviewer, role: :reviewer)
          end
          assert_equal before, @journal.ref_value
        end
      end

      def test_reserved_delegation_namespace_cannot_be_used_for_another_operation
        fixture do
          before = @journal.ref_value
          assert_raises(ArgumentError) do
            call("cancel_review", {}, id: "review-delegate.#{'a' * 64}", peer: @launcher, role: :launcher)
          end
          assert_equal before, @journal.ref_value
        end
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
