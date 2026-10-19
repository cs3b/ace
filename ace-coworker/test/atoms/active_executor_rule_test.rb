# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Coworker
    module Atoms
      class ActiveExecutorRuleTest < AceCoworkerTestCase
        def rule(config:, assignments: [])
          ActiveExecutorRule.evaluate(config: config, assignments: assignments)
        end

        def assignment(id:, state:)
          {"id" => id, "state" => state}
        end

        def test_missing_config_with_only_finished_or_pending_assignments_is_not_active
          result = rule(config: nil, assignments: [
            assignment(id: "a1", state: "completed"),
            assignment(id: "a2", state: "paused"),
            assignment(id: "a3", state: "failed"),
            assignment(id: "a4", state: "empty")
          ])

          refute result[:active]
          assert_nil result[:evidence]
        end

        def test_commissioned_assignment_not_completed_is_active
          %w[running stalled paused failed empty].each do |state|
            result = rule(config: {"assignment" => "a1"},
              assignments: [assignment(id: "a1", state: state)])

            assert result[:active], state
            assert_equal "config", result[:evidence]["source"]
            assert_equal "a1", result[:evidence]["assignment"]
            assert_equal state, result[:evidence]["state"]
          end
        end

        def test_commissioned_completed_assignment_is_not_active
          result = rule(config: {"assignment" => "a1"},
            assignments: [assignment(id: "a1", state: "completed")])

          refute result[:active]
        end

        def test_commissioned_completed_with_other_in_flight_assignment_is_active
          result = rule(config: {"assignment" => "a1"},
            assignments: [assignment(id: "a1", state: "completed"),
              assignment(id: "a2", state: "running")])

          assert result[:active]
          assert_equal "assignment", result[:evidence]["source"]
          assert_equal "a2", result[:evidence]["assignment"]
          assert_equal "running", result[:evidence]["state"]
        end

        def test_commissioned_completed_with_finished_others_is_not_active
          result = rule(config: {"assignment" => "a1"},
            assignments: [assignment(id: "a1", state: "completed"),
              assignment(id: "a2", state: "paused"),
              assignment(id: "a3", state: "failed")])

          refute result[:active]
        end

        def test_commissioned_assignment_missing_from_list_is_active
          result = rule(config: {"assignment" => "gone"},
            assignments: [assignment(id: "a1", state: "completed")])

          assert result[:active]
          assert_equal "unknown", result[:evidence]["state"]
        end

        def test_unparseable_config_is_active
          result = rule(config: ActiveExecutorRule::UNPARSEABLE)

          assert result[:active]
          assert_equal "config", result[:evidence]["source"]
          assert_equal "unparseable", result[:evidence]["state"]
        end

        def test_config_without_assignment_key_is_not_commissioned
          result = rule(config: {"role" => "worker"},
            assignments: [assignment(id: "a1", state: "paused")])

          refute result[:active]
        end

        def test_uncommissioned_in_flight_assignment_is_active
          %w[running stalled].each do |state|
            result = rule(config: nil, assignments: [assignment(id: "a1", state: state)])

            assert result[:active], state
            assert_equal "assignment", result[:evidence]["source"]
          end
        end

        def test_uncommissioned_failed_or_pending_assignments_do_not_block
          result = rule(config: nil, assignments: [
            assignment(id: "a1", state: "failed"),
            assignment(id: "a2", state: "paused")
          ])

          refute result[:active]
        end
      end
    end
  end
end
