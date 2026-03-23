# frozen_string_literal: true

require "test_helper"
require "ace/prompt_prep/molecules/bundle_loader"

class BundleLoaderTest < Minitest::Test
  def test_call_returns_empty_string_for_nil_path
    result = Ace::PromptPrep::Molecules::BundleLoader.call(nil)
    assert_equal "", result
  end

  def test_call_returns_empty_string_for_empty_path
    result = Ace::PromptPrep::Molecules::BundleLoader.call("")
    assert_equal "", result
  end

  def test_call_with_nonexistent_file
    result = Ace::PromptPrep::Molecules::BundleLoader.call("/nonexistent/path.md")
    # Should return empty string (error handled gracefully)
    assert_equal "", result
  end

  def test_call_with_path_traversal_attempts
    # Should reject paths with directory traversal attempts
    result = Ace::PromptPrep::Molecules::BundleLoader.call("../../etc/passwd")
    assert_equal "", result

    result = Ace::PromptPrep::Molecules::BundleLoader.call("..\\windows\\system32\\config")
    assert_equal "", result
  end

  def test_call_with_whitespace_path
    result = Ace::PromptPrep::Molecules::BundleLoader.call("   ")
    assert_equal "", result

    result = Ace::PromptPrep::Molecules::BundleLoader.call("\t\n")
    assert_equal "", result
  end

  def test_call_with_invalid_format_option
    # Test with invalid format that gets corrected
    result = Ace::PromptPrep::Molecules::BundleLoader.call("/tmp/test.md", format: "invalid")
    # Should still work but log warning
    assert_equal "", result  # Returns empty because file doesn't exist
  end

  def test_call_with_invalid_embed_source_option
    # Test with invalid embed_source option that gets corrected
    result = Ace::PromptPrep::Molecules::BundleLoader.call("/tmp/test.md", embed_source: "maybe")
    # Should still work but log warning
    assert_equal "", result  # Returns empty because file doesn't exist
  end

  def test_valid_prompt_path_validation
    # Test the private method indirectly
    assert Ace::PromptPrep::Molecules::BundleLoader.call("/valid/path.md").is_a?(String)
    assert Ace::PromptPrep::Molecules::BundleLoader.call("relative/path.md").is_a?(String)
  end

  # Note: Full integration with ace-bundle is tested via integration tests.
  # Unit tests focus on edge cases and error handling.
end
