# frozen_string_literal: true

require "test_helper"
require "ace/docs/organisms/validator"
require "ace/docs/organisms/document_registry"
require "ace/docs/models/document"

module Ace
  module Docs
    module Organisms
      class ValidatorTest < AceTestCase
        def setup
          # Registry is never used by Validator, pass nil to avoid expensive DocumentRegistry.new
          @validator = Validator.new(nil)
        end

        def test_validate_document_with_valid_document
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test document"
            },
            content: "# Test Document\n\nThis is content."
          )

          result = @validator.validate_document(document)

          assert result[:valid]
          assert_empty result[:errors]
          assert_empty result[:warnings]
        end

        def test_validate_document_missing_frontmatter
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide"
              # Missing purpose
            },
            content: "# Test Document"
          )

          result = @validator.validate_document(document)

          refute result[:valid]
          assert_includes result[:errors], "Missing required frontmatter fields"
        end

        def test_validate_max_lines_rule
          content = (["Line"] * 200).join("\n")

          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test document",
              "rules" => {
                "max-lines" => 100
              }
            },
            content: content
          )

          result = @validator.validate_document(document)

          refute result[:valid]
          assert result[:errors].any? { |e| e.include?("Exceeds max lines") }
          assert result[:errors].any? { |e| e.include?("200/100") }
        end

        def test_validate_max_lines_rule_within_limit
          content = (["Line"] * 50).join("\n")

          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test document",
              "rules" => {
                "max-lines" => 100
              }
            },
            content: content
          )

          result = @validator.validate_document(document)

          assert result[:valid]
          assert_empty result[:errors]
        end

        def test_validate_required_sections
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test document",
              "rules" => {
                "sections" => ["Overview", "Usage", "Examples"]
              }
            },
            content: <<~MARKDOWN
              # Test Document

              ## Overview
              This is the overview.

              ## Usage
              This is how to use it.

              Missing the Examples section.
            MARKDOWN
          )

          result = @validator.validate_document(document)

          refute result[:valid]
          assert result[:errors].any? { |e| e.include?("Missing required sections") }
          assert result[:errors].any? { |e| e.include?("Examples") }
        end

        def test_validate_all_required_sections_present
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test document",
              "rules" => {
                "sections" => ["Overview", "Usage", "Examples"]
              }
            },
            content: <<~MARKDOWN
              # Test Document

              ## Overview
              This is the overview.

              ## Usage
              This is how to use it.

              ## Examples
              Here are some examples.
            MARKDOWN
          )

          result = @validator.validate_document(document)

          assert result[:valid]
          assert_empty result[:errors]
        end

        def test_validate_sections_case_insensitive
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test document",
              "rules" => {
                "sections" => ["Overview", "USAGE", "examples"]
              }
            },
            content: <<~MARKDOWN
              # Test Document

              ## OVERVIEW
              This is the overview.

              ## usage
              This is how to use it.

              ## Examples
              Here are some examples.
            MARKDOWN
          )

          result = @validator.validate_document(document)

          assert result[:valid]
          assert_empty result[:errors]
        end

        def test_validate_with_both_h1_and_h2_sections
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test document",
              "rules" => {
                "sections" => ["Overview", "Details"]
              }
            },
            content: <<~MARKDOWN
              # Overview
              This is the main overview.

              ## Details
              These are the details.
            MARKDOWN
          )

          result = @validator.validate_document(document)

          assert result[:valid]
          assert_empty result[:errors]
        end

        def test_validate_syntax_only
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test document"
            },
            content: "# Test"
          )

          result = @validator.validate_document(document, syntax: true, semantic: false)

          assert result[:valid]
          # Syntax validation is TODO, so should return empty results for now
          assert_empty result[:errors]
          assert_empty result[:warnings]
        end

        def test_validate_semantic_only
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test document"
            },
            content: "# Test"
          )

          # Mock LLM call to return VALID response
          @validator.stub :call_llm_for_validation, {text: "VALID\n"} do
            result = @validator.validate_document(document, syntax: false, semantic: true)

            assert result[:valid]
            assert_empty result[:errors]
            assert_empty result[:warnings]
          end
        end

        def test_validate_neither_syntax_nor_semantic
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test document"
            },
            content: "# Test"
          )

          result = @validator.validate_document(document, syntax: false, semantic: false)

          assert result[:valid]
          assert_empty result[:errors]
          assert_empty result[:warnings]
        end

        def test_validate_document_with_no_rules
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test document"
              # No rules defined
            },
            content: "# Very long document\n" + ("Line\n" * 1000)
          )

          result = @validator.validate_document(document)

          # Should be valid since no rules are defined
          assert result[:valid]
          assert_empty result[:errors]
        end

        def test_validate_multiple_errors
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              # Missing purpose
              "rules" => {
                "max-lines" => 5,
                "sections" => ["Overview", "Usage"]
              }
            },
            content: "# Document\n" + ("Line\n" * 10)
          )

          result = @validator.validate_document(document)

          refute result[:valid]
          assert result[:errors].size >= 3  # Missing frontmatter, max lines, missing sections
          assert result[:errors].any? { |e| e.include?("Missing required frontmatter") }
          assert result[:errors].any? { |e| e.include?("Exceeds max lines") }
          assert result[:errors].any? { |e| e.include?("Missing required sections") }
        end

        def test_validate_semantic_detects_issues
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test document"
            },
            content: "# Test"
          )

          # Mock LLM to return INVALID with issues
          invalid_response = {
            text: "INVALID\n- Content doesn't match purpose\n- Missing examples"
          }

          @validator.stub :call_llm_for_validation, invalid_response do
            result = @validator.validate_document(document, syntax: false, semantic: true)

            refute result[:valid]
            assert_includes result[:errors], "Content doesn't match purpose"
            assert_includes result[:errors], "Missing examples"
          end
        end

        def test_validate_semantic_handles_llm_error
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test document"
            },
            content: "# Test"
          )

          # Mock LLM to raise error (generic StandardError since Ace::LLM might not be loaded)
          @validator.stub :call_llm_for_validation, ->(_) { raise StandardError, "not found" } do
            result = @validator.validate_document(document, syntax: false, semantic: true)

            refute result[:valid]
            assert result[:errors].any? { |e| e.include?("Semantic validation unavailable") }
          end
        end

        def test_validate_semantic_handles_generic_error
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test document"
            },
            content: "# Test"
          )

          # Mock LLM to raise generic error
          @validator.stub :call_llm_for_validation, ->(_) { raise StandardError, "Network timeout" } do
            result = @validator.validate_document(document, syntax: false, semantic: true)

            refute result[:valid]
            assert result[:errors].any? { |e| e.include?("Semantic validation error") }
            assert result[:errors].any? { |e| e.include?("Network timeout") }
          end
        end

        def test_validate_semantic_invalid_without_issues
          document = Models::Document.new(
            path: "test.md",
            frontmatter: {
              "doc-type" => "guide",
              "purpose" => "Test document"
            },
            content: "# Test"
          )

          # Mock LLM to return INVALID but no bullet points
          invalid_response = {
            text: "INVALID\nSome other text without bullets"
          }

          @validator.stub :call_llm_for_validation, invalid_response do
            result = @validator.validate_document(document, syntax: false, semantic: true)

            refute result[:valid]
            # Should have generic error when INVALID but no issues extracted
            assert result[:errors].any? { |e| e.include?("Content validation failed - semantic issues detected") }
          end
        end
      end
    end
  end
end
