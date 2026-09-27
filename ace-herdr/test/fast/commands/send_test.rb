# frozen_string_literal: true

require "json"
require "test_helper"

module Ace
  module Herdr
    module CLI
      module Commands
        class SendTest < Minitest::Test
          def setup
            @executor = plain_executor
          end

          # agent_get raising agent_not_found proves a plain pane
          def plain_executor
            HerdrTestHelper::FakeExecutor.new(outcomes: {
              agent_get: Ace::Herdr::AgentNotFoundError.new("agent_not_found: no agent")
            })
          end

          def test_sends_cmd_from_argv_order
            cmd = Send.new(executor: @executor, argv_source: %w[send --pane p5 --cmd ls --key enter])

            out, = capture_io { cmd.call(pane: "p5", cmd: "ls", msg: [], key: ["enter"], quiet: nil) }

            parsed = JSON.parse(out)
            assert_equal "cmd", parsed["sent"]
            assert_equal({pane: "p5", command: "ls"}, @executor.calls_of(:pane_run).first[:args])
          end

          def test_preserves_declaration_order_across_flags
            cmd = Send.new(
              executor: @executor,
              argv_source: %w[send --pane p5 --msg one --key enter --msg two]
            )

            capture_io { cmd.call(pane: "p5", cmd: nil, msg: %w[one two], key: ["enter"], quiet: true) }

            operations = @executor.calls.map { |c| c[:operation] }
            assert_equal %i[agent_get pane_send_text pane_send_keys pane_send_text], operations
          end

          def test_rejects_key_before_cmd_from_argv_before_transport
            cmd = Send.new(executor: @executor, argv_source: %w[send --pane p5 --key esc --cmd run])

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(pane: "p5", cmd: "run", msg: [], key: ["esc"], quiet: nil)
            end

            assert_match(/after --cmd/, error.message)
            assert_empty @executor.calls
          end

          def test_parses_equals_form_flags
            cmd = Send.new(executor: @executor, argv_source: %w[send --pane p5 --msg=hello --key=enter])

            out, = capture_io { cmd.call(pane: "p5", cmd: nil, msg: ["hello"], key: ["enter"], quiet: nil) }

            parsed = JSON.parse(out)
            assert_equal "text", parsed["sent"]
          end

          def test_falls_back_to_option_arrays_without_argv_input_flags
            cmd = Send.new(executor: @executor, argv_source: %w[some test argv])

            out, = capture_io { cmd.call(pane: "p5", cmd: nil, msg: ["hello"], key: [], quiet: nil) }

            parsed = JSON.parse(out)
            assert_equal "text", parsed["sent"]
            assert_equal({pane: "p5", text: "hello"}, @executor.calls_of(:pane_send_text).first[:args])
          end

          def test_requires_pane
            cmd = Send.new(executor: @executor, argv_source: %w[--key enter])

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(pane: nil, cmd: nil, msg: [], key: ["enter"], quiet: nil)
            end

            assert_match(/--pane is required/, error.message)
          end

          def test_requires_at_least_one_input
            cmd = Send.new(executor: @executor, argv_source: %w[send --pane p5])

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(pane: "p5", cmd: nil, msg: [], key: [], quiet: nil)
            end

            assert_match(/at least one/, error.message)
          end

          def test_blocked_agent_surfaces_native_code
            @executor = HerdrTestHelper::FakeExecutor.new(outcomes: {
              agent_prompt: Ace::Herdr::AgentBlockedError.new("agent_blocked: busy")
            })
            cmd = Send.new(executor: @executor, argv_source: %w[send --pane p5 --cmd hi])

            error = assert_raises(Ace::Support::Cli::Error) do
              cmd.call(pane: "p5", cmd: "hi", msg: [], key: [], quiet: nil)
            end

            assert_match(/agent_blocked/, error.message)
          end
        end
      end
    end
  end
end
