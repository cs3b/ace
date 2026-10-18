# frozen_string_literal: true

require "json"
require "test_helper"

module Ace
  module Herdr
    module CLI
      module Commands
        class StatusCommandTest < Minitest::Test
          def native_result(payload)
            Molecules::ExecutionResult.new(
              stdout: JSON.generate(payload), stderr: "", success: true, exit_code: 0
            )
          end

          def executor_with_layout
            HerdrTestHelper::FakeExecutor.new(outcomes: {
              workspace_list: native_result(result: {workspaces: [
                {"workspace_id" => "w1", "label" => "development", "number" => 1, "tab_count" => 1, "pane_count" => 2, "focused" => true}
              ]}),
              tab_list: native_result(result: {tabs: [
                {"tab_id" => "w1:t1", "workspace_id" => "w1", "label" => "editor", "number" => 1, "pane_count" => 2, "focused" => true}
              ]}),
              pane_list: native_result(result: {panes: [
                {"pane_id" => "p1", "tab_id" => "w1:t1", "workspace_id" => "w1", "terminal_title" => "agent", "cwd" => Dir.home, "focused" => true, "agent_status" => "working"},
                {"pane_id" => "p2", "tab_id" => "w1:t1", "workspace_id" => "w1", "terminal_title" => "shell", "cwd" => "/tmp", "focused" => false}
              ]})
            })
          end

          def test_table_shows_runtime_counts_and_tree
            cmd = Status.new(executor: executor_with_layout)

            out, = capture_io do
              cmd.call(format: nil, quiet: nil)
            end

            assert_includes out, "Herdr runtime: available"
            assert_includes out, "Workspaces: 1  Tabs: 1  Panes: 2"
            assert_includes out, "w1 development *"
            assert_includes out, "w1:t1 editor *"
            assert_includes out, "agent:working"
            assert_includes out, "plain"
            assert_includes out, "agent  ~"
          end

          def test_json_output_matches_schema
            cmd = Status.new(executor: executor_with_layout)

            out, = capture_io do
              cmd.call(format: "json", quiet: nil)
            end

            parsed = JSON.parse(out)
            assert_equal "available", parsed.dig("runtime", "state")
            assert_equal 1, parsed.dig("counts", "workspaces")
            assert_equal "w1", parsed.dig("workspaces", 0, "workspace", "id")
            assert_equal "p1", parsed.dig("workspaces", 0, "tabs", 0, "panes", 0, "id")
          end

          def test_unavailable_renders_marker_not_empty_table
            cmd = Status.new(executor: HerdrTestHelper::FakeExecutor.new(outcomes: {
              workspace_list: ExecutorUnavailableError.new("herdr binary not found")
            }))

            out, = capture_io do
              cmd.call(format: nil, quiet: nil)
            end

            assert_includes out, "Herdr runtime: unavailable"
            assert_includes out, "Start or install herdr"
            refute_includes out, "Workspaces: 0"
          end

          def test_error_renders_marker
            cmd = Status.new(executor: HerdrTestHelper::FakeExecutor.new(outcomes: {
              workspace_list: CommandError.new("herdr exit 1: boom")
            }))

            out, = capture_io do
              cmd.call(format: nil, quiet: nil)
            end

            assert_includes out, "Herdr runtime: error - herdr exit 1: boom"
          end

          def test_empty_valid_set_renders_zero_counts
            cmd = Status.new(executor: HerdrTestHelper::FakeExecutor.new)

            out, = capture_io do
              cmd.call(format: nil, quiet: nil)
            end

            assert_includes out, "Herdr runtime: available"
            assert_includes out, "Workspaces: 0  Tabs: 0  Panes: 0"
            assert_includes out, "No herdr workspaces, tabs, or panes."
          end

          def test_quiet_prints_nothing
            cmd = Status.new(executor: executor_with_layout)

            out, = capture_io do
              cmd.call(format: nil, quiet: true)
            end

            assert_equal "", out
          end

          def test_invalid_format_is_a_usage_error
            cmd = Status.new(executor: HerdrTestHelper::FakeExecutor.new)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(format: "yaml", quiet: nil)
            end
            assert_includes error.message, "table or json"
          end
        end
      end
    end
  end
end
