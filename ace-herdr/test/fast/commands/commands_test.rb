# frozen_string_literal: true

require "test_helper"

module Ace
  module Herdr
    module CLI
      module Commands
        class CommandsTest < Minitest::Test
          def setup
            @dir = Dir.mktmpdir("ace_herdr_commands_test")
            @executor = HerdrTestHelper::FakeExecutor.new
          end

          def teardown
            FileUtils.rm_rf(@dir)
          end

          def write_file(name, content)
            path = File.join(@dir, name)
            File.write(path, content)
            path
          end

          # --- default construction (CLI registration path) ------------------

          def test_all_commands_build_real_executor_by_default
            [Deliver, Dispatch, Wait, Close].each do |command_class|
              assert_instance_of Molecules::HerdrExecutor, command_class.new.send(:executor)
            end
          end

          def test_deliver_resume_redelivers_stored_answer_without_ref
            cmd = Deliver.new(executor: @executor)
            answer_path = write_file("a.md", "stored answer")
            capture_io do
              cmd.call(
                session: "ws-1", pane: "p5", event_id: "evt-resume",
                kind: nil, label: nil, answer_file: answer_path, resume: nil
              )
            end

            out, = capture_io do
              with_env("HERDR_SESSION" => nil, "HERDR_PANE" => nil) do
                cmd.call(
                  session: nil, pane: nil, event_id: nil, kind: nil,
                  label: nil, answer_file: nil, resume: "evt-resume"
                )
              end
            end

            parsed = JSON.parse(out)
            assert parsed["resumed"]
            assert_equal "delivered", parsed["state"]
          ensure
            FileUtils.rm_f(Dir.glob(".ace-local/herdr/deliveries/evt-resume*"))
          end

          # --- deliver -------------------------------------------------------

          def test_deliver_outputs_state_and_succeeds
            cmd = Deliver.new(executor: @executor)

            out, = capture_io do
              cmd.call(
                session: "ws-1", pane: "p5", event_id: "evt-1",
                kind: nil, label: nil, answer_file: write_file("a.md", "answer")
              )
            end

            parsed = JSON.parse(out)
            assert_equal "delivered", parsed["state"]
            assert_equal "ws-1", parsed["ref"]["session"]
          end

          def test_deliver_non_delivered_state_raises_cli_error
            @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
              agent_prompt: Ace::Herdr::AgentBlockedError.new("blocked")
            })
            cmd = Deliver.new(executor: @executor)

            error = assert_raises(Ace::Support::Cli::Error) do
              capture_io do
                cmd.call(
                  session: "ws-1", pane: "p5", event_id: "evt-2",
                  kind: nil, label: nil, answer_file: write_file("a.md", "answer")
                )
              end
            end

            assert_match(/failed/, error.message)
          end

          def test_deliver_without_resolvable_ref_fails_closed
            cmd = Deliver.new(executor: @executor)

            with_env("HERDR_SESSION" => nil, "HERDR_PANE" => nil) do
              error = assert_raises(Ace::Support::Cli::Error) do
                cmd.call(
                  session: nil, pane: nil, event_id: nil,
                  kind: nil, label: nil, answer_file: write_file("a.md", "answer")
                )
              end
              assert_match(/HERDR_SESSION/, error.message)
            end
          end

          def test_deliver_missing_answer_file_is_cli_error
            cmd = Deliver.new(executor: @executor)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(
                session: "ws-1", pane: "p5", event_id: "evt-3",
                kind: nil, label: nil, answer_file: File.join(@dir, "missing.md")
              )
            end

            assert_match(/not found/, error.message)
          end

          # --- dispatch --------------------------------------------------------

          def test_dispatch_outputs_outcome_json
            cmd = Dispatch.new(executor: @executor)

            out, = capture_io do
              with_env("HERDR_WORKSPACE_ID" => "ws-1") do
                cmd.call(
                  label: "8wm.t.vs0", kind: nil, workspace: nil, pane: "p7",
                  cwd: nil, prompt_file: write_file("p.md", "go"), no_prompt: nil
                )
              end
            end

            parsed = JSON.parse(out)
            assert_equal "p7", parsed["pane"]
            assert_equal "8wm.t.vs0", parsed["agent"]
            refute parsed["tab_created"]
          end

          def test_dispatch_requires_label
            cmd = Dispatch.new(executor: @executor)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(
                label: nil, kind: nil, workspace: nil, pane: nil,
                cwd: nil, prompt_file: nil, no_prompt: true
              )
            end

            assert_match(/--label is required/, error.message)
          end

          # --- wait ------------------------------------------------------------

          def test_wait_passes_until_states_and_timeout_to_executor
            cmd = Wait.new(executor: @executor)

            capture_io do
              cmd.call(pane: "p5", until: "done,idle", timeout: 12, quiet: true)
            end

            call = @executor.calls_of(:agent_wait).first
            assert_equal({pane: "p5", until_states: %w[done idle], timeout_ms: 12_000}, call[:args])
          end

          def test_wait_reports_ready_json_without_quiet
            cmd = Wait.new(executor: @executor)

            out, = capture_io do
              cmd.call(pane: "p5", until: nil, timeout: 5, quiet: nil)
            end

            assert_match(/"state":"ready"/, out)
          end

          def test_wait_requires_pane
            cmd = Wait.new(executor: @executor)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(pane: nil, until: nil, timeout: nil, quiet: nil)
            end

            assert_match(/--pane is required/, error.message)
          end

          # --- wait: output mode -----------------------------------------------

          def test_wait_output_converts_seconds_to_ms_and_passes_pattern
            cmd = Wait.new(executor: @executor)

            capture_io do
              cmd.call(pane: "p5", for: "output", pattern: "done", until: nil, timeout: 15, quiet: nil)
            end

            call = @executor.calls_of(:pane_wait_output).first
            assert_equal(
              {pane: "p5", pattern: "done", source: "recent", lines: nil, timeout_ms: 15_000},
              call[:args]
            )
          end

          def test_wait_output_reports_matched_json
            cmd = Wait.new(executor: @executor)

            out, = capture_io do
              cmd.call(pane: "p5", for: "output", pattern: "done", until: nil, timeout: 5, quiet: nil)
            end

            parsed = JSON.parse(out)
            assert_equal "p5", parsed["pane"]
            assert parsed["matched"]
          end

          def test_wait_agent_mode_unchanged_by_output_options
            cmd = Wait.new(executor: @executor)

            out, = capture_io do
              cmd.call(pane: "p5", for: "agent", pattern: nil, until: "done", timeout: 5, quiet: nil)
            end

            assert_match(/"state":"ready"/, out)
            assert_empty @executor.calls_of(:pane_wait_output)
          end

          def test_wait_output_requires_pattern
            cmd = Wait.new(executor: @executor)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(pane: "p5", for: "output", pattern: nil, until: nil, timeout: nil, quiet: nil)
            end

            assert_match(/requires --pattern/, error.message)
          end

          def test_wait_output_rejects_until
            cmd = Wait.new(executor: @executor)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(pane: "p5", for: "output", pattern: "x", until: "done", timeout: nil, quiet: nil)
            end

            assert_match(/--until requires --for agent/, error.message)
          end

          def test_wait_agent_rejects_pattern
            cmd = Wait.new(executor: @executor)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(pane: "p5", for: "agent", pattern: "x", until: nil, timeout: nil, quiet: nil)
            end

            assert_match(/--pattern requires --for output/, error.message)
          end

          def test_wait_timeout_error_is_cli_error
            @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
              pane_wait_output: Ace::Herdr::WaitTimeoutError.new("timeout: no match")
            })
            cmd = Wait.new(executor: @executor)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(pane: "p5", for: "output", pattern: "x", until: nil, timeout: 1, quiet: nil)
            end

            assert_match(/timeout/, error.message)
          end

          # --- close -------------------------------------------------------------

          def test_close_renames_and_closes
            cmd = Close.new(executor: @executor)

            out, = capture_io do
              cmd.call(pane: "p5", rename: "done", keep: nil)
            end

            parsed = JSON.parse(out)
            assert parsed["renamed"]
            assert parsed["closed"]
            assert_equal 1, @executor.calls_of(:pane_rename).length
            assert_equal 1, @executor.calls_of(:pane_close).length
          end

          def test_close_keep_renames_without_closing
            cmd = Close.new(executor: @executor)

            out, = capture_io do
              cmd.call(pane: "p5", rename: "wip", keep: true)
            end

            parsed = JSON.parse(out)
            assert parsed["renamed"]
            refute parsed["closed"]
            assert_empty @executor.calls_of(:pane_close)
          end

          def test_close_requires_pane
            cmd = Close.new(executor: @executor)

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(pane: nil, rename: nil, keep: nil)
            end

            assert_match(/--pane is required/, error.message)
          end
        end
      end
    end
  end
end
