# frozen_string_literal: true

require "test_helper"
require "tempfile"

class Ace::Lint::Molecules::KramdownFormatterTest < Minitest::Test
  def test_detect_structural_changes_reports_expected_categories
    original = <<~MARKDOWN
      ---
      name: test
      ---

      | a | b |
      | - | - |
      | 1 | 2 |

      ```ruby
      puts "hi"
      ```

      <div>body</div>
    MARKDOWN

    formatted = <<~MARKDOWN
      ---
      name: changed
      ---

      | a | b |
      | - | - |

      <div class="x">body</div>
    MARKDOWN

    changes = Ace::Lint::Molecules::KramdownFormatter.detect_structural_changes(original, formatted)

    assert_includes changes, "frontmatter"
    assert_includes changes, "code blocks"
    assert_includes changes, "tables"
    assert_includes changes, "html attributes"
  end

  def test_format_file_with_guardrails_skips_risky_write
    original = "---\nname: test\n---\n\nBody\n"
    risky = "---\nname: changed\n---\n\nBody\n"

    Tempfile.create(["kramdown_guardrails", ".md"]) do |file|
      file.write(original)
      file.rewind

      Ace::Lint::Molecules::KramdownFormatter.stub(:format_content, {success: true, formatted_content: risky, errors: []}) do
        result = Ace::Lint::Molecules::KramdownFormatter.format_file(file.path, guardrails: true)

        assert result[:success]
        refute result[:formatted]
        assert_equal original, File.read(file.path)
        assert_match(/structural change risk/, result[:warnings].first)
      end
    end
  end

  def test_format_file_with_guardrails_writes_when_safe
    original = "# Heading\n\nBody\n"
    safe = "# Heading\n\nBody paragraph\n"

    Tempfile.create(["kramdown_guardrails", ".md"]) do |file|
      file.write(original)
      file.rewind

      Ace::Lint::Molecules::KramdownFormatter.stub(:format_content, {success: true, formatted_content: safe, errors: []}) do
        result = Ace::Lint::Molecules::KramdownFormatter.format_file(file.path, guardrails: true)

        assert result[:success]
        assert result[:formatted]
        assert_equal safe, File.read(file.path)
      end
    end
  end

  def test_detect_structural_changes_flags_html_attribute_removal
    original = "<div class=\"alpha\" data-id=\"42\">Body</div>\n"
    formatted = "<div>Body</div>\n"

    changes = Ace::Lint::Molecules::KramdownFormatter.detect_structural_changes(original, formatted)

    assert_includes changes, "html attributes"
  end
end
