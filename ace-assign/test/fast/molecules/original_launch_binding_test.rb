# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/molecules/original_launch_binding"

module Ace
  module Assign
    class OriginalLaunchBindingTest < AceAssignTestCase
      def fixture
        params = {"assignment_id" => "assignment", "mapping_id" => "mapping", "attempt_id" => "attempt"}
        child = {"pid" => 12, "parent_pid" => 11, "uid" => 13001, "gid" => 13001, "groups" => [13001],
          "host" => "fixture", "started_at" => "linux:12345678-1234-1234-1234-123456789abc:91"}
        binding = {"terminal_id" => "term_ab", "process_identity" => child}
        state = params.merge("process_binding" => binding, "guarded_origin" => {"terminal_id" => "term_ab",
          "runtime_incarnation" => "12345678-1234-1234-1234-123456789abc", "child" => child})
        event = Models::EvidenceEvent.build(type: "authority_mutation", attempt_id: "attempt",
          payload: {"operation" => "record_launch", "data" => state})
        [params, state, event]
      end

      def test_exact_accepted_record_is_shared_read_only_projection
        params, state, event = fixture
        result = Molecules::OriginalLaunchBinding.verify!(events: [event], state: state, params: params)
        assert_equal event.fetch("digest"), result.fetch("binding_digest")
        assert_equal state.fetch("guarded_origin"), result.fetch("origin")
        assert result.frozen?
        assert result.fetch("origin").fetch("child").frozen?
      end

      def test_changed_guard_process_selectors_and_corrupt_chain_refuse
        params, state, event = fixture
        [state.merge("guarded_origin" => state.fetch("guarded_origin").merge("terminal_id" => "term_cd")),
          state.merge("process_binding" => state.fetch("process_binding").merge("terminal_id" => "term_cd"))].each do |changed|
          assert_raises(AttemptErrors::EvidenceUnavailable) { Molecules::OriginalLaunchBinding.verify!(events: [event], state: changed, params: params) }
        end
        assert_raises(AttemptErrors::EvidenceUnavailable) { Molecules::OriginalLaunchBinding.verify!(events: [event], state: state, params: params.merge("assignment_id" => "other")) }
        assert_raises(AttemptErrors::EvidenceUnavailable) { Molecules::OriginalLaunchBinding.verify!(events: [event.merge("digest" => "f" * 64)], state: state, params: params) }
        assert_raises(AttemptErrors::EvidenceUnavailable) { Molecules::OriginalLaunchBinding.verify!(events: [], state: state, params: params) }
      end

      def test_second_intact_record_is_not_a_replacement_authority
        params, state, event = fixture
        second = Models::EvidenceEvent.build(type: "authority_mutation", attempt_id: "attempt", previous_digest: event.fetch("digest"),
          payload: {"operation" => "record_launch", "data" => state})
        assert_raises(AttemptErrors::EvidenceUnavailable) { Molecules::OriginalLaunchBinding.verify!(events: [event, second], state: state, params: params) }
      end
    end
  end
end
