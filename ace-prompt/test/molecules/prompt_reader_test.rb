# frozen_string_literal: true

require "test_helper"
require "ace/prompt/molecules/prompt_reader"

class PromptReaderTest < Ace::Prompt::TestCase
  def test_read_with_frontmatter
    content = "---\ncontext:\n  files: [test.rb]\n---\nTest prompt"
    path = create_prompt_file(content)

    result = Ace::Prompt::Molecules::PromptReader.read(path)

    assert_equal({"context" => {"files" => ["test.rb"]}}, result[:frontmatter])
    assert_equal "Test prompt", result[:content]
    assert_equal content, result[:full_text]
  end

  def test_read_without_frontmatter
    content = "Simple prompt"
    path = create_prompt_file(content)

    result = Ace::Prompt::Molecules::PromptReader.read(path)

    assert_equal({}, result[:frontmatter])
    assert_equal "Simple prompt", result[:content]
  end

  def test_read_raises_error_when_file_not_found
    error = assert_raises(Ace::Prompt::Molecules::PromptReader::PromptNotFoundError) do
      Ace::Prompt::Molecules::PromptReader.read("nonexistent.md")
    end

    assert_match(/not found/, error.message)
  end

  def test_exists_returns_true_when_file_exists
    path = create_prompt_file("content")

    assert Ace::Prompt::Molecules::PromptReader.exists?(path)
  end

  def test_exists_returns_false_when_file_missing
    refute Ace::Prompt::Molecules::PromptReader.exists?("nonexistent.md")
  end
end
