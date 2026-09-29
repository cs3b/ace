# frozen_string_literal: true

require "test_helper"

module Forgejo
  # Provider behaviors beyond the shared parity suite
  class ProviderTest < AceGitForgejoTestCase
    SERVER = Ace::Git::ResolvedServer.new(name: "forge", provider: :forgejo, url: "https://forge.example.com/owner/repo")
    VERSION_OK = {success: true, stdout: "fj v0.6.0\nCheck for a new version with `fj version --check`\n", stderr: "", exit_code: 0}.freeze

    def build_provider(runner)
      Ace::Git::Forgejo::Provider.new(server: SERVER, runner: runner)
    end

    def view(number, state, head_ref)
      <<~TEXT
        PR title #{number} ##{number}
        By lab-builder — #{state} — +3 -1
        From `owner/repo:#{head_ref}` into `main`
      TEXT
    end

    def test_pull_request_for_branch_prefers_newest_and_hydrates_evidence
      runner = scripted_runner(
        "fj version" => VERSION_OK,
        "fj -H https://forge.example.com --style minimal pr search --state all -r owner/repo" => {
          success: true, stdout: "2 pull requests\n#91: PR title 91 (by lab-builder)\n#90: PR title 90 (by lab-builder)\n", stderr: "", exit_code: 0
        },
        "fj -H https://forge.example.com --style minimal pr view owner/repo#91" => {
          success: true, stdout: view(91, "Open", "feature"), stderr: "", exit_code: 0
        },
        "fj -H https://forge.example.com --style minimal pr view owner/repo#91 commits" => {
          success: true, stdout: "commit #{'a' * 40} (+3, -1)\n", stderr: "", exit_code: 0
        }
      )

      pr = build_provider(runner).pull_request_for_branch(branch: "feature")
      assert_equal 91, pr.number
      assert_equal :open, pr.state
      assert_equal "a" * 40, pr.head_sha
      assert_equal "#{SERVER.url}/pulls/91", pr.url
      assert_equal SERVER.url, pr.base_repository_url
      assert_equal "https://forge.example.com/owner/repo", pr.head_repository_url
    end

    def test_pull_request_for_branch_returns_nil_when_no_branch_matches
      runner = scripted_runner(
        "fj version" => VERSION_OK,
        "fj -H https://forge.example.com --style minimal pr search --state all -r owner/repo" => {
          success: true, stdout: "1 pull requests\n#90: PR title 90 (by lab-builder)\n", stderr: "", exit_code: 0
        },
        "fj -H https://forge.example.com --style minimal pr view owner/repo#90" => {
          success: true, stdout: view(90, "Merged", "other-branch"), stderr: "", exit_code: 0
        },
        "fj -H https://forge.example.com --style minimal pr view owner/repo#90 commits" => {
          success: true, stdout: "commit #{'b' * 40}\n", stderr: "", exit_code: 0
        }
      )

      assert_nil build_provider(runner).pull_request_for_branch(branch: "feature")
    end

    def test_recent_pull_requests_caps_client_side_newest_first
      runner = scripted_runner(
        "fj version" => VERSION_OK,
        "fj -H https://forge.example.com --style minimal pr search --state all -r owner/repo" => {
          success: true, stdout: "3 pull requests\n#91: PR title 91 (by lab-builder)\n#90: PR title 90 (by lab-builder)\n#89: PR title 89 (by lab-builder)\n", stderr: "", exit_code: 0
        }
      )

      prs = build_provider(runner).recent_pull_requests(limit: 2)
      assert_equal [91, 90], prs.map(&:number)
      assert prs.all? { |pr| pr.base_repository_url == SERVER.url }
    end

    def test_selected_target_validated_from_server_url
      provider = build_provider(->(args:, timeout: nil, env: nil) { {success: true, stdout: "", stderr: "", exit_code: 0} })
      target = provider.send(:repository_target)
      assert_equal "forge.example.com", target.host
      assert_equal "owner/repo", target.repo
      assert_equal "owner/repo#25", target.qualified_ref(25)
      assert_equal "https://forge.example.com", target.host_url

      ported = Ace::Git::ResolvedServer.new(name: "p", provider: :forgejo, url: "https://forge.example.com:3443/o/r")
      target = Ace::Git::Forgejo::Provider.new(server: ported).send(:repository_target)
      assert_equal "forge.example.com:3443", target.authority
      assert_equal "https://forge.example.com:3443", target.host_url

      # `-H` preserves an explicit http authority; fj assumes HTTPS for a
      # bare host (observed v0.6.0), so the scheme must ride along.
      local = Ace::Git::ResolvedServer.new(name: "l", provider: :forgejo, url: "http://forge.internal:3000/o/r")
      target = Ace::Git::Forgejo::Provider.new(server: local).send(:repository_target)
      assert_equal "http://forge.internal:3000", target.host_url
    end

    def test_unsupported_url_scheme_is_configuration_failure
      weird = Ace::Git::ResolvedServer.new(name: "w", provider: :forgejo, url: "ftp://forge.example.com/o/r")
      provider = Ace::Git::Forgejo::Provider.new(server: weird, runner: ->(**_kw) { flunk("no subprocess") })
      error = assert_raises(Ace::Git::ConfigError) { provider.pull_request(number: 1) }
      assert_match(/scheme must be http or https/, error.message)
    end

    def test_malformed_server_url_is_configuration_failure
      broken = Ace::Git::ResolvedServer.new(name: "b", provider: :forgejo, url: "https://forge.example.com/just-owner")
      provider = Ace::Git::Forgejo::Provider.new(server: broken, runner: ->(**_kw) { flunk("no subprocess") })
      assert_raises(Ace::Git::ConfigError) { provider.pull_request(number: 1) }
    end

    def test_repository_evidence_url_falls_back_to_selected_target
      runner = scripted_runner(
        "fj version" => VERSION_OK,
        "fj -H https://forge.example.com --style minimal repo view owner/repo" => {
          success: true, stdout: "owner/repo\n> Sample repository\n", stderr: "", exit_code: 0
        }
      )
      repo = build_provider(runner).repository
      assert_equal "owner/repo", repo.full_name
      assert_equal SERVER.url, repo.url
    end

    def test_fork_pr_head_provenance_uses_server_host_root
      runner = scripted_runner(
        "fj version" => VERSION_OK,
        "fj -H https://forge.example.com --style minimal pr view owner/repo#25" => {
          success: true, stdout: <<~VIEW, stderr: "", exit_code: 0
            Ship it #25
            By forker — Open — +1 -0
            From `forker/other:feature` into `main`
          VIEW
        },
        "fj -H https://forge.example.com --style minimal pr view owner/repo#25 commits" => {
          success: true, stdout: "commit #{'c' * 40}\n", stderr: "", exit_code: 0
        }
      )

      pr = build_provider(runner).pull_request(number: 25)
      assert_equal "https://forge.example.com/forker/other", pr.head_repository_url
      assert_equal SERVER.url, pr.base_repository_url
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
