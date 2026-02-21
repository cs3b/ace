# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/llm/providers/cli/atoms/skill_command_rewriter"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          class SkillCommandRewriterTest < Minitest::Test
            SKILLS = %w[ace_onboard ace_git_commit ace_review_pr commit search].freeze

            def test_rewrites_simple_skill_at_start_of_line
              result = SkillCommandRewriter.call("/ace_onboard", skill_names: SKILLS)
              assert_equal "/skill:ace_onboard", result
            end

            def test_rewrites_skill_after_whitespace
              result = SkillCommandRewriter.call("Please run /ace_onboard first", skill_names: SKILLS)
              assert_equal "Please run /skill:ace_onboard first", result
            end

            def test_rewrites_underscore_skill_names
              result = SkillCommandRewriter.call("/ace_git_commit", skill_names: SKILLS)
              assert_equal "/skill:ace_git_commit", result
            end

            def test_rewrites_multiple_skills_in_same_prompt
              input = "Run /ace_onboard then /ace_git_commit"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_equal "Run /skill:ace_onboard then /skill:ace_git_commit", result
            end

            def test_does_not_rewrite_unknown_names
              result = SkillCommandRewriter.call("/unknown-command", skill_names: SKILLS)
              assert_equal "/unknown-command", result
            end

            def test_does_not_double_rewrite_skill_prefix
              # If prompt already has /skill:name, it should NOT become /skill:skill:name
              result = SkillCommandRewriter.call("/skill:ace_onboard", skill_names: SKILLS)
              assert_equal "/skill:ace_onboard", result
            end

            def test_skips_fenced_code_blocks
              input = <<~TEXT
                Run this:
                ```
                /ace_onboard
                ```
                Then /commit
              TEXT
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_includes result, "/ace_onboard"       # preserved inside code block
              assert_includes result, "/skill:commit"  # rewritten outside code block
              refute_includes result, "/skill:ace_onboard" # NOT rewritten inside code block
            end

            def test_skips_inline_code_spans
              input = "Use `/ace_onboard` to start, then run /commit"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_includes result, "`/ace_onboard`"      # preserved inside backticks
              assert_includes result, "/skill:commit"    # rewritten outside backticks
            end

            def test_does_not_rewrite_urls
              # URLs have slash preceded by another slash or domain chars — not whitespace
              input = "Visit https://example.com/ace_onboard for details"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_equal "Visit https://example.com/ace_onboard for details", result
            end

            def test_longest_match_first
              # "ace_review_pr" should match before "ace_review" in partial overlaps
              skills = %w[ace_review_pr ace_review]
              input = "/ace_review_pr please"
              result = SkillCommandRewriter.call(input, skill_names: skills)
              assert_equal "/skill:ace_review_pr please", result
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
              result = SkillCommandRewriter.call("/ace_onboard", skill_names: nil)
              assert_equal "/ace_onboard", result
            end

            def test_returns_original_for_empty_skill_names
              result = SkillCommandRewriter.call("/ace_onboard", skill_names: [])
              assert_equal "/ace_onboard", result
            end

            def test_skill_at_end_of_line
              result = SkillCommandRewriter.call("Run /ace_onboard", skill_names: SKILLS)
              assert_equal "Run /skill:ace_onboard", result
            end

            def test_multiline_prompt
              input = "/ace_onboard\nThen /ace_git_commit\nDone"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_includes result, "/skill:ace_onboard"
              assert_includes result, "/skill:ace_git_commit"
            end

            def test_does_not_rewrite_file_paths
              # File paths like /usr/bin/ace_onboard have slash before the name
              input = "Check /usr/bin/ace_onboard"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              # "/usr/bin/ace_onboard" — the "/ace_onboard" part is preceded by "/bin"
              # so it should not match (not preceded by whitespace)
              refute_includes result, "/skill:ace_onboard"
            end
          end
        end
      end
    end
  end
end
