# frozen_string_literal: true

require "minitest/autorun"
require "tempfile"
require "tmpdir"
require_relative "../../lib/ace/llm/molecules/client_registry"
require_relative "../../lib/ace/llm/molecules/provider_loader"
require_relative "../../lib/ace/llm/atoms/provider_config_validator"

module Ace
  module LLM
    class TestClientRegistry < Minitest::Test
      def setup
        @temp_dir = Dir.mktmpdir
        @registry = nil
      end

      def teardown
        FileUtils.rm_rf(@temp_dir) if @temp_dir && File.exist?(@temp_dir)
      end

      def test_initialize_with_custom_paths
        provider_dir = File.join(@temp_dir, "providers")
        Dir.mkdir(provider_dir)

        registry = Molecules::ClientRegistry.new(config_paths: [provider_dir])
        assert_equal [provider_dir], registry.config_paths
      end

      def test_load_provider_configuration
        provider_dir = File.join(@temp_dir, "providers")
        Dir.mkdir(provider_dir)

        # Create a test provider config
        config = {
          "name" => "test-provider",
          "class" => "TestProviders::TestClient",
          "gem" => "test-gem",
          "models" => ["test-model-1", "test-model-2"],
          "api_key" => {
            "env" => "TEST_API_KEY",
            "required" => true
          }
        }

        File.write(File.join(provider_dir, "test.yml"), config.to_yaml)

        registry = Molecules::ClientRegistry.new(config_paths: [provider_dir])

        # Check provider is loaded
        assert registry.provider_exists?("test-provider")
        assert registry.provider_exists?("test_provider") # Test normalization
        assert_equal ["testprovider"], registry.available_providers
      end

      def test_get_provider_configuration
        provider_dir = File.join(@temp_dir, "providers")
        Dir.mkdir(provider_dir)

        config = {
          "name" => "test-provider",
          "class" => "TestProviders::TestClient",
          "gem" => "test-gem",
          "models" => ["model-1", "model-2"]
        }

        File.write(File.join(provider_dir, "test.yml"), config.to_yaml)

        registry = Molecules::ClientRegistry.new(config_paths: [provider_dir])

        provider = registry.get_provider("test-provider")
        assert_equal "test-provider", provider["name"]
        assert_equal "TestProviders::TestClient", provider["class"]
        assert_equal ["model-1", "model-2"], provider["models"]
      end

      def test_models_for_provider
        provider_dir = File.join(@temp_dir, "providers")
        Dir.mkdir(provider_dir)

        config = {
          "name" => "test-provider",
          "class" => "TestProviders::TestClient",
          "gem" => "test-gem",
          "models" => ["model-a", "model-b", "model-c"]
        }

        File.write(File.join(provider_dir, "test.yml"), config.to_yaml)

        registry = Molecules::ClientRegistry.new(config_paths: [provider_dir])

        models = registry.models_for_provider("test-provider")
        assert_equal ["model-a", "model-b", "model-c"], models
      end

      def test_provider_not_found
        registry = Molecules::ClientRegistry.new(config_paths: [@temp_dir])

        refute registry.provider_exists?("nonexistent")
        assert_nil registry.get_provider("nonexistent")
        assert_nil registry.models_for_provider("nonexistent")
      end

      def test_list_providers_with_status
        provider_dir = File.join(@temp_dir, "providers")
        Dir.mkdir(provider_dir)

        config = {
          "name" => "test-provider",
          "class" => "TestProviders::TestClient",
          "gem" => "test-gem",
          "models" => ["model-1"],
          "api_key" => {
            "env" => "TEST_API_KEY",
            "required" => true
          }
        }

        File.write(File.join(provider_dir, "test.yml"), config.to_yaml)

        registry = Molecules::ClientRegistry.new(config_paths: [provider_dir])

        status = registry.list_providers_with_status
        assert_equal 1, status.length

        provider_status = status.first
        assert_equal "testprovider", provider_status[:name]
        assert_equal ["model-1"], provider_status[:models]
        assert_equal "test-gem", provider_status[:gem]
        assert_equal true, provider_status[:api_key_required]
        assert_equal false, provider_status[:api_key_present] # ENV var not set
      end

      def test_reload_configurations
        provider_dir = File.join(@temp_dir, "providers")
        Dir.mkdir(provider_dir)

        registry = Molecules::ClientRegistry.new(config_paths: [provider_dir])
        assert_equal [], registry.available_providers

        # Add a provider config after initialization
        config = {
          "name" => "new-provider",
          "class" => "NewProviders::NewClient",
          "gem" => "new-gem"
        }

        File.write(File.join(provider_dir, "new.yml"), config.to_yaml)

        # Reload and check it's found
        registry.reload!
        assert registry.provider_exists?("new-provider")
      end

      def test_invalid_configuration_handling
        provider_dir = File.join(@temp_dir, "providers")
        Dir.mkdir(provider_dir)

        # Missing required fields
        invalid_config = {
          "name" => "invalid-provider"
          # Missing 'class' and 'gem'
        }

        File.write(File.join(provider_dir, "invalid.yml"), invalid_config.to_yaml)

        # Should not crash, just warn
        registry = Molecules::ClientRegistry.new(config_paths: [provider_dir])
        refute registry.provider_exists?("invalid-provider")
      end

      def test_provider_name_normalization
        provider_dir = File.join(@temp_dir, "providers")
        Dir.mkdir(provider_dir)

        config = {
          "name" => "Test-Provider_Name",
          "class" => "TestProviders::TestClient",
          "gem" => "test-gem"
        }

        File.write(File.join(provider_dir, "test.yml"), config.to_yaml)

        registry = Molecules::ClientRegistry.new(config_paths: [provider_dir])

        # All these should find the same provider
        assert registry.provider_exists?("Test-Provider_Name")
        assert registry.provider_exists?("test-provider-name")
        assert registry.provider_exists?("test_provider_name")
        assert registry.provider_exists?("testprovidername")
      end

      def test_first_config_wins
        # Create two directories with conflicting configs
        dir1 = File.join(@temp_dir, "dir1")
        dir2 = File.join(@temp_dir, "dir2")
        Dir.mkdir(dir1)
        Dir.mkdir(dir2)

        config1 = {
          "name" => "duplicate",
          "class" => "Provider1::Client",
          "gem" => "gem1",
          "models" => ["model1"]
        }

        config2 = {
          "name" => "duplicate",
          "class" => "Provider2::Client",
          "gem" => "gem2",
          "models" => ["model2"]
        }

        File.write(File.join(dir1, "dup.yml"), config1.to_yaml)
        File.write(File.join(dir2, "dup.yml"), config2.to_yaml)

        # First directory wins
        registry = Molecules::ClientRegistry.new(config_paths: [dir1, dir2])

        provider = registry.get_provider("duplicate")
        assert_equal "Provider1::Client", provider["class"]
        assert_equal ["model1"], provider["models"]
      end

      def test_yaml_config_string_keys_work
        # Verify string keys work correctly (explicit test for migration)
        provider_dir = File.join(@temp_dir, "providers")
        Dir.mkdir(provider_dir)

        config = {
          "name" => "string-key-provider",
          "class" => "TestProviders::TestClient",
          "gem" => "test-gem",
          "models" => ["model-1"]
        }

        File.write(File.join(provider_dir, "test.yml"), config.to_yaml)

        registry = Molecules::ClientRegistry.new(config_paths: [provider_dir])
        assert registry.provider_exists?("string-key-provider")

        provider = registry.get_provider("string-key-provider")
        assert_equal "string-key-provider", provider["name"]
        assert_equal "TestProviders::TestClient", provider["class"]
      end

      def test_yaml_config_with_symbol_keys_rejected
        provider_dir = File.join(@temp_dir, "providers")
        Dir.mkdir(provider_dir)

        # YAML with explicit symbol key (YAML syntax: :symbol_key)
        # Note: YAML.safe_load without Symbol in permitted_classes will raise
        # Psych::DisallowedClass when encountering symbol syntax
        yaml_content = <<~YAML
          name: test-provider
          class: TestProviders::TestClient
          :symbol_key: "this should not be allowed"
        YAML

        File.write(File.join(provider_dir, "test.yml"), yaml_content)

        # Should fail to load due to symbol key - provider should not exist
        # The registry catches and warns about errors during loading
        _output, err = capture_io do
          registry = Molecules::ClientRegistry.new(config_paths: [provider_dir])
          refute registry.provider_exists?("test-provider")
        end

        # Verify the warning message indicates symbol keys are not permitted
        assert_match(/Invalid YAML/, err, "Should warn about invalid YAML")
        assert_match(/symbol keys not permitted/, err, "Should mention symbol keys are not permitted")
      end

      def test_resolve_alias_provider_as_model_uses_default
        provider_dir = File.join(@temp_dir, "providers")
        Dir.mkdir(provider_dir)

        codex_config = {
          "name" => "codex",
          "class" => "TestProviders::CodexClient",
          "gem" => "test-gem",
          "models" => ["gpt-5", "gpt-5-mini"],
          "aliases" => {
            "model" => {"mini" => "gpt-5-mini", "5" => "gpt-5"}
          }
        }

        claude_config = {
          "name" => "claude",
          "class" => "TestProviders::ClaudeClient",
          "gem" => "test-gem",
          "models" => ["claude-opus-4-1", "claude-sonnet-4-5"]
        }

        File.write(File.join(provider_dir, "codex.yml"), codex_config.to_yaml)
        File.write(File.join(provider_dir, "claude.yml"), claude_config.to_yaml)

        registry = Molecules::ClientRegistry.new(config_paths: [provider_dir])

        # provider:provider auto-resolves to provider:default_model
        assert_equal "codex:gpt-5", registry.resolve_alias("codex:codex")
        assert_equal "claude:claude-opus-4-1", registry.resolve_alias("claude:claude")

        # Existing model aliases still work
        assert_equal "codex:gpt-5-mini", registry.resolve_alias("codex:mini")

        # Non-matching alias passes through unchanged
        assert_equal "codex:unknown", registry.resolve_alias("codex:unknown")
      end

      def test_yaml_config_date_fields_supported
        # Verify that Date fields in YAML are handled correctly
        # Date class is permitted for timestamp fields like last_synced
        provider_dir = File.join(@temp_dir, "providers")
        Dir.mkdir(provider_dir)

        yaml_content = <<~YAML
          name: date-test-provider
          class: TestProviders::TestClient
          gem: test-gem
          last_synced: 2025-12-05
        YAML

        File.write(File.join(provider_dir, "test.yml"), yaml_content)

        registry = Molecules::ClientRegistry.new(config_paths: [provider_dir])
        assert registry.provider_exists?("date-test-provider")

        provider = registry.get_provider("date-test-provider")
        # Date is parsed as Date object (permitted for timestamp fields)
        assert_instance_of Date, provider["last_synced"]
        assert_equal Date.new(2025, 12, 5), provider["last_synced"]
      end
    end
  end
end