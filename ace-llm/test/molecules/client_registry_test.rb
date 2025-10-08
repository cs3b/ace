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
    end
  end
end