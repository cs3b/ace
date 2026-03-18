# frozen_string_literal: true

require_relative "../test_helper"

class CachingTest < AceTestCase
  include Ace::TestSupport::ConfigHelpers

  def setup
    @env = Ace::TestSupport::TestEnvironment.new("core")
    @env.setup
    Ace::Core.reset_config!
  end

  def teardown
    @env.teardown
    Ace::Core.reset_config!
  end

  # === Caching Tests ===

  def test_config_returns_cached_resolver
    # First call creates the resolver
    config1 = Ace::Core.config
    # Second call should return same cached result
    config2 = Ace::Core.config

    # Both should resolve successfully (cached resolver works)
    assert_kind_of Ace::Support::Config::Models::Config, config1
    assert_kind_of Ace::Support::Config::Models::Config, config2
  end

  def test_reset_config_clears_cache
    # First resolution (creates cache)
    original_resolver_id = Ace::Core.send(:cached_resolver).object_id

    # Reset the cache
    Ace::Core.reset_config!

    # Get a new resolver - should be different object
    new_resolver_id = Ace::Core.send(:cached_resolver).object_id

    refute_equal original_resolver_id, new_resolver_id,
      "reset_config! should clear the cached resolver"
  end

  def test_reset_config_also_clears_ace_config_cache
    # Ensure ace-config is also reset
    # This is important for test isolation
    Ace::Core.reset_config!

    # After reset, calling config should work (no stale state)
    config = Ace::Core.config
    assert_kind_of Ace::Support::Config::Models::Config, config
  end

  def test_reset_config_clears_env_cache
    # This tests that the environment variable cache is also cleared
    Ace::Core.reset_config!

    # After reset, get_env should work without stale data
    # Using a likely-nonexistent key to verify fresh resolution
    result = Ace::Core.get_env("NONEXISTENT_TEST_VAR_12345", "default")
    assert_equal "default", result
  end

  def test_get_uses_cached_resolver
    # Multiple calls to get should use the same cached resolver
    Ace::Core.reset_config!

    resolver_id_1 = Ace::Core.send(:cached_resolver).object_id
    Ace::Core.get("test", "key")
    resolver_id_2 = Ace::Core.send(:cached_resolver).object_id

    assert_equal resolver_id_1, resolver_id_2,
      "get should use the same cached resolver"
  end
end
