# frozen_string_literal: true

require_relative "../test_helper"
require "ace/llm/molecules/model_limit_resolver"

class CodexTargetTest < AceLlmTestCase
  include Ace::TestSupport::ConfigHelpers

  IDS = %w[gpt-6-astra gpt-5.6-sol gpt-5.6-terra gpt-5.6-luna gpt-5.3-chat-latest
    gpt-5.3-codex gpt-5.3-codex-spark gpt-5.4 gpt-5.4-mini gpt-5.4-nano gpt-5.4-pro gpt-9].freeze

  def setup
    super
    Ace::LLM.reset_configuration!
    @registry = Ace::LLM::Molecules::ClientRegistry.new
    @attempts = []
  end

  def teardown
    Ace::LLM.reset_configuration!
    super
  end

  def test_named_generic_and_thinking_selectors_reach_requested_client
    {"codex" => "gpt-5.6-terra", "codex:gpt" => "gpt-5.6-terra",
     "codex:mini" => "gpt-5.6-luna", "codex:astra:high" => "gpt-6-astra",
     "codex:sol:low" => "gpt-5.6-sol", "codex:terra:medium" => "gpt-5.6-terra",
     "codex:luna:high" => "gpt-5.6-luna", "codex:spark" => "gpt-5.3-codex-spark"}.each do |selector, model|
      with_client do
        result = Ace::LLM::QueryInterface.query(selector, "ping", fallback: false)
        assert_equal model, result[:model]
        assert_equal ["codex", model], @attempts.last
      end
    end
  end

  def test_explicit_ids_preserve_native_error_without_fallback_even_when_enabled
    IDS.each do |id|
      @attempts.clear
      with_client(error: "native rejection: #{id}") do
        error = assert_raises(Ace::LLM::Error) do
          Ace::LLM::QueryInterface.query("codex:#{id}:medium", "ping",
            fallback: true, fallback_providers: ["codex:terra"])
        end
        assert_equal "native rejection: #{id}", error.message
        assert_equal [["codex", id]], @attempts
      end
    end
  end

  def test_ruby_model_override_and_no_fallback_each_keep_one_target
    [{model: "gpt-9", fallback: true}, {fallback: false}].each do |options|
      @attempts.clear
      with_client(error: "native unsupported effort") do
        assert_raises(Ace::LLM::Error) do
          Ace::LLM::QueryInterface.query("codex:astra:high", "ping",
            fallback_providers: ["codex:terra"], **options)
        end
        assert_equal [["codex", options[:model] || "gpt-6-astra"]], @attempts
      end
    end
  end

  def test_parser_distinguishes_aliases_provider_defaults_and_full_ids
    parser = Ace::LLM::Molecules::ProviderModelParser.new
    %w[codex codex:gpt codex:astra:high codex:mini].each { |s| refute parser.parse(s).explicit_model }
    IDS.each do |id|
      parsed = parser.parse("codex:#{id}:high")
      assert parsed.valid?
      assert parsed.explicit_model
      assert_equal id, parsed.model
      assert_equal "high", parsed.thinking_level
    end
  end

  def test_new_models_use_labeled_operational_fallback_not_inherited_old_limits
    IDS.first(4).each do |id|
      result = Ace::LLM::Molecules::ModelLimitResolver.resolve("codex:#{id}")
      assert_equal id, result.model
      assert_equal :fallback, result.source
      assert_equal 200_000, result.context_limit
      assert_nil result.output_limit
    end
  end

  private

  def with_client(error: nil)
    attempts = @attempts
    client = Object.new
    client.define_singleton_method(:generate) do |*args, **options|
      raise Ace::LLM::Error, error if error

      {text: "pong"}
    end
    @registry.define_singleton_method(:get_client) do |provider, model:, **options|
      attempts << [provider, model]
      client
    end
    with_real_config do
      Ace::LLM::Molecules::ClientRegistry.stub(:new, @registry) { yield }
    end
  end
end
