# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Coworker
    module Atoms
      class PrepareDecisionTest < AceCoworkerTestCase
        def switch_hit(task_id: "8xg.t.aaa")
          {success: true, worktree_path: "/proj/.ace-wt/t.8xg-t-aaa",
           branch: "8xg-aaa-branch", task_id: task_id}
        end

        def test_switch_hit_matching_task_reuses
          result = PrepareDecision.from_switch(switch_hit, expected_task_id: "8xg.t.aaa")

          assert_equal :reuse, result[:disposition]
          assert_equal "/proj/.ace-wt/t.8xg-t-aaa", result[:worktree_path]
          assert_equal "8xg-aaa-branch", result[:branch]
        end

        def test_switch_hit_short_id_association_still_reuses
          # ace-git-worktree stores the association under the short id.
          result = PrepareDecision.from_switch(switch_hit(task_id: "aaa"),
            expected_task_id: "8xg.t.aaa")

          assert_equal :reuse, result[:disposition]
        end

        def test_switch_hit_foreign_task_is_conflict_mismatch
          result = PrepareDecision.from_switch(switch_hit(task_id: "8xg.t.bbb"),
            expected_task_id: "8xg.t.aaa")

          assert_equal :conflict_mismatch, result[:disposition]
          assert_includes result[:reason], "belongs to task '8xg.t.bbb'"
        end

        def test_switch_failure_with_stale_registration_is_stale_recovery
          # The real owner's switch never resolves a missing directory; the
          # registration (from the association inventory) carries the truth.
          result = PrepareDecision.from_switch(
            {success: false, error: "Worktree directory does not exist: /proj/.ace-wt/t.8xg-t-aaa"},
            expected_task_id: "8xg.t.aaa",
            stale_registration: {task_id: "aaa", worktree_path: "/proj/.ace-wt/t.8xg-t-aaa",
                                 branch: "8xg-aaa-branch"})

          assert_equal :stale_recovery, result[:disposition]
          assert_equal "/proj/.ace-wt/t.8xg-t-aaa", result[:worktree_path]
          assert_equal "8xg-aaa-branch", result[:branch]
          assert_equal "aaa", result[:task_id]
          assert_includes result[:reason], "missing directory"
        end

        def test_switch_miss_without_registration_reports_reason
          result = PrepareDecision.from_switch({success: false, error: "Worktree not found: 8xg.t.aaa"},
            expected_task_id: "8xg.t.aaa")

          assert_equal :miss, result[:disposition]
          assert_equal "Worktree not found: 8xg.t.aaa", result[:reason]
        end

        def test_create_success_new_is_created
          result = PrepareDecision.from_create(
            {success: true, worktree_path: "/proj/.ace-wt/t.8xg-t-aaa",
             branch: "8xg-aaa-branch", message: "created"})

          assert_equal :created, result[:disposition]
        end

        def test_create_success_existing_is_reuse
          result = PrepareDecision.from_create(
            {success: true, existing: true, worktree_path: "/w", branch: "b"})

          assert_equal :reuse, result[:disposition]
        end

        def test_create_success_recovered_marks_recovery
          result = PrepareDecision.from_create(
            {success: true, recovered: true, worktree_path: "/w", branch: "b"})

          assert_equal :recovered, result[:disposition]
        end

        def test_create_failure_with_occupied_directory_is_conflict_mismatch
          result = PrepareDecision.from_create(
            {success: false, error: "target path already exists"}, occupied_directory: true)

          assert_equal :conflict_mismatch, result[:disposition]
          assert_equal "target path already exists", result[:reason]
        end

        def test_create_failure_without_occupant_is_error
          result = PrepareDecision.from_create(
            {success: false, error: "boom"}, occupied_directory: false)

          assert_equal :error, result[:disposition]
          assert_equal "boom", result[:reason]
        end
      end
    end
  end
end
