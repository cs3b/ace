# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../lib/ace/llm/providers/cli/atoms/command_rewriter"
require_relative "../../../lib/ace/llm/providers/cli/atoms/command_formatters"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          class CommandRewriterTest < Minitest::Test
            SKILLS = %w[ace-onboard ace-git-commit ace-review-pr commit search].freeze

            # PI Formatter Tests
            def test_pi_formatter_rewrites_simple_skill_at_start_of_line
              result = CommandRewriter.call("/ace-onboard", skill_names: SKILLS, formatter: CommandFormatters::PI_FORMATTER)
              assert_equal "/skill:ace-onboard", result
            end

            def test_pi_formatter_rewrites_skill_after_whitespace
              result = CommandRewriter.call("Please run /ace-onboard first", skill_names: SKILLS, formatter: CommandFormatters::PI_FORMATTER)
              assert_equal "Please run /skill:ace-onboard first", result
            end

            def test_pi_formatter_rewrites_underscore_skill_names
              result = CommandRewriter.call("/ace-git-commit", skill_names: SKILLS, formatter: CommandFormatters::PI_FORMATTER)
              assert_equal "/skill:ace-git-commit", result
            end

            def test_pi_formatter_rewrites_multiple_skills_in_same_prompt
              input = "Run /ace-onboard then /ace-git-commit"
              result = CommandRewriter.call(input, skill_names: SKILLS, formatter: CommandFormatters::PI_FORMATTER)
              assert_equal "Run /skill:ace-onboard then /skill:ace-git-commit", result
            end

            # Codex Formatter Tests
            def test_codex_formatter_rewrites_simple_skill_at_start_of_line
              result = CommandRewriter.call("/ace-onboard", skill_names: SKILLS, formatter: CommandFormatters::CODEX_FORMATTER)
              assert_equal "$ace-onboard", result
            end

            def test_codex_formatter_rewrites_skill_after_whitespace
              result = CommandRewriter.call("Please run /ace-onboard first", skill_names: SKILLS, formatter: CommandFormatters::CODEX_FORMATTER)
              assert_equal "Please run $ace-onboard first", result
            end

            def test_codex_formatter_preserves_underscores
              result = CommandRewriter.call("/ace-git-commit", skill_names: SKILLS, formatter: CommandFormatters::CODEX_FORMATTER)
              assert_equal "$ace-git-commit", result
            end

            def test_codex_formatter_rewrites_multiple_skills_in_same_prompt
              input = "Run /ace-onboard then /ace-git-commit"
              result = CommandRewriter.call(input, skill_names: SKILLS, formatter: CommandFormatters::CODEX_FORMATTER)
              assert_equal "Run $ace-onboard then $ace-git-commit", result
            end

            # Common behavior tests (applies to both formatters)
            def test_does_not_rewrite_unknown_names
              pi_result = CommandRewriter.call("/unknown-command", skill_names: SKILLS, formatter: CommandFormatters::PI_FORMATTER)
              codex_result = CommandRewriter.call("/unknown-command", skill_names: SKILLS, formatter: CommandFormatters::CODEX_FORMATTER)
              assert_equal "/unknown-command", pi_result
              assert_equal "/unknown-command", codex_result
            end

            def test_skips_fenced_code_blocks
              input = <<~TEXT
                Run this:
                ```
                /ace-onboard
                ```
                Then /commit
              TEXT

              pi_result = CommandRewriter.call(input, skill_names: SKILLS, formatter: CommandFormatters::PI_FORMATTER)
              codex_result = CommandRewriter.call(input, skill_names: SKILLS, formatter: CommandFormatters::CODEX_FORMATTER)

              # Both should preserve /ace-onboard inside code block
              assert_includes pi_result, "/ace-onboard"
              assert_includes codex_result, "/ace-onboard"

              # Both should rewrite /commit outside code block
              assert_includes pi_result, "/skill:commit"
              assert_includes codex_result, "$commit"
            end

            def test_skips_inline_code_spans
              input = "Use `/ace-onboard` to start, then run /commit"

              pi_result = CommandRewriter.call(input, skill_names: SKILLS, formatter: CommandFormatters::PI_FORMATTER)
              codex_result = CommandRewriter.call(input, skill_names: SKILLS, formatter: CommandFormatters::CODEX_FORMATTER)

              # Both should preserve `/ace-onboard` inside backticks
              assert_includes pi_result, "`/ace-onboard`"
              assert_includes codex_result, "`/ace-onboard`"

              # Both should rewrite /commit outside backticks
              assert_includes pi_result, "/skill:commit"
              assert_includes codex_result, "$commit"
            end

            def test_does_not_rewrite_urls
              input = "Visit https://example.com/ace-onboard for details"

              pi_result = CommandRewriter.call(input, skill_names: SKILLS, formatter: CommandFormatters::PI_FORMATTER)
              codex_result = CommandRewriter.call(input, skill_names: SKILLS, formatter: CommandFormatters::CODEX_FORMATTER)

              assert_equal "Visit https://example.com/ace-onboard for details", pi_result
              assert_equal "Visit https://example.com/ace-onboard for details", codex_result
            end

            def test_longest_match_first
              skills = %w[ace-review-pr ace_review]
              input = "/ace-review-pr please"

              pi_result = CommandRewriter.call(input, skill_names: skills, formatter: CommandFormatters::PI_FORMATTER)
              codex_result = CommandRewriter.call(input, skill_names: skills, formatter: CommandFormatters::CODEX_FORMATTER)

              assert_equal "/skill:ace-review-pr please", pi_result
              assert_equal "$ace-review-pr please", codex_result
            end

            def test_returns_original_for_nil_prompt
              pi_result = CommandRewriter.call(nil, skill_names: SKILLS, formatter: CommandFormatters::PI_FORMATTER)
              codex_result = CommandRewriter.call(nil, skill_names: SKILLS, formatter: CommandFormatters::CODEX_FORMATTER)

              assert_nil pi_result
              assert_nil codex_result
            end

            def test_returns_original_for_empty_prompt
              pi_result = CommandRewriter.call("", skill_names: SKILLS, formatter: CommandFormatters::PI_FORMATTER)
              codex_result = CommandRewriter.call("", skill_names: SKILLS, formatter: CommandFormatters::CODEX_FORMATTER)

              assert_equal "", pi_result
              assert_equal "", codex_result
            end

            def test_returns_original_for_nil_skill_names
              pi_result = CommandRewriter.call("/ace-onboard", skill_names: nil, formatter: CommandFormatters::PI_FORMATTER)
              codex_result = CommandRewriter.call("/ace-onboard", skill_names: nil, formatter: CommandFormatters::CODEX_FORMATTER)

              assert_equal "/ace-onboard", pi_result
              assert_equal "/ace-onboard", codex_result
            end

            def test_returns_original_for_empty_skill_names
              pi_result = CommandRewriter.call("/ace-onboard", skill_names: [], formatter: CommandFormatters::PI_FORMATTER)
              codex_result = CommandRewriter.call("/ace-onboard", skill_names: [], formatter: CommandFormatters::CODEX_FORMATTER)

              assert_equal "/ace-onboard", pi_result
              assert_equal "/ace-onboard", codex_result
            end

            def test_skill_at_end_of_line
              pi_result = CommandRewriter.call("Run /ace-onboard", skill_names: SKILLS, formatter: CommandFormatters::PI_FORMATTER)
              codex_result = CommandRewriter.call("Run /ace-onboard", skill_names: SKILLS, formatter: CommandFormatters::CODEX_FORMATTER)

              assert_equal "Run /skill:ace-onboard", pi_result
              assert_equal "Run $ace-onboard", codex_result
            end

            def test_multiline_prompt
              input = "/ace-onboard\nThen /ace-git-commit\nDone"

              pi_result = CommandRewriter.call(input, skill_names: SKILLS, formatter: CommandFormatters::PI_FORMATTER)
              codex_result = CommandRewriter.call(input, skill_names: SKILLS, formatter: CommandFormatters::CODEX_FORMATTER)

              assert_includes pi_result, "/skill:ace-onboard"
              assert_includes pi_result, "/skill:ace-git-commit"
              assert_includes codex_result, "$ace-onboard"
              assert_includes codex_result, "$ace-git-commit"
            end

            def test_does_not_rewrite_file_paths
              input = "Check /usr/bin/ace-onboard"

              pi_result = CommandRewriter.call(input, skill_names: SKILLS, formatter: CommandFormatters::PI_FORMATTER)
              codex_result = CommandRewriter.call(input, skill_names: SKILLS, formatter: CommandFormatters::CODEX_FORMATTER)

              # "/usr/bin/ace-onboard" — the "/ace-onboard" part is preceded by "/bin"
              # so it should not match (not preceded by whitespace)
              refute_includes pi_result, "/skill:ace-onboard"
              refute_includes codex_result, "$ace-onboard"
            end
          end
        end
      end
    end
  end
end
