# frozen_string_literal: true

require_relative "../test_helper"
require "ace/git/cli/commands/pr"

class PrTest < AceGitTestCase
  def setup
    super
    @command = Ace::Git::CLI::Commands::Pr.new
  end

  def test_execute_returns_error_when_gh_not_installed
    Ace::Git::Molecules::PrMetadataFetcher.stub :gh_installed?, false do
      error = assert_raises(Ace::Support::Cli::Error) do
        @command.call(format: nil)
      end
      assert_match(/GitHub CLI.*not installed/, error.message)
    end
  end

  def test_execute_returns_error_when_no_pr_number_and_no_pr_for_branch
    Ace::Git::Molecules::PrMetadataFetcher.stub :gh_installed?, true do
      Ace::Git::Molecules::PrMetadataFetcher.stub :find_pr_for_branch, nil do
        error = assert_raises(Ace::Support::Cli::Error) do
          @command.call(format: nil)
        end
        assert_match(/No PR found for current branch/, error.message)
      end
    end
  end

  def test_execute_returns_success_with_pr_number
    mock_result = {
      success: true,
      metadata: {
        "number" => 42,
        "title" => "Test PR",
        "state" => "OPEN",
        "url" => "https://github.com/test/repo/pull/42"
      }
    }

    Ace::Git::Molecules::PrMetadataFetcher.stub :gh_installed?, true do
      Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_metadata, mock_result do
        output = capture_io do
          result = @command.call(number: 42, format: nil, with_diff: false)
          assert_nil result
        end
        # Compact format: # PR #42: Test PR [OPEN]
        assert_match(/PR #42/, output.first)
        assert_match(/Test PR/, output.first)
      end
    end
  end

  def test_execute_auto_finds_pr_for_current_branch
    mock_result = {
      success: true,
      metadata: {
        "number" => 99,
        "title" => "Auto-found PR",
        "state" => "OPEN"
      }
    }

    Ace::Git::Molecules::PrMetadataFetcher.stub :gh_installed?, true do
      Ace::Git::Molecules::PrMetadataFetcher.stub :find_pr_for_branch, "99" do
        Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_metadata, mock_result do
          output = capture_io do
            result = @command.call(format: nil, with_diff: false)
            assert_nil result
          end
          # Compact format: # PR #99: Auto-found PR [OPEN]
          assert_match(/PR #99/, output.first)
        end
      end
    end
  end

  def test_execute_outputs_json_format
    mock_result = {
      success: true,
      metadata: {
        "number" => 42,
        "title" => "Test PR",
        "state" => "OPEN",
        "headRefName" => "feature/test",
        "baseRefName" => "main"
      }
    }

    Ace::Git::Molecules::PrMetadataFetcher.stub :gh_installed?, true do
      Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_metadata, mock_result do
        output = capture_io do
          result = @command.call(number: 42, format: "json", with_diff: false)
          assert_nil result
        end
        json = JSON.parse(output.first)
        assert_equal 42, json["metadata"]["number"]
        assert_equal "Test PR", json["metadata"]["title"]
      end
    end
  end

  def test_execute_with_diff_includes_diff_content
    mock_result = {
      success: true,
      metadata: {
        "number" => 42,
        "title" => "Test PR",
        "state" => "OPEN"
      },
      diff: "+added line\n-removed line"
    }

    Ace::Git::Molecules::PrMetadataFetcher.stub :gh_installed?, true do
      Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_pr, mock_result do
        output = capture_io do
          result = @command.call(number: 42, format: nil, with_diff: true)
          assert_nil result
        end
        assert_match(/## Diff/, output.first)
        assert_match(/\+added line/, output.first)
      end
    end
  end

  def test_execute_returns_error_on_fetch_failure
    mock_result = {success: false, error: "PR not found"}

    Ace::Git::Molecules::PrMetadataFetcher.stub :gh_installed?, true do
      Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_metadata, mock_result do
        error = assert_raises(Ace::Support::Cli::Error) do
          @command.call(number: 999, format: nil, with_diff: false)
        end
        assert_match(/PR not found/, error.message)
      end
    end
  end

  def test_execute_handles_gh_not_installed_error
    Ace::Git::Molecules::PrMetadataFetcher.stub :gh_installed?, true do
      Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_metadata, ->(_) { raise Ace::Git::GhNotInstalledError, "gh not found" } do
        error = assert_raises(Ace::Support::Cli::Error) do
          @command.call(number: 42, format: nil, with_diff: false)
        end
        assert_match(/gh not found/, error.message)
      end
    end
  end

  def test_execute_handles_authentication_error
    Ace::Git::Molecules::PrMetadataFetcher.stub :gh_installed?, true do
      Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_metadata, ->(_) { raise Ace::Git::GhAuthenticationError, "Not authenticated" } do
        error = assert_raises(Ace::Support::Cli::Error) do
          @command.call(number: 42, format: nil, with_diff: false)
        end
        assert_match(/Not authenticated/, error.message)
      end
    end
  end

  def test_execute_handles_pr_not_found_error
    Ace::Git::Molecules::PrMetadataFetcher.stub :gh_installed?, true do
      Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_metadata, ->(_) { raise Ace::Git::PrNotFoundError, "PR #999 not found" } do
        error = assert_raises(Ace::Support::Cli::Error) do
          @command.call(number: 999, format: nil, with_diff: false)
        end
        assert_match(/PR #999 not found/, error.message)
      end
    end
  end

  def test_execute_handles_timeout_error
    Ace::Git::Molecules::PrMetadataFetcher.stub :gh_installed?, true do
      Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_metadata, ->(_) { raise Ace::Git::TimeoutError, "Request timed out" } do
        error = assert_raises(Ace::Support::Cli::Error) do
          @command.call(number: 42, format: nil, with_diff: false)
        end
        assert_match(/Request timed out/, error.message)
      end
    end
  end

  def test_execute_handles_argument_error
    Ace::Git::Molecules::PrMetadataFetcher.stub :gh_installed?, true do
      Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_metadata, ->(_) { raise ArgumentError, "Invalid PR identifier" } do
        error = assert_raises(Ace::Support::Cli::Error) do
          @command.call(number: "invalid", format: nil, with_diff: false)
        end
        assert_match(/Invalid PR identifier/, error.message)
      end
    end
  end

  def test_execute_shows_author_info
    mock_result = {
      success: true,
      metadata: {
        "number" => 42,
        "title" => "Test PR",
        "state" => "OPEN",
        "author" => {"login" => "testuser"}
      }
    }

    Ace::Git::Molecules::PrMetadataFetcher.stub :gh_installed?, true do
      Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_metadata, mock_result do
        output = capture_io do
          result = @command.call(number: 42, format: nil, with_diff: false)
          assert_nil result
        end
        assert_match(/testuser/, output.first)
      end
    end
  end
end
