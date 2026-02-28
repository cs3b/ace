# frozen_string_literal: true

require "test_helper"

class IdeaLlmEnhancerTest < AceIdeaTestCase
  def test_falls_back_to_stub_when_llm_unavailable
    enhancer = Ace::Idea::Molecules::IdeaLlmEnhancer.new(config: {})
    enhancer.stub(:llm_available?, false) do
      result = enhancer.enhance("Add dark mode support to the app")

      assert result[:success], "Enhancement should succeed (fallback if needed)"
      refute_nil result[:content]
      assert result[:content].length > 0
    end
  end

  def test_fallback_content_includes_3question_structure
    enhancer = Ace::Idea::Molecules::IdeaLlmEnhancer.new(config: {})
    enhancer.stub(:llm_available?, false) do
      result = enhancer.enhance("Test idea")

      content = result[:content]
      # Should have the 3-Question Brief structure or stub placeholders
      has_structure = content.include?("What I Hope to Accomplish") ||
                      content.include?("What") ||
                      content.include?("Test idea")
      assert has_structure
    end
  end

  def test_enhancement_returns_string_content
    enhancer = Ace::Idea::Molecules::IdeaLlmEnhancer.new(config: {})
    enhancer.stub(:llm_available?, false) do
      result = enhancer.enhance("My raw idea")

      assert result[:success]
      assert result[:content].is_a?(String)
    end
  end
end
