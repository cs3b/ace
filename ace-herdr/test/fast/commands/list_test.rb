# frozen_string_literal: true

require "json"
require "test_helper"

module Ace
  module Herdr
    module CLI
      module Commands
        class ListTest < Minitest::Test
          def setup
            @executor = HerdrTestHelper::FakeExecutor.new
          end

          def native_result(payload)
            Molecules::ExecutionResult.new(
              stdout: JSON.generate(payload), stderr: "", success: true, exit_code: 0
            )
          end

          def test_lists_panes_by_default
            cmd = List.new(executor: @executor)

            out, = capture_io do
              cmd.call(panes: nil, tabs: nil, workspaces: nil, workspace: nil, quiet: nil)
            end

            parsed = JSON.parse(out)
            assert_equal [], parsed["panes"]
          end

          def test_lists_tabs_scoped_to_workspace
            @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
              tab_list: native_result(result: {tabs: [{"tab_id" => "w1:t1", "label" => "editor"}]})
            })
            cmd = List.new(executor: @executor)

            out, = capture_io do
              cmd.call(panes: nil, tabs: true, workspaces: nil, workspace: "w1", quiet: nil)
            end

            parsed = JSON.parse(out)
            assert_equal "w1:t1", parsed["tabs"].first["id"]
            call = @executor.calls_of(:tab_list).first
            assert_equal({workspace_id: "w1"}, call[:args])
          end

          def test_lists_workspaces
            cmd = List.new(executor: @executor)

            out, = capture_io do
              cmd.call(panes: nil, tabs: nil, workspaces: true, workspace: nil, quiet: nil)
            end

            parsed = JSON.parse(out)
            assert_equal [], parsed["workspaces"]
          end

          def test_rejects_multiple_scope_flags
            cmd = List.new(executor: @executor)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(panes: true, tabs: true, workspaces: nil, workspace: nil, quiet: nil)
            end

            assert_match(/only one of/, error.message)
          end

          def test_rejects_workspaces_with_workspace_scope
            cmd = List.new(executor: @executor)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(panes: nil, tabs: nil, workspaces: true, workspace: "w1", quiet: nil)
            end

            assert_match(/--workspaces does not accept --workspace/, error.message)
          end

          def test_quiet_suppresses_output
            cmd = List.new(executor: @executor)

            out, = capture_io do
              cmd.call(panes: nil, tabs: nil, workspaces: nil, workspace: nil, quiet: true)
            end

            assert_equal "", out
          end

          def test_unknown_workspace_surfaces_native_code
            @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
              pane_list: Ace::Herdr::WorkspaceNotFoundError.new("workspace_not_found: nope")
            })
            cmd = List.new(executor: @executor)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(panes: nil, tabs: nil, workspaces: nil, workspace: "nope", quiet: nil)
            end

            assert_match(/workspace_not_found/, error.message)
          end
        end
      end
    end
  end
end
