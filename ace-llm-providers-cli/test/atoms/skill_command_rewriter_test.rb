# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/llm/providers/cli/atoms/skill_command_rewriter"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          class SkillCommandRewriterTest < Minitest::Test
            SKILLS = %w[ace-onboard ace-git-commit ace-review-pr commit search].freeze

            def test_rewrites_simple_skill_at_start_of_line
              result = SkillCommandRewriter.call("/ace-onboard", skill_names: SKILLS)
              assert_equal "/skill:ace-onboard", result
            end

            def test_rewrites_skill_after_whitespace
              result = SkillCommandRewriter.call("Please run /ace-onboard first", skill_names: SKILLS)
              assert_equal "Please run /skill:ace-onboard first", result
            end

            def test_rewrites_underscore_skill_names
              result = SkillCommandRewriter.call("/ace-git-commit", skill_names: SKILLS)
              assert_equal "/skill:ace-git-commit", result
            end

            def test_rewrites_multiple_skills_in_same_prompt
              input = "Run /ace-onboard then /ace-git-commit"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_equal "Run /skill:ace-onboard then /skill:ace-git-commit", result
            end

            def test_does_not_rewrite_unknown_names
              result = SkillCommandRewriter.call("/unknown-command", skill_names: SKILLS)
              assert_equal "/unknown-command", result
            end

            def test_does_not_double_rewrite_skill_prefix
              # If prompt already has /skill:name, it should NOT become /skill:skill:name
              result = SkillCommandRewriter.call("/skill:ace-onboard", skill_names: SKILLS)
              assert_equal "/skill:ace-onboard", result
            end

            def test_skips_fenced_code_blocks
              input = <<~TEXT
                Run this:
                ```
                /ace-onboard
                ```
                Then /commit
              TEXT
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_includes result, "/ace-onboard"       # preserved inside code block
              assert_includes result, "/skill:commit"  # rewritten outside code block
              refute_includes result, "/skill:ace-onboard" # NOT rewritten inside code block
            end

            def test_skips_inline_code_spans
              input = "Use `/ace-onboard` to start, then run /commit"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_includes result, "`/ace-onboard`"      # preserved inside backticks
              assert_includes result, "/skill:commit"    # rewritten outside backticks
            end

            def test_does_not_rewrite_urls
              # URLs have slash preceded by another slash or domain chars — not whitespace
              input = "Visit https://example.com/ace-onboard for details"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_equal "Visit https://example.com/ace-onboard for details", result
            end

            def test_longest_match_first
              # "ace-review-pr" should match before "ace_review" in partial overlaps
              skills = %w[ace-review-pr ace_review]
              input = "/ace-review-pr please"
              result = SkillCommandRewriter.call(input, skill_names: skills)
              assert_equal "/skill:ace-review-pr please", result
            end

            def test_returns_original_for_nil_prompt
              result = SkillCommandRewriter.call(nil, skill_names: SKILLS)
              assert_nil result
            end

            def test_returns_original_for_empty_prompt
              result = SkillCommandRewriter.call("", skill_names: SKILLS)
              assert_equal "", result
            end

            def test_returns_original_for_nil_skill_names
              result = SkillCommandRewriter.call("/ace-onboard", skill_names: nil)
              assert_equal "/ace-onboard", result
            end

            def test_returns_original_for_empty_skill_names
              result = SkillCommandRewriter.call("/ace-onboard", skill_names: [])
              assert_equal "/ace-onboard", result
            end

            def test_skill_at_end_of_line
              result = SkillCommandRewriter.call("Run /ace-onboard", skill_names: SKILLS)
              assert_equal "Run /skill:ace-onboard", result
            end

            def test_multiline_prompt
              input = "/ace-onboard\nThen /ace-git-commit\nDone"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_includes result, "/skill:ace-onboard"
              assert_includes result, "/skill:ace-git-commit"
            end

            def test_does_not_rewrite_file_paths
              # File paths like /usr/bin/ace-onboard have slash before the name
              input = "Check /usr/bin/ace-onboard"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              # "/usr/bin/ace-onboard" — the "/ace-onboard" part is preceded by "/bin"
              # so it should not match (not preceded by whitespace)
              refute_includes result, "/skill:ace-onboard"
            end
          end
        end
      end
    end
  end
end
