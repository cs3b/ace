# frozen_string_literal: true

require_relative "../../test_helper"

class InteractiveCommandBuilderTest < AceLlmTestCase
  FakeParseResult = Struct.new(:valid?, :error, :provider, :model, :preset, :thinking_level, keyword_init: true)

  class FakeRegistry
    attr_reader :requested

    def get_client(provider_name, model: nil, **_options)
      @requested = {provider_name: provider_name, model: model}
      @client
    end

    def set_client(client)
      @client = client
    end
  end

  def test_build_returns_interactive_invocation_from_client
    registry = FakeRegistry.new
    client = Object.new
    client.define_singleton_method(:interactive_supported?) { true }
    client.define_singleton_method(:build_interactive_invocation) do |messages, **options|
      {
        command: ["codex", "$as-assign-drive abc123@010"],
        env: {"FOO" => "bar"},
        working_dir: "/tmp/project",
        prompt: "$as-assign-drive abc123@010",
        messages: messages,
        options: options
      }
    end
    registry.set_client(client)
    builder = Ace::LLM::Molecules::InteractiveCommandBuilder.new(registry: registry)

    parser = Object.new
    parser.define_singleton_method(:parse) do |_input|
      FakeParseResult.new(valid?: true, provider: "codex", model: "gpt-5", preset: nil, thinking_level: nil)
    end
    builder.instance_variable_set(:@parser, parser)

    result = builder.build(provider_model: "codex:gpt-5", prompt: "/as-assign-drive abc123@010", cli_args: "--full-auto")

    assert_equal ["codex", "$as-assign-drive abc123@010"], result[:command]
    assert_equal "codex", result[:provider]
    assert_equal "gpt-5", result[:model]
    assert_equal "codex", registry.requested[:provider_name]
    assert_equal "gpt-5", registry.requested[:model]
    assert_equal "user", result[:messages].last[:role]
    assert_equal "/as-assign-drive abc123@010", result[:messages].last[:content]
    assert_equal ["--full-auto"], result[:options][:cli_args]
  end

  def test_build_errors_for_provider_without_interactive_support
    registry = FakeRegistry.new
    client = Object.new
    client.define_singleton_method(:interactive_supported?) { false }
    registry.set_client(client)
    builder = Ace::LLM::Molecules::InteractiveCommandBuilder.new(registry: registry)
    parser = Object.new
    parser.define_singleton_method(:parse) do |_input|
      FakeParseResult.new(valid?: true, provider: "google", model: "gemini-2.5-flash", preset: nil, thinking_level: nil)
    end
    builder.instance_variable_set(:@parser, parser)

    error = assert_raises(Ace::LLM::Error) do
      builder.build(provider_model: "google:gemini-2.5-flash", prompt: "hi")
    end

    assert_includes error.message, "does not support interactive mode"
  end
end
