# frozen_string_literal: true

require "test_helper"
require "ace/context/atoms/pr_identifier_parser"

module Ace
  module Context
    module Atoms
      class PrIdentifierParserTest < Minitest::Test
        def test_parse_simple_number
          result = PrIdentifierParser.parse("123")

          assert_equal "123", result.number
          assert_nil result.repo
          assert_equal "123", result.gh_format
        end

        def test_parse_simple_number_as_integer
          result = PrIdentifierParser.parse(456)

          assert_equal "456", result.number
          assert_nil result.repo
          assert_equal "456", result.gh_format
        end

        def test_parse_qualified_reference
          result = PrIdentifierParser.parse("owner/repo#789")

          assert_equal "789", result.number
          assert_equal "owner/repo", result.repo
          assert_equal "owner/repo#789", result.gh_format
        end

        def test_parse_qualified_reference_with_dashes
          result = PrIdentifierParser.parse("my-org/my-repo#42")

          assert_equal "42", result.number
          assert_equal "my-org/my-repo", result.repo
          assert_equal "my-org/my-repo#42", result.gh_format
        end

        def test_parse_qualified_reference_with_dots
          result = PrIdentifierParser.parse("org/repo.name#99")

          assert_equal "99", result.number
          assert_equal "org/repo.name", result.repo
          assert_equal "org/repo.name#99", result.gh_format
        end

        def test_parse_github_url_https
          result = PrIdentifierParser.parse("https://github.com/rails/rails/pull/12345")

          assert_equal "12345", result.number
          assert_equal "rails/rails", result.repo
          assert_equal "rails/rails#12345", result.gh_format
        end

        def test_parse_github_url_http
          result = PrIdentifierParser.parse("http://github.com/user/project/pull/999")

          assert_equal "999", result.number
          assert_equal "user/project", result.repo
          assert_equal "user/project#999", result.gh_format
        end

        def test_parse_github_url_with_dashes
          result = PrIdentifierParser.parse("https://github.com/my-org/my-project/pull/1")

          assert_equal "1", result.number
          assert_equal "my-org/my-project", result.repo
          assert_equal "my-org/my-project#1", result.gh_format
        end

        def test_parse_returns_nil_for_nil_input
          result = PrIdentifierParser.parse(nil)

          assert_nil result
        end

        def test_parse_returns_nil_for_empty_string
          result = PrIdentifierParser.parse("")

          assert_nil result
        end

        def test_parse_returns_nil_for_whitespace_only
          result = PrIdentifierParser.parse("   ")

          assert_nil result
        end

        def test_parse_strips_whitespace_from_number
          result = PrIdentifierParser.parse("  123  ")

          assert_equal "123", result.number
        end

        def test_parse_strips_whitespace_from_qualified_ref
          result = PrIdentifierParser.parse("  owner/repo#456  ")

          assert_equal "456", result.number
          assert_equal "owner/repo", result.repo
        end

        def test_parse_raises_for_invalid_format
          error = assert_raises(ArgumentError) do
            PrIdentifierParser.parse("not-a-pr-identifier")
          end

          assert_match(/Invalid PR identifier format/, error.message)
          assert_match(/not-a-pr-identifier/, error.message)
        end

        def test_parse_raises_for_negative_number
          error = assert_raises(ArgumentError) do
            PrIdentifierParser.parse("-123")
          end

          assert_match(/Invalid PR identifier format/, error.message)
        end

        def test_parse_raises_for_zero
          error = assert_raises(ArgumentError) do
            PrIdentifierParser.parse("0")
          end

          assert_match(/Invalid PR identifier format/, error.message)
        end

        def test_parse_raises_for_malformed_qualified_ref_missing_hash
          error = assert_raises(ArgumentError) do
            PrIdentifierParser.parse("owner/repo123")
          end

          assert_match(/Invalid PR identifier format/, error.message)
        end

        def test_parse_raises_for_malformed_qualified_ref_missing_number
          error = assert_raises(ArgumentError) do
            PrIdentifierParser.parse("owner/repo#")
          end

          assert_match(/Invalid PR identifier format/, error.message)
        end

        def test_parse_raises_for_malformed_url_missing_pull
          error = assert_raises(ArgumentError) do
            PrIdentifierParser.parse("https://github.com/owner/repo/issues/123")
          end

          assert_match(/Invalid PR identifier format/, error.message)
        end

        def test_parse_raises_for_non_github_url
          error = assert_raises(ArgumentError) do
            PrIdentifierParser.parse("https://gitlab.com/owner/repo/merge_requests/123")
          end

          assert_match(/Invalid PR identifier format/, error.message)
        end

        def test_parse_normalizes_leading_zeros_in_number
          # Leading zeros are stripped to produce canonical form
          # "00123" becomes "123" since gh CLI treats them equivalently
          result = PrIdentifierParser.parse("00123")

          assert_equal "123", result.number
          assert_equal "123", result.gh_format
        end

        def test_parse_result_is_data_object
          result = PrIdentifierParser.parse("123")

          assert_kind_of Data, result
          assert_respond_to result, :number
          assert_respond_to result, :repo
          assert_respond_to result, :gh_format
        end
      end
    end
  end
end
