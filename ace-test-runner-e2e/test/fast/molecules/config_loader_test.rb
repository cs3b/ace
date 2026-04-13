# frozen_string_literal: true

require_relative "../../test_helper"

class ConfigLoaderTest < Minitest::Test
  ConfigLoader = Ace::Test::EndToEndRunner::Molecules::ConfigLoader

  def setup
    @original_test_mode = Ace::Support::Config.test_mode
    @original_default_mock = Ace::Support::Config.default_mock

    Ace::Support::Config.reset_config!
    Ace::Support::Config.test_mode = true
    Ace::Support::Config.default_mock = mock_config
  end

  def teardown
    Ace::Support::Config.reset_config!
    Ace::Support::Config.test_mode = @original_test_mode
    Ace::Support::Config.default_mock = @original_default_mock
  end

  def mock_config
    {
      "execution" => {
        "provider" => "role:e2e-runner",
        "runner_provider" => "role:e2e-runner",
        "verifier_provider" => "role:e2e-verifier",
        "timeout" => 600,
        "parallel" => 3
      },
      "providers" => {
        "cli" => %w[claude gemini codex codexoss opencode pi]
      },
      "paths" => {
        "preflight" => "test/feat",
        "scenarios" => "test/e2e",
        "cache_dir" => ".ace-local/test-e2e"
      },
      "patterns" => {
        "preflight" => "test/feat/**/*_test.rb",
        "discovery" => "test/e2e/TS-*/scenario.yml"
      },
      "required_fields" => %w[test-id title area]
    }
  end

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
    assert_equal "test/feat", config.dig("paths", "preflight")
    assert_equal "test/feat/**/*_test.rb", config.dig("patterns", "preflight")
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

  def test_default_parallel_matches_execution_config
    config = ConfigLoader.load
    assert_equal config.dig("execution", "parallel"), ConfigLoader.default_parallel
  end

  def test_cli_providers_accessor
    providers = ConfigLoader.cli_providers
    assert_equal %w[claude gemini codex codexoss opencode pi].sort, providers.sort
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
