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
    assert_equal "claude:sonnet", config.dig("execution", "provider")
    assert_equal 300, config.dig("execution", "timeout")
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

  def test_load_includes_skill_aware_providers
    config = ConfigLoader.load
    assert_equal %w[claude], config.dig("providers", "skill_aware")
  end

  def test_load_includes_cli_args
    config = ConfigLoader.load
    assert_equal "dangerously-skip-permissions", config.dig("providers", "cli_args", "claude")
    assert_equal "full-auto", config.dig("providers", "cli_args", "codex")
  end

  def test_load_includes_existing_config_sections
    config = ConfigLoader.load
    assert config.key?("paths"), "Config should have paths section"
    assert config.key?("patterns"), "Config should have patterns section"
    assert config.key?("required_fields"), "Config should have required_fields section"
  end

  def test_default_provider_accessor
    assert_equal "claude:sonnet", ConfigLoader.default_provider
  end

  def test_default_timeout_accessor
    assert_equal 300, ConfigLoader.default_timeout
  end

  def test_default_parallel_accessor
    assert_equal 3, ConfigLoader.default_parallel
  end

  def test_cli_providers_accessor
    providers = ConfigLoader.cli_providers
    assert_equal %w[claude gemini codex codexoss opencode pi], providers
  end

  def test_skill_aware_providers_accessor
    assert_equal %w[claude], ConfigLoader.skill_aware_providers
  end

  def test_cli_args_for_claude
    assert_equal "dangerously-skip-permissions", ConfigLoader.cli_args_for("claude")
  end

  def test_cli_args_for_codex
    assert_equal "full-auto", ConfigLoader.cli_args_for("codex")
  end

  def test_cli_args_for_unknown_provider
    assert_nil ConfigLoader.cli_args_for("unknown")
  end

  def test_instance_load_returns_same_as_class_load
    loader = ConfigLoader.new
    config = loader.load
    assert_kind_of Hash, config
    assert_equal "claude:sonnet", config.dig("execution", "provider")
  end
end
