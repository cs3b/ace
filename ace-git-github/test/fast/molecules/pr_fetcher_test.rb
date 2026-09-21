# frozen_string_literal: true

require "test_helper"

module Github
  class PrFetcherTest < AceGitGithubTestCase
    def ok_runner
      @ok_runner ||= scripted_runner(
        "gh --version" => {success: true, stdout: "gh version 2.63.0", stderr: "", exit_code: 0},
        "gh auth status" => {success: true, stdout: "", stderr: "ok", exit_code: 0},
        "gh pr diff 42" => {success: true, stdout: "+added line\n-removed line", stderr: "", exit_code: 0},
        "gh pr diff owner/repo#42" => {success: true, stdout: "+added line\n-removed line", stderr: "", exit_code: 0},
        "gh pr view 42 --json #{fields}" => {
          success: true, stdout: {"number" => 42, "title" => "Test PR", "state" => "OPEN"}.to_json, stderr: "", exit_code: 0
        },
        "gh pr view --json number" => {success: true, stdout: {"number" => 123}.to_json, stderr: "", exit_code: 0},
        "gh pr list --state merged --limit 3 --json number,title,mergedAt,author" => {
          success: true,
          stdout: [
            {"number" => 84, "title" => "Test PR", "mergedAt" => "2025-12-23T12:00:00Z"},
            {"number" => 82, "title" => "Other PR", "mergedAt" => "2025-12-22T12:00:00Z"}
          ].to_json,
          stderr: "", exit_code: 0
        },
        "gh pr list --state open --limit 10 --json number,title,author,headRefName" => {
          success: true,
          stdout: [
            {"number" => 85, "title" => "Open PR", "author" => {"login" => "user1"}, "headRefName" => "feature-1"},
            {"number" => 86, "title" => "Other PR", "author" => {"login" => "user2"}, "headRefName" => "feature-2"}
          ].to_json,
          stderr: "", exit_code: 0
        }
      )
    end

    def fields
      Ace::Git::Github::PrFetcher::PR_FIELDS.join(",")
    end

    def test_installed_true_when_probe_succeeds
      assert Ace::Git::Github::PrFetcher.installed?(runner: ok_runner)
    end

    def test_authenticated_true_when_probe_succeeds
      assert Ace::Git::Github::PrFetcher.authenticated?(runner: ok_runner)
    end

    def test_fetch_diff_returns_diff_content_on_success
      result = Ace::Git::Github::PrFetcher.fetch_diff("42", timeout: 5, runner: ok_runner)
      assert result[:success]
      assert_match(/added line/, result[:diff])
    end

    def test_fetch_diff_raises_on_invalid_identifier
      assert_raises(ArgumentError) do
        Ace::Git::Github::PrFetcher.fetch_diff("not-a-pr", timeout: 5, runner: ok_runner)
      end
    end

    def test_fetch_diff_raises_object_not_found_error
      runner = scripted_runner("gh pr diff 99999" => ["Could not resolve to a PullRequest", 1])
      error = assert_raises(Ace::Git::ProviderObjectNotFoundError) do
        Ace::Git::Github::PrFetcher.fetch_diff("99999", timeout: 5, runner: runner)
      end
      assert_match(/99999/, error.message)
    end

    def test_fetch_diff_raises_authentication_error
      runner = scripted_runner("gh pr diff 42" => ["not logged in", 4])
      assert_raises(Ace::Git::ProviderAuthenticationError) do
        Ace::Git::Github::PrFetcher.fetch_diff("42", timeout: 5, runner: runner)
      end
    end

    def test_fetch_metadata_returns_parsed_json
      result = Ace::Git::Github::PrFetcher.fetch_metadata("42", timeout: 5, runner: ok_runner)
      assert result[:success]
      assert_equal 42, result[:metadata]["number"]
      assert_equal "Test PR", result[:metadata]["title"]
    end

    def test_fetch_metadata_raises_on_invalid_identifier
      assert_raises(ArgumentError) do
        Ace::Git::Github::PrFetcher.fetch_metadata("invalid", timeout: 5, runner: ok_runner)
      end
    end

    def test_fetch_metadata_raises_malformed_output_on_json_parse_error
      runner = scripted_runner("gh pr view 42 --json #{fields}" => {success: true, stdout: "not valid json", stderr: "", exit_code: 0})
      error = assert_raises(Ace::Git::ProviderMalformedOutputError) do
        Ace::Git::Github::PrFetcher.fetch_metadata("42", timeout: 5, runner: runner)
      end
      assert_match(/Failed to parse PR metadata/, error.message)
    end

    def test_fetch_pr_returns_both_diff_and_metadata
      result = Ace::Git::Github::PrFetcher.fetch_pr("42", timeout: 5, runner: ok_runner)
      assert result[:success]
      assert_match(/added/, result[:diff])
      assert_equal 42, result[:metadata]["number"]
    end

    def test_find_pr_for_branch_returns_number_string
      result = Ace::Git::Github::PrFetcher.find_pr_for_branch(timeout: 5, runner: ok_runner)
      assert_equal "123", result
    end

    def test_find_pr_for_branch_returns_nil_when_no_pr
      runner = scripted_runner("gh pr view --json number" => ["no pull requests", 1])
      result = Ace::Git::Github::PrFetcher.find_pr_for_branch(timeout: 5, runner: runner)
      assert_nil result
    end

    def test_find_pr_for_branch_returns_nil_on_json_error
      runner = scripted_runner("gh pr view --json number" => {success: true, stdout: "not json", stderr: "", exit_code: 0})
      result = Ace::Git::Github::PrFetcher.find_pr_for_branch(timeout: 5, runner: runner)
      assert_nil result
    end

    def test_fetch_diff_includes_repo_in_source_label
      result = Ace::Git::Github::PrFetcher.fetch_diff("owner/repo#42", timeout: 5, runner: ok_runner)
      assert result[:success]
      assert_match(/owner\/repo/, result[:source])
    end

    def test_timeout_raises_unreachable_error
      runner = ->(args:, timeout: nil, env: nil) { :timeout }
      error = assert_raises(Ace::Git::ProviderUnreachableError) do
        Ace::Git::Github::PrFetcher.fetch_diff("42", timeout: 1, runner: runner)
      end
      assert_match(/timed out/, error.message)
    end

    def test_fetch_recently_merged_returns_prs_on_success
      result = Ace::Git::Github::PrFetcher.fetch_recently_merged(limit: 3, timeout: 5, runner: ok_runner)
      assert result[:success]
      assert_equal 2, result[:prs].length
      assert_equal 84, result[:prs][0]["number"]
    end

    def test_fetch_recently_merged_returns_empty_on_failure
      runner = scripted_runner("gh pr list --state merged --limit 3 --json number,title,mergedAt,author" => ["error", 1])
      result = Ace::Git::Github::PrFetcher.fetch_recently_merged(timeout: 5, runner: runner)
      refute result[:success]
      assert_empty result[:prs]
    end

    def test_fetch_recently_merged_raises_malformed_on_json_error
      runner = scripted_runner("gh pr list --state merged --limit 3 --json number,title,mergedAt,author" => {success: true, stdout: "not valid json", stderr: "", exit_code: 0})
      assert_raises(Ace::Git::ProviderMalformedOutputError) do
        Ace::Git::Github::PrFetcher.fetch_recently_merged(timeout: 5, runner: runner)
      end
    end

    def test_fetch_recently_merged_respects_limit
      captured = nil
      runner = lambda do |args:, timeout: nil, env: nil|
        captured = args.join(" ")
        {success: true, stdout: [{"number" => 1}].to_json, stderr: "", exit_code: 0}
      end

      Ace::Git::Github::PrFetcher.fetch_recently_merged(limit: 5, timeout: 5, runner: runner)
      assert_includes captured, "--limit 5"
    end

    def test_fetch_open_prs_excludes_specified_branch
      captured = nil
      runner = lambda do |args:, timeout: nil, env: nil|
        captured = args.join(" ")
        {success: true, stdout: [
          {"number" => 85, "title" => "Open PR", "headRefName" => "feature-1"},
          {"number" => 86, "title" => "Current PR", "headRefName" => "current-branch"}
        ].to_json, stderr: "", exit_code: 0}
      end

      result = Ace::Git::Github::PrFetcher.fetch_open_prs(exclude_branch: "current-branch", timeout: 5, runner: runner)
      assert result[:success]
      assert_equal 1, result[:prs].length
      assert_equal 85, result[:prs][0]["number"]
    end

    def test_fetch_open_prs_with_nil_exclude_branch_returns_all
      result = Ace::Git::Github::PrFetcher.fetch_open_prs(exclude_branch: nil, timeout: 5, runner: ok_runner)
      assert result[:success]
      assert_equal 2, result[:prs].length
    end

    def test_fetch_open_prs_returns_empty_on_failure
      runner = scripted_runner("gh pr list --state open --limit 10 --json number,title,author,headRefName" => ["error", 1])
      result = Ace::Git::Github::PrFetcher.fetch_open_prs(timeout: 5, runner: runner)
      refute result[:success]
      assert_empty result[:prs]
    end
  end
end
