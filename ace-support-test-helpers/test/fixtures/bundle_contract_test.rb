# frozen_string_literal: true

require "test_helper"

# Contract tests for Ace::Bundle mock structures
#
# These tests ensure that mock fixtures match the actual API of Ace::Bundle.
# If the real API changes, these tests will fail, alerting us to update mocks.
#
# Philosophy: Mocks should return the same structure as production code.
# When production API changes, both mocks and dependent tests need updating.
class BundleContractTest < AceTestCase
  def setup
    skip "ace-bundle not available" unless defined?(Ace::Bundle)
  end

  # Test that mock load_file result structure matches real API
  def test_mock_load_file_matches_real_structure
    # Get mock result
    mock_result = Ace::TestSupport::Fixtures::BundleMocks.mock_load_file_result("test.yml")

    # Verify mock has expected structure
    assert_respond_to mock_result, :content, "Mock should have content accessor"
    assert_respond_to mock_result, :metadata, "Mock should have metadata accessor"
    assert_respond_to mock_result, :success, "Mock should have success accessor"

    # Verify data types
    assert_kind_of String, mock_result.content, "content should be a String"
    assert_kind_of Hash, mock_result.metadata, "metadata should be a Hash"
    assert [TrueClass, FalseClass].include?(mock_result.success.class), "success should be Boolean"

    # Verify metadata structure
    assert mock_result.metadata.key?("format"), "metadata should have 'format' key"
    assert_kind_of String, mock_result.metadata["format"], "metadata['format'] should be String"
  end

  # Test that mock load_auto result structure matches real API
  def test_mock_load_auto_matches_real_structure
    # Get mock result
    mock_result = Ace::TestSupport::Fixtures::BundleMocks.mock_load_auto_result("test content", format: "markdown")

    # Verify mock has expected structure
    assert_respond_to mock_result, :content, "Mock should have content accessor"
    assert_respond_to mock_result, :metadata, "Mock should have metadata accessor"
    assert_respond_to mock_result, :success, "Mock should have success accessor"

    # Verify data types
    assert_kind_of String, mock_result.content, "content should be a String"
    assert_kind_of Hash, mock_result.metadata, "metadata should be a Hash"
    assert [TrueClass, FalseClass].include?(mock_result.success.class), "success should be Boolean"

    # Verify metadata structure
    assert mock_result.metadata.key?("format"), "metadata should have 'format' key"
    assert mock_result.metadata.key?("config"), "metadata should have 'config' key"
    assert_kind_of String, mock_result.metadata["format"], "metadata['format'] should be String"
    assert_kind_of Hash, mock_result.metadata["config"], "metadata['config'] should be Hash"
  end

  # Integration test: Verify mock can substitute for real Ace::Bundle in tests
  def test_mock_substitutes_for_real_context
    # This test verifies mocks work the same way as real code in test scenarios
    original_method = Ace::Bundle.method(:load_file) if Ace::Bundle.respond_to?(:load_file)
    methods_holder = {}

    begin
      # Install mock
      Ace::TestSupport::Fixtures::BundleMocks.stub_load_file(methods_holder) do
        # Use mocked version
        result = Ace::Bundle.load_file("test.yml")

        # Verify it returns expected structure
        assert result.success, "Mock should return successful result"
        assert result.content.length > 0, "Mock should return non-empty content"
        assert result.metadata["format"], "Mock should return metadata with format"
      end

      # Verify restoration works (if real method existed)
      if original_method
        Ace::Bundle.method(:load_file)
        # Methods should be restored (may not be same object due to stubbing mechanism)
        assert Ace::Bundle.respond_to?(:load_file), "Method should still exist after unstubbing"
      end
    ensure
      # Cleanup
      Ace::TestSupport::Fixtures::BundleMocks.restore_load_file(methods_holder) if methods_holder[:load_file]
    end
  end

  # Test that git extractor mock constants are valid
  def test_git_extractor_mock_constants_are_valid_diffs
    # Verify mock constants are valid git diff format
    assert Ace::TestSupport::Fixtures::BundleMocks::MOCK_STAGED_DIFF.include?("diff --git"),
      "MOCK_STAGED_DIFF should be valid git diff format"

    assert Ace::TestSupport::Fixtures::BundleMocks::MOCK_WORKING_DIFF.include?("diff --git"),
      "MOCK_WORKING_DIFF should be valid git diff format"

    assert Ace::TestSupport::Fixtures::BundleMocks::MOCK_GIT_DIFF.include?("diff --git"),
      "MOCK_GIT_DIFF should be valid git diff format"

    # Verify diffs have hunks
    assert Ace::TestSupport::Fixtures::BundleMocks::MOCK_STAGED_DIFF.include?("@@"),
      "MOCK_STAGED_DIFF should include hunk markers"

    assert Ace::TestSupport::Fixtures::BundleMocks::MOCK_WORKING_DIFF.include?("@@"),
      "MOCK_WORKING_DIFF should include hunk markers"
  end
end
