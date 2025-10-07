# frozen_string_literal: true

require "test_helper"

module Ace
  module LLM
    module Providers
      class CLITest < Minitest::Test
        def test_that_it_has_a_version_number
          refute_nil ::Ace::LLM::Providers::CLI::VERSION
        end

        def test_version_is_correct
          assert_equal "0.9.1", ::Ace::LLM::Providers::CLI::VERSION
        end

        def test_module_exists
          assert_kind_of Module, ::Ace::LLM::Providers::CLI
        end

        def test_claude_code_client_exists
          assert_kind_of Class, ::Ace::LLM::Providers::CLI::ClaudeCodeClient
        end

        def test_codex_client_exists
          assert_kind_of Class, ::Ace::LLM::Providers::CLI::CodexClient
        end

        def test_setup_method_exists
          assert_respond_to ::Ace::LLM::Providers::CLI, :setup
        end
      end
    end
  end
end