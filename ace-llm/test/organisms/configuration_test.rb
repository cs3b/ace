# frozen_string_literal: true

require_relative "../test_helper"
require "ace/llm/configuration"
require "ace/support/models"

module Ace
  module LLM
    class ConfigurationTest < AceLlmTestCase
      def setup
        super
        @provider_configs = {
          "google" => {"name" => "Google", "class" => "X"},
          "anthropic" => {"name" => "anthropic", "class" => "X"},
          "deepseek" => {"name" => "Deep_Seek", "class" => "X"}
        }
        @configuration = Configuration.new
      end

      def teardown
        ENV.delete("ACE_LLM_PROVIDERS_ACTIVE")
        super
      end

      def test_providers_returns_all_when_active_list_missing
        with_config(active: nil) do
          assert_equal @provider_configs.keys.sort, @configuration.providers.keys.sort
          refute @configuration.provider_filter_applied?
        end
      end

      def test_providers_filters_and_normalizes_active_list
        with_config(active: ["Google", "ANTHROPIC"]) do
          assert_equal %w[anthropic google], @configuration.providers.keys.sort
          assert_equal %w[anthropic google], @configuration.active_provider_names
          assert_equal ["deepseek"], @configuration.inactive_provider_names
          assert @configuration.provider_filter_applied?
        end
      end

      def test_empty_active_list_keeps_all_providers
        with_config(active: []) do
          assert_equal @provider_configs.keys.sort, @configuration.providers.keys.sort
          refute @configuration.provider_filter_applied?
        end
      end

      def test_env_override_takes_precedence_over_yaml
        ENV["ACE_LLM_PROVIDERS_ACTIVE"] = "deepseek"

        with_config(active: ["google"]) do
          assert_equal ["deepseek"], @configuration.providers.keys
          assert_equal ["deepseek"], @configuration.active_provider_names
        end
      end

      def test_empty_env_disables_filter_even_when_yaml_has_active_list
        ENV["ACE_LLM_PROVIDERS_ACTIVE"] = ""

        with_config(active: ["google"]) do
          assert_equal @provider_configs.keys.sort, @configuration.providers.keys.sort
          refute @configuration.provider_filter_applied?
        end
      end

      def test_invalid_active_provider_name_warns_and_is_ignored
        with_config(active: ["google", "does-not-exist"]) do
          _stdout, stderr = capture_io { @configuration.providers }

          assert_equal ["google"], @configuration.providers.keys
          assert_match(/Unknown providers in llm.providers.active: doesnotexist/, stderr)
          assert_match(/were skipped/, stderr)
          assert_match(/ace-llm --list-providers/, stderr)
        end
      end

      def test_provider_inactive_checks_filtered_state
        with_config(active: ["google"]) do
          assert @configuration.provider_inactive?("deepseek")
          refute @configuration.provider_inactive?("google")
          refute @configuration.provider_inactive?("nonexistent")
        end
      end

      private

      def with_config(active:)
        @configuration.reload!
        @configuration.stub(:get, active) do
          Ace::Support::Models::Atoms::ProviderConfigReader.stub(:read_all, @provider_configs) do
            yield
          end
        end
      end
    end
  end
end
