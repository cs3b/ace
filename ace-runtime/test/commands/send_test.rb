# frozen_string_literal: true

require "test_helper"
require "stringio"
require "ace/runtime/testing"
require_relative "../support/fake_runtime_adapter"
require "ace/runtime/cli"

module Ace
  module Runtime
    module CLI
      module Commands
        class SendCommandTest < AceRuntimeTestCase
          DETECTION_ENV_KEYS = %w[ACE_RUNTIME TMUX ACE_TMUX_SESSION HERDR_SESSION HERDR_PANE].freeze

          def setup
            super
            Ace::Runtime.reset_registry!
            Ace::Runtime.reset_config!
            @fixture = Testing::ScriptedRuntime.new
            @fixture.seed_window("main")
            @fixture.seed_pane("main")
            Ace::Runtime.register(:faketest, -> {
              Ace::Runtime::FakeRuntimeAdapter.new(fixture: @fixture, send_profile: :plain_pane)
            })
          end

          def teardown
            Ace::Runtime.reset_registry!
            Ace::Runtime.reset_config!
          end

          def test_callback_form_submits_message_then_enter_once
            output = run_send("--pane", "%1", "--msg", "Reply with exactly: pong", "--key", "Enter")

            assert_equal [
              {op: :write_text, pane: "%1", text: "Reply with exactly: pong"},
              {op: :press_key, pane: "%1", key: "Enter"}
            ], @fixture.calls
            assert_match(/Sent via faketest: 1 message \+ 1 key/, output[:stdout])
            assert_equal 0, output[:exit_code]
          end

          def test_cmd_form_submits_command_with_enter
            output = run_send("--pane", "%1", "--cmd", "echo ready")

            assert_equal [
              {op: :write_text, pane: "%1", text: "echo ready"},
              {op: :press_key, pane: "%1", key: "Enter"}
            ], @fixture.calls
            assert_match(/Sent via faketest: command/, output[:stdout])
          end

          def test_keys_only_form_is_valid
            output = run_send("--pane", "%1", "--key", "C-c")

            assert_equal [{op: :press_key, pane: "%1", key: "C-c"}], @fixture.calls
            assert_match(/Sent via faketest: 1 key/, output[:stdout])
          end

          def test_multiple_messages_and_keys_build_ordered_items
            output = run_send("--pane", "%1", "--msg", "one", "--msg", "two", "--key", "Enter")

            assert_equal [
              {op: :write_text, pane: "%1", text: "one"},
              {op: :write_text, pane: "%1", text: "two"},
              {op: :press_key, pane: "%1", key: "Enter"}
            ], @fixture.calls
            assert_match(/2 messages \+ 1 key/, output[:stdout])
          end

          def test_missing_input_is_a_usage_error_before_resolution
            Ace::Runtime.register(:never_resolved, -> { raise "must not resolve" })

            output = run_send("--pane", "%1")

            assert_equal 1, output[:exit_code]
            assert_match(/provide at least one of --cmd, --msg, or --key/, output[:stderr])
          end

          def test_leading_key_before_cmd_is_a_usage_error
            output = run_send("--pane", "%1", "--key", "Esc", "--cmd", "run")

            assert_equal 1, output[:exit_code]
            assert_match(/--cmd must be declared before every key/, output[:stderr])
            assert_empty @fixture.calls
          end

          def test_key_after_cmd_is_accepted
            output = run_send("--pane", "%1", "--cmd", "run", "--key", "C-c")

            assert_equal [
              {op: :write_text, pane: "%1", text: "run"},
              {op: :press_key, pane: "%1", key: "Enter"},
              {op: :press_key, pane: "%1", key: "C-c"}
            ], @fixture.calls
            assert_equal 0, output[:exit_code]
          end

          def test_unknown_runtime_fails_closed_with_available_list
            output = run_send("--pane", "%1", "--cmd", "run", "--runtime", "bogus")

            assert_equal 1, output[:exit_code]
            assert_match(/unknown runtime 'bogus'/, output[:stderr])
            assert_match(/available: faketest/, output[:stderr])
            assert_empty @fixture.calls
          end

          def test_missing_runtime_selection_fails_clearly
            Ace::Runtime.reset_registry!

            output = run_cli(["send", "--pane", "%1", "--cmd", "run"])

            assert_equal 1, output[:exit_code]
            assert_match(/no terminal runtime selected/, output[:stderr])
          end

          def test_explicit_runtime_beats_ace_runtime_env
            second_fixture = register_other_runtime

            output = run_send("--pane", "%1", "--cmd", "run", "--runtime", "faketest", env: {"ACE_RUNTIME" => "other"})

            assert_equal 0, output[:exit_code]
            assert_equal 2, @fixture.calls.length
            assert_empty second_fixture.calls
          end

          def test_ace_runtime_env_selects_runtime
            second_fixture = register_other_runtime

            output = run_send("--pane", "%1", "--cmd", "run", env: {"ACE_RUNTIME" => "other"})

            assert_equal 0, output[:exit_code]
            assert_equal 2, second_fixture.calls.length
            assert_empty @fixture.calls
          end

          def test_quiet_suppresses_output
            output = run_send("--pane", "%1", "--cmd", "run", "--quiet")

            assert_equal 0, output[:exit_code]
            assert_empty output[:stdout].strip
          end

          def test_adapter_errors_surface_as_cli_errors
            output = run_send("--pane", "%missing", "--cmd", "run")

            assert_equal 1, output[:exit_code]
            assert_match(/no pane '%missing'/, output[:stderr])
          end

          private

          def register_other_runtime
            fixture = Testing::ScriptedRuntime.new
            fixture.seed_window("main")
            fixture.seed_pane("main")
            Ace::Runtime.register(:other, -> {
              Ace::Runtime::FakeRuntimeAdapter.new(fixture: fixture, send_profile: :plain_pane)
            })
            fixture
          end

          def run_send(*args, env: {})
            run_cli(["send", *args], env: {"ACE_RUNTIME" => "faketest"}.merge(env))
          end

          def run_cli(args, env: {})
            full_env = DETECTION_ENV_KEYS.to_h { |key| [key, nil] }.merge(env)
            old_stdout = $stdout
            old_stderr = $stderr
            $stdout = StringIO.new
            $stderr = StringIO.new

            exit_code = 0

            with_env(full_env) do
              begin
                exit_code = Ace::Runtime::CLI.start(args.dup)
              rescue Ace::Support::Cli::Error => e
                $stderr.puts e.message
                exit_code = e.exit_code
              rescue SystemExit => e
                exit_code = e.status
              end
            end

            {stdout: $stdout.string, stderr: $stderr.string, exit_code: exit_code}
          ensure
            $stdout = old_stdout
            $stderr = old_stderr
          end

          def with_env(overrides)
            saved = {}
            overrides.each do |key, value|
              saved[key] = ENV[key]
              if value.nil?
                ENV.delete(key)
              else
                ENV[key] = value
              end
            end
            yield
          ensure
            saved.each do |key, value|
              if value.nil?
                ENV.delete(key)
              else
                ENV[key] = value
              end
            end
          end
        end
      end
    end
  end
end
