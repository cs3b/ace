# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Assign
    class AttemptStateMachineTest < AceAssignTestCase
      def test_legal_transitions_match_specified_lifecycle
        machine = Atoms::AttemptStateMachine

        assert_equal %w[running], machine.next_states("reserved")
        assert_equal %w[succeeded failed stopped uncertain], machine.next_states("running")
        assert_equal %w[succeeded failed], machine.next_states("uncertain")
      end

      def test_terminal_states_accept_no_transitions
        machine = Atoms::AttemptStateMachine

        %w[succeeded failed stopped].each do |state|
          assert machine.terminal?(state)
          assert_empty machine.next_states(state)
          refute machine.can_transition?(state, "running")
        end

        refute machine.terminal?("running")
        refute machine.terminal?("uncertain")
      end

      def test_stop_is_not_success
        machine = Atoms::AttemptStateMachine

        assert machine.can_transition?("running", "stopped")
        refute machine.terminal?("succeeded") == false && machine.terminal?("stopped") == false
        assert machine.terminal?("stopped")
      end

      def test_transition_returns_target_for_legal_transition
        assert_equal "running", Atoms::AttemptStateMachine.transition!("reserved", "running")
        assert_equal "uncertain", Atoms::AttemptStateMachine.transition!("running", "uncertain")
        assert_equal "succeeded", Atoms::AttemptStateMachine.transition!("uncertain", "succeeded")
      end

      def test_transition_raises_for_illegal_transition
        error = assert_raises(Ace::Assign::AttemptErrors::InvalidTransition) do
          Atoms::AttemptStateMachine.transition!("succeeded", "running")
        end
        assert_equal 5, error.exit_code

        assert_raises(Ace::Assign::AttemptErrors::InvalidTransition) do
          Atoms::AttemptStateMachine.transition!("reserved", "succeeded")
        end

        assert_raises(Ace::Assign::AttemptErrors::InvalidTransition) do
          Atoms::AttemptStateMachine.transition!("stopped", "uncertain")
        end
      end

      def test_unknown_state_has_no_transitions
        assert_empty Atoms::AttemptStateMachine.next_states("bogus")
        refute Atoms::AttemptStateMachine.can_transition?("bogus", "running")
      end
    end
  end
end
