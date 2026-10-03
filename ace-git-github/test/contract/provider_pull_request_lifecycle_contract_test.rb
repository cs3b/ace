# frozen_string_literal: true

require "test_helper"

# PR-lifecycle contract parity suite for the GitHub provider.
# Shares identical assertions with ace-git-forgejo via
# Ace::TestSupport::PullRequestLifecycleContract; fixtures are `gh`-shaped.
class GithubProviderPullRequestLifecycleContractTest < AceGitGithubTestCase
  include Ace::TestSupport::PullRequestLifecycleContract

  CONTRACT = Ace::TestSupport::PullRequestLifecycleContract
  SERVER = Ace::Git::ResolvedServer.new(name: "forge-server", provider: :github, url: CONTRACT::SERVER_URL)
  SHA = CONTRACT::HEAD_SHA

  PR_FIELDS = "number,state,isDraft,title,body,author,headRefName,baseRefName,url,headRefOid,mergeCommit,mergedAt,headRepositoryOwner,headRepository"
  LIST_FIELDS = Ace::Git::Github::Provider::LIFECYCLE_LIST_FIELDS

  def build_provider(runner)
    Ace::Git::Github::Provider.new(server: SERVER, runner: runner)
  end

  def ready_supported?
    true
  end

  def merge_supported?
    true
  end

  def lifecycle_runner(scenario)
    scripted_runner(scenario_responses.fetch(scenario))
  end

  def scenario_responses
    @scenario_responses ||= {
      find_single: {
        "gh pr list --state open --limit 200 --json #{LIST_FIELDS} --repo forge.example.com/owner/repo" => {
          success: true, stdout: [list_entry(25, SHA)].to_json, stderr: "", exit_code: 0
        }
      },
      find_multi: {
        "gh pr list --state open --limit 200 --json #{LIST_FIELDS} --repo forge.example.com/owner/repo" => {
          success: true, stdout: [list_entry(25, SHA), list_entry(26, CONTRACT::OTHER_SHA)].to_json,
          stderr: "", exit_code: 0
        }
      },
      create_new: {
        "gh pr list --state open --limit 200 --json #{LIST_FIELDS} --repo forge.example.com/owner/repo" => {
          success: true, stdout: [].to_json, stderr: "", exit_code: 0
        },
        "gh pr create --head feature/x --base main --title Ship it --draft --repo forge.example.com/owner/repo" => {
          success: true, stdout: "#{CONTRACT::SERVER_URL}/pull/25\n", stderr: "", exit_code: 0
        },
        "gh pr view 25 --json #{PR_FIELDS} --repo forge.example.com/owner/repo" => {
          success: true, stdout: view_json(25, SHA).to_json, stderr: "", exit_code: 0
        }
      },
      create_existing: {
        "gh pr list --state open --limit 200 --json #{LIST_FIELDS} --repo forge.example.com/owner/repo" => {
          success: true, stdout: [list_entry(25, SHA)].to_json, stderr: "", exit_code: 0
        }
      },
      create_unknown: {
        "gh pr list --state open --limit 200 --json #{LIST_FIELDS} --repo forge.example.com/owner/repo" => {
          success: true, stdout: [].to_json, stderr: "", exit_code: 0
        },
        "gh pr create --head feature/x --base main --title Ship it --draft --repo forge.example.com/owner/repo" => [
          "network unreachable: cannot reach api.github.com", 1
        ]
      },
      update_stale: {
        "gh pr view 25 --json #{PR_FIELDS} --repo forge.example.com/owner/repo" => {
          success: true, stdout: view_json(25, SHA).to_json, stderr: "", exit_code: 0
        }
      },
      update_ok: {
        "gh pr view 25 --json #{PR_FIELDS} --repo forge.example.com/owner/repo" => {
          success: true, stdout: view_json(25, SHA).to_json, stderr: "", exit_code: 0
        },
        "gh pr edit 25 --title New title --repo forge.example.com/owner/repo" => {success: true, stdout: "", stderr: "", exit_code: 0}
      },
      ready_ok: {
        "gh pr view 25 --json #{PR_FIELDS} --repo forge.example.com/owner/repo" => {
          success: true, stdout: view_json(25, SHA).to_json, stderr: "", exit_code: 0
        },
        "gh pr ready 25 --repo forge.example.com/owner/repo" => {success: true, stdout: "", stderr: "", exit_code: 0}
      },
      merge_ok: {
        "gh pr merge 25 --squash --match-head-commit #{SHA} --repo forge.example.com/owner/repo" => {
          success: true, stdout: "Squashed and merged pull request #25", stderr: "", exit_code: 0
        },
        "gh pr view 25 --json #{PR_FIELDS} --repo forge.example.com/owner/repo" => {
          success: true, stdout: view_json(25, SHA).to_json, stderr: "", exit_code: 0
        }
      },
      merge_stale: {
        "gh pr merge 25 --squash --match-head-commit #{CONTRACT::OTHER_SHA} --repo forge.example.com/owner/repo" => [
          "X Pull request #25 head commit does not match --match-head-commit", 1
        ]
      }
    }
  end

  private

  def list_entry(number, sha)
    {
      "number" => number,
      "title" => "Ship it",
      "state" => "OPEN",
      "isDraft" => true,
      "author" => {"login" => "lab-builder"},
      "headRefName" => "feature/x",
      "baseRefName" => "main",
      "url" => "#{CONTRACT::SERVER_URL}/pull/#{number}",
      "headRefOid" => sha,
      "headRepositoryOwner" => {"login" => "owner"},
      "headRepository" => {"name" => "repo"}
    }
  end

  def view_json(number, sha)
    list_entry(number, sha).merge(
      "mergeCommit" => nil,
      "mergedAt" => nil
    )
  end
end
