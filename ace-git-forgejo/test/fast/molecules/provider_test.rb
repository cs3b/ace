# frozen_string_literal: true

require "test_helper"

module Forgejo
  # Provider behaviors beyond the shared parity suite
  class ProviderTest < AceGitForgejoTestCase
    SERVER = Ace::Git::ResolvedServer.new(name: "forge", provider: :forgejo, url: "https://forge.example.com/owner/repo")

    def build_provider(runner)
      Ace::Git::Forgejo::Provider.new(server: SERVER, runner: runner)
    end

    def view(number, state, head_ref)
      <<~TEXT
        PR title #{number} ##{number}
        By lab-builder - #{state.capitalize} - +3 -1
        From `owner/repo:#{head_ref}` into `main`
      TEXT
    end

    def test_pull_request_for_branch_prefers_newest_and_hydrates_evidence
      runner = scripted_runner(
        "fj --style minimal pr search --state all" => {
          success: true, stdout: "2 pull requests\n#91: PR title 91 (by lab-builder)\n#90: PR title 90 (by lab-builder)\n", stderr: "", exit_code: 0
        },
        "fj --style minimal pr view 91" => {success: true, stdout: view(91, "open", "feature"), stderr: "", exit_code: 0},
        "fj --style minimal pr view 91 commits" => {success: true, stdout: "commit #{'a' * 40} (+3, -1)\n", stderr: "", exit_code: 0}
      )

      pr = build_provider(runner).pull_request_for_branch(branch: "feature")
      assert_equal 91, pr.number
      assert_equal :open, pr.state
      assert_equal "a" * 40, pr.head_sha
      assert_equal "#{SERVER.url}/pulls/91", pr.url
    end

    def test_pull_request_for_branch_returns_nil_when_no_branch_matches
      runner = scripted_runner(
        "fj --style minimal pr search --state all" => {
          success: true, stdout: "1 pull requests\n#90: PR title 90 (by lab-builder)\n", stderr: "", exit_code: 0
        },
        "fj --style minimal pr view 90" => {success: true, stdout: view(90, "merged", "other-branch"), stderr: "", exit_code: 0}
      )

      assert_nil build_provider(runner).pull_request_for_branch(branch: "feature")
    end

    def test_recent_pull_requests_caps_client_side_newest_first
      runner = scripted_runner(
        "fj --style minimal pr search --state all" => {
          success: true, stdout: "3 pull requests\n#91: PR title 91 (by lab-builder)\n#90: PR title 90 (by lab-builder)\n#89: PR title 89 (by lab-builder)\n", stderr: "", exit_code: 0
        }
      )

      prs = build_provider(runner).recent_pull_requests(limit: 2)
      assert_equal [91, 90], prs.map(&:number)
    end

    def test_server_host_extracted_from_server_url
      provider = build_provider(->(args:, timeout: nil, env: nil) { {success: true, stdout: "", stderr: "", exit_code: 0} })
      assert_equal "forge.example.com", provider.send(:server_host)
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
