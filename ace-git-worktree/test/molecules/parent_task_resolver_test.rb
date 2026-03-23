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

          def test_orchestrator_task_uses_current_branch
            task_data = {
              id: "v.0.9.0+task.202",
              title: "Orchestrator Task"
            }

            Atoms::GitCommand.stub(:current_branch, "237-ace-coworker-mvp") do
              resolver = create_resolver({})
              result = resolver.resolve_target_branch(task_data)
              assert_equal "237-ace-coworker-mvp", result
            end
          end

          def test_orchestrator_task_falls_back_to_main_when_no_current_branch
            task_data = {
              id: "v.0.9.0+task.202",
              title: "Orchestrator Task"
            }

            Atoms::GitCommand.stub(:current_branch, nil) do
              resolver = create_resolver({})
              result = resolver.resolve_target_branch(task_data)
              assert_equal "main", result
            end
          end

          def test_orchestrator_task_falls_back_to_main_when_detached_head
            task_data = {
              id: "v.0.9.0+task.229",
              title: "CLI Refactor"
            }

            Atoms::GitCommand.stub(:current_branch, "abc1234") do
              Atoms::GitCommand.stub(:ref_exists?, false) do
                resolver = create_resolver({})
                result = resolver.resolve_target_branch(task_data)
                assert_equal "main", result
              end
            end
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

            Atoms::GitCommand.stub(:current_branch, nil) do
              resolver = create_resolver("202" => parent_task)
              result = resolver.resolve_target_branch(subtask_data)
              assert_equal "main", result
            end
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

            Atoms::GitCommand.stub(:current_branch, nil) do
              resolver = create_resolver("202" => parent_task)
              result = resolver.resolve_target_branch(subtask_data)
              assert_equal "main", result
            end
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
            Atoms::GitCommand.stub(:current_branch, nil) do
              resolver = create_resolver({})
              result = resolver.extract_parent_branch(nil)
              assert_equal "main", result
            end
          end

          def test_extract_parent_branch_returns_default_for_no_worktree
            parent_task = {
              "id" => "v.0.9.0+task.202",
              "title" => "Parent Task"
            }

            Atoms::GitCommand.stub(:current_branch, nil) do
              resolver = create_resolver({})
              result = resolver.extract_parent_branch(parent_task)
              assert_equal "main", result
            end
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

          # Current branch fallback tests

          def test_current_branch_fallback_when_parent_has_no_worktree
            parent_task = {
              "id" => "v.0.9.0+task.202",
              "title" => "Parent Task"
              # No worktree metadata
            }

            subtask_data = {
              id: "v.0.9.0+task.202.01",
              title: "Subtask 01"
            }

            Atoms::GitCommand.stub(:current_branch, "216-add-rubocop-feature") do
              resolver = create_resolver("202" => parent_task)
              result = resolver.resolve_target_branch(subtask_data)
              assert_equal "216-add-rubocop-feature", result
            end
          end

          def test_main_fallback_when_detached_head_returns_sha
            parent_task = {
              "id" => "v.0.9.0+task.202",
              "title" => "Parent Task"
              # No worktree metadata
            }

            subtask_data = {
              id: "v.0.9.0+task.202.01",
              title: "Subtask 01"
            }

            # Simulate detached HEAD returning a SHA
            Atoms::GitCommand.stub(:current_branch, "abc1234") do
              Atoms::GitCommand.stub(:ref_exists?, false) do
                resolver = create_resolver("202" => parent_task)
                result = resolver.resolve_target_branch(subtask_data)
                assert_equal "main", result
              end
            end
          end

          def test_main_fallback_when_current_branch_returns_nil
            parent_task = {
              "id" => "v.0.9.0+task.202",
              "title" => "Parent Task"
              # No worktree metadata
            }

            subtask_data = {
              id: "v.0.9.0+task.202.01",
              title: "Subtask 01"
            }

            Atoms::GitCommand.stub(:current_branch, nil) do
              resolver = create_resolver("202" => parent_task)
              result = resolver.resolve_target_branch(subtask_data)
              assert_equal "main", result
            end
          end

          def test_parent_worktree_branch_takes_precedence_over_current_branch
            parent_task = {
              "id" => "v.0.9.0+task.202",
              "title" => "Parent Task",
              "worktree" => {
                "branch" => "202-parent-branch",
                "path" => ".ace-wt/task.202"
              }
            }

            subtask_data = {
              id: "v.0.9.0+task.202.01",
              title: "Subtask 01"
            }

            # Current branch should be ignored when parent has worktree branch
            Atoms::GitCommand.stub(:current_branch, "216-different-branch") do
              resolver = create_resolver("202" => parent_task)
              result = resolver.resolve_target_branch(subtask_data)
              assert_equal "202-parent-branch", result
            end
          end

          def test_current_branch_fallback_when_parent_worktree_has_no_branch
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

            Atoms::GitCommand.stub(:current_branch, "216-current-feature") do
              resolver = create_resolver("202" => parent_task)
              result = resolver.resolve_target_branch(subtask_data)
              assert_equal "216-current-feature", result
            end
          end

          # Direct unit tests for current_branch_fallback private method

          def test_current_branch_fallback_returns_branch_name
            Atoms::GitCommand.stub(:current_branch, "feature-branch") do
              resolver = create_resolver({})
              result = resolver.send(:current_branch_fallback)
              assert_equal "feature-branch", result
            end
          end

          def test_current_branch_fallback_returns_nil_for_nil_branch
            Atoms::GitCommand.stub(:current_branch, nil) do
              resolver = create_resolver({})
              result = resolver.send(:current_branch_fallback)
              assert_nil result
            end
          end

          def test_current_branch_fallback_returns_nil_for_empty_string
            Atoms::GitCommand.stub(:current_branch, "") do
              resolver = create_resolver({})
              result = resolver.send(:current_branch_fallback)
              assert_nil result
            end
          end

          def test_current_branch_fallback_returns_nil_for_explicit_head
            # Git returns "HEAD" in newer versions for detached state
            Atoms::GitCommand.stub(:current_branch, "HEAD") do
              resolver = create_resolver({})
              result = resolver.send(:current_branch_fallback)
              assert_nil result
            end
          end

          def test_current_branch_fallback_returns_nil_for_short_sha
            Atoms::GitCommand.stub(:current_branch, "abc1234") do
              Atoms::GitCommand.stub(:ref_exists?, false) do
                resolver = create_resolver({})
                result = resolver.send(:current_branch_fallback)
                assert_nil result
              end
            end
          end

          def test_current_branch_fallback_returns_nil_for_full_sha
            Atoms::GitCommand.stub(:current_branch, "abc1234567890abcdef1234567890abcdef12345") do
              Atoms::GitCommand.stub(:ref_exists?, false) do
                resolver = create_resolver({})
                result = resolver.send(:current_branch_fallback)
                assert_nil result
              end
            end
          end

          def test_current_branch_fallback_returns_nil_for_mixed_case_sha
            Atoms::GitCommand.stub(:current_branch, "AbC1234DeF") do
              Atoms::GitCommand.stub(:ref_exists?, false) do
                resolver = create_resolver({})
                result = resolver.send(:current_branch_fallback)
                assert_nil result
              end
            end
          end

          def test_current_branch_fallback_returns_hex_branch_when_branch_exists
            Atoms::GitCommand.stub(:current_branch, "deadbeef") do
              Atoms::GitCommand.stub(:ref_exists?, ->(ref) { ref == "refs/heads/deadbeef" }) do
                resolver = create_resolver({})
                result = resolver.send(:current_branch_fallback)
                assert_equal "deadbeef", result
              end
            end
          end

          def test_current_branch_fallback_rescues_standard_error
            Atoms::GitCommand.stub(:current_branch, -> { raise StandardError, "Git error" }) do
              resolver = create_resolver({})
              result = resolver.send(:current_branch_fallback)
              assert_nil result
            end
          end

          # Integration test for error handling in extract_parent_branch

          def test_extract_parent_branch_handles_git_error_gracefully
            parent_task = {
              "id" => "v.0.9.0+task.202",
              "title" => "Parent Task"
              # No worktree metadata - will trigger fallback
            }

            Atoms::GitCommand.stub(:current_branch, -> { raise Errno::ENOENT, "git not found" }) do
              resolver = create_resolver({})
              result = resolver.extract_parent_branch(parent_task)
              assert_equal "main", result
            end
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
