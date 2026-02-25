# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/idea_enhancer"

class IdeaEnhancerTest < AceTaskflowTestCase
  def setup
    @enhancer = Ace::Taskflow::Molecules::IdeaEnhancer.new(debug: false, config: {})
  end

  def test_enhance_with_llm_success
    enhanced_desc = <<~DESC
      ## What I Hope to Accomplish
      Keep test execution deterministic and affordable.

      ## What "Complete" Looks Like
      Test suite runs without real LLM API calls.

      ## Success Criteria
      - No tests call external LLM APIs
      - Mock responses are used consistently
    DESC

    mock_response = mock_enhancement_response(
      title: "Implement LLM Mocking Strategy",
      filename: "feat-test-llm-mock",
      enhanced_description: enhanced_desc
    )

    mock_llm_query(response_text: mock_response) do
      result = @enhancer.enhance("Add LLM mocking to tests")

      assert_equal true, result[:success]
      assert result[:content].include?("---")
      assert result[:content].include?("title: Implement LLM Mocking Strategy")
      assert result[:content].include?("# Implement LLM Mocking Strategy")
      assert result[:content].include?("## What I Hope to Accomplish")
      assert_equal "feat-test-llm-mock", result[:filename]
      assert_equal "Implement LLM Mocking Strategy", result[:title]
    end
  end

  def test_enhance_with_llm_failure_uses_stub
    mock_llm_failure do
      result = @enhancer.enhance("Some idea content")

      assert_equal true, result[:success]
      assert result[:content].include?("Some idea content")
      assert result[:content].include?("## What I Hope to Accomplish")
      assert result[:content].include?("## What \"Complete\" Looks Like")
      assert result[:content].include?("## Success Criteria")
    end
  end

  def test_enhance_with_invalid_json_uses_stub
    mock_llm_query(response_text: "not json") do
      result = @enhancer.enhance("Test idea")

      assert_equal true, result[:success]
      assert result[:content].include?("Test idea")
      # Should use stub fallback
      assert result[:content].include?("What I Hope to Accomplish")
    end
  end

  def test_enhance_with_truncated_json_uses_stub
    mock_llm_query(response_text: '{"title": "Test"') do
      result = @enhancer.enhance("Test idea")

      assert_equal true, result[:success]
      # Should use stub fallback
      assert result[:content].include?("Test idea")
    end
  end

  def test_enhance_with_missing_keys_uses_stub
    mock_response = { invalid: "structure" }.to_json

    mock_llm_query(response_text: mock_response) do
      result = @enhancer.enhance("Test idea")

      assert_equal true, result[:success]
      # Should handle missing keys gracefully
      assert !result[:content].nil? && !result[:content].empty?
    end
  end

  def test_enhance_with_markdown_code_blocks_strips_them
    enhanced_desc = "## What I Hope to Accomplish\nImprove reliability"
    mock_response = "```json\n#{mock_enhancement_response(
      title: "Test",
      filename: "test",
      enhanced_description: enhanced_desc
    )}\n```"

    mock_llm_query(response_text: mock_response) do
      result = @enhancer.enhance("Test")

      assert_equal true, result[:success]
      assert_equal "test", result[:filename]
    end
  end

  def test_enhance_with_incomplete_markdown_blocks_strips_them
    # Simulates truncated response with opening ``` but no closing
    enhanced_desc = "## What I Hope to Accomplish\nImprove reliability"
    mock_response = "```json\n#{mock_enhancement_response(
      title: "Test",
      filename: "test",
      enhanced_description: enhanced_desc
    )}"

    mock_llm_query(response_text: mock_response) do
      result = @enhancer.enhance("Test")

      assert_equal true, result[:success]
      assert_equal "test", result[:filename]
    end
  end

  def test_enhance_with_context_includes_metadata
    context = {
      location: "current",
      llm_model: "gflash"
    }

    enhanced_desc = "## What I Hope to Accomplish\nImprove reliability"
    mock_response = mock_enhancement_response(
      title: "Test",
      filename: "test",
      enhanced_description: enhanced_desc
    )

    mock_llm_query(response_text: mock_response, model: "gflash") do
      result = @enhancer.enhance("Test content", context)

      assert_equal true, result[:success]
      assert result[:content].include?("location: current")
      assert result[:content].include?("llm_model: gflash")
    end
  end

  def test_enhance_includes_original_idea_section
    enhanced_desc = "## What I Hope to Accomplish\nImprove reliability"
    mock_response = mock_enhancement_response(
      title: "Test",
      filename: "test",
      enhanced_description: enhanced_desc
    )

    original_content = "My original idea text"

    mock_llm_query(response_text: mock_response) do
      result = @enhancer.enhance(original_content)

      assert_equal true, result[:success]
      assert result[:content].include?("## Original Idea")
      assert result[:content].include?(original_content)
    end
  end
end
