# frozen_string_literal: true

require "test_helper"

# Provider-contract parity suite for the GitHub provider.
# Shares identical assertions with ace-git-forgejo via
# Ace::TestSupport::ProviderContract; fixtures are GitHub (`gh`) shaped.
class GithubProviderContractTest < AceGitGithubTestCase
  include Ace::TestSupport::ProviderContract

  SERVER = Ace::Git::ResolvedServer.new(name: "forge-server", provider: :github, url: "https://github.example.com/owner/repo")

  PR_FIELDS = "number,state,isDraft,title,author,headRefName,baseRefName,url,headRefOid,mergeCommit,mergedAt"
  LIST_FIELDS = Ace::Git::Github::PrFetcher::LIST_FIELDS

  def build_provider(runner)
    Ace::Git::Github::Provider.new(server: SERVER, runner: runner)
  end

  def ok_runner
    @ok_runner ||= scripted_runner(
      "gh --version" => {success: true, stdout: "gh version 2.63.0", stderr: "", exit_code: 0},
      "gh auth status" => {success: true, stdout: "", stderr: "ok", exit_code: 0},
      "gh pr view 25 --json #{PR_FIELDS}" => {success: true, stdout: pr25_json.to_json, stderr: "", exit_code: 0},
      "gh pr list --state all --limit 30 --json #{LIST_FIELDS}" => {
        success: true, stdout: [pr25_list_json, pr31_json].to_json, stderr: "", exit_code: 0
      },
      "gh pr diff 25" => {success: true, stdout: "diff --git a/lib/x.rb b/lib/x.rb\n+new line\n", stderr: "", exit_code: 0},
      "gh issue view 9 --json number,title,state,author,url" => {
        success: true, stdout: issue9_json.to_json, stderr: "", exit_code: 0
      },
      "gh pr checks fc14c43d3660ac6c133959a6dec29603413f0e8a --json name,state,bucket" => {
        success: true, stdout: [{"name" => "test-suite", "state" => "SUCCESS", "bucket" => "pass"}].to_json,
        stderr: "", exit_code: 0
      },
      "gh repo view --json nameWithOwner,defaultBranchRef,url" => {
        success: true, stdout: {
          "nameWithOwner" => "owner/repo",
          "defaultBranchRef" => {"name" => "main"},
          "url" => "https://forge.example.com/owner/repo"
        }.to_json, stderr: "", exit_code: 0
      }
    )
  end

  def version_fail_runner
    scripted_runner("gh --version" => ["gh: command not found", 127])
  end

  def auth_fail_runner
    scripted_runner(
      "gh --version" => {success: true, stdout: "gh version 2.63.0", stderr: "", exit_code: 0},
      "gh auth status" => ["not logged in; run gh auth login", 4]
    )
  end

  def not_found_runner
    scripted_runner(
      "gh --version" => {success: true, stdout: "gh version 2.63.0", stderr: "", exit_code: 0},
      "gh auth status" => {success: true, stdout: "", stderr: "ok", exit_code: 0},
      "gh pr view 999 --json #{PR_FIELDS}" => ["Could not resolve to a PullRequest with the number 999", 1]
    )
  end

  def malformed_runner
    scripted_runner(
      "gh --version" => {success: true, stdout: "gh version 2.63.0", stderr: "", exit_code: 0},
      "gh auth status" => {success: true, stdout: "", stderr: "ok", exit_code: 0},
      "gh pr view 25 --json #{PR_FIELDS}" => {success: true, stdout: "definitely not { json", stderr: "", exit_code: 0}
    )
  end

  def unreachable_runner
    scripted_runner(
      "gh --version" => {success: true, stdout: "gh version 2.63.0", stderr: "", exit_code: 0},
      "gh auth status" => {success: true, stdout: "", stderr: "ok", exit_code: 0},
      "gh pr view 25 --json #{PR_FIELDS}" => ["network unreachable: cannot reach api.github.com", 1]
    )
  end

  private

  def pr25_json
    {
      "number" => 25,
      "state" => "MERGED",
      "isDraft" => false,
      "title" => "Ship the provider contract",
      "author" => {"login" => "lab-builder"},
      "headRefName" => "lab/W675-ace",
      "baseRefName" => "main",
      "url" => "https://forge.example.com/owner/repo/pull/25",
      "headRefOid" => "fc14c43d3660ac6c133959a6dec29603413f0e8a",
      "mergeCommit" => {"oid" => "deadbeefdeadbeefdeadbeefdeadbeefdeadbeef"},
      "mergedAt" => "2026-09-20T21:24:04Z"
    }
  end

  def pr25_list_json
    pr25_json.merge("isDraft" => false)
  end

  def pr31_json
    {
      "number" => 31,
      "state" => "OPEN",
      "isDraft" => true,
      "title" => "Wire status to providers",
      "author" => {"login" => "lab-builder"},
      "headRefName" => "lab/W676-ace",
      "baseRefName" => "main",
      "url" => "https://forge.example.com/owner/repo/pull/31",
      "headRefOid" => "a1b2c3d4e5f60718293a4b5c6d7e8f9012345678",
      "mergeCommit" => nil,
      "mergedAt" => nil
    }
  end

  def issue9_json
    {
      "number" => 9,
      "title" => "Broken diff on detached HEAD",
      "state" => "OPEN",
      "author" => {"login" => "lab-admin"},
      "url" => "https://forge.example.com/owner/repo/issues/9"
    }
  end
end
