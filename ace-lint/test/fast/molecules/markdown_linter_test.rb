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

      Load and run `ace-bundle wfi://task/plan` in the current project, then follow the loaded workflow as the source of truth and execute it end-to-end instead of only summarizing it.
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

  def test_check_markdown_style_ignores_heading_warnings_inside_fenced_code_blocks
    content = <<~MARKDOWN
      ```ruby
      # Inside code block heading-like line
      * list-like line
      ```
    MARKDOWN

    warnings = Ace::Lint::Molecules::MarkdownLinter.check_markdown_style(content)

    refute warnings.any? { |warning| warning.message.include?("heading") }
    refute warnings.any? { |warning| warning.message.include?("list") }
  end

  def test_check_markdown_style_detects_trailing_whitespace
    content = "# Heading\n\nLine with trailing spaces   \n"

    warnings = Ace::Lint::Molecules::MarkdownLinter.check_markdown_style(content)

    assert warnings.any? { |warning| warning.message == "Trailing whitespace found" }
  end
end
