# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../lib/ace/llm/providers/cli/atoms/skill_command_rewriter"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          class SkillCommandRewriterTest < Minitest::Test
            SKILLS = %w[as-onboard as-git-commit as-review-pr commit search].freeze

            def test_rewrites_simple_skill_at_start_of_line
              result = SkillCommandRewriter.call("/as-onboard", skill_names: SKILLS)
              assert_equal "/skill:as-onboard", result
            end

            def test_rewrites_skill_after_whitespace
              result = SkillCommandRewriter.call("Please run /as-onboard first", skill_names: SKILLS)
              assert_equal "Please run /skill:as-onboard first", result
            end

            def test_rewrites_underscore_skill_names
              result = SkillCommandRewriter.call("/as-git-commit", skill_names: SKILLS)
              assert_equal "/skill:as-git-commit", result
            end

            def test_rewrites_multiple_skills_in_same_prompt
              input = "Run /as-onboard then /as-git-commit"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_equal "Run /skill:as-onboard then /skill:as-git-commit", result
            end

            def test_does_not_rewrite_unknown_names
              result = SkillCommandRewriter.call("/unknown-command", skill_names: SKILLS)
              assert_equal "/unknown-command", result
            end

            def test_does_not_double_rewrite_skill_prefix
              # If prompt already has /skill:name, it should NOT become /skill:skill:name
              result = SkillCommandRewriter.call("/skill:as-onboard", skill_names: SKILLS)
              assert_equal "/skill:as-onboard", result
            end

            def test_skips_fenced_code_blocks
              input = <<~TEXT
                Run this:
                ```
                /as-onboard
                ```
                Then /commit
              TEXT
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_includes result, "/as-onboard"       # preserved inside code block
              assert_includes result, "/skill:commit"  # rewritten outside code block
              refute_includes result, "/skill:as-onboard" # NOT rewritten inside code block
            end

            def test_skips_inline_code_spans
              input = "Use `/as-onboard` to start, then run /commit"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_includes result, "`/as-onboard`"      # preserved inside backticks
              assert_includes result, "/skill:commit"    # rewritten outside backticks
            end

            def test_does_not_rewrite_urls
              # URLs have slash preceded by another slash or domain chars — not whitespace
              input = "Visit https://example.com/as-onboard for details"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_equal "Visit https://example.com/as-onboard for details", result
            end

            def test_longest_match_first
              # "as-review-pr" should match before "as_review" in partial overlaps
              skills = %w[as-review-pr as_review]
              input = "/as-review-pr please"
              result = SkillCommandRewriter.call(input, skill_names: skills)
              assert_equal "/skill:as-review-pr please", result
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
              result = SkillCommandRewriter.call("/as-onboard", skill_names: nil)
              assert_equal "/as-onboard", result
            end

            def test_returns_original_for_empty_skill_names
              result = SkillCommandRewriter.call("/as-onboard", skill_names: [])
              assert_equal "/as-onboard", result
            end

            def test_skill_at_end_of_line
              result = SkillCommandRewriter.call("Run /as-onboard", skill_names: SKILLS)
              assert_equal "Run /skill:as-onboard", result
            end

            def test_multiline_prompt
              input = "/as-onboard\nThen /as-git-commit\nDone"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_includes result, "/skill:as-onboard"
              assert_includes result, "/skill:as-git-commit"
            end

            def test_does_not_rewrite_file_paths
              # File paths like /usr/bin/as-onboard have slash before the name
              input = "Check /usr/bin/as-onboard"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              # "/usr/bin/as-onboard" — the "/as-onboard" part is preceded by "/bin"
              # so it should not match (not preceded by whitespace)
              refute_includes result, "/skill:as-onboard"
            end
          end
        end
      end
    end
  end
end
