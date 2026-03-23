# frozen_string_literal: true

require_relative "../test_helper"

class BaseClientHelpersTest < AceTestCase
  def setup
    @anthropic_client = Ace::LLM::Organisms::AnthropicClient.allocate
    @openai_client = Ace::LLM::Organisms::OpenAIClient.allocate
    @google_client = Ace::LLM::Organisms::GoogleClient.allocate
  end

  # Test concatenate_system_prompts helper
  def test_concatenate_both_prompts
    result = @anthropic_client.send(:concatenate_system_prompts, "Base prompt", "Additional context")
    assert_equal "Base prompt\n\n---\n\nAdditional context", result
  end

  def test_concatenate_with_nil_base
    result = @anthropic_client.send(:concatenate_system_prompts, nil, "Only append")
    assert_equal "Only append", result
  end

  def test_concatenate_with_nil_append
    result = @anthropic_client.send(:concatenate_system_prompts, "Only base", nil)
    assert_equal "Only base", result
  end

  def test_concatenate_with_empty_base
    result = @anthropic_client.send(:concatenate_system_prompts, "", "Only append")
    assert_equal "Only append", result
  end

  def test_concatenate_with_empty_append
    result = @anthropic_client.send(:concatenate_system_prompts, "Only base", "")
    assert_equal "Only base", result
  end

  def test_concatenate_with_both_nil
    result = @anthropic_client.send(:concatenate_system_prompts, nil, nil)
    assert_nil result
  end

  def test_concatenate_with_both_empty
    result = @anthropic_client.send(:concatenate_system_prompts, "", "")
    assert_nil result
  end

  # Test deep_copy_messages helper
  def test_deep_copy_messages
    original = [
      {role: "system", content: "System prompt"},
      {role: "user", content: "User message"}
    ]

    copied = @anthropic_client.send(:deep_copy_messages, original)

    # Verify it's a copy, not the same object
    refute_same original, copied
    refute_same original[0], copied[0]

    # Verify content is identical
    assert_equal original[0][:role], copied[0][:role]
    assert_equal original[0][:content], copied[0][:content]

    # Verify mutation doesn't affect original
    copied[0][:content] = "Modified"
    refute_equal original[0][:content], copied[0][:content]
  end

  # Test process_messages_with_system_append
  def test_process_messages_with_system_append_no_existing_system
    messages = [{role: "user", content: "Hello"}]
    result = @anthropic_client.send(:process_messages_with_system_append, messages, "System context")

    assert_equal 2, result.length
    assert_equal "system", result[0][:role]
    assert_equal "System context", result[0][:content]
    assert_equal "user", result[1][:role]
  end

  def test_process_messages_with_system_append_with_existing_system
    messages = [
      {role: "system", content: "Base system"},
      {role: "user", content: "Hello"}
    ]
    result = @anthropic_client.send(:process_messages_with_system_append, messages, "Additional")

    assert_equal 2, result.length
    assert_equal "system", result[0][:role]
    assert_equal "Base system\n\n---\n\nAdditional", result[0][:content]
  end

  def test_process_messages_with_system_append_nil_append
    messages = [{role: "user", content: "Hello"}]
    result = @anthropic_client.send(:process_messages_with_system_append, messages, nil)

    # Should return deep copy with no system message added
    assert_equal 1, result.length
    assert_equal "user", result[0][:role]
    refute_same messages[0], result[0]
  end

  def test_process_messages_with_system_append_empty_append
    messages = [{role: "user", content: "Hello"}]
    result = @anthropic_client.send(:process_messages_with_system_append, messages, "")

    # Should return deep copy with no system message added
    assert_equal 1, result.length
    assert_equal "user", result[0][:role]
  end

  # Test that original messages aren't mutated
  def test_original_messages_not_mutated
    original = [
      {role: "system", content: "Original system"},
      {role: "user", content: "User message"}
    ]
    original_system_content = original[0][:content]

    @openai_client.send(:process_messages_with_system_append, original, "Appended")

    # Verify original wasn't modified
    assert_equal original_system_content, original[0][:content]
    assert_equal 2, original.length
  end
end
