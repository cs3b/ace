# frozen_string_literal: true

require "test_helper"

module Atoms
  class PrIdentifierTest < AceGitTestCase
    def test_parses_simple_number
      result = Ace::Git::Atoms::PrIdentifier.parse("123")
      assert_equal "123", result.number
      assert_nil result.repo
    end

    def test_parses_integer_input
      result = Ace::Git::Atoms::PrIdentifier.parse(42)
      assert_equal "42", result.number
      assert_nil result.repo
    end

    def test_canonicalizes_leading_zeros
      result = Ace::Git::Atoms::PrIdentifier.parse("007")
      assert_equal "7", result.number
    end

    def test_parses_qualified_reference
      result = Ace::Git::Atoms::PrIdentifier.parse("owner/repo#456")
      assert_equal "456", result.number
      assert_equal "owner/repo", result.repo
    end

    def test_returns_nil_for_nil_and_empty_input
      assert_nil Ace::Git::Atoms::PrIdentifier.parse(nil)
      assert_nil Ace::Git::Atoms::PrIdentifier.parse("")
      assert_nil Ace::Git::Atoms::PrIdentifier.parse("   ")
    end

    def test_rejects_zero_number
      error = assert_raises(ArgumentError) { Ace::Git::Atoms::PrIdentifier.parse("0") }
      assert_match(/Invalid PR identifier/, error.message)
    end

    def test_rejects_non_numeric_bare_input
      assert_raises(ArgumentError) { Ace::Git::Atoms::PrIdentifier.parse("abc") }
    end

    def test_rejects_malformed_qualified_reference
      assert_raises(ArgumentError) { Ace::Git::Atoms::PrIdentifier.parse("owner#456") }
      assert_raises(ArgumentError) { Ace::Git::Atoms::PrIdentifier.parse("owner/repo/") }
    end

    def test_rejects_overlong_input
      assert_raises(ArgumentError) { Ace::Git::Atoms::PrIdentifier.parse("1" * 257) }
    end
  end
end
