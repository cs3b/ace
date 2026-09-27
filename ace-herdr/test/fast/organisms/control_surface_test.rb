# frozen_string_literal: true

require "test_helper"

module Ace
  module Herdr
    module Organisms
      class ControlSurfaceTest < Minitest::Test
        def setup
          @executor = HerdrTestHelper::FakeExecutor.new
          @control = ControlSurface.new(executor: @executor)
        end

        def native_result(payload)
          Molecules::ExecutionResult.new(
            stdout: JSON.generate(payload), stderr: "", success: true, exit_code: 0
          )
        end

        # --- list -----------------------------------------------------------

        def test_list_panes_normalizes_native_rows
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_list: native_result(
              id: "cli:pane:list",
              result: {
                type: "pane_list",
                panes: [
                  {
                    "pane_id" => "w1:p1", "tab_id" => "w1:t1", "workspace_id" => "w1",
                    "terminal_title" => "~", "terminal_title_stripped" => "~",
                    "cwd" => "/tmp", "focused" => true, "agent_status" => "idle"
                  }
                ]
              }
            )
          })
          @control = ControlSurface.new(executor: @executor)

          panes = @control.list_panes

          assert_equal(
            [{id: "w1:p1", tab: "w1:t1", workspace: "w1", title: "~", cwd: "/tmp",
              focused: true, agent_status: "idle"}],
            panes
          )
        end

        def test_list_panes_falls_back_to_raw_title
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            pane_list: native_result(
              result: {panes: [{"pane_id" => "w1:p1", "terminal_title" => "raw"}]}
            )
          })
          @control = ControlSurface.new(executor: @executor)

          assert_equal "raw", @control.list_panes.first[:title]
        end

        def test_list_panes_scopes_by_workspace
          @control.list_panes(workspace_id: "w2")

          call = @executor.calls_of(:pane_list).first
          assert_equal({workspace_id: "w2"}, call[:args])
        end

        def test_list_panes_empty_result_is_empty_array
          assert_empty @control.list_panes
        end

        def test_list_tabs_normalizes_native_rows
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            tab_list: native_result(
              result: {
                tabs: [{
                  "tab_id" => "w1:t1", "workspace_id" => "w1", "label" => "editor",
                  "number" => 1, "pane_count" => 2, "focused" => true
                }]
              }
            )
          })
          @control = ControlSurface.new(executor: @executor)

          assert_equal(
            [{id: "w1:t1", workspace: "w1", title: "editor", number: 1,
              pane_count: 2, focused: true}],
            @control.list_tabs
          )
        end

        def test_list_workspaces_normalizes_native_rows
          @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
            workspace_list: native_result(
              result: {
                workspaces: [{
                  "workspace_id" => "w1", "label" => "dev", "number" => 1,
                  "tab_count" => 2, "pane_count" => 3, "focused" => false
                }]
              }
            )
          })
          @control = ControlSurface.new(executor: @executor)

          assert_equal(
            [{id: "w1", title: "dev", number: 1, tab_count: 2, pane_count: 3, focused: false}],
            @control.list_workspaces
          )
        end
      end
    end
  end
end
