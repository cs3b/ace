# frozen_string_literal: true

require_relative "../test_helper"

class ConfigLoaderTest < Minitest::Test
  ConfigLoader = Ace::Test::EndToEndRunner::Molecules::ConfigLoader

  def test_load_returns_hash
    config = ConfigLoader.load
    assert_kind_of Hash, config
  end

  def test_load_includes_execution_section
    config = ConfigLoader.load
    assert config.key?("execution"), "Config should have execution section"
    assert_kind_of String, config.dig("execution", "provider")
    assert_kind_of Integer, config.dig("execution", "timeout")
  end

  def test_load_includes_providers_section
    config = ConfigLoader.load
    assert config.key?("providers"), "Config should have providers section"
    assert_includes config.dig("providers", "cli"), "claude"
    assert_includes config.dig("providers", "cli"), "gemini"
    assert_includes config.dig("providers", "cli"), "codex"
    assert_includes config.dig("providers", "cli"), "codexoss"
    assert_includes config.dig("providers", "cli"), "opencode"
  end

  def test_load_does_not_define_provider_cli_args
    config = ConfigLoader.load
    assert_nil config.dig("providers", "cli_args")
  end

  def test_load_includes_existing_config_sections
    config = ConfigLoader.load
    assert config.key?("paths"), "Config should have paths section"
    assert config.key?("patterns"), "Config should have patterns section"
    assert config.key?("required_fields"), "Config should have required_fields section"
  end

  def test_default_provider_accessor
    provider = ConfigLoader.default_provider
    assert_kind_of String, provider
    assert_match(/\A(role:[a-z0-9-]+|[^:]+:[^@]+@[^@]+)\z/, provider)
  end

  def test_default_timeout_accessor
    timeout = ConfigLoader.default_timeout
    assert_kind_of Integer, timeout
    assert timeout > 0, "Timeout should be positive"
  end

  def test_default_parallel_accessor
    parallel = ConfigLoader.default_parallel
    assert_kind_of Integer, parallel
    assert parallel > 0, "Parallel count should be positive"
  end

  def test_cli_providers_accessor
    providers = ConfigLoader.cli_providers
    assert_equal ConfigLoader.load.dig("providers", "cli"), providers
  end

  def test_cli_args_for_claude
    assert_nil ConfigLoader.cli_args_for("claude")
  end

  def test_cli_args_for_codex
    assert_nil ConfigLoader.cli_args_for("codex")
  end

  def test_cli_args_for_unknown_provider
    assert_nil ConfigLoader.cli_args_for("unknown")
  end

  def test_instance_load_returns_same_as_class_load
    loader = ConfigLoader.new
    config = loader.load
    assert_kind_of Hash, config
    assert_equal ConfigLoader.default_provider, config.dig("execution", "provider")
  end
end
