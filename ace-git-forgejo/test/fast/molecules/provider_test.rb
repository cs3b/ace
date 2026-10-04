# frozen_string_literal: true

require "test_helper"

module Forgejo
  # Provider behaviors beyond the shared parity suites
  class ProviderTest < AceGitForgejoTestCase
    SERVER = Ace::Git::ResolvedServer.new(name: "forge", provider: :forgejo, url: "https://forge.example.com/owner/repo")
    VERSION_OK = {success: true, stdout: "fj v0.6.0\nCheck for a new version with `fj version --check`\n", stderr: "", exit_code: 0}.freeze
    API = "https://forge.example.com/api/v1/repos/owner/repo"
    SHA = "a" * 40

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

    # ---- Authoritative API pull request read ----

    def test_pull_request_hydrates_draft_and_merge_evidence_from_api
      runner = api_runner(
        "pulls/25" => {status: 200, payload: pr_payload(25,
          state: "closed", merged: true, draft: false, merge_commit_sha: "f" * 40)}
      )
      pr = build_provider(runner).pull_request(number: 25)
      assert_equal :merged, pr.state
      assert_equal false, pr.draft
      assert_equal "f" * 40, pr.merge_commit_sha
      assert_equal SERVER.url, pr.head_repository_url
    end

    def test_pull_request_fork_provenance_uses_server_host_root
      payload = pr_payload(25, state: "open", merged: false, draft: true)
      payload["head"] = head_branch("feature", SHA, "forker/other")
      runner = api_runner("pulls/25" => {status: 200, payload: payload})
      pr = build_provider(runner).pull_request(number: 25)
      assert_equal "https://forge.example.com/forker/other", pr.head_repository_url
      assert_equal SERVER.url, pr.base_repository_url
      assert_equal true, pr.draft
    end

    def test_pull_request_misrouted_base_repository_refuses
      payload = pr_payload(25, state: "open", merged: false, draft: false)
      payload["base"] = head_branch("main", "b" * 40, "someone/elsewhere")
      runner = api_runner("pulls/25" => {status: 200, payload: payload})
      error = assert_raises(Ace::Git::ProviderIdentityMismatchError) do
        build_provider(runner).pull_request(number: 25)
      end
      assert_match(/misrouted evidence/, error.message)
    end

    def test_pull_request_deleted_fork_reports_honest_absence
      payload = pr_payload(25, state: "open", merged: false, draft: false)
      payload["head"] = head_branch("feature", SHA, nil)
      runner = api_runner("pulls/25" => {status: 200, payload: payload})
      pr = build_provider(runner).pull_request(number: 25)
      assert_nil pr.head_repository_url
    end

    # ---- Lifecycle refusals before any mutation ----

    def test_create_rejects_stale_head_before_any_mutation
      posts = []
      runner = api_runner_with(posts,
        "pulls?state=open" => {status: 200, queue: [[pr_payload(25, state: "open", merged: false, draft: true)].to_json, "[]"]}
      )
      error = assert_raises(Ace::Git::ProviderExpectedHeadConflictError) do
        build_provider(runner).create_pull_request(
          head_ref: "feature", base_ref: "main", expected_head: "b" * 40,
          title: "Ship it", head_repository_url: nil, draft: true
        )
      end
      assert_match(/head changed/, error.message)
      assert_empty posts
    end

    def test_create_conflicts_when_existing_draft_state_disagrees
      runner = api_runner(
        "pulls?state=open" => {status: 200, queue: [[pr_payload(25, state: "open", merged: false, draft: false)].to_json, "[]"]}
      )
      error = assert_raises(Ace::Git::ProviderConflictingMatchesError) do
        build_provider(runner).create_pull_request(
          head_ref: "feature", base_ref: "main", expected_head: SHA,
          title: "Ship it", head_repository_url: nil, draft: true
        )
      end
      assert_match(/draft/, error.message)
    end

    def test_create_refuses_wip_title_with_draft_false_before_mutation
      posts = []
      runner = api_runner_with(posts, "pulls?state=open" => {status: 200, payload: []})
      error = assert_raises(Ace::Git::ProviderConflictingMatchesError) do
        build_provider(runner).create_pull_request(
          head_ref: "feature", base_ref: "main", expected_head: SHA,
          title: "WIP: Ship it", head_repository_url: nil, draft: false
        )
      end
      assert_match(/draft:false conflicts/i, error.message)
      assert_empty posts
    end

    def test_ready_refuses_unknown_wip_prefix_before_mutation
      runner = api_runner("pulls/25" => {status: 200, payload: pr_payload(25,
        state: "open", merged: false, draft: true, title: "DRAFT: Ship it")})
      error = assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
        build_provider(runner).ready_pull_request(number: 25, expected_head: SHA)
      end
      assert_match(/no known WIP prefix/, error.message)
    end

    def test_ready_reports_unknown_when_head_moves_during_transition
      reads = 0
      runner = lambda do |args:, **|
        path = args[2].to_s
        if path == "https://forge.example.com/api/v1/version"
          ok_raw(200, {"version" => "8.0.5"}.to_json)
        elsif args[1] == "PATCH"
          reads = 2
          {success: true, status: 200, stdout: "", stderr: "", exit_code: 0}
        elsif path == "#{API}/pulls/25"
          reads += 1
          payload = if reads > 1
            pr_payload(25, state: "open", merged: false, draft: false, head_sha: "c" * 40, title: "Ship it")
          else
            pr_payload(25, state: "open", merged: false, draft: true, title: "WIP: Ship it")
          end
          ok(payload)
        else
          flunk("Unexpected #{args[1]} #{path}")
        end
      end
      error = assert_raises(Ace::Git::ProviderUnknownOutcomeError) do
        build_provider(runner).ready_pull_request(number: 25, expected_head: SHA)
      end
      assert_match(/head moved during mutation/, error.message)
    end

    # ---- Version capability gate ----

    def test_lifecycle_mutations_fail_closed_below_supported_version
      posts = []
      runner = lambda do |args:, **|
        path = args[2].to_s
        if path == "https://forge.example.com/api/v1/version"
          ok_raw(200, {"version" => "6.9.2+gitea-6.9.2"}.to_json)
        elsif path.include?("/pulls?state=open")
          ok_raw(200, [].to_json)
        elsif args[1] == "POST"
          posts << args
          ok_raw(201, pr_payload(25, state: "open", merged: false, draft: true).to_json)
        else
          flunk("Unexpected #{args[1]} #{path}")
        end
      end
      error = assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
        build_provider(runner).create_pull_request(
          head_ref: "feature", base_ref: "main", expected_head: SHA,
          title: "Ship it", head_repository_url: nil, draft: true
        )
      end
      assert_match(/PR delivery requires/, error.message)
      assert_empty posts
    end

    def test_lifecycle_mutations_fail_closed_without_provable_version
      runner = lambda do |args:, **|
        path = args[2].to_s
        if path == "https://forge.example.com/api/v1/version"
          {success: false, status: 404, stdout: "", stderr: "", exit_code: 1}
        elsif path == "#{API}/pulls/25"
          ok(pr_payload(25, state: "open", merged: false, draft: true, title: "WIP: Ship it"))
        else
          flunk("no mutation may follow a failed version probe: #{args[1]} #{path}")
        end
      end
      error = assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
        build_provider(runner).ready_pull_request(number: 25, expected_head: SHA)
      end
      assert_match(/cannot prove the PR delivery capability floor/, error.message)
    end

    # ---- Merge classification ----

    def test_merge_transient_mergeable_check_is_retryable_unreachable
      runner = lambda do |args:, **|
        path = args[2].to_s
        case path
        when "https://forge.example.com/api/v1/version"
          ok_raw(200, {"version" => "8.0.3"}.to_json)
        when "#{API}/pulls/25"
          ok(pr_payload(25, state: "open", merged: false, draft: false))
        when "#{API}/pulls/25/merge"
          {success: false, status: 405, stdout: {message: "Please try again later"}.to_json,
           stderr: "", exit_code: 1}
        else
          flunk("Unexpected #{args[1]} #{path}")
        end
      end
      error = assert_raises(Ace::Git::ProviderUnreachableError) do
        build_provider(runner).merge_pull_request(number: 25, expected_head: SHA, method: :squash)
      end
      assert_match(/still computing/, error.message)
      assert_match(/may be repeated/, error.message)
    end

    def test_merge_disabled_method_is_capability_refusal
      runner = lambda do |args:, **|
        path = args[2].to_s
        case path
        when "https://forge.example.com/api/v1/version"
          ok_raw(200, {"version" => "8.0.5"}.to_json)
        when "#{API}/pulls/25"
          ok(pr_payload(25, state: "open", merged: false, draft: false))
        when "#{API}/pulls/25/merge"
          {success: false, status: 405,
           stdout: {message: "Invalid merge style: squash is not an allowed merge style for this repository"}.to_json,
           stderr: "", exit_code: 1}
        else
          flunk("Unexpected #{args[1]} #{path}")
        end
      end
      error = assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
        build_provider(runner).merge_pull_request(number: 25, expected_head: SHA, method: :squash)
      end
      assert_match(/refused to merge/i, error.message)
    end

    def test_merge_content_conflict_stays_unknown_outcome
      runner = lambda do |args:, **|
        path = args[2].to_s
        case path
        when "https://forge.example.com/api/v1/version"
          ok_raw(200, {"version" => "8.0.5"}.to_json)
        when "#{API}/pulls/25"
          ok(pr_payload(25, state: "open", merged: false, draft: false))
        when "#{API}/pulls/25/merge"
          {success: false, status: 409,
           stdout: {message: "merge conflicts", "ConflictFiles" => ["x.rb"]}.to_json, stderr: "", exit_code: 1}
        else
          flunk("Unexpected #{args[1]} #{path}")
        end
      end
      error = assert_raises(Ace::Git::ProviderUnknownOutcomeError) do
        build_provider(runner).merge_pull_request(number: 25, expected_head: SHA, method: :merge)
      end
      assert_match(/reconcile before repeating/, error.message)
    end

    def test_merge_success_without_merge_commit_proof_is_unknown
      reads = 0
      runner = lambda do |args:, **|
        path = args[2].to_s
        case path
        when "https://forge.example.com/api/v1/version"
          ok_raw(200, {"version" => "8.0.5"}.to_json)
        when "#{API}/pulls/25"
          reads += 1
          if reads > 1
            ok(pr_payload(25, state: "closed", merged: true, draft: false, merge_commit_sha: nil))
          else
            ok(pr_payload(25, state: "open", merged: false, draft: false))
          end
        when "#{API}/pulls/25/merge"
          ok_raw(200, "")
        else
          flunk("Unexpected #{args[1]} #{path}")
        end
      end
      error = assert_raises(Ace::Git::ProviderUnknownOutcomeError) do
        build_provider(runner).merge_pull_request(number: 25, expected_head: SHA, method: :merge)
      end
      assert_match(/does not prove merged state/, error.message)
    end

    private

    def scripted_runner(responses)
      lambda do |args:, timeout: nil, env: nil|
        response = responses.fetch(args.join(" ")) { flunk("Unexpected command: #{args.join(' ')}") }
        response.is_a?(Array) ? {success: false, stdout: "", stderr: response[0], exit_code: response[1]} : response
      end
    end

    # API runner that records POST/PATCH sends into `sends` so tests can
    # assert that a refusal happened before any mutation.
    def api_runner_with(sends, routes)
      lambda do |args:, **|
        sends << args if %w[POST PATCH].include?(args[1].to_s)
        respond_api(args, routes)
      end
    end

    def api_runner(routes)
      api_runner_with([], routes)
    end

    def respond_api(args, routes)
      method = args[1]
      path = args[2].to_s
      route = routes.find { |suffix, _| path.include?(suffix) }
      flunk("Unexpected API route: #{method} #{path}") unless route

      spec = route[1]
      body = if spec.key?(:queue)
        q = spec[:queue]
        q.length > 1 ? q.shift : q.first
      elsif spec.key?(:body)
        spec[:body]
      else
        spec[:payload].to_json
      end
      ok_raw(spec.fetch(:status, 200), body)
    end

    def ok_raw(status, body)
      {success: (200..299).cover?(status), status: status, stdout: body, stderr: "",
       exit_code: (200..299).cover?(status) ? 0 : 1}
    end

    def ok(payload)
      ok_raw(200, payload.to_json)
    end

    def head_branch(ref, sha, full_name)
      repo = full_name ? {"full_name" => full_name} : nil
      {"label" => "#{full_name || "owner/repo"}:#{ref}", "ref" => ref, "sha" => sha, "repo" => repo}
    end

    def pr_payload(number, state:, merged:, draft:, title: "Ship it", merge_commit_sha: nil, head_sha: SHA)
      {
        "number" => number,
        "title" => title,
        "body" => "Ship the thing",
        "state" => state,
        "draft" => draft,
        "merged" => merged,
        "merged_at" => merged ? "2026-10-04T12:00:00Z" : nil,
        "merge_commit_sha" => merge_commit_sha,
        "user" => {"login" => "lab-builder"},
        "head" => head_branch("feature", head_sha, "owner/repo"),
        "base" => head_branch("main", "b" * 40, "owner/repo")
      }
    end
  end
end
