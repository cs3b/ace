# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/llm/molecules/openai_compatible_params"

module Ace
  module LLM
    module Molecules
      class OpenAICompatibleParamsTest < Minitest::Test
        # Create a test class that includes the module
        class TestClient
          include OpenAICompatibleParams
        end

        def setup
          @client = TestClient.new
        end

        def test_extracts_frequency_penalty
          options = {frequency_penalty: 0.5}
          gen_opts = {}

          result = @client.extract_openai_compatible_options(options, gen_opts)

          assert_equal 0.5, result[:frequency_penalty]
        end

        def test_extracts_presence_penalty
          options = {presence_penalty: 0.3}
          gen_opts = {}

          result = @client.extract_openai_compatible_options(options, gen_opts)

          assert_equal 0.3, result[:presence_penalty]
        end

        def test_extracts_both_penalties
          options = {frequency_penalty: 0.5, presence_penalty: 0.3}
          gen_opts = {}

          result = @client.extract_openai_compatible_options(options, gen_opts)

          assert_equal 0.5, result[:frequency_penalty]
          assert_equal 0.3, result[:presence_penalty]
        end

        def test_preserves_zero_frequency_penalty
          options = {frequency_penalty: 0}
          gen_opts = {}

          result = @client.extract_openai_compatible_options(options, gen_opts)

          assert_equal 0, result[:frequency_penalty]
          assert result.key?(:frequency_penalty), "frequency_penalty should be present with value 0"
        end

        def test_preserves_zero_presence_penalty
          options = {presence_penalty: 0}
          gen_opts = {}

          result = @client.extract_openai_compatible_options(options, gen_opts)

          assert_equal 0, result[:presence_penalty]
          assert result.key?(:presence_penalty), "presence_penalty should be present with value 0"
        end

        def test_preserves_negative_frequency_penalty
          options = {frequency_penalty: -0.5}
          gen_opts = {}

          result = @client.extract_openai_compatible_options(options, gen_opts)

          assert_equal(-0.5, result[:frequency_penalty])
        end

        def test_preserves_negative_presence_penalty
          options = {presence_penalty: -0.3}
          gen_opts = {}

          result = @client.extract_openai_compatible_options(options, gen_opts)

          assert_equal(-0.3, result[:presence_penalty])
        end

        def test_ignores_nil_frequency_penalty
          options = {frequency_penalty: nil}
          gen_opts = {}

          result = @client.extract_openai_compatible_options(options, gen_opts)

          refute result.key?(:frequency_penalty), "frequency_penalty should not be present when nil"
        end

        def test_ignores_nil_presence_penalty
          options = {presence_penalty: nil}
          gen_opts = {}

          result = @client.extract_openai_compatible_options(options, gen_opts)

          refute result.key?(:presence_penalty), "presence_penalty should not be present when nil"
        end

        def test_ignores_missing_frequency_penalty
          options = {}
          gen_opts = {}

          result = @client.extract_openai_compatible_options(options, gen_opts)

          refute result.key?(:frequency_penalty), "frequency_penalty should not be present when missing"
        end

        def test_ignores_missing_presence_penalty
          options = {}
          gen_opts = {}

          result = @client.extract_openai_compatible_options(options, gen_opts)

          refute result.key?(:presence_penalty), "presence_penalty should not be present when missing"
        end

        def test_preserves_existing_gen_opts
          options = {frequency_penalty: 0.5}
          gen_opts = {temperature: 0.7, max_tokens: 100}

          result = @client.extract_openai_compatible_options(options, gen_opts)

          assert_equal 0.7, result[:temperature]
          assert_equal 100, result[:max_tokens]
          assert_equal 0.5, result[:frequency_penalty]
        end

        def test_returns_gen_opts
          options = {frequency_penalty: 0.5}
          gen_opts = {}

          result = @client.extract_openai_compatible_options(options, gen_opts)

          assert_same gen_opts, result, "Should return the same gen_opts hash that was passed in"
        end
      end
    end
  end
end
