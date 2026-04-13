# frozen_string_literal: true

require_relative "../../test_helper"

class TestCaseParserTest < Minitest::Test
  TestCaseParser = Ace::Test::EndToEndRunner::Atoms::TestCaseParser

  # --- normalize_identifier ---

  def test_normalize_already_normalized
    assert_equal "TC-001", TestCaseParser.normalize_identifier("TC-001")
  end

  def test_normalize_lowercase
    assert_equal "TC-001", TestCaseParser.normalize_identifier("tc-001")
  end

  def test_normalize_number_only
    assert_equal "TC-001", TestCaseParser.normalize_identifier("001")
  end

  def test_normalize_single_digit
    assert_equal "TC-001", TestCaseParser.normalize_identifier("1")
  end

  def test_normalize_tc_with_single_digit
    assert_equal "TC-001", TestCaseParser.normalize_identifier("TC-1")
  end

  def test_normalize_two_digit
    assert_equal "TC-012", TestCaseParser.normalize_identifier("12")
  end

  def test_normalize_large_number
    assert_equal "TC-1234", TestCaseParser.normalize_identifier("1234")
  end

  def test_normalize_with_alpha_suffix
    assert_equal "TC-001a", TestCaseParser.normalize_identifier("TC-001a")
  end

  def test_normalize_with_alpha_suffix_lowercase
    assert_equal "TC-001b", TestCaseParser.normalize_identifier("tc-001B")
  end

  def test_normalize_strips_whitespace
    assert_equal "TC-001", TestCaseParser.normalize_identifier("  TC-001  ")
  end

  def test_normalize_raises_on_empty
    assert_raises(ArgumentError) { TestCaseParser.normalize_identifier("") }
  end

  def test_normalize_raises_on_nil
    assert_raises(ArgumentError) { TestCaseParser.normalize_identifier(nil) }
  end

  def test_normalize_raises_on_invalid
    assert_raises(ArgumentError) { TestCaseParser.normalize_identifier("abc") }
  end

  def test_normalize_raises_on_mixed_invalid
    assert_raises(ArgumentError) { TestCaseParser.normalize_identifier("TC-abc") }
  end

  # --- normalize_identifiers ---

  def test_normalize_identifiers_batch
    result = TestCaseParser.normalize_identifiers(%w[tc-001 002 TC-3])
    assert_equal %w[TC-001 TC-002 TC-003], result
  end

  def test_normalize_identifiers_empty_array
    assert_equal [], TestCaseParser.normalize_identifiers([])
  end

  # --- parse ---

  def test_parse_comma_separated
    result = TestCaseParser.parse("tc-001,002,TC-3")
    assert_equal %w[TC-001 TC-002 TC-003], result
  end

  def test_parse_single_id
    result = TestCaseParser.parse("TC-001")
    assert_equal %w[TC-001], result
  end

  def test_parse_with_spaces
    result = TestCaseParser.parse("tc-001, 002, TC-3")
    assert_equal %w[TC-001 TC-002 TC-003], result
  end

  def test_parse_raises_on_empty_string
    assert_raises(ArgumentError) { TestCaseParser.parse("") }
  end

  def test_parse_raises_on_nil
    assert_raises(ArgumentError) { TestCaseParser.parse(nil) }
  end

  def test_parse_raises_on_whitespace_only
    assert_raises(ArgumentError) { TestCaseParser.parse("   ") }
  end

  # --- extract_from_content ---

  def test_extract_from_content_finds_tc_headers
    content = <<~MD
      # Test Scenario

      ## Test Cases

      ### TC-001: Basic check
      Verify basic functionality.

      ### TC-002: Advanced check
      Verify advanced functionality.

      ### TC-003: Edge case
      Verify edge case handling.
    MD

    result = TestCaseParser.extract_from_content(content)
    assert_equal %w[TC-001 TC-002 TC-003], result
  end

  def test_extract_from_content_handles_lowercase
    content = <<~MD
      ### tc-001: lowercase header
      Some content
    MD

    result = TestCaseParser.extract_from_content(content)
    assert_equal %w[TC-001], result
  end

  def test_extract_from_content_empty_for_no_headers
    content = "# Just a title\n\nNo test cases here."
    result = TestCaseParser.extract_from_content(content)
    assert_equal [], result
  end

  def test_extract_from_content_with_alpha_suffix
    content = <<~MD
      ### TC-001a: First variant
      Content

      ### TC-001b: Second variant
      Content
    MD

    result = TestCaseParser.extract_from_content(content)
    assert_equal %w[TC-001A TC-001B], result
  end

  # --- validate_against_available ---

  def test_validate_against_available_all_present
    result = TestCaseParser.validate_against_available(
      %w[TC-001 TC-002],
      %w[TC-001 TC-002 TC-003]
    )
    assert_equal %w[TC-001 TC-002], result
  end

  def test_validate_against_available_raises_on_missing
    error = assert_raises(ArgumentError) do
      TestCaseParser.validate_against_available(
        %w[TC-001 TC-999],
        %w[TC-001 TC-002 TC-003]
      )
    end
    assert_includes error.message, "TC-999"
    assert_includes error.message, "not found"
  end

  def test_validate_against_available_case_insensitive
    result = TestCaseParser.validate_against_available(
      %w[TC-001],
      %w[tc-001 TC-002]
    )
    assert_equal %w[TC-001], result
  end
end
