# frozen_string_literal: true

require "test_helper"

class EnvironmentPolicyTest < Minitest::Test
  def test_default_policy_preserves_toolchain_and_temp_keys_only
    policy = Ace::TestRunner::Models::EnvironmentPolicy.new

    assert_equal %w[PATH LANG LC_ALL TMPDIR TMP TEMP], policy.preserved_keys
  end

  def test_default_policy_blocks_ambient_lab_and_ace_configuration
    policy = Ace::TestRunner::Models::EnvironmentPolicy.new

    assert policy.blocked_key?("LAB_SOCKET")
    assert policy.blocked_key?("LAB_HITL_STORE")
    assert policy.blocked_key?("ACE_ASSIGN_ID")
    assert policy.blocked_key?("ACE_RUNTIME_ENDPOINT")
  end

  def test_default_policy_blocks_provider_credentials_and_project_selection
    policy = Ace::TestRunner::Models::EnvironmentPolicy.new

    assert policy.blocked_key?("ANTHROPIC_API_KEY")
    assert policy.blocked_key?("OPENAI_API_KEY")
    assert policy.blocked_key?("BUNDLE_GEMFILE")
    assert policy.blocked_key?("GEM_HOME")
    assert policy.blocked_key?("RUBYOPT")
    assert policy.blocked_key?("HTTP_PROXY")
    assert policy.blocked_key?("GITHUB_TOKEN")
  end

  def test_unlisted_keys_are_not_preserved
    policy = Ace::TestRunner::Models::EnvironmentPolicy.new

    refute policy.preserved_key?("MY_TOOL")
    refute policy.blocked_key?("MY_TOOL")
  end

  def test_from_config_adds_preserved_keys_overrides_and_requirements
    policy = Ace::TestRunner::Models::EnvironmentPolicy.from_config(
      "preserve" => ["MY_TOOLCHAIN_KEY"],
      "overrides" => {"PROBE_ENDPOINT" => "http://127.0.0.1:1"},
      "require" => ["PROBE_ENDPOINT"]
    )

    assert policy.preserved_key?("MY_TOOLCHAIN_KEY")
    assert policy.preserved_key?("PATH")
    assert_equal({"PROBE_ENDPOINT" => "http://127.0.0.1:1"}, policy.overrides)
    assert_equal %w[PROBE_ENDPOINT], policy.required_keys
  end

  def test_from_config_accepts_nil
    policy = Ace::TestRunner::Models::EnvironmentPolicy.from_config(nil)

    assert_equal Ace::TestRunner::Models::EnvironmentPolicy::PRESERVED_KEYS, policy.preserved_keys
    assert_empty policy.overrides
  end

  def test_preserving_blocked_key_is_a_setup_error_naming_the_key
    error = assert_raises(Ace::TestRunner::EnvironmentSetupError) do
      Ace::TestRunner::Models::EnvironmentPolicy.new(preserved_keys: %w[PATH LAB_SOCKET])
    end

    assert_includes error.message, "LAB_SOCKET"
  end

  def test_policy_is_immutable_against_callers
    policy = Ace::TestRunner::Models::EnvironmentPolicy.new

    assert_raises(FrozenError) { policy.preserved_keys << "MY_TOOL" }
    assert_raises(FrozenError) { policy.overrides["MY_TOOL"] = "1" }
  end

  def test_credential_like_keys_are_redacted_in_diagnostics
    policy = Ace::TestRunner::Models::EnvironmentPolicy.new

    assert_equal "[redacted]", policy.redacted_value("MY_API_TOKEN", "s3cr3t")
    assert_equal "[redacted]", policy.redacted_value("PROBE_SOCKET", "/tmp/probe.sock")
    assert_equal "http://127.0.0.1:1", policy.redacted_value("PROBE_MODE_ONLY", "http://127.0.0.1:1")
  end

  def test_merge_with_prefers_specific_overrides_and_unions_lists
    suite = Ace::TestRunner::Models::EnvironmentPolicy.from_config(
      "preserve" => ["SUITE_TOOL_KEY"],
      "overrides" => {"SHARED_ENDPOINT" => "http://suite:1", "SUITE_ONLY" => "suite"},
      "require" => ["SHARED_ENDPOINT"]
    )
    package = Ace::TestRunner::Models::EnvironmentPolicy.from_config(
      "overrides" => {"SHARED_ENDPOINT" => "http://package:1"}
    )

    merged = suite.merge_with(package)

    assert_equal "http://package:1", merged.overrides["SHARED_ENDPOINT"]
    assert_equal "suite", merged.overrides["SUITE_ONLY"]
    assert merged.preserved_key?("SUITE_TOOL_KEY")
    assert_equal %w[SHARED_ENDPOINT], merged.required_keys
  end

  def test_channel_payload_round_trips_through_from_channel
    policy = Ace::TestRunner::Models::EnvironmentPolicy.from_config(
      "preserve" => ["EXTRA_KEY"],
      "overrides" => {"PROBE_ENDPOINT" => "http://127.0.0.1:1"},
      "require" => ["PROBE_ENDPOINT"]
    )

    restored = Ace::TestRunner::Models::EnvironmentPolicy.from_channel(policy.channel_payload)

    assert_equal policy.overrides, restored.overrides
    assert_equal policy.required_keys, restored.required_keys
    assert restored.preserved_key?("EXTRA_KEY")
  end

  def test_invalid_channel_payload_is_a_setup_error
    error = assert_raises(Ace::TestRunner::EnvironmentSetupError) do
      Ace::TestRunner::Models::EnvironmentPolicy.from_channel("{not json")
    end

    assert_includes error.message, Ace::TestRunner::Models::EnvironmentPolicy::SUITE_CHANNEL_KEY
  end
end
