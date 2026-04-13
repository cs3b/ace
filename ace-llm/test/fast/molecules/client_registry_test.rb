# frozen_string_literal: true

require "minitest/autorun"
require "tempfile"
require "tmpdir"
require_relative "../../../lib/ace/llm/molecules/client_registry"
require_relative "../../../lib/ace/llm/molecules/provider_loader"
require_relative "../../../lib/ace/llm/atoms/provider_config_validator"
require_relative "../../../lib/ace/llm/configuration"

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

      def test_initialize_loads_providers
        providers = {
          "testprovider" => {
            "name" => "test-provider",
            "class" => "TestProviders::TestClient",
            "gem" => "test-gem",
            "models" => ["test-model-1"]
          }
        }

        registry = create_registry_with(providers)
        assert registry.provider_exists?("test-provider")
      end

      def test_load_provider_configuration
        providers = {
          "testprovider" => {
            "name" => "test-provider",
            "class" => "TestProviders::TestClient",
            "gem" => "test-gem",
            "models" => ["test-model-1", "test-model-2"],
            "api_key" => {
              "env" => "TEST_API_KEY",
              "required" => true
            }
          }
        }

        registry = create_registry_with(providers)

        # Check provider is loaded
        assert registry.provider_exists?("test-provider")
        assert registry.provider_exists?("test_provider") # Test normalization
        assert_equal ["testprovider"], registry.available_providers
      end

      def test_get_provider_configuration
        providers = {
          "testprovider" => {
            "name" => "test-provider",
            "class" => "TestProviders::TestClient",
            "gem" => "test-gem",
            "models" => ["model-1", "model-2"]
          }
        }

        registry = create_registry_with(providers)

        provider = registry.get_provider("test-provider")
        assert_equal "test-provider", provider["name"]
        assert_equal "TestProviders::TestClient", provider["class"]
        assert_equal ["model-1", "model-2"], provider["models"]
      end

      def test_models_for_provider
        providers = {
          "testprovider" => {
            "name" => "test-provider",
            "class" => "TestProviders::TestClient",
            "gem" => "test-gem",
            "models" => ["model-a", "model-b", "model-c"]
          }
        }

        registry = create_registry_with(providers)

        models = registry.models_for_provider("test-provider")
        assert_equal ["model-a", "model-b", "model-c"], models
      end

      def test_provider_not_found
        registry = create_registry_with({})

        refute registry.provider_exists?("nonexistent")
        assert_nil registry.get_provider("nonexistent")
        assert_nil registry.models_for_provider("nonexistent")
      end

      def test_list_providers_with_status
        providers = {
          "testprovider" => {
            "name" => "test-provider",
            "class" => "TestProviders::TestClient",
            "gem" => "test-gem",
            "models" => ["model-1"],
            "api_key" => {
              "env" => "TEST_API_KEY",
              "required" => true
            }
          }
        }

        registry = create_registry_with(providers)

        status = registry.list_providers_with_status
        assert_equal 1, status.length

        provider_status = status.first
        assert_equal "testprovider", provider_status[:name]
        assert_equal ["model-1"], provider_status[:models]
        assert_equal "test-gem", provider_status[:gem]
        assert_equal true, provider_status[:api_key_required]
        assert_equal false, provider_status[:api_key_present] # ENV var not set
        assert_equal ["TEST_API_KEY"], provider_status[:credential_env_keys]
      end

      def test_list_providers_with_status_uses_backend_env_key_metadata
        providers = {
          "codexoai" => {
            "name" => "codexoai",
            "class" => "TestProviders::CodexClient",
            "gem" => "test-gem",
            "backends" => {
              "codexcli" => {"env_key" => "CODEX_OAI_API_KEY"}
            }
          }
        }

        registry = create_registry_with(providers)

        status = registry.list_providers_with_status.first
        assert_equal true, status[:api_key_required]
        assert_equal ["CODEX_OAI_API_KEY"], status[:credential_env_keys]
      end

      def test_list_providers_with_status_uses_default_env_key_fallback
        providers = {
          "google" => {
            "name" => "google",
            "class" => "TestProviders::GoogleClient",
            "gem" => "test-gem"
          }
        }

        registry = create_registry_with(providers)

        status = registry.list_providers_with_status.first
        assert_equal true, status[:api_key_required]
        assert_equal %w[GEMINI_API_KEY GOOGLE_API_KEY], status[:credential_env_keys]
      end

      def test_list_providers_with_status_recognizes_google_api_key_fallback_presence
        providers = {
          "google" => {
            "name" => "google",
            "class" => "TestProviders::GoogleClient",
            "gem" => "test-gem"
          }
        }

        registry = create_registry_with(providers)

        previous_gemini = ENV["GEMINI_API_KEY"]
        previous_google = ENV["GOOGLE_API_KEY"]
        ENV.delete("GEMINI_API_KEY")
        ENV["GOOGLE_API_KEY"] = "google-fallback-key"
        begin
          status = registry.list_providers_with_status.first
          assert_equal true, status[:api_key_required]
          assert_equal true, status[:api_key_present]
          assert_equal %w[GEMINI_API_KEY GOOGLE_API_KEY], status[:credential_env_keys]
        ensure
          previous_gemini.nil? ? ENV.delete("GEMINI_API_KEY") : ENV["GEMINI_API_KEY"] = previous_gemini
          previous_google.nil? ? ENV.delete("GOOGLE_API_KEY") : ENV["GOOGLE_API_KEY"] = previous_google
        end
      end

      def test_provider_api_key_present_uses_fallback_env_keys
        providers = {
          "google" => {
            "name" => "google",
            "class" => "TestProviders::GoogleClient",
            "gem" => "test-gem"
          }
        }

        registry = create_registry_with(providers)

        previous_gemini = ENV["GEMINI_API_KEY"]
        previous_google = ENV["GOOGLE_API_KEY"]
        ENV.delete("GEMINI_API_KEY")
        ENV["GOOGLE_API_KEY"] = "google-fallback-key"
        begin
          assert_equal true, registry.provider_api_key_present?("google")
        ensure
          previous_gemini.nil? ? ENV.delete("GEMINI_API_KEY") : ENV["GEMINI_API_KEY"] = previous_gemini
          previous_google.nil? ? ENV.delete("GOOGLE_API_KEY") : ENV["GOOGLE_API_KEY"] = previous_google
        end
      end

      def test_reload_configurations
        registry = create_registry_with({})
        assert_equal [], registry.available_providers

        # Inject a provider via reload
        new_providers = {
          "newprovider" => {
            "name" => "new-provider",
            "class" => "NewProviders::NewClient",
            "gem" => "new-gem"
          }
        }

        Ace::LLM.stub :providers, new_providers do
          registry.reload!
          assert registry.provider_exists?("new-provider")
        end
      end

      def test_invalid_configuration_handling
        providers = {
          "invalidprovider" => {
            "name" => "invalid-provider"
            # Missing 'class'
          }
        }

        # Should not crash, just warn
        registry = create_registry_with(providers)
        refute registry.provider_exists?("invalid-provider")
      end

      def test_provider_name_normalization
        providers = {
          "testprovidername" => {
            "name" => "Test-Provider_Name",
            "class" => "TestProviders::TestClient",
            "gem" => "test-gem"
          }
        }

        registry = create_registry_with(providers)

        # All these should find the same provider
        assert registry.provider_exists?("Test-Provider_Name")
        assert registry.provider_exists?("test-provider-name")
        assert registry.provider_exists?("test_provider_name")
        assert registry.provider_exists?("testprovidername")
      end

      def test_yaml_config_string_keys_work
        # Verify string keys work correctly
        providers = {
          "stringkeyprovider" => {
            "name" => "string-key-provider",
            "class" => "TestProviders::TestClient",
            "gem" => "test-gem",
            "models" => ["model-1"]
          }
        }

        registry = create_registry_with(providers)
        assert registry.provider_exists?("string-key-provider")

        provider = registry.get_provider("string-key-provider")
        assert_equal "string-key-provider", provider["name"]
        assert_equal "TestProviders::TestClient", provider["class"]
      end

      def test_resolve_alias_provider_as_model_uses_default
        providers = {
          "codex" => {
            "name" => "codex",
            "class" => "TestProviders::CodexClient",
            "gem" => "test-gem",
            "models" => ["gpt-5", "gpt-5-mini"],
            "aliases" => {
              "model" => {"mini" => "gpt-5-mini", "5" => "gpt-5"}
            }
          },
          "claude" => {
            "name" => "claude",
            "class" => "TestProviders::ClaudeClient",
            "gem" => "test-gem",
            "models" => ["claude-opus-4-1", "claude-sonnet-4-5"]
          }
        }

        registry = create_registry_with(providers)

        # provider:provider auto-resolves to provider:default_model
        assert_equal "codex:gpt-5", registry.resolve_alias("codex:codex")
        assert_equal "claude:claude-opus-4-1", registry.resolve_alias("claude:claude")

        # Existing model aliases still work
        assert_equal "codex:gpt-5-mini", registry.resolve_alias("codex:mini")

        # Non-matching alias passes through unchanged
        assert_equal "codex:unknown", registry.resolve_alias("codex:unknown")
      end

      def test_yaml_config_date_fields_supported
        # Verify that Date fields in provider config are handled correctly
        providers = {
          "datetestprovider" => {
            "name" => "date-test-provider",
            "class" => "TestProviders::TestClient",
            "gem" => "test-gem",
            "last_synced" => Date.new(2025, 12, 5)
          }
        }

        registry = create_registry_with(providers)
        assert registry.provider_exists?("date-test-provider")

        provider = registry.get_provider("date-test-provider")
        assert_instance_of Date, provider["last_synced"]
        assert_equal Date.new(2025, 12, 5), provider["last_synced"]
      end

      private

      # Helper to create a registry with injected providers.
      # Bypasses load_all_configurations by using allocate, then sets providers directly.
      def create_registry_with(providers)
        registry = Molecules::ClientRegistry.allocate
        registry.instance_variable_set(:@providers, {})
        registry.instance_variable_set(:@loaded_gems, {})
        registry.instance_variable_set(:@global_aliases, {})
        registry.instance_variable_set(:@model_aliases, {})

        # Inject providers with validation (mirrors load_all_configurations logic)
        providers.each do |_key, config|
          next unless config["name"] && config["class"]

          normalized_name = config["name"].to_s.strip.downcase.gsub(/[-_]/, "")
          registry.providers[normalized_name] = config
        end

        # Build alias maps
        registry.send(:build_alias_maps)
        registry
      end
    end
  end
end
