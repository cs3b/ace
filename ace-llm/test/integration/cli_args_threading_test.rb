# frozen_string_literal: true

require "test_helper"

module Ace
  module LLM
    class CliArgsThreadingTest < AceLlmTestCase
      FakeClient = Struct.new(:received_options) do
        def generate(_messages, **options)
          self.received_options = options
          { text: "ok", metadata: {} }
        end
      end

      class FakeRegistry
        def initialize(client)
          @client = client
        end

        def available_providers
          ["claude"]
        end

        def models_for_provider(_provider)
          ["sonnet"]
        end

        def resolve_alias(input)
          input
        end

        def available_aliases
          { global: {}, model: {} }
        end

        def get_client(_provider, model:, timeout: nil)
          @client
        end
      end

      def test_query_interface_threads_cli_args
        client = FakeClient.new
        registry = FakeRegistry.new(client)

        Ace::LLM::Molecules::ClientRegistry.stub(:new, registry) do
          QueryInterface.query("claude:sonnet", "hi", cli_args: "dangerously-skip-permissions")
        end

        assert_equal "dangerously-skip-permissions", client.received_options[:cli_args]
      end

      def test_query_interface_threads_sandbox
        client = FakeClient.new
        registry = FakeRegistry.new(client)

        Ace::LLM::Molecules::ClientRegistry.stub(:new, registry) do
          QueryInterface.query("claude:sonnet", "hi", sandbox: "read-only")
        end

        assert_equal "read-only", client.received_options[:sandbox]
      end

      def test_query_interface_threads_working_dir
        client = FakeClient.new
        registry = FakeRegistry.new(client)

        Ace::LLM::Molecules::ClientRegistry.stub(:new, registry) do
          QueryInterface.query("claude:sonnet", "hi", working_dir: "/tmp/e2e-sandbox")
        end

        assert_equal "/tmp/e2e-sandbox", client.received_options[:working_dir]
      end

      def test_cli_command_threads_cli_args
        client = FakeClient.new
        registry = FakeRegistry.new(client)
        command = Ace::LLM::CLI::Commands::Query.new

        capture_io do
          Ace::LLM::Molecules::ClientRegistry.stub(:new, registry) do
            command.call(provider_model: "claude:sonnet", prompt_text: "hi", cli_args: "--verbose")
          end
        end

        assert_equal "--verbose", client.received_options[:cli_args]
      end

      def test_claude_ro_preset_allows_bash_and_read_tools
        preset_path = File.expand_path("../../.ace-defaults/llm/presets/claude/ro.yml", __dir__)
        preset = YAML.load_file(preset_path)

        assert_equal ["--tools", "Bash,Read"], preset["cli_args"]
      end

      def test_claude_prompt_preset_disables_tools
        preset_path = File.expand_path("../../.ace-defaults/llm/presets/claude/prompt.yml", __dir__)
        preset = YAML.load_file(preset_path)

        assert_equal ["--tools", ""], preset["cli_args"]
      end
    end
  end
end
