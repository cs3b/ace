# frozen_string_literal: true

require "test_helper"

class ContentHasherTest < Minitest::Test
  def test_generates_hash_for_content
    result = Ace::PromptPrep::Atoms::ContentHasher.call(content: "test content")

    assert result[:hash]
    assert_equal 64, result[:hash].length # SHA256 hex = 64 chars
  end

  def test_returns_empty_hash_for_nil_content
    result = Ace::PromptPrep::Atoms::ContentHasher.call(content: nil)

    assert_equal "", result[:hash]
  end

  def test_returns_empty_hash_for_empty_content
    result = Ace::PromptPrep::Atoms::ContentHasher.call(content: "")

    assert_equal "", result[:hash]
  end

  def test_generates_consistent_hash
    content = "consistent content"
    result1 = Ace::PromptPrep::Atoms::ContentHasher.call(content: content)
    result2 = Ace::PromptPrep::Atoms::ContentHasher.call(content: content)

    assert_equal result1[:hash], result2[:hash]
  end

  def test_handles_unicode_content
    content = "日本語 Привет café 🎉"
    result = Ace::PromptPrep::Atoms::ContentHasher.call(content: content)

    assert result[:hash]
    assert_equal 64, result[:hash].length
  end

  def test_handles_very_long_content
    content = "x" * 100_000
    result = Ace::PromptPrep::Atoms::ContentHasher.call(content: content)

    assert result[:hash]
    assert_equal 64, result[:hash].length
  end
end
