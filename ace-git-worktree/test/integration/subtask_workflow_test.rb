# frozen_string_literal: true

require "test_helper"
require "ace/git/worktree/models/worktree_config"
require "ace/git/worktree/molecules/task_status_updater"
require "ace/git/worktree/atoms/task_id_extractor"

# Integration tests for subtask workflow
#
# These tests verify that hierarchical task IDs (e.g., "121.01") are handled
# consistently across all ace-git-worktree components:
# - WorktreeConfig.format_directory
# - TaskStatusUpdater.normalize_task_reference
# - TaskIDExtractor (underlying atom)
#
# Critical: Parent tasks (121) and subtasks (121.01) must produce distinct paths
# to avoid operations targeting the wrong worktree.
module Ace
  module Git
    module Worktree
      module Integration
        class SubtaskWorkflowTest < Minitest::Test
          # Tests that parent task ID produces correct worktree path
          def test_worktree_path_for_parent_task
            task_data = { id: "v.0.9.0+task.121", title: "Parent task" }
            config = Models::WorktreeConfig.new

            path = config.format_directory(task_data)
            assert_equal "task.121", path
          end

          # Tests that subtask ID produces correct worktree path (with suffix)
          def test_worktree_path_for_subtask
            task_data = { id: "v.0.9.0+task.121.01", title: "Subtask" }
            config = Models::WorktreeConfig.new

            path = config.format_directory(task_data)
            assert_equal "task.121.01", path
          end

          # Tests that parent and subtask produce different paths (critical!)
          def test_parent_and_subtask_have_distinct_paths
            parent_data = { id: "v.0.9.0+task.121", title: "Parent" }
            subtask_data = { id: "v.0.9.0+task.121.01", title: "Subtask" }
            config = Models::WorktreeConfig.new

            parent_path = config.format_directory(parent_data)
            subtask_path = config.format_directory(subtask_data)

            refute_equal parent_path, subtask_path, "Parent and subtask must have distinct paths"
            assert_equal "task.121", parent_path
            assert_equal "task.121.01", subtask_path
          end

          # Tests multiple subtasks have distinct paths
          def test_multiple_subtasks_have_distinct_paths
            config = Models::WorktreeConfig.new

            paths = (1..3).map do |i|
              task_data = { id: "v.0.9.0+task.121.0#{i}", title: "Subtask #{i}" }
              config.format_directory(task_data)
            end

            assert_equal %w[task.121.01 task.121.02 task.121.03], paths
            assert_equal 3, paths.uniq.size, "All subtasks must have unique paths"
          end

          # Tests TaskStatusUpdater normalizes subtask references correctly
          def test_status_updater_normalizes_subtask_refs
            updater = Molecules::TaskStatusUpdater.new

            # Simple subtask ID
            assert_equal "121.01", updater.send(:normalize_task_reference, "121.01")

            # With task. prefix
            assert_equal "121.01", updater.send(:normalize_task_reference, "task.121.01")

            # Full qualified ID
            assert_equal "121.01", updater.send(:normalize_task_reference, "v.0.9.0+task.121.01")
          end

          # Tests that parent and subtask normalize to different IDs
          def test_status_updater_distinguishes_parent_from_subtask
            updater = Molecules::TaskStatusUpdater.new

            parent_id = updater.send(:normalize_task_reference, "121")
            subtask_id = updater.send(:normalize_task_reference, "121.01")

            refute_equal parent_id, subtask_id, "Parent and subtask must normalize to different IDs"
            assert_equal "121", parent_id
            assert_equal "121.01", subtask_id
          end

          # Tests TaskIDExtractor.extract handles various input formats
          def test_extractor_handles_all_id_formats
            # Standard task ID
            assert_equal "121", Atoms::TaskIDExtractor.extract({ id: "v.0.9.0+task.121" })

            # Subtask ID
            assert_equal "121.01", Atoms::TaskIDExtractor.extract({ id: "v.0.9.0+task.121.01" })

            # Backlog task
            assert_equal "042", Atoms::TaskIDExtractor.extract({ id: "backlog+task.042" })

            # Backlog subtask
            assert_equal "042.01", Atoms::TaskIDExtractor.extract({ id: "backlog+task.042.01" })
          end

          # Tests TaskIDExtractor.normalize handles various reference formats
          def test_extractor_normalizes_all_ref_formats
            # Bare ID
            assert_equal "121", Atoms::TaskIDExtractor.normalize("121")

            # Subtask bare ID
            assert_equal "121.01", Atoms::TaskIDExtractor.normalize("121.01")

            # With task. prefix
            assert_equal "121", Atoms::TaskIDExtractor.normalize("task.121")
            assert_equal "121.01", Atoms::TaskIDExtractor.normalize("task.121.01")

            # Full qualified ID
            assert_equal "121", Atoms::TaskIDExtractor.normalize("v.0.9.0+task.121")
            assert_equal "121.01", Atoms::TaskIDExtractor.normalize("v.0.9.0+task.121.01")
          end

          # Tests branch format includes subtask suffix
          def test_branch_format_includes_subtask
            subtask_data = { id: "v.0.9.0+task.121.01", title: "Fix subtask bug" }
            config = Models::WorktreeConfig.new

            branch = config.format_branch(subtask_data)

            assert_match(/121\.01/, branch, "Branch name should include subtask suffix")
          end

          # Tests commit message format includes subtask suffix
          def test_commit_message_format_includes_subtask
            subtask_data = { id: "v.0.9.0+task.121.01", title: "Fix subtask bug" }
            config = Models::WorktreeConfig.new

            message = config.format_commit_message(subtask_data)

            assert_match(/121\.01/, message, "Commit message should include subtask suffix")
          end
        end
      end
    end
  end
end
