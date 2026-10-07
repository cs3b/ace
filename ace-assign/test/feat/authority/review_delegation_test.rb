# frozen_string_literal: true
require_relative "../../test_helper"
require_relative "../../support/endcap_result_owner_fixture"
require "ace/assign/authority/server"
require "ace/assign/authority/client"

module Ace
  module Assign
    class ReviewDelegationTest < AceAssignTestCase
      include EndcapResultOwnerFixture

      def assign_direct(id: "review", number: 1)
        params = {"head" => @head, "candidate_generation" => number, "expected_generation" => generation,
          "reviewer_uid" => @reviewer.fetch("uid"), "reviewer_process_binding" => @reviewer}
        [call("assign_review", params, id: id, peer: @launcher, role: :launcher), params]
      end

      def review_event
        @journal.read_events("assignment").reverse.find do |event|
          event["type"] == "authority_mutation" && event.dig("payload", "operation") == "assign_review"
        end
      end

      def cancellation(event)
        {"head" => @head, "candidate_generation" => 1, "review_event_id" => event.fetch("digest"),
          "expected_generation" => generation}
      end

      def test_direct_assignment_requires_explicit_revocation_before_replacement
        fixture do
          first, params = assign_direct
          event = review_event
          assert_equal event.fetch("digest"), first.dig(:data, "assignment_event_id")
          before = @journal.ref_value
          assert_raises(AttemptErrors::Conflict) { assign_direct(id: "silent-replacement") }
          assert_equal before, @journal.ref_value
          cancel = cancellation(event)
          result = call("cancel_review", cancel, id: "cancel", peer: @launcher, role: :launcher)
          assert_equal "cancelled", result.dig(:data, "state")
          accepted = @journal.read_events("assignment", commit: result.dig(:data, "journal_commit")).find do |entry|
            entry["digest"] == result.dig(:data, "cancellation_event_id")
          end
          assert_equal "cancel_review", accepted.dig("payload", "operation")
          after = @journal.ref_value
          replay = call("cancel_review", cancel, id: "cancel", peer: @launcher, role: :launcher)
          assert replay.fetch(:replayed)
          assert_equal result.fetch(:data), replay.fetch(:data)
          assert_equal after, @journal.ref_value
          old = call("assign_review", params, id: "review", peer: @launcher, role: :launcher)
          assert old.fetch(:replayed)
          assert_equal first.fetch(:data), old.fetch(:data)
          events = @journal.read_events("assignment").select { |entry| entry["attempt_id"] == @attempt }
          current = {"head" => @head, "candidate_generation" => 1}
          assert_nil @endcap.send(:active_review_event, events, current)
          assert_equal first.dig(:data, "review_id"), @endcap.send(:assigned_review, events).fetch("review_id")
          assert_raises(AttemptErrors::UnauthorizedIdentity) do
            @endcap.send(:export_admission!, @journal, events,
              current.merge("purpose_id" => first.dig(:data, "review_id")), @map, nil, @reviewer, :reviewer)
          end
          second, = assign_direct(id: "explicit-new")
          refute_equal first.dig(:data, "review_id"), second.dig(:data, "review_id")
          assert_raises(AttemptErrors::Conflict) do
            call("cancel_review", cancel.merge("expected_generation" => generation), id: "cancel-again", peer: @launcher, role: :launcher)
          end
        end
      end

      def test_wrong_identity_selector_generation_or_upload_cannot_cancel
        fixture do
          assign_direct
          params = cancellation(review_event)
          before = @journal.ref_value
          assert_raises(AttemptErrors::UnauthorizedIdentity) { call("cancel_review", params, id: "worker-cancel") }
          assert_raises(AttemptErrors::UnauthorizedIdentity) do
            call("cancel_review", params.merge("review_event_id" => "f" * 64), id: "foreign", peer: @launcher, role: :launcher)
          end
          assert_raises(AttemptErrors::Conflict) do
            call("cancel_review", params.merge("expected_generation" => 0), id: "stale", peer: @launcher, role: :launcher)
          end
          assert_raises(ArgumentError) do
            call("cancel_review", params, id: "upload", peer: @launcher, role: :launcher, transfer: Object.new)
          end
          assert_equal before, @journal.ref_value
          candidate(2)
          # A new exact candidate has its own review reservation.
          assert assign_direct(id: "new-candidate", number: 2).first.dig(:data, "review_id")
        end
      end

      def test_accepted_cancellation_replays_after_candidate_advances_without_revoking_new_review
        fixture do
          assign_direct
          params = cancellation(review_event)
          accepted = call("cancel_review", params, id: "cancel", peer: @launcher, role: :launcher)
          candidate(2)
          replacement, = assign_direct(id: "replacement", number: 2)
          before = @journal.ref_value
          replay = call("cancel_review", params, id: "cancel", peer: @launcher, role: :launcher)
          assert replay.fetch(:replayed)
          assert_equal accepted.fetch(:data), replay.fetch(:data)
          assert_equal before, @journal.ref_value
          assert_raises(AttemptErrors::Conflict) do
            call("cancel_review", params.merge("expected_generation" => generation),
              id: "fresh-old-cancel", peer: @launcher, role: :launcher)
          end
          events = @journal.read_events("assignment").select { |entry| entry["attempt_id"] == @attempt }
          assert_equal replacement.dig(:data, "assignment_event_id"),
            @endcap.send(:active_review_event, events, {"head" => @head, "candidate_generation" => 2}).fetch("digest")
          assert_equal before, @journal.ref_value
        end
      end

      def test_cancellation_revokes_accepted_approval_without_erasing_evidence
        fixture do
          assigned, = assign_direct
          event = review_event
          artifact = "independent review report"
          receipt = {"assignment_id" => "assignment", "attempt_id" => @attempt, "project_id" => "project",
            "scope" => "010", "operation" => "review", "head" => @head, "verdict" => "succeeded",
            "producer" => {"actor" => "worker", "role" => "worker", "runtime" => "herdr"},
            "artifacts" => [{"path" => "review-report", "sha256" => Digest::SHA256.hexdigest(artifact)}],
            "checks" => [{"name" => "controlled-review", "verdict" => "passed"}],
            "review" => {"head" => @head, "verdict" => "approved",
              "reviewer" => {"actor" => assigned.dig(:data, "reviewer_actor")}}}
          params, input, = upload(parts: [artifact], receipt: receipt)
          params["purpose_id"] = assigned.dig(:data, "review_id")
          accepted = call("accept_review", params, id: "accept", peer: @reviewer, role: :reviewer, transfer: input)
          selectors = {"assignment_id" => "assignment", "attempt_id" => @attempt}
          current = {"head" => @head, "candidate_generation" => 1}
          read = -> { @endcap.send(:approved_review!, @journal, @journal.read_events("assignment"), selectors, @map, current) }
          assert_equal assigned.dig(:data, "review_id"), read.call.fetch("review_id")
          accepted_commit = accepted.dig(:data, "journal_commit")
          history = @journal.read_events("assignment", commit: accepted_commit)
          call("cancel_review", cancellation(event), id: "cancel-approved", peer: @launcher, role: :launcher)
          assert_raises(AttemptErrors::ReceiptRejected) { read.call }
          before = @journal.ref_value
          assert_raises(AttemptErrors::UnauthorizedIdentity) do
            call("accept_review", params, id: "accept", peer: @reviewer, role: :reviewer, transfer: input)
          end
          assert_equal before, @journal.ref_value
          assert_equal history, @journal.read_events("assignment", commit: accepted_commit)
          reference = accepted.dig(:data, "review_receipt", "artifacts").first
          assert_equal artifact, @journal.blob(reference.fetch("path"))
        end
      end

      def test_actual_client_server_cancellation_uses_bodyless_canonical_reply
        fixture do
          @kernel.peer_identity = @launcher
          @server = Authority::Server.new(authority_id: "authority", lifecycle: @router,
            deployment: @deployment, kernel: @kernel, composition: "services")
          # Only installed directory and OS identity admission are controlled.
          wire = Object.new
          wire.define_singleton_method(:root_path!) { |*_, **_| true }
          %i[socket_identity read write deadline].each do |name|
            wire.define_singleton_method(name) { |*args, **options| WIRE.public_send(name, *args, **options) }
          end
          @server.define_singleton_method(:wire) { wire }
          @owner = Thread.new { @server.serve }
          Timeout.timeout(3) { sleep 0.005 until File.socket?(@service.fetch("socket_path")) }
          kernel = Kernel.new
          kernel.peer_identity = @service.slice("uid", "gid", "groups")
          client = Authority::Client.new(mapping_id: "mapping", deployment: @deployment, kernel: kernel)
          assignment = client.call("assign_review", {"assignment_id" => "assignment", "attempt_id" => @attempt,
            "head" => @head, "candidate_generation" => 1, "expected_generation" => generation,
            "reviewer_uid" => @reviewer.fetch("uid"), "reviewer_process_binding" => @reviewer},
            mutation_id: "wire-assign", timeout: 30)
          params = {"head" => @head, "candidate_generation" => 1,
            "review_event_id" => assignment.data.fetch("assignment_event_id"), "expected_generation" => generation,
            "assignment_id" => "assignment", "attempt_id" => @attempt}
          reply = client.call("cancel_review", params, mutation_id: "wire-cancel", timeout: 30)
          assert_equal "cancelled", reply.data.fetch("state")
          assert_match(/\A[0-9a-f]{64}\z/, reply.data.fetch("cancellation_event_id"))
          before = @journal.ref_value
          replay = client.call("cancel_review", params, mutation_id: "wire-cancel", timeout: 30)
          assert replay.replayed
          assert_equal reply.data, replay.data
          assert_equal before, @journal.ref_value
        end
      end
    end
  end
end
