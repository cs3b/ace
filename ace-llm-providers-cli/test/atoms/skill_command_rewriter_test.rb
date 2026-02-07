# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/llm/providers/cli/atoms/skill_command_rewriter"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          class SkillCommandRewriterTest < Minitest::Test
            SKILLS = %w[onboard ace:commit ace:review-pr commit search].freeze

            def test_rewrites_simple_skill_at_start_of_line
              result = SkillCommandRewriter.call("/onboard", skill_names: SKILLS)
              assert_equal "/skill:onboard", result
            end

            def test_rewrites_skill_after_whitespace
              result = SkillCommandRewriter.call("Please run /onboard first", skill_names: SKILLS)
              assert_equal "Please run /skill:onboard first", result
            end

            def test_rewrites_colon_skill_names
              result = SkillCommandRewriter.call("/ace:commit", skill_names: SKILLS)
              assert_equal "/skill:ace:commit", result
            end

            def test_rewrites_multiple_skills_in_same_prompt
              input = "Run /onboard then /ace:commit"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_equal "Run /skill:onboard then /skill:ace:commit", result
            end

            def test_does_not_rewrite_unknown_names
              result = SkillCommandRewriter.call("/unknown-command", skill_names: SKILLS)
              assert_equal "/unknown-command", result
            end

            def test_does_not_double_rewrite_skill_prefix
              # If prompt already has /skill:name, it should NOT become /skill:skill:name
              result = SkillCommandRewriter.call("/skill:onboard", skill_names: SKILLS)
              assert_equal "/skill:onboard", result
            end

            def test_skips_fenced_code_blocks
              input = <<~TEXT
                Run this:
                ```
                /onboard
                ```
                Then /commit
              TEXT
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_includes result, "/onboard"       # preserved inside code block
              assert_includes result, "/skill:commit"  # rewritten outside code block
              refute_includes result, "/skill:onboard" # NOT rewritten inside code block
            end

            def test_skips_inline_code_spans
              input = "Use `/onboard` to start, then run /commit"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_includes result, "`/onboard`"      # preserved inside backticks
              assert_includes result, "/skill:commit"    # rewritten outside backticks
            end

            def test_does_not_rewrite_urls
              # URLs have slash preceded by another slash or domain chars — not whitespace
              input = "Visit https://example.com/onboard for details"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_equal "Visit https://example.com/onboard for details", result
            end

            def test_longest_match_first
              # "ace:review-pr" should match before "search" in partial overlaps
              skills = %w[ace:review-pr ace:review]
              input = "/ace:review-pr please"
              result = SkillCommandRewriter.call(input, skill_names: skills)
              assert_equal "/skill:ace:review-pr please", result
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
              result = SkillCommandRewriter.call("/onboard", skill_names: nil)
              assert_equal "/onboard", result
            end

            def test_returns_original_for_empty_skill_names
              result = SkillCommandRewriter.call("/onboard", skill_names: [])
              assert_equal "/onboard", result
            end

            def test_skill_at_end_of_line
              result = SkillCommandRewriter.call("Run /onboard", skill_names: SKILLS)
              assert_equal "Run /skill:onboard", result
            end

            def test_multiline_prompt
              input = "/onboard\nThen /ace:commit\nDone"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              assert_includes result, "/skill:onboard"
              assert_includes result, "/skill:ace:commit"
            end

            def test_does_not_rewrite_file_paths
              # File paths like /usr/bin/onboard have slash before the name
              input = "Check /usr/bin/onboard"
              result = SkillCommandRewriter.call(input, skill_names: SKILLS)
              # "/usr/bin/onboard" — the "/onboard" part is preceded by "/bin"
              # so it should not match (not preceded by whitespace)
              refute_includes result, "/skill:onboard"
            end
          end
        end
      end
    end
  end
end
