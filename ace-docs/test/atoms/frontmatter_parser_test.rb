# frozen_string_literal: true

require "test_helper"
require "ace/docs/atoms/frontmatter_parser"

module Ace
  module Docs
    module Atoms
      class FrontmatterParserTest < AceTestCase
        def test_parse_valid_frontmatter
          content = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Test document for parsing
            update:
              frequency: weekly
              last-updated: 2024-10-01
            ---

            # Test Document

            This is the document content.
          MARKDOWN

          result = FrontmatterParser.parse(content)

          assert result[:valid], "Should be valid"
          assert_equal "guide", result[:frontmatter]["doc-type"]
          assert_equal "Test document for parsing", result[:frontmatter]["purpose"]
          assert_equal "weekly", result[:frontmatter]["update"]["frequency"]
          assert result[:content].include?("# Test Document")
          assert_empty result[:errors]
        end

        def test_parse_minimal_valid_frontmatter
          content = <<~MARKDOWN
            ---
            doc-type: reference
            purpose: Minimal valid document
            ---

            Content here.
          MARKDOWN

          result = FrontmatterParser.parse(content)

          assert result[:valid], "Should be valid with minimal required fields"
          assert_equal "reference", result[:frontmatter]["doc-type"]
          assert_equal "Minimal valid document", result[:frontmatter]["purpose"]
        end

        def test_parse_missing_frontmatter
          content = <<~MARKDOWN
            # Document without frontmatter

            This document has no frontmatter.
          MARKDOWN

          result = FrontmatterParser.parse(content)

          refute result[:valid], "Should not be valid without frontmatter"
          assert_empty result[:frontmatter]
          assert_equal content, result[:content]
          assert_includes result[:errors], "No frontmatter found"
        end

        def test_parse_missing_closing_delimiter
          content = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Missing closing delimiter

            # Content starts here
          MARKDOWN

          result = FrontmatterParser.parse(content)

          refute result[:valid], "Should not be valid without closing delimiter"
          assert_includes result[:errors], "Missing closing '---' delimiter for frontmatter"
        end

        def test_parse_invalid_yaml_syntax
          content = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Invalid YAML
            update:
              - frequency: weekly
                last-updated: [invalid
            ---

            Content here.
          MARKDOWN

          result = FrontmatterParser.parse(content)

          refute result[:valid], "Should not be valid with invalid YAML"
          assert result[:errors].any? { |e| e.include?("YAML syntax error") }
        end

        def test_parse_missing_required_doc_type
          content = <<~MARKDOWN
            ---
            purpose: Missing doc-type
            ---

            Content here.
          MARKDOWN

          result = FrontmatterParser.parse(content)

          refute result[:valid], "Should not be valid without doc-type"
          assert_includes result[:errors], "Missing required field: doc-type"
        end

        def test_parse_missing_required_purpose
          content = <<~MARKDOWN
            ---
            doc-type: guide
            ---

            Content here.
          MARKDOWN

          result = FrontmatterParser.parse(content)

          refute result[:valid], "Should not be valid without purpose"
          assert_includes result[:errors], "Missing required field: purpose"
        end

        def test_parse_invalid_doc_type
          content = <<~MARKDOWN
            ---
            doc-type: invalid-type
            purpose: Test document
            ---

            Content here.
          MARKDOWN

          result = FrontmatterParser.parse(content)

          refute result[:valid], "Should not be valid with invalid doc-type"
          assert result[:errors].any? { |e| e.include?("Invalid doc-type: invalid-type") }
        end

        def test_parse_all_valid_doc_types
          valid_types = %w[context guide template workflow reference api]

          valid_types.each do |doc_type|
            content = <<~MARKDOWN
              ---
              doc-type: #{doc_type}
              purpose: Test #{doc_type} document
              ---

              Content for #{doc_type}.
            MARKDOWN

            result = FrontmatterParser.parse(content)
            assert result[:valid], "Should be valid for doc-type: #{doc_type}"
            assert_equal doc_type, result[:frontmatter]["doc-type"]
          end
        end

        def test_parse_invalid_update_frequency
          content = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Test document
            update:
              frequency: invalid-frequency
            ---

            Content here.
          MARKDOWN

          result = FrontmatterParser.parse(content)

          refute result[:valid], "Should not be valid with invalid frequency"
          assert result[:errors].any? { |e| e.include?("Invalid update frequency") }
        end

        def test_parse_valid_update_frequencies
          valid_frequencies = %w[daily weekly monthly on-change]

          valid_frequencies.each do |frequency|
            content = <<~MARKDOWN
              ---
              doc-type: guide
              purpose: Test document
              update:
                frequency: #{frequency}
              ---

              Content here.
            MARKDOWN

            result = FrontmatterParser.parse(content)
            assert result[:valid], "Should be valid for frequency: #{frequency}"
            assert_equal frequency, result[:frontmatter]["update"]["frequency"]
          end
        end

        def test_parse_valid_date_formats
          date_strings = ["2024-10-01", "2024-10-01T10:30:00", "2024/10/01"]

          date_strings.each do |date_str|
            content = <<~MARKDOWN
              ---
              doc-type: guide
              purpose: Test document
              update:
                last-updated: #{date_str}
              ---

              Content here.
            MARKDOWN

            result = FrontmatterParser.parse(content)
            assert result[:valid], "Should be valid for date: #{date_str}"
          end
        end

        def test_parse_invalid_date_format
          content = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Test document
            update:
              last-updated: not-a-date
            ---

            Content here.
          MARKDOWN

          result = FrontmatterParser.parse(content)

          refute result[:valid], "Should not be valid with invalid date"
          assert result[:errors].any? { |e| e.include?("Invalid date format") }
        end

        def test_parse_empty_content
          result = FrontmatterParser.parse("")

          refute result[:valid], "Should not be valid for empty content"
          assert_empty result[:frontmatter]
          assert_empty result[:content]
          assert_includes result[:errors], "Empty content"
        end

        def test_parse_nil_content
          result = FrontmatterParser.parse(nil)

          refute result[:valid], "Should not be valid for nil content"
          assert_empty result[:frontmatter]
          assert_empty result[:content]
          assert_includes result[:errors], "Empty content"
        end

        def test_extract_frontmatter
          content = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Test extraction
            ---

            Document content.
          MARKDOWN

          frontmatter = FrontmatterParser.extract_frontmatter(content)

          assert_equal "guide", frontmatter["doc-type"]
          assert_equal "Test extraction", frontmatter["purpose"]
        end

        def test_extract_frontmatter_when_missing
          content = "# No frontmatter here"

          frontmatter = FrontmatterParser.extract_frontmatter(content)

          assert_empty frontmatter
        end

        def test_extract_content
          content = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Test extraction
            ---

            # Main Content

            This is the body.
          MARKDOWN

          body = FrontmatterParser.extract_content(content)

          assert body.include?("# Main Content")
          assert body.include?("This is the body.")
          refute body.include?("doc-type")
        end

        def test_extract_content_when_no_frontmatter
          content = "# Just content"

          body = FrontmatterParser.extract_content(content)

          assert_equal content, body
        end

        def test_has_valid_frontmatter
          valid_content = <<~MARKDOWN
            ---
            doc-type: guide
            purpose: Valid document
            ---

            Content.
          MARKDOWN

          assert FrontmatterParser.has_valid_frontmatter?(valid_content)
        end

        def test_has_valid_frontmatter_returns_false_for_missing
          content = "# No frontmatter"

          refute FrontmatterParser.has_valid_frontmatter?(content)
        end

        def test_has_valid_frontmatter_returns_false_for_invalid
          invalid_content = <<~MARKDOWN
            ---
            purpose: Missing doc-type
            ---

            Content.
          MARKDOWN

          refute FrontmatterParser.has_valid_frontmatter?(invalid_content)
        end

        def test_parse_with_complex_nested_structure
          content = <<~MARKDOWN
            ---
            doc-type: workflow
            purpose: Complex nested structure test
            update:
              frequency: weekly
              last-updated: 2024-10-01
              focus:
                - implementation
                - testing
            context:
              preset: standard
              includes:
                - docs/*.md
                - lib/**/*.rb
              excludes:
                - test/**/*
            rules:
              max-lines: 500
              sections:
                - overview
                - usage
                - examples
              no-duplicate-from:
                - README.md
                - CONTRIBUTING.md
            ---

            # Complex Document

            With nested frontmatter structure.
          MARKDOWN

          result = FrontmatterParser.parse(content)

          assert result[:valid], "Should handle complex nested structures"
          assert_equal "workflow", result[:frontmatter]["doc-type"]
          assert_equal ["implementation", "testing"], result[:frontmatter]["update"]["focus"]
          assert_equal "standard", result[:frontmatter]["context"]["preset"]
          assert_equal 500, result[:frontmatter]["rules"]["max-lines"]
          assert_includes result[:frontmatter]["rules"]["sections"], "usage"
        end

        def test_parse_preserves_content_formatting
          content = <<~MARKDOWN
            ---
            doc-type: api
            purpose: Formatting preservation test
            ---

            # Header 1

            Some text with **bold** and *italic*.

            ```ruby
            def hello
              puts "world"
            end
            ```

            - List item 1
            - List item 2

            > Block quote
          MARKDOWN

          result = FrontmatterParser.parse(content)

          assert result[:valid]
          assert result[:content].include?("```ruby")
          assert result[:content].include?("**bold**")
          assert result[:content].include?("> Block quote")
        end
      end
    end
  end
end