# frozen_string_literal: true

require "test_helper"

module Forgejo
  class PrIdentifierTest < AceGitForgejoTestCase
    def setup
      super
      @parser = Ace::Git::Forgejo::PrIdentifier
    end

    def test_parse_simple_number
      result = @parser.parse("123")
      assert_equal "123", result.number
      assert_nil result.repo
      assert_equal "123", result.forgejo_format
    end

    def test_parse_qualified_reference_uses_numeric_cli_format
      result = @parser.parse("owner/repo#789")
      assert_equal "789", result.number
      assert_equal "owner/repo", result.repo
      assert_equal "789", result.forgejo_format
    end

    def test_parse_forgejo_url
      result = @parser.parse("https://forgejo.example.com/owner/repo/pulls/101")
      assert_equal "101", result.number
      assert_equal "owner/repo", result.repo
      assert_equal "101", result.forgejo_format
    end

    def test_parse_nil_returns_nil
      assert_nil @parser.parse(nil)
      assert_nil @parser.parse("")
    end

    def test_parse_invalid_format_raises_error
      assert_raises(ArgumentError) { @parser.parse("invalid") }
    end

    def test_parse_zero_raises_error
      assert_raises(ArgumentError) { @parser.parse("0") }
    end

    def test_parse_normalizes_leading_zeros
      result = @parser.parse("00123")
      assert_equal "123", result.number
    end
  end
end
