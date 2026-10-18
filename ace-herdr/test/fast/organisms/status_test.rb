# frozen_string_literal: true

require "json"
require "test_helper"

module Ace
  module Herdr
    module Organisms
      class StatusTest < Minitest::Test
        def native_result(payload)
          Molecules::ExecutionResult.new(
            stdout: JSON.generate(payload), stderr: "", success: true, exit_code: 0
          )
        end

        def full_outcomes
          {
            workspace_list: native_result(result: {workspaces: [
              {"workspace_id" => "w1", "label" => "development", "number" => 1, "tab_count" => 2, "pane_count" => 3, "focused" => true},
              {"workspace_id" => "w2", "label" => "scratch", "number" => 2, "tab_count" => 1, "pane_count" => 2, "focused" => false}
            ]}),
            tab_list: native_result(result: {tabs: [
              {"tab_id" => "w1:t1", "workspace_id" => "w1", "label" => "editor", "number" => 1, "pane_count" => 2, "focused" => true},
              {"tab_id" => "w1:t2", "workspace_id" => "w1", "label" => "build", "number" => 2, "pane_count" => 1, "focused" => false},
              {"tab_id" => "w2:t1", "workspace_id" => "w2", "label" => "logs", "number" => 1, "pane_count" => 2, "focused" => false}
            ]}),
            pane_list: native_result(result: {panes: [
              {"pane_id" => "p1", "tab_id" => "w1:t1", "workspace_id" => "w1", "terminal_title" => "agent", "cwd" => "/Users/x/ace", "focused" => true, "agent_status" => "working"},
              {"pane_id" => "p2", "tab_id" => "w1:t1", "workspace_id" => "w1", "terminal_title" => "shell", "cwd" => "/Users/x/ace/ace-herdr", "focused" => false},
              {"pane_id" => "p3", "tab_id" => "w1:t2", "workspace_id" => "w1", "terminal_title" => "build", "cwd" => "/Users/x/ace", "focused" => false},
              {"pane_id" => "p4", "tab_id" => "w2:t1", "workspace_id" => "w2", "terminal_title" => "logs", "cwd" => "/tmp", "focused" => false},
              {"pane_id" => "p5", "tab_id" => "orphan:t9", "workspace_id" => "orphan", "terminal_title" => "race", "cwd" => "/tmp", "focused" => false}
            ]})
          }
        end

        def test_full_tree_groups_panes_under_tabs_under_workspaces
          executor = HerdrTestHelper::FakeExecutor.new(outcomes: full_outcomes)
          snapshot = Status.new(executor: executor).snapshot

          assert_equal "available", snapshot["runtime"]["state"]
          assert_equal({"workspaces" => 2, "tabs" => 3, "panes" => 5}, snapshot["counts"])

          w1 = snapshot["workspaces"].first
          assert_equal "w1", w1["workspace"][:id]
          t1 = w1["tabs"].first
          assert_equal "w1:t1", t1["tab"][:id]
          assert_equal %w[p1 p2], t1["panes"].map { |p| p[:id] }

          w2 = snapshot["workspaces"][1]
          assert_equal %w[w2:t1], w2["tabs"].map { |t| t["tab"][:id] }

          assert_equal(["p5"], snapshot["unattached"]["panes"].map { |p| p[:id] })
          assert_equal([], snapshot["unattached"]["tabs"])
        end

        def test_empty_valid_set_is_available_not_unavailable
          executor = HerdrTestHelper::FakeExecutor.new
          snapshot = Status.new(executor: executor).snapshot

          assert_equal "available", snapshot["runtime"]["state"]
          assert_equal({"workspaces" => 0, "tabs" => 0, "panes" => 0}, snapshot["counts"])
          assert_equal [], snapshot["workspaces"]
        end

        def test_unavailable_runtime_is_marked_not_empty
          executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            workspace_list: ExecutorUnavailableError.new("herdr binary not found")
          })
          snapshot = Status.new(executor: executor).snapshot

          assert_equal "unavailable", snapshot["runtime"]["state"]
          assert_includes snapshot["runtime"]["error"], "herdr binary not found"
          assert_nil snapshot["counts"]
          assert_nil snapshot["workspaces"]
        end

        def test_source_error_is_marked
          executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            workspace_list: CommandError.new("herdr exit 1: socket closed")
          })
          snapshot = Status.new(executor: executor).snapshot

          assert_equal "error", snapshot["runtime"]["state"]
          assert_includes snapshot["runtime"]["error"], "socket closed"
          assert_nil snapshot["counts"]
        end

        def test_unattached_tab_lands_in_unattached_bucket
          outcomes = full_outcomes
          outcomes[:tab_list] = native_result(result: {tabs: [
            {"tab_id" => "w1:t1", "workspace_id" => "w1", "label" => "editor", "number" => 1, "pane_count" => 2, "focused" => true},
            {"tab_id" => "ghost:t1", "workspace_id" => "ghost", "label" => "race", "number" => 9, "pane_count" => 0, "focused" => false}
          ]})
          executor = HerdrTestHelper::FakeExecutor.new(outcomes: outcomes)
          snapshot = Status.new(executor: executor).snapshot

          assert_equal(["ghost:t1"], snapshot["unattached"]["tabs"].map { |t| t[:id] })
          assert_equal 2, snapshot["counts"]["tabs"]
        end
      end
    end
  end
end
