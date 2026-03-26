# frozen_string_literal: true

require "test_helper"
require "tempfile"

class Ace::Lint::Molecules::MarkdownSurgicalFixerTest < Minitest::Test
  def test_fix_content_applies_typography_outside_code_and_links
    content = <<~MARKDOWN
      Start with em-dash\u2014and \u201Csmart quotes\u201D.
      Link [\u201Clabel\u201D](https://example.com/path\u2014keep).
      Inline `code\u2014keep` should stay.

      ```ruby
      puts "code block \u2014 keep"
      ```
    MARKDOWN

    result = Ace::Lint::Molecules::MarkdownSurgicalFixer.fix_content(content)

    assert result[:success]
    assert result[:formatted]
    assert_includes result[:formatted_content], "Start with em-dash--and \"smart quotes\"."
    assert_includes result[:formatted_content], "Link [\"label\"](https://example.com/path\u2014keep)."
    assert_includes result[:formatted_content], "`code\u2014keep`"
    assert_includes result[:formatted_content], "puts \"code block \u2014 keep\""
  end

  def test_fix_content_preserves_link_destination_with_nested_parentheses
    content = "Link [\u201CLabel\u201D](https://example.com/a(b)c\u2014d)\n"

    result = Ace::Lint::Molecules::MarkdownSurgicalFixer.fix_content(content)

    assert result[:success]
    assert result[:formatted]
    assert_includes result[:formatted_content], "[\"Label\"](https://example.com/a(b)c\u2014d)"
  end

  def test_fix_content_preserves_frontmatter_exactly
    content = <<~MARKDOWN
      ---
      name: "My \u201CSkill\u201D"
      ---
      # Heading
      Body\u2014text
    MARKDOWN

    result = Ace::Lint::Molecules::MarkdownSurgicalFixer.fix_content(content)

    assert result[:success]
    assert result[:formatted]
    assert_includes result[:formatted_content], "name: \"My \u201CSkill\u201D\""
    assert_includes result[:formatted_content], "# Heading"
    assert_includes result[:formatted_content], "Body--text"
  end

  def test_fix_content_inserts_blank_lines_and_trailing_newline
    content = "# Heading\nBody\n* item\nAfter list\n```ruby\nputs 'hi'\n```\nAfter code block"

    result = Ace::Lint::Molecules::MarkdownSurgicalFixer.fix_content(content)
    fixed = result[:formatted_content]

    assert result[:success]
    assert result[:formatted]
    assert_includes fixed, "# Heading\n\nBody"
    assert_includes fixed, "* item\n\nAfter list"
    assert_includes fixed, "```\n\nAfter code block"
    assert fixed.end_with?("\n")
  end

  def test_fix_file_returns_not_formatted_when_no_changes_needed
    Tempfile.create(["markdown_surgical_fixer", ".md"]) do |file|
      file.write("# Heading\n\nBody.\n")
      file.rewind

      result = Ace::Lint::Molecules::MarkdownSurgicalFixer.fix_file(file.path)

      assert result[:success]
      refute result[:formatted]
      assert_empty result[:warnings]
    end
  end

  def test_fix_file_skips_non_utf8_files
    Tempfile.create(["markdown_surgical_fixer", ".md"]) do |file|
      File.binwrite(file.path, "\xFF\xFE".b)

      result = Ace::Lint::Molecules::MarkdownSurgicalFixer.fix_file(file.path)

      assert result[:success]
      refute result[:formatted]
      assert_equal 1, result[:warnings].size
      assert_match(/Skipped non-UTF8 file/, result[:warnings].first)
    end
  end

  def test_fix_file_returns_error_for_missing_file
    result = Ace::Lint::Molecules::MarkdownSurgicalFixer.fix_file("missing-file-does-not-exist.md")

    refute result[:success]
    assert_equal false, result[:formatted]
    assert_match(/File not found/, result[:errors].first)
  end
end
