# frozen_string_literal: true

require "json"
require "test_helper"

module Ace
  module Herdr
    module CLI
      module Commands
        class StatusTest < Minitest::Test
          def setup
            @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
              workspace_list: native_result(result: {workspaces: [
                {"workspace_id" => "w1", "label" => "main", "number" => 1, "focused" => true}
              ]}),
              tab_list: native_result(result: {tabs: [
                {"tab_id" => "w1:t1", "workspace_id" => "w1", "label" => "agent", "number" => 1, "focused" => true}
              ]}),
              pane_list: native_result(result: {panes: [
                {"pane_id" => "p5", "tab_id" => "w1:t1", "workspace_id" => "w1",
                 "terminal_title" => "pi", "cwd" => Dir.home + "/Ps/ace", "focused" => true,
                 "agent_status" => "working"},
                {"pane_id" => "p6", "tab_id" => "w1:t1", "workspace_id" => "w1",
                 "terminal_title_stripped" => "", "cwd" => "/tmp", "focused" => false}
              ]})
            })
          end

          def native_result(payload)
            Molecules::ExecutionResult.new(
              stdout: JSON.generate(payload), stderr: "", success: true, exit_code: 0
            )
          end

          def call_cmd(options = {})
            cmd = Status.new(executor: @executor)
            capture_io { cmd.call(**{workspace: nil, format: "table", quiet: nil}.merge(options)) }
          end

          def test_issues_all_three_list_calls
            call_cmd

            assert @executor.calls_of(:workspace_list).length == 1
            assert @executor.calls_of(:tab_list).length == 1
            assert @executor.calls_of(:pane_list).length == 1
          end

          def test_workspace_scope_reaches_tabs_and_panes
            call_cmd(workspace: "w1")

            assert_equal({workspace_id: "w1"}, @executor.calls_of(:tab_list).first[:args])
            assert_equal({workspace_id: "w1"}, @executor.calls_of(:pane_list).first[:args])
          end

          def test_workspace_scope_renders_only_the_requested_workspace
            @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
              workspace_list: native_result(result: {workspaces: [
                {"workspace_id" => "w1", "label" => "main", "number" => 1, "focused" => true},
                {"workspace_id" => "w2", "label" => "other", "number" => 2, "focused" => false}
              ]}),
              tab_list: native_result(result: {tabs: [
                {"tab_id" => "w1:t1", "workspace_id" => "w1", "label" => "agent", "number" => 1, "focused" => true},
                {"tab_id" => "w2:t1", "workspace_id" => "w2", "label" => "side", "number" => 1, "focused" => false}
              ]}),
              pane_list: native_result(result: {panes: [
                {"pane_id" => "p5", "tab_id" => "w1:t1", "workspace_id" => "w1",
                 "terminal_title" => "pi", "cwd" => "/tmp", "focused" => true}
              ]})
            })
            out, = call_cmd(workspace: "w1")

            assert_includes out, "Herdr: 1 workspace(s), 1 tab(s), 1 pane(s)"
            assert_includes out, "* w1"
            refute_includes out, "w2"
          end

          def test_unknown_workspace_scope_is_a_concrete_error
            error = assert_raises(Ace::Support::Cli::Error) { call_cmd(workspace: "nope") }

            assert_match(/Unknown workspace: nope/, error.message)
          end

          def test_table_renders_tree_with_focus_marker_agent_and_home_shortening
            out, = call_cmd

            assert_includes out, "Herdr: 1 workspace(s), 1 tab(s), 2 pane(s)"
            assert_includes out, "* w1"
            assert_includes out, "w1:t1"
            assert_includes out, "~/Ps/ace"
            assert_includes out, "agent: working"
            assert_includes out, "—"
          end

          def test_home_shortening_respects_path_boundaries
            @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
              workspace_list: native_result(result: {workspaces: [
                {"workspace_id" => "w1", "label" => "main", "number" => 1, "focused" => true}
              ]}),
              tab_list: native_result(result: {tabs: [
                {"tab_id" => "w1:t1", "workspace_id" => "w1", "label" => "agent", "number" => 1, "focused" => true}
              ]}),
              pane_list: native_result(result: {panes: [
                {"pane_id" => "p5", "tab_id" => "w1:t1", "workspace_id" => "w1",
                 "terminal_title" => "sibling", "cwd" => Dir.home + "-tools/x", "focused" => true}
              ]})
            })
            out, = call_cmd

            assert_includes out, "#{Dir.home}-tools/x"
            refute_includes out, "~-tools/x"
          end

          def test_table_omits_agent_status_when_absent
            out, = call_cmd

            refute_includes out, "agent: \n"
            lines = out.split("\n")
            pane_lines = lines.select { |line| line.include?("p6") }
            assert pane_lines.one?
            refute_includes pane_lines.first, "agent:"
          end

          def test_json_format_emits_composed_tree
            out, = call_cmd(format: "json")

            parsed = JSON.parse(out)
            workspace = parsed["workspaces"].first
            assert_equal "w1", workspace["id"]
            assert_equal 1, workspace["tab_count"]
            assert_equal 2, workspace["pane_count"]
            tab = workspace["tabs"].first
            assert_equal "w1:t1", tab["id"]
            assert_equal 2, tab["panes"].length
          end

          def test_empty_live_state_is_not_an_error
            @executor = HerdrTestHelper::FakeExecutor.new
            out, = call_cmd

            assert_includes out, "No live herdr workspaces."
          end

          def test_unavailable_runtime_is_an_error_not_an_empty_table
            @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
              workspace_list: Ace::Herdr::ExecutorUnavailableError.new("herdr CLI or socket unreachable")
            })

            error = assert_raises(Ace::Support::Cli::Error) { call_cmd }
            assert_match(/unreachable/, error.message)
          end

          def test_generic_executor_error_is_surfaced
            @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
              workspace_list: Ace::Herdr::CommandError.new("herdr list failed")
            })

            error = assert_raises(Ace::Support::Cli::Error) { call_cmd }
            assert_match(/herdr list failed/, error.message)
          end

          def test_quiet_suppresses_output
            out, = call_cmd(quiet: true)

            assert_equal "", out
          end

          def test_invalid_format_is_a_usage_error
            error = assert_raises(Ace::Support::Cli::Error) { call_cmd(format: "xml") }

            assert_match(/Invalid format/, error.message)
          end
        end
      end
    end
  end
end
