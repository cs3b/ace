# frozen_string_literal: true

require "test_helper"

class PrIdentifierParserTest < AceGitTestCase
  def setup
    super
    @parser = Ace::Git::Atoms::PrIdentifierParser
  end

  def test_parse_simple_number
    result = @parser.parse("123")

    assert_equal "123", result.number
    assert_nil result.repo
    assert_equal "123", result.gh_format
  end

  def test_parse_integer
    result = @parser.parse(456)

    assert_equal "456", result.number
    assert_nil result.repo
    assert_equal "456", result.gh_format
  end

  def test_parse_qualified_reference
    result = @parser.parse("owner/repo#789")

    assert_equal "789", result.number
    assert_equal "owner/repo", result.repo
    assert_equal "owner/repo#789", result.gh_format
  end

  def test_parse_github_url
    result = @parser.parse("https://github.com/owner/repo/pull/101")

    assert_equal "101", result.number
    assert_equal "owner/repo", result.repo
    assert_equal "owner/repo#101", result.gh_format
  end

  def test_parse_nil_returns_nil
    assert_nil @parser.parse(nil)
  end

  def test_parse_empty_string_returns_nil
    assert_nil @parser.parse("")
    assert_nil @parser.parse("  ")
  end

  def test_parse_invalid_format_raises_error
    assert_raises(ArgumentError) do
      @parser.parse("invalid")
    end
  end

  def test_parse_zero_raises_error
    assert_raises(ArgumentError) do
      @parser.parse("0")
    end
  end

  def test_parse_normalizes_leading_zeros
    result = @parser.parse("00123")

    assert_equal "123", result.number
    assert_equal "123", result.gh_format
  end

  def test_parse_handles_repo_with_dots_and_hyphens
    result = @parser.parse("my-org/my.repo#42")

    assert_equal "42", result.number
    assert_equal "my-org/my.repo", result.repo
    assert_equal "my-org/my.repo#42", result.gh_format
  end
end
