# frozen_string_literal: true

require "test_helper"

# Provider-contract parity suite for the Forgejo provider.
# Shares identical assertions with ace-git-github via
# Ace::TestSupport::ProviderContract. Pull request identity reads ride the
# documented Forgejo API v1 (`forgejo-http` transport, selected-repository
# bound); `fj` fixtures are minimal-style and `-H <authority>` bound.
class ForgejoProviderContractTest < AceGitForgejoTestCase
  include Ace::TestSupport::ProviderContract

  SERVER = Ace::Git::ResolvedServer.new(name: "forge-server", provider: :forgejo, url: "https://forgejo.example.com/owner/repo")
  HOST = "forgejo.example.com"
  API = "https://forgejo.example.com/api/v1/repos/owner/repo"

  def build_provider(runner)
    Ace::Git::Forgejo::Provider.new(server: SERVER, runner: runner)
  end

  def ok_runner
    @ok_runner ||= api_and_fj_runner(
      "pulls/25" => {status: 200, payload: pr25_payload},
      "fj version" => version_ok,
      "fj auth list" => {success: true, stdout: "forgejo.example.com\n", stderr: "", exit_code: 0},
      "fj -H https://forgejo.example.com --style minimal pr view owner/repo#25" => {success: true, stdout: pr25_view, stderr: "", exit_code: 0},
      "fj -H https://forgejo.example.com --style minimal pr view owner/repo#25 commits" => {
        success: true, stdout: "commit fc14c43d3660ac6c133959a6dec29603413f0e8a (+252, -8)\nAuthor: Lab Builder <lab-builder@lab.invalid>\n", stderr: "", exit_code: 0
      },
      "fj -H https://forgejo.example.com --style minimal pr search --state all -r owner/repo" => {
        success: true, stdout: "2 pull requests\n#31: Wire status to providers (by lab-builder)\n#25: Ship the provider contract (by lab-builder)\n", stderr: "", exit_code: 0
      },
      "fj -H https://forgejo.example.com --style minimal pr view owner/repo#31" => {success: true, stdout: pr31_view, stderr: "", exit_code: 0},
      "fj -H https://forgejo.example.com --style minimal pr view owner/repo#31 commits" => {
        success: true, stdout: "commit a1b2c3d4e5f60718293a4b5c6d7e8f9012345678 (+12, -2)\nAuthor: Lab Builder <lab-builder@lab.invalid>\n", stderr: "", exit_code: 0
      },
      "fj -H https://forgejo.example.com pr view owner/repo#25 diff" => {
        success: true, stdout: "diff --git a/lib/x.rb b/lib/x.rb\n+new line\n", stderr: "", exit_code: 0
      },
      "fj -H https://forgejo.example.com --style minimal issue view owner/repo#9" => {success: true, stdout: issue9_view, stderr: "", exit_code: 0},
      "fj -H https://forgejo.example.com --style minimal actions tasks -r owner/repo" => {
        success: true, stdout: "1 tasks\n#83 (fc14c43d3660ac6c133959a6dec29603413f0e8a) success test-suite 23s (push): subject\n", stderr: "", exit_code: 0
      },
      "fj -H https://forgejo.example.com --style minimal repo view owner/repo" => {
        success: true, stdout: "owner/repo\n> Sample repository\nView online at https://forgejo.example.com/owner/repo\n", stderr: "", exit_code: 0
      }
    )
  end

  def version_fail_runner
    scripted_runner("fj version" => ["fj: command not found", 127])
  end

  # The shared EXPECTED_REPO pins a historical forge.example.com URL that a
  # selected-repository bound provider must not echo: real `fj repo view`
  # reports the selected host (observed), and returned URL evidence is
  # validated against the selection. Same fields, forge-consistent URL.
  def test_contract_repository_evidence_matches_normalized_shape
    repo = build_provider(ok_runner).repository
    assert_instance_of Ace::Git::ProviderRepository, repo
    assert_equal EXPECTED_REPO[:server_name], repo.server_name
    assert_equal EXPECTED_REPO[:full_name], repo.full_name
    assert_equal SERVER.url, repo.url
  end

  def auth_fail_runner
    scripted_runner(
      "fj version" => version_ok,
      "fj auth list" => {success: true, stdout: "other-host.example.com\n", stderr: "", exit_code: 0}
    )
  end

  def not_found_runner
    api_runner("pulls/999" => {status: 404, payload: {"message" => "pull request does not exist"}})
  end

  def malformed_runner
    api_runner("pulls/25" => {status: 200, body: "unexpected output shape"})
  end

  def unreachable_runner
    api_runner("pulls/25" => {status: 502, payload: {"message" => "upstream failure"}})
  end

  private

  # Route `forgejo-http` API exchanges by suffix and `fj` commands by their
  # full argv; each API route serves one scripted status/payload.
  def api_and_fj_runner(routes)
    fj_responses = routes.except("pulls/25")
    api_route = routes["pulls/25"]
    lambda do |args:, **|
      if args.first == "forgejo-http"
        respond_api(args, "pulls/25" => api_route)
      else
        fj_responses.fetch(args.join(" ")) { flunk("Unexpected command in test: #{args.join(' ')}") }
      end
    end
  end

  # API-only runner: every exchange is routed by the path suffix.
  def api_runner(routes)
    lambda do |args:, **|
      flunk("Unexpected non-API command: #{args.join(' ')}") unless args.first == "forgejo-http"
      respond_api(args, routes)
    end
  end

  def respond_api(args, routes)
    method = args[1]
    path = args[2].to_s
    route = routes.find { |suffix, _| path.end_with?(suffix) }
    flunk("Unexpected API route: #{method} #{path}") unless route

    spec = route[1]
    status = spec.is_a?(Hash) ? spec.fetch(:status, 200) : spec
    body = spec.is_a?(Hash) && spec.key?(:body) ? spec[:body] : JSON.generate(spec.is_a?(Hash) ? spec[:payload] : {})
    {success: (200..299).cover?(status), status: status, stdout: body, stderr: "", exit_code: (200..299).cover?(status) ? 0 : 1}
  end

  def version_ok
    {success: true, stdout: "fj v0.6.0\nCheck for a new version with `fj version --check`\n", stderr: "", exit_code: 0}
  end

  def pr25_payload
    {
      "number" => 25,
      "title" => "Ship the provider contract",
      "body" => "body text",
      "state" => "closed",
      "draft" => false,
      "merged" => true,
      "merged_at" => "2026-09-30T10:00:00Z",
      "merge_commit_sha" => "c" * 40,
      "user" => {"login" => "lab-builder"},
      "head" => {"label" => "owner/repo:lab/W675-ace", "ref" => "lab/W675-ace",
                 "sha" => "fc14c43d3660ac6c133959a6dec29603413f0e8a",
                 "repo" => {"full_name" => "owner/repo"}},
      "base" => {"label" => "main", "ref" => "main", "sha" => "b" * 40,
                 "repo" => {"full_name" => "owner/repo"}}
    }
  end

  def pr25_view
    <<~TEXT
      Ship the provider contract #25
      By lab-builder — Merged — +252 -8
      From `owner/repo:lab/W675-ace` into `main`
    TEXT
  end

  def pr31_view
    <<~TEXT
      Wire status to providers #31
      By lab-builder — Open — +12 -2
      From `owner/repo:lab/W676-ace` into `main`
    TEXT
  end

  def issue9_view
    <<~TEXT
      Broken diff on detached HEAD #9
      By lab-admin — Open — +0 -0
    TEXT
  end
end
