# frozen_string_literal: true

require "test_helper"

module Ace
  class LLMTest < AceLlmTestCase
    def test_that_it_has_a_version_number
      refute_nil ::Ace::LLM::VERSION
    end

    def test_version_is_correct
      assert_equal "0.9.0", ::Ace::LLM::VERSION
    end

    def test_module_exists
      assert_kind_of Module, ::Ace::LLM
    end

    def test_error_classes_exist
      assert_kind_of Class, ::Ace::LLM::Error
      assert_kind_of Class, ::Ace::LLM::ProviderError
      assert_kind_of Class, ::Ace::LLM::ConfigurationError
      assert_kind_of Class, ::Ace::LLM::AuthenticationError
    end

    def test_query_interface_class_exists
      assert_kind_of Class, ::Ace::LLM::QueryInterface
    end

    def test_atoms_module_exists
      assert_kind_of Module, ::Ace::LLM::Atoms
    end

    def test_molecules_module_exists
      assert_kind_of Module, ::Ace::LLM::Molecules
    end

    def test_organisms_module_exists
      assert_kind_of Module, ::Ace::LLM::Organisms
    end

    def test_client_classes_exist
      assert_kind_of Class, ::Ace::LLM::Organisms::BaseClient
      assert_kind_of Class, ::Ace::LLM::Organisms::GoogleClient
      assert_kind_of Class, ::Ace::LLM::Organisms::OpenAIClient
      assert_kind_of Class, ::Ace::LLM::Organisms::AnthropicClient
      assert_kind_of Class, ::Ace::LLM::Organisms::MistralClient
      assert_kind_of Class, ::Ace::LLM::Organisms::TogetherAIClient
      assert_kind_of Class, ::Ace::LLM::Organisms::LMStudioClient
    end
  end
end