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
        "gh pr list --state all --limit 30 --json #{LIST_FIELDS} --repo github.example.com/owner/repo" => {
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
        "gh issue view 9 --json number,title,state,author,url --repo github.example.com/owner/repo" => {
          success: true,
          stdout: {"number" => 9, "title" => "Broken diff", "state" => "CLOSED", "author" => {"login" => "lab"}, "url" => "https://github.example.com/owner/repo/issues/9"}.to_json,
          stderr: "", exit_code: 0
        }
      )

      issue = build_provider(runner).issue(number: 9)
      assert_equal :closed, issue.state
      assert_equal "lab", issue.author
    end

    def test_add_issue_label_creates_missing_repo_label
      calls = []
      created = false
      runner = lambda do |args:, **_opts|
        joined = args.join(" ")
        calls << joined
        if joined.include?("labels?per_page=100")
          listed = created ? ["ace:tracked"] : []
          next {success: true, stdout: listed.join("\n"), stderr: "", exit_code: 0}
        elsif joined.include?("repos/owner/repo/labels --hostname")
          created = true
          next {success: true, stdout: '{"id":9,"name":"ace:tracked"}', stderr: "", exit_code: 0}
        elsif joined.include?("issues/42/labels")
          next {success: true, stdout: "[]", stderr: "", exit_code: 0}
        end
        flunk("Unexpected command: #{joined}")
      end

      build_provider(runner).add_issue_label(number: 42, label: "ace:tracked")
      # Lookup, create, post-create re-list, then the attach.
      assert_equal 4, calls.length
      assert calls.first.include?("labels?per_page=100")
      assert calls.one? { |call| call.include?("repos/owner/repo/labels --hostname") }
      assert calls.last.include?("issues/42/labels")
    end

    def test_add_issue_label_skips_creation_when_label_exists
      calls = []
      runner = lambda do |args:, **_opts|
        joined = args.join(" ")
        calls << joined
        if joined.include?("labels?per_page=100")
          next {success: true, stdout: "other\nace:tracked\n", stderr: "", exit_code: 0}
        elsif joined.include?("issues/42/labels")
          next {success: true, stdout: "[]", stderr: "", exit_code: 0}
        end
        flunk("Unexpected command: #{joined}")
      end

      build_provider(runner).add_issue_label(number: 42, label: "ace:tracked")
      assert_equal 2, calls.length
    end

    def test_add_issue_label_survives_concurrent_label_creation
      created = false
      runner = lambda do |args:, **_opts|
        joined = args.join(" ")
        if joined.include?("labels?per_page=100")
          listed = created ? ["ace:tracked"] : []
          next {success: true, stdout: listed.join("\n"), stderr: "", exit_code: 0}
        elsif joined.include?("repos/owner/repo/labels --hostname")
          created = true
          next {success: false, stdout: "", stderr: "gh: validation failed (422)", exit_code: 1}
        elsif joined.include?("issues/42/labels")
          next {success: true, stdout: "[]", stderr: "", exit_code: 0}
        end
        flunk("Unexpected command: #{joined}")
      end

      build_provider(runner).add_issue_label(number: 42, label: "ace:tracked")
    end

    def test_add_issue_label_propagates_missing_issue_as_not_found
      runner = lambda do |args:, **_opts|
        joined = args.join(" ")
        if joined.include?("labels?per_page=100")
          next {success: true, stdout: "ace:tracked\n", stderr: "", exit_code: 0}
        elsif joined.include?("issues/42/labels")
          next {success: false, stdout: "", stderr: "gh: Not Found (404)", exit_code: 1}
        end
        flunk("Unexpected command: #{joined}")
      end

      assert_raises(Ace::Git::ProviderObjectNotFoundError) do
        build_provider(runner).add_issue_label(number: 42, label: "ace:tracked")
      end
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
