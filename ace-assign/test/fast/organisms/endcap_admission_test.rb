# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/assign/authority/endcap"
require "ace/assign/authority/launch_lifecycle"

module Ace
  module Assign
    class EndcapAdmissionTest < AceAssignTestCase
      def setup
        super
        @launch = Authority::LaunchLifecycle.new(deployment: Object.new)
        @endcap = Authority::Endcap.new(deployment: Object.new, launch: @launch)
        @params = {"mapping_id" => "mapping-1", "assignment_id" => "assignment-1", "attempt_id" => "attempt-1"}
      end

      def event(operation, phase, previous = nil)
        Models::EvidenceEvent.build(type: "authority_mutation", attempt_id: "attempt-1", previous_digest: previous,
          payload: {"operation" => operation, "data" => @params.merge("launch_ticket" => "fixture-ticket", "phase" => phase)})
      end

      def test_removed_message_observation_is_not_an_authority_transfer
        %w[import_observation fetch_observation].each do |operation|
          refute_includes Authority::Endcap::OPERATIONS, operation
          refute Authority::Endcap::PARAMETERS.key?(operation)
          refute Authority::Endcap::TRANSFER_OPERATIONS.key?(operation)
        end
        assert_equal [:worker], Authority::Endcap::TRANSFER_OPERATIONS.fetch("submit_result").fetch(:roles)
        assert_equal [:executor], Authority::Endcap::TRANSFER_OPERATIONS.fetch("complete_service").fetch(:roles)
      end

      def test_business_mutation_echo_cannot_manufacture_native_origin
        events = [event("submit_candidate", "issued")]
        assert_raises(AttemptErrors::NotFound) { @endcap.send(:active_origin, events, @params) }
      end

      def test_reserved_origin_never_authorizes_candidate_admission
        events = [event("reserve_attempt", "reserved")]
        assert_raises(AttemptErrors::InvalidState) { @endcap.send(:active_origin, events, @params) }
      end

      def test_terminal_transition_rejects_even_an_issued_origin
        launch = event("release_launch", "issued")
        terminal = Models::EvidenceEvent.build(type: "transition", attempt_id: "attempt-1", previous_digest: launch.fetch("digest"),
          payload: {"from" => "running", "to" => "stopped"})
        assert_raises(AttemptErrors::InvalidState) { @endcap.send(:active_origin, [launch, terminal], @params) }
      end

      def test_actor_name_and_mapped_worker_uid_do_not_grant_reviewer_launcher_authority
        peer = {"uid" => 42, "actor" => "launcher"}
        map = {"worker_uid" => 42, "launcher_uid" => 43}
        assert_raises(AttemptErrors::UnauthorizedIdentity) do
          @endcap.send(:worker_or_launcher!, peer, :reviewer, map, {}, launcher_only: true)
        end
        assert_raises(AttemptErrors::UnauthorizedIdentity) do
          @endcap.send(:worker_or_launcher!, peer, :worker, map, {}, launcher_only: true)
        end
      end

      def test_corrupted_origin_chain_is_refused_before_native_identity_access
        launch = event("release_launch", "issued")
        launch["payload"]["data"]["launch_ticket"] = "forged"
        assert_raises(AttemptErrors::InvalidState) { @endcap.send(:active_origin, [launch], @params) }
      end

      def test_full_service_handler_refuses_local_evidence_composition
        journal = Struct.new(:evidence_mode).new(:local)
        assert_raises(ArgumentError) { @endcap.send(:protected_journal!, journal) }
      end
    end
  end
end
