# frozen_string_literal: true

require "test_helper"

module Ace
  module Support
    module Config
      class ConfigResolverTestModeTest < TestCase
        def setup
          super
          # Ensure clean state before each test
          Ace::Support::Config.reset_config!
        end

        def teardown
          # Clean up after each test
          Ace::Support::Config.reset_config!
          super
        end

        # --- Constructor tests ---

        def test_accepts_test_mode_parameter
          resolver = Organisms::ConfigResolver.new(test_mode: true)
          assert resolver.test_mode?
        end

        def test_test_mode_defaults_to_false
          resolver = Organisms::ConfigResolver.new
          refute resolver.test_mode?
        end

        def test_accepts_mock_config_parameter
          resolver = Organisms::ConfigResolver.new(
            test_mode: true,
            mock_config: {"key" => "value"}
          )

          config = resolver.resolve
          assert_equal "value", config.get("key")
        end

        # --- resolve() in test mode ---

        def test_resolve_returns_empty_config_in_test_mode
          resolver = Organisms::ConfigResolver.new(test_mode: true)
          config = resolver.resolve

          assert_equal({}, config.data)
          assert_equal "test_mode", config.source
        end

        def test_resolve_returns_mock_config_in_test_mode
          mock_data = {"setting" => "mocked", "nested" => {"value" => 42}}
          resolver = Organisms::ConfigResolver.new(test_mode: true, mock_config: mock_data)

          config = resolver.resolve
          assert_equal "mocked", config.get("setting")
          assert_equal 42, config.get("nested", "value")
        end

        def test_resolve_does_not_access_filesystem_in_test_mode
          # Create resolver with test_mode but pointing to non-existent paths
          resolver = Organisms::ConfigResolver.new(
            test_mode: true,
            config_dir: "/nonexistent/config",
            defaults_dir: "/nonexistent/defaults",
            gem_path: "/nonexistent/gem"
          )

          # Should NOT raise error because filesystem is never accessed
          config = resolver.resolve
          assert_equal({}, config.data)
        end

        # --- resolve_file() in test mode ---

        def test_resolve_file_returns_mock_config_in_test_mode
          mock_data = {"file_setting" => "test"}
          resolver = Organisms::ConfigResolver.new(test_mode: true, mock_config: mock_data)

          config = resolver.resolve_file("some/path.yml")
          assert_equal "test", config.get("file_setting")
        end

        # --- resolve_namespace() in test mode ---

        def test_resolve_namespace_returns_mock_config_in_test_mode
          mock_data = {"ns_setting" => "namespace_test"}
          resolver = Organisms::ConfigResolver.new(test_mode: true, mock_config: mock_data)

          config = resolver.resolve_namespace("my_gem")
          assert_equal "namespace_test", config.get("ns_setting")
        end

        # --- Class-level API tests ---

        def test_class_test_mode_setter
          Ace::Support::Config.test_mode = true
          assert Ace::Support::Config.test_mode?

          Ace::Support::Config.test_mode = false
          refute Ace::Support::Config.test_mode?
        end

        def test_class_default_mock_setter
          Ace::Support::Config.default_mock = {"default" => "mock_value"}
          assert_equal({"default" => "mock_value"}, Ace::Support::Config.default_mock)
        end

        def test_create_uses_class_test_mode
          Ace::Support::Config.test_mode = true

          resolver = Ace::Support::Config.create
          assert resolver.test_mode?
        end

        def test_create_uses_class_default_mock
          Ace::Support::Config.test_mode = true
          Ace::Support::Config.default_mock = {"class_mock" => "value"}

          resolver = Ace::Support::Config.create
          config = resolver.resolve
          assert_equal "value", config.get("class_mock")
        end

        def test_create_explicit_test_mode_overrides_class_setting
          Ace::Support::Config.test_mode = true

          # Explicit test_mode: false should override class setting
          resolver = Ace::Support::Config.create(test_mode: false)
          refute resolver.test_mode?
        end

        def test_create_explicit_mock_config_overrides_default_mock
          Ace::Support::Config.test_mode = true
          Ace::Support::Config.default_mock = {"default" => "value"}

          resolver = Ace::Support::Config.create(mock_config: {"explicit" => "override"})
          config = resolver.resolve

          assert_nil config.get("default")
          assert_equal "override", config.get("explicit")
        end

        # --- ENV variable detection ---

        def test_env_variable_enables_test_mode
          # Store original value
          original = ENV["ACE_CONFIG_TEST_MODE"]

          begin
            ENV["ACE_CONFIG_TEST_MODE"] = "1"
            assert Ace::Support::Config.test_mode?

            ENV["ACE_CONFIG_TEST_MODE"] = "true"
            assert Ace::Support::Config.test_mode?

            ENV["ACE_CONFIG_TEST_MODE"] = "false"
            refute Ace::Support::Config.test_mode?

            ENV.delete("ACE_CONFIG_TEST_MODE")
            refute Ace::Support::Config.test_mode?
          ensure
            # Restore original value
            if original
              ENV["ACE_CONFIG_TEST_MODE"] = original
            else
              ENV.delete("ACE_CONFIG_TEST_MODE")
            end
          end
        end

        # --- reset_config! tests ---

        def test_reset_config_clears_test_mode
          Ace::Support::Config.test_mode = true
          Ace::Support::Config.default_mock = {"key" => "value"}

          Ace::Support::Config.reset_config!

          refute Ace::Support::Config.test_mode?
          assert_nil Ace::Support::Config.default_mock
        end
      end
    end
  end
end
