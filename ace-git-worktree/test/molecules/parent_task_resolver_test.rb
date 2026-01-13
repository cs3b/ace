# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/git/worktree/molecules/parent_task_resolver"

module Ace
  module Git
    module Worktree
      module Molecules
        class ParentTaskResolverTest < Minitest::Test
          # Mock TaskFetcher for testing
          class MockTaskFetcher
            def initialize(tasks = {})
              @tasks = tasks
            end

            def fetch(task_ref)
              @tasks[task_ref]
            end
          end

          def setup
            @project_root = Dir.pwd
            @mock_fetcher = MockTaskFetcher.new({})
          end

          def test_default_target_when_no_task_data
            resolver = create_resolver({})
            result = resolver.resolve_target_branch(nil)
            assert_equal "main", result
          end

          def test_default_target_for_orchestrator_task
            task_data = {
              id: "v.0.9.0+task.202",
              title: "Orchestrator Task"
            }

            resolver = create_resolver({})
            result = resolver.resolve_target_branch(task_data)
            assert_equal "main", result
          end

          def test_parent_branch_for_subtask
            parent_task = {
              "id" => "v.0.9.0+task.202",
              "title" => "Parent Task",
              "worktree" => {
                "branch" => "202-rename-support-gems",
                "path" => ".ace-wt/task.202"
              }
            }

            subtask_data = {
              id: "v.0.9.0+task.202.01",
              title: "Subtask 01"
            }

            resolver = create_resolver("202" => parent_task)
            result = resolver.resolve_target_branch(subtask_data)
            assert_equal "202-rename-support-gems", result
          end

          def test_default_target_when_parent_not_found
            subtask_data = {
              id: "v.0.9.0+task.202.01",
              title: "Subtask 01"
            }

            resolver = create_resolver({})
            result = resolver.resolve_target_branch(subtask_data)
            assert_equal "main", result
          end

          def test_default_target_when_parent_has_no_worktree
            parent_task = {
              "id" => "v.0.9.0+task.202",
              "title" => "Parent Task"
              # No worktree metadata
            }

            subtask_data = {
              id: "v.0.9.0+task.202.01",
              title: "Subtask 01"
            }

            resolver = create_resolver("202" => parent_task)
            result = resolver.resolve_target_branch(subtask_data)
            assert_equal "main", result
          end

          def test_default_target_when_parent_worktree_has_no_branch
            parent_task = {
              "id" => "v.0.9.0+task.202",
              "title" => "Parent Task",
              "worktree" => {
                "path" => ".ace-wt/task.202"
                # No branch field
              }
            }

            subtask_data = {
              id: "v.0.9.0+task.202.01",
              title: "Subtask 01"
            }

            resolver = create_resolver("202" => parent_task)
            result = resolver.resolve_target_branch(subtask_data)
            assert_equal "main", result
          end

          def test_load_parent_task_returns_nil_for_nonexistent
            resolver = create_resolver({})
            result = resolver.load_parent_task("999")
            assert_nil result
          end

          def test_load_parent_task_returns_data_when_found
            parent_task = {
              "id" => "v.0.9.0+task.202",
              "title" => "Parent Task"
            }

            resolver = create_resolver("202" => parent_task)
            result = resolver.load_parent_task("202")
            assert_equal parent_task, result
          end

          def test_extract_parent_branch_returns_default_for_nil
            resolver = create_resolver({})
            result = resolver.extract_parent_branch(nil)
            assert_equal "main", result
          end

          def test_extract_parent_branch_returns_default_for_no_worktree
            parent_task = {
              "id" => "v.0.9.0+task.202",
              "title" => "Parent Task"
            }

            resolver = create_resolver({})
            result = resolver.extract_parent_branch(parent_task)
            assert_equal "main", result
          end

          def test_extract_parent_branch_returns_branch_from_worktree
            parent_task = {
              "id" => "v.0.9.0+task.202",
              "title" => "Parent Task",
              "worktree" => {
                "branch" => "202-rename-support-gems",
                "path" => ".ace-wt/task.202"
              }
            }

            resolver = create_resolver({})
            result = resolver.extract_parent_branch(parent_task)
            assert_equal "202-rename-support-gems", result
          end

          def test_extract_parent_branch_supports_symbol_keys
            parent_task = {
              id: "v.0.9.0+task.202",
              title: "Parent Task",
              worktree: {
                branch: "202-rename-support-gems",
                path: ".ace-wt/task.202"
              }
            }

            resolver = create_resolver({})
            result = resolver.extract_parent_branch(parent_task)
            assert_equal "202-rename-support-gems", result
          end

          def test_returns_default_when_task_fetcher_raises_exception
            # Mock fetcher that raises an exception
            failing_fetcher = Object.new
            def failing_fetcher.fetch(_)
              raise StandardError, "Simulated fetch failure"
            end

            subtask_data = {
              id: "v.0.9.0+task.202.01",
              title: "Subtask 01"
            }

            resolver = ParentTaskResolver.new(project_root: @project_root, task_fetcher: failing_fetcher)
            result = resolver.resolve_target_branch(subtask_data)
            assert_equal "main", result
          end

          private

          def create_resolver(tasks = {})
            mock_fetcher = MockTaskFetcher.new(tasks)
            ParentTaskResolver.new(project_root: @project_root, task_fetcher: mock_fetcher)
          end
        end
      end
    end
  end
end
