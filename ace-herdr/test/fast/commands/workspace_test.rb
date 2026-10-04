# frozen_string_literal: true

require "json"
require "test_helper"

module Ace
  module Herdr
    module CLI
      module Commands
        class WorkspaceTest < Minitest::Test
          # Loader stub serving the preset under test
          class StubLoader
            def load(type, name)
              {"workspaces" => {"dev" => {"label" => "dev"}}}[type][name]
            end

            def list(type)
              type == "workspaces" ? %w[dev] : []
            end

            def to_lookup(type)
              ->(name) { load(type, name) }
            end
          end

          def setup
            @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
              workspace_create: Molecules::ExecutionResult.new(
                stdout: JSON.generate(
                  result: {workspace: {workspace_id: "w2"}, tab: {tab_id: "w2:t1"}, root_pane: {pane_id: "w2:p1"}}
                ),
                stderr: "", success: true, exit_code: 0
              )
            })
            @control = Organisms::ControlSurface.new(
              executor: @executor, preset_loader: StubLoader.new
            )
            @cmd = Workspace.new(executor: @executor, control: @control)
          end

          def test_outputs_workspace_payload_json
            out, = capture_io { @cmd.call(preset: "dev", cwd: nil, quiet: nil) }

            parsed = JSON.parse(out)
            assert_equal "w2", parsed["workspace"]
            assert_equal [], parsed["tabs"]
          end

          def test_requires_preset_argument
            error = assert_raises(Ace::Support::Cli::Error) do
              @cmd.call(preset: nil, cwd: nil, quiet: nil)
            end

            assert_match(/preset name is required/, error.message)
          end

          def test_quiet_suppresses_output
            out, = capture_io { @cmd.call(preset: "dev", cwd: nil, quiet: true) }

            assert_equal "", out
            assert_equal 1, @executor.calls_of(:workspace_create).length
          end

          def test_unknown_preset_lists_available
            error = assert_raises(Ace::Support::Cli::Error) do
              @cmd.call(preset: "nope", cwd: nil, quiet: nil)
            end

            assert_match(/available: dev/, error.message)
          end

          def test_materialization_failure_translates_to_a_cli_error
            failing = Class.new(Organisms::ControlSurface) do
              def create_workspace(*)
                raise TabMaterializationError.new(
                  tab_id: "w2:t2",
                  message: "Runtime::Error: pane split failed after native create"
                )
              end
            end.new(executor: @executor, preset_loader: StubLoader.new)
            cmd = Workspace.new(executor: @executor, control: failing)

            error = assert_raises(Ace::Support::Cli::Error) do
              capture_io { cmd.call(preset: "dev", cwd: nil, quiet: nil) }
            end

            assert_match(/pane split failed after native create/, error.message)
          end
        end
      end
    end
  end
end
