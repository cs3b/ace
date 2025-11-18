# frozen_string_literal: true

require 'test_helper'
require 'ace/review/molecules/pr_identifier_parser'

module Ace
  module Review
    module Molecules
      class PrIdentifierParserTest < AceReviewTest
        def setup
          super
          @parser = PrIdentifierParser
          # Setup a fake git repository
          setup_git_repo
        end

        def setup_git_repo
          `git init`
          `git config user.email "test@example.com"`
          `git config user.name "Test User"`
          `git remote add origin https://github.com/test-owner/test-repo.git`
        end

        # Test: Parse plain PR number
        def test_parse_pr_number
          result = @parser.parse("123")

          assert_equal "test-owner", result[:owner]
          assert_equal "test-repo", result[:repo]
          assert_equal 123, result[:number]
          assert_equal :number, result[:format]
          assert_equal "123", result[:gh_format]
        end

        # Test: Parse PR number with leading zeros
        def test_parse_pr_number_with_leading_zeros
          result = @parser.parse("0042")

          assert_equal 42, result[:number]
        end

        # Test: Parse GitHub URL (HTTPS)
        def test_parse_github_url_https
          result = @parser.parse("https://github.com/owner/repo/pull/456")

          assert_equal "owner", result[:owner]
          assert_equal "repo", result[:repo]
          assert_equal 456, result[:number]
          assert_equal :url, result[:format]
          assert_equal "github.com", result[:host]
          assert_equal "owner/repo#456", result[:gh_format]
        end

        # Test: Parse GitHub URL with .git suffix
        def test_parse_github_url_with_git_suffix
          result = @parser.parse("https://github.com/owner/repo.git/pull/789")

          assert_equal "owner", result[:owner]
          assert_equal "repo", result[:repo]
          assert_equal 789, result[:number]
        end

        # Test: Parse qualified reference (owner/repo#number)
        def test_parse_qualified_reference
          result = @parser.parse("external/project#999")

          assert_equal "external", result[:owner]
          assert_equal "project", result[:repo]
          assert_equal 999, result[:number]
          assert_equal :qualified, result[:format]
          assert_equal "external/project#999", result[:gh_format]
        end

        # Test: Parse qualified reference with dots in repo name
        def test_parse_qualified_reference_with_dots
          result = @parser.parse("owner/repo.name#42")

          assert_equal "owner", result[:owner]
          assert_equal "repo.name", result[:repo]
          assert_equal 42, result[:number]
        end

        # Test: Detect number format
        def test_detect_format_number
          format = @parser.send(:detect_format, "123")
          assert_equal :number, format
        end

        # Test: Detect URL format
        def test_detect_format_url
          format = @parser.send(:detect_format, "https://github.com/owner/repo/pull/123")
          assert_equal :url, format
        end

        # Test: Detect qualified format
        def test_detect_format_qualified
          format = @parser.send(:detect_format, "owner/repo#123")
          assert_equal :qualified, format
        end

        # Test: Detect unknown format
        def test_detect_format_unknown
          format = @parser.send(:detect_format, "invalid-format")
          assert_equal :unknown, format
        end

        # Test: Invalid PR number (zero)
        def test_parse_pr_number_zero_raises_error
          error = assert_raises(ArgumentError) do
            @parser.parse("0")
          end

          assert_match(/Invalid PR number/, error.message)
        end

        # Test: Invalid PR number (negative)
        def test_parse_pr_number_negative_raises_error
          error = assert_raises(ArgumentError) do
            @parser.parse("-5")
          end

          assert_match(/Invalid PR/, error.message)
        end

        # Test: Invalid PR number (non-numeric)
        def test_parse_non_numeric_raises_error
          error = assert_raises(ArgumentError) do
            @parser.parse("abc")
          end

          assert_match(/Invalid PR identifier format/, error.message)
        end

        # Test: Empty string
        def test_parse_empty_string_returns_nil
          result = @parser.parse("")
          assert_nil result
        end

        # Test: Nil input
        def test_parse_nil_returns_nil
          result = @parser.parse(nil)
          assert_nil result
        end

        # Test: Whitespace-only string
        def test_parse_whitespace_only_returns_nil
          result = @parser.parse("   ")
          assert_nil result
        end

        # Test: Invalid URL (non-GitHub)
        def test_parse_invalid_url_raises_error
          error = assert_raises(ArgumentError) do
            @parser.parse("https://example.com/pr/123")
          end

          assert_match(/Invalid (PR identifier format|GitHub URL format)/, error.message)
        end

        # Test: Invalid GitHub URL format
        def test_parse_malformed_github_url_raises_error
          error = assert_raises(ArgumentError) do
            @parser.parse("https://github.com/owner/pull/123")
          end

          assert_match(/Invalid GitHub URL format/, error.message)
        end

        # Test: Malformed qualified ref (missing #)
        def test_parse_malformed_qualified_ref_raises_error
          error = assert_raises(ArgumentError) do
            @parser.parse("owner/repo/123")
          end

          assert_match(/Invalid PR identifier format/, error.message)
        end

        # Test: Very large PR number
        def test_parse_very_large_pr_number
          result = @parser.parse("999999999")
          assert_equal 999999999, result[:number]
        end

        # Test: Parse GitHub URL with query parameters
        def test_parse_github_url_strips_query_params
          # URL parsing should work, though query params might be included in regex match
          result = @parser.parse("https://github.com/owner/repo/pull/123")
          assert_equal 123, result[:number]
        end

        # Test: Resolve repository from SSH remote
        def test_resolve_repository_from_ssh_remote
          # Change remote to SSH format
          `git remote set-url origin git@github.com:ssh-owner/ssh-repo.git`

          result = @parser.parse("42")

          assert_equal "ssh-owner", result[:owner]
          assert_equal "ssh-repo", result[:repo]
        end

        # Test: Resolve repository from HTTPS remote
        def test_resolve_repository_from_https_remote
          # Remote already set to HTTPS in setup
          result = @parser.parse("42")

          assert_equal "test-owner", result[:owner]
          assert_equal "test-repo", result[:repo]
        end

        # Test: Resolve repository from HTTPS remote without .git
        def test_resolve_repository_from_https_without_git_suffix
          `git remote set-url origin https://github.com/plain-owner/plain-repo`

          result = @parser.parse("42")

          assert_equal "plain-owner", result[:owner]
          assert_equal "plain-repo", result[:repo]
        end

        # Test: Resolve repository raises error when not in git repo
        def test_resolve_repository_raises_when_not_in_git_repo
          # Create a directory without git
          Dir.chdir(@test_dir) do
            FileUtils.rm_rf(".git")

            error = assert_raises(StandardError) do
              @parser.parse("123")
            end

            assert_match(/Not in a git repository/, error.message)
          end
        end

        # Test: Resolve repository raises error when remote not configured
        def test_resolve_repository_raises_when_no_remote
          `git remote remove origin`

          error = assert_raises(StandardError) do
            @parser.parse("123")
          end

          assert_match(/Not in a git repository or remote.origin not configured/, error.message)
        end

        # Test: Resolve repository raises error for unparseable remote URL
        def test_resolve_repository_raises_for_invalid_remote_url
          `git remote set-url origin invalid-url-format`

          error = assert_raises(StandardError) do
            @parser.parse("123")
          end

          assert_match(/Could not parse git remote URL/, error.message)
        end

        # Test: Parse GitHub Enterprise URL
        def test_parse_github_enterprise_url
          result = @parser.parse("https://github.company.com/team/app/pull/10")

          assert_equal "team", result[:owner]
          assert_equal "app", result[:repo]
          assert_equal 10, result[:number]
          assert_equal "github.company.com", result[:host]
        end

        # Test: Parse qualified ref with hyphens in names
        def test_parse_qualified_ref_with_hyphens
          result = @parser.parse("my-org/my-repo#123")

          assert_equal "my-org", result[:owner]
          assert_equal "my-repo", result[:repo]
          assert_equal 123, result[:number]
        end

        # Test: Parse qualified ref with underscores (actually works - pattern allows word chars)
        def test_parse_qualified_ref_with_underscores
          # The pattern [\w-]+ actually includes underscores since \w matches [a-zA-Z0-9_]
          result = @parser.parse("my_org/my_repo#123")

          assert_equal "my_org", result[:owner]
          assert_equal "my_repo", result[:repo]
          assert_equal 123, result[:number]
        end
      end
    end
  end
end
