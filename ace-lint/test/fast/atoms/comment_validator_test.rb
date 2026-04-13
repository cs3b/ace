# frozen_string_literal: true

require "test_helper"

class Ace::Lint::Atoms::CommentValidatorTest < Minitest::Test
  def test_all_comments_present
    content = <<~MARKDOWN
      ---
      name: test
      # bundle: no-fork
      # agent: Bash
      ---

      Body content
    MARKDOWN

    missing = validate(content, ["# bundle:", "# agent:"])

    assert_empty missing
  end

  def test_missing_one_comment
    content = <<~MARKDOWN
      ---
      name: test
      # bundle: no-fork
      ---

      Body content
    MARKDOWN

    missing = validate(content, ["# bundle:", "# agent:"])

    assert_equal 1, missing.size
    assert_includes missing, "# agent:"
  end

  def test_missing_all_comments
    content = <<~MARKDOWN
      ---
      name: test
      ---

      Body content
    MARKDOWN

    missing = validate(content, ["# bundle:", "# agent:"])

    assert_equal 2, missing.size
    assert_includes missing, "# bundle:"
    assert_includes missing, "# agent:"
  end

  def test_no_frontmatter
    content = "Just plain content without frontmatter"

    missing = validate(content, ["# bundle:"])

    assert_equal 1, missing.size
    assert_includes missing, "# bundle:"
  end

  def test_empty_content
    missing = validate("", ["# bundle:"])

    assert_equal 1, missing.size
  end

  def test_nil_content
    missing = validate(nil, ["# bundle:"])

    assert_equal 1, missing.size
  end

  def test_empty_required_comments
    content = <<~MARKDOWN
      ---
      name: test
      ---
    MARKDOWN

    missing = validate(content, [])

    assert_empty missing
  end

  def test_nil_required_comments
    content = <<~MARKDOWN
      ---
      name: test
      ---
    MARKDOWN

    missing = validate(content, nil)

    assert_empty missing
  end

  def test_comment_in_body_not_counted
    # Comment must be in frontmatter, not body
    content = <<~MARKDOWN
      ---
      name: test
      ---

      # bundle: this is in the body
    MARKDOWN

    missing = validate(content, ["# bundle:"])

    # The comment is in body, not frontmatter, so it should be reported as missing
    assert_equal 1, missing.size
  end

  private

  def validate(content, required_comments)
    Ace::Lint::Atoms::CommentValidator.validate(content, required_comments: required_comments)
  end
end
