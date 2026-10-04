# frozen_string_literal: true

require "test_helper"

module Forgejo
  class PullRequestApiTest < AceGitForgejoTestCase
    SERVER = Ace::Git::ResolvedServer.new(name: "forge", provider: :forgejo, url: "https://forge.example.com/owner/repo")
    API = "https://forge.example.com/api/v1/repos/owner/repo"
    VERSION_ROUTE = "https://forge.example.com/api/v1/version"

    def build_api(routes)
      Ace::Git::Forgejo::PullRequestApi.new(server: SERVER, timeout: 5, runner: router(routes))
    end

    def test_version_gate_accepts_documented_release_strings
      ["8.0.5", "v12.0.1", "8.0.3+gitea-1.22.0", "16.0.5+gitea"].each do |version|
        api = build_api("version" => {status: 200, body: {"version" => version}.to_json})
        api.ensure_version_supported!
        assert api.instance_variable_get(:@version_supported)
      end
    end

    def test_version_gate_refuses_below_floor
      api = build_api("version" => {status: 200, body: {"version" => "6.9.2+gitea"}.to_json})
      error = assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
        api.ensure_version_supported!
      end
      assert_match(/PR delivery requires/, error.message)
    end

    def test_version_gate_refuses_unparseable_version
      api = build_api("version" => {status: 200, body: {"version" => "dev-snapshot"}.to_json})
      error = assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
        api.ensure_version_supported!
      end
      assert_match(/not a comparable release/, error.message)
    end

    def test_version_gate_fails_closed_without_version_endpoint
      api = build_api("version" => {status: 404, body: {"message" => "not found"}.to_json})
      error = assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
        api.ensure_version_supported!
      end
      assert_match(/cannot prove the PR delivery capability floor/, error.message)
    end

    def test_version_gate_classifies_authentication_separately
      api = build_api("version" => {status: 401, body: {"message" => "token required"}.to_json})
      error = assert_raises(Ace::Git::ProviderAuthenticationError) do
        api.ensure_version_supported!
      end
      assert_match(/authenticate with fj first/, error.message)
    end

    def test_version_probe_hits_the_server_level_route
      api = build_api("version" => {status: 200, body: {"version" => "8.0.5"}.to_json})
      api.ensure_version_supported!
      # The probe must not be repository-scoped; one call memoizes the gate.
      api.ensure_version_supported!
      assert_equal 1, calls.length
      assert_equal VERSION_ROUTE, calls.first[2]
    end

    def test_pull_request_read_validates_schema
      payload = pr_payload
      api = build_api("pulls/25" => {status: 200, body: payload.to_json})
      assert_equal 25, api.pull_request(25)["number"]
    end

    def test_pull_request_read_refuses_missing_required_fields
      payload = pr_payload.except("draft")
      api = build_api("pulls/25" => {status: 200, body: payload.to_json})
      error = assert_raises(Ace::Git::ProviderMalformedOutputError) { api.pull_request(25) }
      assert_match(/Malformed Forgejo pull request payload/, error.message)

      payload = pr_payload
      payload["head"]["sha"] = "tooshort"
      api = build_api("pulls/25" => {status: 200, body: payload.to_json})
      assert_raises(Ace::Git::ProviderMalformedOutputError) { api.pull_request(25) }
    end

    def test_pull_request_read_refuses_misrouted_number
      api = build_api("pulls/25" => {status: 200, body: pr_payload(number: 31).to_json})
      error = assert_raises(Ace::Git::ProviderIdentityMismatchError) { api.pull_request(25) }
      assert_match(/misrouted/, error.message)
    end

    def test_pull_request_read_classifies_status_failures
      api = build_api("pulls/25" => {status: 404, body: {"message" => "not found"}.to_json})
      assert_raises(Ace::Git::ProviderObjectNotFoundError) { api.pull_request(25) }

      api = build_api("pulls/25" => {status: 403, body: {"message" => "forbidden"}.to_json})
      assert_raises(Ace::Git::ProviderAuthenticationError) { api.pull_request(25) }

      api = build_api("pulls/25" => {status: 502, body: "".to_s})
      assert_raises(Ace::Git::ProviderUnreachableError) { api.pull_request(25) }
    end

    def test_open_pull_requests_paginates_and_validates
      # Page 2 repeats page 1 in this fake; the client stops on the empty
      # follow-up page, so the route serves content once, then nothing.
      api = build_api("pulls?state=open" => {status: 200, queue: [[pr_payload, pr_payload(number: 26)].to_json, [].to_json]})
      numbers = api.open_pull_requests.map { |payload| payload["number"] }
      assert_equal [25, 26], numbers
    end

    def test_create_sends_documented_form_and_surfaces_refusals
      api = build_api("pulls" => {status: 201, body: pr_payload.to_json})
      outcome = api.create_pull_request(head: "forker:feature", base: "main", title: "WIP: Ship it", body: "desc")
      assert_equal 201, outcome.status
      assert_equal 25, outcome.payload["number"]
      assert_equal "POST", calls.find { |c| c[2] == "#{API}/pulls" }[1]
      sent = calls.find { |c| c[2] == "#{API}/pulls" }[3]
      assert_equal({"title" => "WIP: Ship it", "base" => "main", "head" => "forker:feature", "body" => "desc"}, sent)

      api = build_api("pulls" => {status: 409, body: {"message" => "pull request already exists"}.to_json})
      outcome = api.create_pull_request(head: "feature", base: "main", title: "Ship it")
      assert_equal 409, outcome.status
      assert_match(/already exists/, outcome.message)
    end

    def test_create_transport_failure_is_unknown_outcome
      api = build_api("pulls" => -> { raise IOError, "socket closed" })
      error = assert_raises(Ace::Git::ProviderUnknownOutcomeError) do
        api.create_pull_request(head: "feature", base: "main", title: "Ship it")
      end
      assert_match(/outcome unknown/, error.message)
    end

    def test_edit_sends_only_provided_fields
      api = build_api("pulls/25" => {status: 200, body: ""})
      api.edit_pull_request(25, title: "Ship it")
      assert_equal({"title" => "Ship it"}, sent_patch_body)

      api = build_api("pulls/25" => {status: 200, body: ""})
      api.edit_pull_request(25, title: "T", body: "B")
      assert_equal({"title" => "T", "body" => "B"}, calls.last[3])
    end

    def test_merge_sends_documented_atomic_form
      api = build_api("pulls/25/merge" => {status: 200, body: ""})
      outcome = api.merge_pull_request(25, do_method: "squash", head_commit_id: "a" * 40)
      assert_equal 200, outcome.status
      sent = calls.find { |c| c[2] == "#{API}/pulls/25/merge" }[3]
      assert_equal({"Do" => "squash", "head_commit_id" => "a" * 40}, sent)

      api = build_api("pulls/25/merge" => {status: 409, body: {"message" => "Merge: head out of date"}.to_json})
      outcome = api.merge_pull_request(25, do_method: "merge", head_commit_id: "a" * 40)
      assert_equal 409, outcome.status
      assert_match(/head out of date/, outcome.message)
    end

    def test_mutation_server_errors_stay_unknown_outcomes
      api = build_api("pulls/25/merge" => {status: 500, body: {"message" => "boom"}.to_json})
      error = assert_raises(Ace::Git::ProviderUnknownOutcomeError) do
        api.merge_pull_request(25, do_method: "merge", head_commit_id: "a" * 40)
      end
      assert_match(/HTTP 500; reconcile before repeating/, error.message)
    end

    private

    def sent_patch_body
      call = calls.find { |c| c[1] == "PATCH" && c[2] == "#{API}/pulls/25" }
      call && call[3]
    end

    def calls
      @calls ||= []
    end

    def router(routes)
      lambda do |args:, **|
        calls << args
        spec = routes.find { |suffix, _| args[2].to_s.include?(suffix) }&.last
        flunk("Unexpected route: #{args.join(' ')}") unless spec
        if spec.is_a?(Proc)
          spec.call
        else
          status = spec.fetch(:status, 200)
          body = if spec.key?(:queue)
            q = spec[:queue]
            q.length > 1 ? q.shift : q.first
          elsif spec.key?(:body)
            spec[:body]
          else
            ""
          end
          {success: (200..299).cover?(status), status: status,
           stdout: body, stderr: "", exit_code: (200..299).cover?(status) ? 0 : 1}
        end
      end
    end

    def pr_payload(number: 25)
      {
        "number" => number,
        "title" => "Ship it",
        "body" => "desc",
        "state" => "open",
        "draft" => false,
        "merged" => false,
        "merged_at" => nil,
        "merge_commit_sha" => nil,
        "user" => {"login" => "lab-builder"},
        "head" => {"label" => "owner/repo:feature", "ref" => "feature", "sha" => "a" * 40,
                   "repo" => {"full_name" => "owner/repo"}},
        "base" => {"label" => "main", "ref" => "main", "sha" => "b" * 40,
                   "repo" => {"full_name" => "owner/repo"}}
      }
    end
  end
end
