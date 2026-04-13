# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../lib/ace/llm/providers/cli/atoms/args_normalizer"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          class ArgsNormalizerTest < Minitest::Test
            def setup
              @normalizer = ArgsNormalizer.new
            end

            def test_normalizes_string_args_with_prefix
              assert_equal ["--foo", "--bar"], @normalizer.normalize_cli_args("foo bar")
            end

            def test_keeps_existing_prefixes
              assert_equal ["--foo", "--bar"], @normalizer.normalize_cli_args("--foo --bar")
            end

            def test_handles_array_args
              assert_equal ["--foo", "--bar"], @normalizer.normalize_cli_args(["foo", "--bar"])
            end

            def test_handles_array_args_with_embedded_spaces
              assert_equal ["--sandbox", "danger-full-access", "--verbose"], @normalizer.normalize_cli_args(["--sandbox danger-full-access", "verbose"])
            end

            def test_preserves_single_dash_flags
              assert_equal ["-v"], @normalizer.normalize_cli_args("-v")
            end

            def test_preserves_flag_values_when_space_separated
              assert_equal ["--model", "sonnet"], @normalizer.normalize_cli_args("--model sonnet")
            end

            def test_prefixes_equals_syntax
              assert_equal ["--model=sonnet"], @normalizer.normalize_cli_args("model=sonnet")
            end

            def test_preserves_path_like_value_after_short_flag
              assert_equal ["-v", "lib/foo.rb"], @normalizer.normalize_cli_args("-v lib/foo.rb")
            end

            def test_handles_empty_input
              assert_equal [], @normalizer.normalize_cli_args(nil)
              assert_equal [], @normalizer.normalize_cli_args("")
              assert_equal [], @normalizer.normalize_cli_args([])
            end

            def test_preserves_explicit_empty_value_in_array_args
              assert_equal ["--tools", ""], @normalizer.normalize_cli_args(["--tools", ""])
            end

            def test_sentinel_passes_remaining_args_verbatim
              assert_equal ["--", "foo", "bar"], @normalizer.normalize_cli_args("-- foo bar")
            end

            def test_sentinel_after_flags
              assert_equal ["--verbose", "--", "foo"], @normalizer.normalize_cli_args("--verbose -- foo")
            end
          end
        end
      end
    end
  end
end
