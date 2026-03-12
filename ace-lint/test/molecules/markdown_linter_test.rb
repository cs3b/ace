# frozen_string_literal: true

require "test_helper"

class Ace::Lint::Molecules::MarkdownLinterTest < Minitest::Test
  def test_frontmatter_is_ignored_for_markdown_heading_and_link_warnings
    content = <<~MARKDOWN
      ---
      name: as-task-plan
      description: Creates JIT implementation plan
      # bundle: wfi://task/plan
      # agent: Plan
      user-invocable: true
      argument-hint: [task-id]
      ---

      read and run `ace-bundle wfi://task/plan`
    MARKDOWN

    result = Ace::Lint::Molecules::MarkdownLinter.lint_content("SKILL.md", content)

    assert result.success?
    refute result.warnings.any? { |warning| warning.message.include?("Missing blank line after heading") }
    refute result.warnings.any? { |warning| warning.message.include?("No link definition") }
  end

  def test_body_markdown_warnings_still_report_after_frontmatter
    content = <<~MARKDOWN
      ---
      name: as-task-plan
      description: Creates JIT implementation plan
      # bundle: wfi://task/plan
      # agent: Plan
      user-invocable: true
      ---
      # Heading
      Body
    MARKDOWN

    result = Ace::Lint::Molecules::MarkdownLinter.lint_content("SKILL.md", content)

    assert result.warnings.any? { |warning| warning.message.include?("Missing blank line after heading") }
  end
end
