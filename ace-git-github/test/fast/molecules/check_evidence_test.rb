# frozen_string_literal: true

require "test_helper"

# Check-evidence contract for the GitHub provider: check runs and combined
# commit statuses must both be collected, and a truncated snapshot must fail
# closed instead of understating evidence.
class GithubCheckEvidenceTest < AceGitGithubTestCase
  SERVER = Ace::Git::ResolvedServer.new(
    name: "forge-server", provider: :github, url: "https://github.example.com/owner/repo"
  )
  HEAD = "fc14c43d3660ac6c133959a6dec29603413f0e8a"

  def build_provider(runner)
    Ace::Git::Github::Provider.new(server: SERVER, runner: runner)
  end

  def scripted_checks_runner(checks_payload:, status_payload:)
    scripted_runner(
      "gh --version" => {success: true, stdout: "gh version 2.63.0", stderr: "", exit_code: 0},
      "gh auth status" => {success: true, stdout: "", stderr: "ok", exit_code: 0},
      "gh pr view 25 --json #{Ace::Git::Github::Provider::PR_FIELDS} --repo github.example.com/owner/repo" => {
        success: true, stdout: pr_json.to_json, stderr: "", exit_code: 0
      },
      "gh api repos/owner/repo/commits/#{HEAD}/check-runs?per_page=100 --hostname github.example.com" => {
        success: true, stdout: checks_payload.to_json, stderr: "", exit_code: 0
      },
      "gh api repos/owner/repo/commits/#{HEAD}/status --hostname github.example.com" => {
        success: true, stdout: status_payload.to_json, stderr: "", exit_code: 0
      }
    )
  end

  def pr_json
    {
      "number" => 25, "state" => "OPEN", "isDraft" => false, "title" => "t", "body" => nil,
      "author" => {"login" => "dev"}, "headRefName" => "feature", "baseRefName" => "main",
      "url" => "https://github.example.com/owner/repo/pull/25", "headRefOid" => HEAD,
      "mergeCommit" => nil, "mergedAt" => nil,
      "headRepositoryOwner" => {"login" => "owner"}, "headRepository" => {"name" => "repo"}
    }
  end

  def test_status_only_evidence_is_collected_as_checks
    runner = scripted_checks_runner(
      checks_payload: {"total_count" => 0, "check_runs" => []},
      status_payload: {
        "state" => "success",
        "statuses" => [
          {"context" => "ci/lab", "state" => "success", "target_url" => "https://ci.example.com/1"},
          {"context" => "docs", "state" => "pending", "target_url" => nil}
        ]
      }
    )

    checks = build_provider(runner).pull_request_checks(number: 25, head_sha: HEAD)

    assert_equal 2, checks.length
    lab = checks.find { |c| c.name == "ci/lab" }
    assert_equal :success, lab.state
    assert_nil lab.conclusion
    assert_equal "https://ci.example.com/1", lab.url
    assert_equal :pending, checks.find { |c| c.name == "docs" }.state
  end

  def test_check_runs_and_statuses_are_merged
    runner = scripted_checks_runner(
      checks_payload: {
        "total_count" => 1,
        "check_runs" => [
          {"name" => "test-suite", "status" => "COMPLETED", "conclusion" => "SUCCESS", "html_url" => "https://ci.example.com/run/1"}
        ]
      },
      status_payload: {
        "state" => "failure",
        "statuses" => [{"context" => "ci/lab", "state" => "failure", "target_url" => nil}]
      }
    )

    checks = build_provider(runner).pull_request_checks(number: 25, head_sha: HEAD)

    assert_equal 2, checks.length
    assert_equal :completed, checks.first.state
    assert_equal :success, checks.first.conclusion
    assert_equal :failure, checks.last.state
  end

  def test_truncated_check_run_page_fails_closed
    runner = scripted_checks_runner(
      checks_payload: {
        "total_count" => 101,
        "check_runs" => Array.new(100) { |i| {"name" => "check-#{i}", "status" => "COMPLETED", "conclusion" => "SUCCESS"} }
      },
      status_payload: {"state" => "success", "statuses" => []}
    )

    error = assert_raises(Ace::Git::ProviderMalformedOutputError) do
      build_provider(runner).pull_request_checks(number: 25, head_sha: HEAD)
    end
    assert_match(/Incomplete GitHub PR check evidence/, error.message)
  end

  def test_missing_total_count_fails_closed
    runner = scripted_checks_runner(
      checks_payload: {"check_runs" => [{"name" => "test-suite", "status" => "COMPLETED", "conclusion" => "SUCCESS"}]},
      status_payload: {"state" => "success", "statuses" => []}
    )

    error = assert_raises(Ace::Git::ProviderMalformedOutputError) do
      build_provider(runner).pull_request_checks(number: 25, head_sha: HEAD)
    end
    assert_match(/Incomplete GitHub PR check evidence/, error.message)
  end
end
