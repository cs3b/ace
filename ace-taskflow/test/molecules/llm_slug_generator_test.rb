# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/llm_slug_generator"

class LlmSlugGeneratorTest < AceTaskflowTestCase
  def setup
    @generator = Ace::Taskflow::Molecules::LlmSlugGenerator.new(debug: false)
  end

  # Task slug generation tests
  def test_generate_task_slugs_with_llm_success
    mock_response = mock_slug_response(
      folder_slug: "taskflow-enhance",
      file_slug: "idea-management-system"
    )

    mock_llm_query(response_text: mock_response) do
      result = @generator.generate_task_slugs("Add idea management system to taskflow")

      assert_equal true, result[:success]
      assert_equal "taskflow-enhance", result[:folder_slug]
      assert_equal "idea-management-system", result[:file_slug]
      assert_equal :llm, result[:source]
    end
  end

  def test_generate_task_slugs_with_llm_failure_uses_fallback
    mock_llm_failure do
      result = @generator.generate_task_slugs("Add feature to ace-taskflow")

      assert_equal true, result[:success]
      assert_equal :fallback, result[:source]
      assert !result[:folder_slug].nil? && !result[:folder_slug].empty?
      assert !result[:file_slug].nil? && !result[:file_slug].empty?
    end
  end

  def test_generate_task_slugs_with_invalid_json_uses_fallback
    mock_llm_query(response_text: "not valid json") do
      result = @generator.generate_task_slugs("Add feature")

      assert_equal true, result[:success]
      assert_equal :fallback, result[:source]
      assert !result[:folder_slug].nil? && !result[:folder_slug].empty?
      assert !result[:file_slug].nil? && !result[:file_slug].empty?
    end
  end

  def test_generate_task_slugs_with_missing_keys_uses_fallback
    mock_response = { invalid: "structure" }.to_json

    mock_llm_query(response_text: mock_response) do
      result = @generator.generate_task_slugs("Add feature")

      assert_equal true, result[:success]
      assert_equal :fallback, result[:source]
    end
  end

  # Idea slug generation tests
  def test_generate_idea_slugs_with_llm_success
    mock_response = mock_slug_response(
      folder_slug: "llm-mock",
      file_slug: "test-strategy-implementation"
    )

    mock_llm_query(response_text: mock_response) do
      result = @generator.generate_idea_slugs("Implement LLM mocking strategy for tests")

      assert_equal true, result[:success]
      assert_equal "llm-mock", result[:folder_slug]
      assert_equal "test-strategy-implementation", result[:file_slug]
      assert_equal :llm, result[:source]
    end
  end

  def test_generate_idea_slugs_with_llm_failure_uses_fallback
    mock_llm_failure do
      result = @generator.generate_idea_slugs("Some idea content")

      assert_equal true, result[:success]
      assert_equal :fallback, result[:source]
      assert !result[:folder_slug].nil? && !result[:folder_slug].empty?
      assert !result[:file_slug].nil? && !result[:file_slug].empty?
    end
  end

  def test_generate_idea_slugs_with_metadata_context
    mock_response = mock_slug_response(
      folder_slug: "taskflow-feature",
      file_slug: "new-capability"
    )

    metadata = { title: "New capability", location: "current" }

    mock_llm_query(response_text: mock_response) do
      result = @generator.generate_idea_slugs("Add new capability", metadata)

      assert_equal true, result[:success]
      assert_equal "taskflow-feature", result[:folder_slug]
      assert_equal "new-capability", result[:file_slug]
    end
  end

  # Edge cases
  def test_generate_with_truncated_json_response
    mock_llm_query(response_text: '{"folder_slug": "test"') do
      result = @generator.generate_task_slugs("Test")

      assert_equal true, result[:success]
      assert_equal :fallback, result[:source]
    end
  end

  def test_generate_with_empty_response
    mock_llm_query(response_text: "") do
      result = @generator.generate_task_slugs("Test")

      assert_equal true, result[:success]
      assert_equal :fallback, result[:source]
    end
  end
end
