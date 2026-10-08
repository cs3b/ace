# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module Ace
  module Herdr
    module CLI
      module Commands
        class InboxTest < Minitest::Test
          THREAD = "0123abcd-0000-4000-8000-000000000001"

          def test_cli_shared_pair_contract_accepts_native_and_refuses_mixed_targets
            consumer = Object.new.extend(Ace::Herdr::CLI::Commands::Runtime)
            ref = consumer.send(:resolve_ref, " $0 ", " %0 ")
            assert_equal ["$0", "%0"], [ref.session, ref.pane]
            assert_raises(Ace::Hitl::Providers::InvalidRefError) do
              consumer.send(:resolve_ref, "$0", "p1")
            end
          end

          class Executor
            attr_reader :prompts
            def initialize = @prompts = []
            def agent_prompt_bounded(pane:, text:, timeout_ms:)
              @prompts << [pane, text]
              Molecules::ExecutionResult.new(stdout: "sent", stderr: "", success: true, exit_code: 0)
            end
            def pane_get_bounded(_pane)
              Molecules::ExecutionResult.new(
                stdout: JSON.generate("result" => {"pane" => {
                  "pane_id" => "p1", "workspace_id" => "ws1", "terminal_id" => "term-1",
                  "agent" => "codex", "agent_status" => "busy",
                  "agent_session" => {"agent" => "codex", "kind" => "id", "value" => THREAD}
                }}), stderr: "", success: true, exit_code: 0
              )
            end
          end

          class Native
            attr_reader :calls
            attr_accessor :result

            def initialize
              @calls = []
              @result = {"accepted" => true, "stdout" => "queued"}
            end

            # This state-machine fixture injects the native boundary; real correlation is tested in the service composition.
            def prepare_submission(**_arguments) = nil

            def submit(**options)
              @calls << options
              result
            end
          end

          def setup
            @dir = Dir.mktmpdir("ace-herdr-inbox-cli")
            @native = Native.new
            entry = Ace::Runtime::Molecules::ProtectedTaskContextEntry.new(stat: ->(path) {
              allowed = [Ace::Runtime::Molecules::ProtectedTaskContextEntry::PATH,
                *Ace::Runtime::Molecules::ProtectedTaskContextEntry::PRESENCE_PATHS]
              raise "unexpected installation probe" unless allowed.include?(path)
              raise Errno::ENOENT, path
            })
            @selection = Molecules::ProtectedInboxSelection.new(entry_owner: entry, env: {})
            @executor = Executor.new
            @command = Inbox.new(executor: @executor, native: @native, selection: @selection)
            delivery_path = File.join(@dir, "deliveries")
            @command.define_singleton_method(:config) do
              {"deliveries_dir" => delivery_path}
            end
            File.write(File.join(@dir, "ref.json"), JSON.generate("session" => "ws1", "pane" => "p1"))
            File.write(File.join(@dir, "payload.txt"), "hello")
          end

          def teardown
            FileUtils.remove_entry(@dir)
          end

          def call(operation, **options)
            out, = capture_io { @command.call(operation: operation, event: "inb-12345678", **options) }
            JSON.parse(out)
          end

          def test_even_empty_protected_only_options_refuse_before_local_configuration
            @command.define_singleton_method(:config) { raise "local configuration must not be read" }
            %i[project mapping inbox_context claim_generation assignment].each do |key|
              assert_raises(Ace::Support::Cli::Error) { call("status", **{key => ""}) }
            end
          end

          def test_removed_observation_operation_refuses_before_configuration
            error = assert_raises(Ace::Support::Cli::Error) { call("observe", event: "event1") }
            assert_match(/operation/, error.message)
          end

          def test_enqueue_status_deliver_across_separate_command_calls
            queued = call("enqueue", attempt: "att-1", ref: File.join(@dir, "ref.json"),
              file: File.join(@dir, "payload.txt"))
            assert_equal "queued", queued["state"]
            assert_equal "att-1", queued["attempt_id"]
            assert_equal "queued", call("status", format: "json")["state"]

            delivered = call("deliver")

            assert_equal "delivered", delivered["state"]
            assert_empty @native.calls
            assert_equal [["p1", "hello"]], @executor.prompts
            assert_equal delivered["payload_sha256"], delivered.dig("receipt", "payload_sha256")
            assert_equal "delivered", call("status")["state"]
          end

          def test_missing_payload_is_cli_error_before_record_creation
            error = assert_raises(Ace::Support::Cli::Error) do
              call("enqueue", attempt: "att-1", ref: File.join(@dir, "ref.json"), file: "missing.txt")
            end

            assert_match(/missing.txt/, error.message)
            assert_raises(Ace::Support::Cli::Error) { call("status") }
          end








        end
      end
    end
  end
end
