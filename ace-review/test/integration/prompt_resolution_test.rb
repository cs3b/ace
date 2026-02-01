# frozen_string_literal: true

require "test_helper"

# Integration tests for ace-nav prompt resolution
#
# These tests verify real subprocess behavior with ace-nav.
# Skipped by default unless TEST_INTEGRATION is set.
class PromptResolutionTest < AceReviewTest
  def test_resolve_prompt_path_finds_synthesis_prompt
    skip "Set TEST_INTEGRATION to run ace-nav subprocess test" unless ENV["TEST_INTEGRATION"]

    # Create a fresh synthesizer without stub for actual resolution test
    synthesizer = Ace::Review::Molecules::ReportSynthesizer.new
    path = synthesizer.send(:resolve_prompt_path, "synthesis-review-reports.system.md")

    # Path should be non-empty and end with the expected filename
    refute_empty path, "Should resolve to a path"
    assert_match(/synthesis-review-reports\.system\.md$/, path)

    # If file exists, verify content (may not exist in test temp directory)
    if File.exist?(path)
      content = File.read(path)
      assert_includes content, "Multi-Model Review Synthesis"
      assert_includes content, "Consensus Findings"
    end
  end
end
