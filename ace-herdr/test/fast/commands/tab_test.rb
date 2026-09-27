# frozen_string_literal: true

require "json"
require "test_helper"

module Ace
  module Herdr
    module CLI
      module Commands
        class TabTest < Minitest::Test
          # Loader stub serving the tab preset under test
          class StubLoader
            def load(type, name)
              {"tabs" => {"agent" => {"label" => "agent", "panes" => [{"label" => "agent"}]}}}[type][name]
            end

            def list(type)
              type == "tabs" ? %w[agent] : []
            end

            def to_lookup(type)
              ->(name) { load(type, name) }
            end
          end

          def setup
            @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
              tab_create: Molecules::ExecutionResult.new(
                stdout: JSON.generate(result: {tab: {tab_id: "w1:t9"}, root_pane: {pane_id: "w1:p9"}}),
                stderr: "", success: true, exit_code: 0
              )
            })
            @control = Organisms::ControlSurface.new(
              executor: @executor, preset_loader: StubLoader.new
            )
            @cmd = Tab.new(executor: @executor, control: @control)
          end

          def test_outputs_tab_payload_json
            out, = with_env("HERDR_WORKSPACE_ID" => "w1") do
              capture_io { @cmd.call(preset: "agent", workspace: nil, cwd: nil, quiet: nil) }
            end

            parsed = JSON.parse(out)
            assert_equal "w1:t9", parsed["tab"]
            assert_equal ["w1:p9"], parsed["panes"]
          end

          def test_passes_explicit_workspace
            capture_io do
              with_env("HERDR_WORKSPACE_ID" => "w1") do
                @cmd.call(preset: "agent", workspace: "w2", cwd: nil, quiet: true)
              end
            end

            call = @executor.calls_of(:tab_create).first
            assert_equal "w2", call[:args][:workspace_id]
          end

          def test_requires_preset_argument
            error = assert_raises(Ace::Support::Cli::Error) do
              @cmd.call(preset: nil, workspace: nil, cwd: nil, quiet: nil)
            end

            assert_match(/preset name is required/, error.message)
          end
        end
      end
    end
  end
end
