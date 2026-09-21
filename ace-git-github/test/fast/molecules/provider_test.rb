# frozen_string_literal: true

require "test_helper"

module Github
  # Provider behaviors beyond the shared parity suite
  class ProviderTest < AceGitGithubTestCase
    SERVER = Ace::Git::ResolvedServer.new(name: "forge", provider: :github, url: "https://github.example.com/owner/repo")

    LIST_FIELDS = Ace::Git::Github::PrFetcher::LIST_FIELDS
    PR_FIELDS = "number,state,isDraft,title,author,headRefName,baseRefName,url,headRefOid,mergeCommit,mergedAt"

    def build_provider(runner)
      Ace::Git::Github::Provider.new(server: SERVER, runner: runner)
    end

    def evidence(number, state, head_ref)
      {
        "number" => number, "state" => state, "isDraft" => false, "title" => "PR #{number}",
        "author" => {"login" => "dev"}, "headRefName" => head_ref, "baseRefName" => "main",
        "url" => "https://github.example.com/owner/repo/pull/#{number}", "headRefOid" => "a" * 40,
        "mergeCommit" => nil, "mergedAt" => nil
      }
    end

    def test_pull_request_for_branch_prefers_open_over_merged
      runner = scripted_runner(
        "gh pr list --state all --limit 30 --json #{LIST_FIELDS}" => {
          success: true,
          stdout: [evidence(90, "MERGED", "feature"), evidence(91, "OPEN", "feature")].to_json,
          stderr: "", exit_code: 0
        }
      )

      pr = build_provider(runner).pull_request_for_branch(branch: "feature")
      assert_equal 91, pr.number
      assert_equal :open, pr.state
    end

    def test_issue_normalizes_state_and_author
      runner = scripted_runner(
        "gh issue view 9 --json number,title,state,author,url" => {
          success: true,
          stdout: {"number" => 9, "title" => "Broken diff", "state" => "CLOSED", "author" => {"login" => "lab"}, "url" => "https://github.example.com/owner/repo/issues/9"}.to_json,
          stderr: "", exit_code: 0
        }
      )

      issue = build_provider(runner).issue(number: 9)
      assert_equal :closed, issue.state
      assert_equal "lab", issue.author
    end

    private

    def scripted_runner(responses)
      lambda do |args:, timeout: nil, env: nil|
        response = responses.fetch(args.join(" ")) { flunk("Unexpected command: #{args.join(' ')}") }
        response.is_a?(Array) ? {success: false, stdout: "", stderr: response[0], exit_code: response[1]} : response
      end
    end
  end
end
