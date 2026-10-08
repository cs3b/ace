# frozen_string_literal: true

require "test_helper"

# PR-lifecycle contract parity suite for the Forgejo provider.
# Shares identical assertions with ace-git-github via
# Ace::TestSupport::PullRequestLifecycleContract. Fixtures serve the
# documented Forgejo API v1 shapes on the selected repository transport.
class ForgejoProviderPullRequestLifecycleContractTest < AceGitForgejoTestCase
  include Ace::TestSupport::PullRequestLifecycleContract

  CONTRACT = Ace::TestSupport::PullRequestLifecycleContract
  SERVER = Ace::Git::ResolvedServer.new(name: "forge-server", provider: :forgejo, url: CONTRACT::SERVER_URL)
  SHA = CONTRACT::HEAD_SHA
  REPO = "owner/repo"
  API = "https://forge.example.com/api/v1/repos/owner/repo"

  def build_provider(runner)
    Ace::Git::Forgejo::Provider.new(server: SERVER, runner: runner)
  end

  # The documented API v1 surface: server-enforced expected-head merge
  # (`head_commit_id`) and WIP-title draft transitions.
  def ready_supported?
    true
  end

  def merge_supported?
    true
  end

  def lifecycle_runner(scenario)
    lambda do |args:, **|
      method = args[1]
      path = args[2].to_s
      body = args[3]
      respond_to_lifecycle(method, path, body, scenario)
    end
  end

  # Route one scripted API exchange per scenario.
  def respond_to_lifecycle(method, path, body, scenario)
    return ok(repository_payload(REPO)) if method == "GET" && path == API
    if method == "GET" && path == "https://forge.example.com/api/v1/version"
      return ok({"version" => "8.0.5"})
    end
    if method == "GET" && path.start_with?("#{API}/pulls?state=open")
      page = path[/page=(\d+)/, 1].to_i
      numbers = if page > 1
        []
      elsif scenario == :find_multi
        [25, 26]
      elsif [:create_new, :create_unknown].include?(scenario)
        []
      else
        [25]
      end
      return ok(numbers.map { |n| pr_payload(n, draft: true) })
    end
    if method == "GET" && path == "#{API}/pulls/25"
      return ok(merged_payload) if @merged
      return ok(pr_payload(25, draft: !@ready_edited))
    end
    if method == "GET" && path == "#{API}/pulls/26"
      return ok(pr_payload(26, draft: true))
    end
    if method == "POST" && path == "#{API}/pulls"
      raise IOError, "dial tcp: connection refused" if scenario == :create_unknown

      assert_equal "WIP: Ship it", body["title"], "a draft create must ride the WIP title convention"
      assert_equal "feature/x", body["head"]
      assert_equal "main", body["base"]
      return created(pr_payload(25, draft: true))
    end
    if method == "PATCH" && path == "#{API}/pulls/25"
      if scenario == :ready_ok
        assert_equal "Ship it", body["title"], "ready must strip the WIP prefix"
        @ready_edited = true
      else
        assert_equal "WIP: New title", body["title"], "update must preserve draft state"
      end
      return ok("")
    end
    if method == "POST" && path == "#{API}/pulls/25/merge"
      assert_equal CONTRACT::HEAD_SHA, body["head_commit_id"],
        "merge must send the expected head in the server-enforced field"
      assert_equal "squash", body["Do"]
      if scenario == :merge_stale
        return conflict("Merge: head out of date")
      end

      @merged = true
      return ok("")
    end
    flunk("Unexpected #{method} #{path} in lifecycle scenario #{scenario}")
  end

  # ---- Forgejo-specific lifecycle behavior beyond the shared suite ----

  def test_lifecycle_create_refuses_cross_host_head_before_any_mutation
    calls = []
    runner = lambda do |args:, **|
      calls << args
      method = args[1]
      path = args[2].to_s
      if method == "GET" && path == "#{API}/pulls?state=open&page=1&limit=50"
        ok("[]")
      else
        flunk("no request may follow the cross-host refusal: #{method} #{path}")
      end
    end
    error = assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
      build_provider(runner).create_pull_request(
        head_repository_url: "#{CONTRACT::SERVER_URL.gsub("forge.example.com", "other.example.com")}/fork",
        head_ref: "feature/x", base_ref: "main", expected_head: SHA, title: "Ship it"
      )
    end
    assert_match(/cannot target head repository/i, error.message)
    assert_equal 1, calls.length
  end

  def test_lifecycle_create_encodes_same_server_fork_head
    fork_url = "https://forge.example.com/forker/other"
    forked = pr_payload(25, draft: true).merge("head" => pr_branch("feature/x", SHA, "forker/other"))
    runner = lambda do |args:, **|
      method = args[1]
      path = args[2].to_s
      body = args[3]
      if method == "GET" && path == "https://forge.example.com/api/v1/version"
        ok({"version" => "8.0.5"})
      elsif method == "GET" && path.include?("/pulls?state=open")
        ok([])
      elsif method == "GET" && path == API
        ok(repository_payload(REPO))
      elsif method == "GET" && path.include?("/forks?")
        ok(path.include?("page=1&") ? [repository_payload("forker/other")] : [])
      elsif method == "POST" && path == "#{API}/pulls"
        assert_equal "forker:feature/x", body["head"], "fork heads must use the documented owner:branch form"
        created(forked)
      elsif method == "GET" && path == "#{API}/pulls/25"
        ok(forked)
      else
        flunk("Unexpected #{method} #{path}")
      end
    end
    receipt = build_provider(runner).create_pull_request(
      head_repository_url: fork_url, head_ref: "feature/x", base_ref: "main",
      expected_head: SHA, title: "Ship it"
    )
    assert_equal :created, receipt.idempotency
    assert_equal fork_url, receipt.pull_request.head_repository_url
    assert_equal SERVER.url, receipt.pull_request.base_repository_url
  end

  def test_create_rejects_same_owner_wrong_repository_before_post
    posts = 0
    runner = lambda do |args:, **|
      method, path = args[1], args[2].to_s
      if method == "POST"
        posts += 1
        created(pr_payload(25, draft: true))
      elsif path.end_with?("/version")
        ok({"version" => "8.0.5"})
      elsif path.include?("/pulls?state=open")
        ok([])
      elsif path.end_with?("/pulls/25")
        ok(pr_payload(25, draft: true))
      elsif path == API
        ok(repository_payload(REPO))
      else
        flunk("Unexpected #{method} #{path}")
      end
    end
    assert_raises(Ace::Git::ProviderIdentityMismatchError) do
      build_provider(runner).create_pull_request(
        head_repository_url: "https://forge.example.com/owner/unrelated", head_ref: "feature/x",
        base_ref: "main", expected_head: SHA, title: "Ship it"
      )
    end
    assert_equal 0, posts
  end

  def test_create_read_failure_after_201_is_unknown_without_replay
    posts = 0
    runner = lambda do |args:, **|
      method, path = args[1], args[2].to_s
      if method == "POST"
        posts += 1
        created(pr_payload(25, draft: true))
      elsif path.end_with?("/version")
        ok({"version" => "8.0.5"})
      elsif path.include?("/pulls?state=open")
        ok([])
      elsif path.end_with?("/pulls/25")
        raise IOError, "read failed"
      elsif path == API
        ok(repository_payload(REPO))
      else
        flunk("Unexpected #{method} #{path}")
      end
    end
    error = assert_raises(Ace::Git::ProviderUnknownOutcomeError) do
      build_provider(runner).create_pull_request(head_repository_url: SERVER.url,
        head_ref: "feature/x", base_ref: "main", expected_head: SHA, title: "Ship it")
    end
    assert_match(/reconcile.*feature\/x/, error.message)
    assert_equal 1, posts
  end

  def create_probe(response: nil, read: nil, base: nil, forks: nil, head_url: SERVER.url)
    calls = []
    runner = lambda do |args:, **|
      calls << args
      method, path = args[1], args[2].to_s
      if method == "POST"
        response || created(pr_payload(25, draft: true))
      elsif path.end_with?("/version")
        ok({"version" => "8.0.5"})
      elsif path == API
        base || ok(repository_payload(REPO))
      elsif path.include?("/forks?")
        ok(path.include?("page=1&") ? (forks || []) : [])
      elsif path.include?("/pulls?state=open")
        ok([])
      elsif path.match?(%r{/pulls/(25|26)$})
        read.respond_to?(:call) ? read.call : (read || ok(pr_payload(25, draft: true)))
      else
        flunk("Unexpected #{method} #{path}")
      end
    end
    result = yield build_provider(runner), head_url
    [result, calls]
  end

  def test_create_proves_every_accepted_and_readback_identity_field
    changes = {
      source_repository: ->(p) { p["head"]["repo"]["full_name"] = "owner/unrelated" },
      destination_repository: ->(p) { p["base"]["repo"]["full_name"] = "owner/unrelated" },
      source_id: ->(p) { p["head"]["repo"]["id"] = 900 },
      destination_id: ->(p) { p["base"]["repo"]["id"] = 900 },
      source_ref: ->(p) { p["head"]["ref"] = "wrong" },
      destination_ref: ->(p) { p["base"]["ref"] = "wrong" },
      sha: ->(p) { p["head"]["sha"] = "f" * 40 },
      draft: ->(p) { p["draft"] = false },
      malformed_source: ->(p) { p["head"]["repo"] = "malformed" },
      malformed_destination: ->(p) { p["base"]["repo"] = "malformed" },
      missing_source: ->(p) { p["head"].delete("repo") },
      missing_destination: ->(p) { p["base"].delete("repo") },
      number: ->(p) { p["number"] = 26 },
      closed: ->(p) { p["state"] = "closed" }
    }
    changes.each do |field, mutate|
      [:response, :read].each do |phase|
        payload = pr_payload(25, draft: true)
        mutate.call(payload)
        options = {phase => phase == :response ? created(payload) : ok(payload)}
        error, calls = create_probe(**options) do |provider, url|
          assert_raises(Ace::Git::ProviderUnknownOutcomeError, "#{phase}: #{field}") do
            provider.create_pull_request(head_repository_url: url, head_ref: "feature/x",
              base_ref: "main", expected_head: SHA, title: "Ship it")
          end
        end
        assert_match(/expected head #{SHA}, draft true/, error.message)
        assert_equal 1, calls.count { |c| c[1] == "POST" }
      end
    end
  end

  def test_create_all_post_acceptance_read_failures_remain_unknown
    [401, 403, 404, 503].each do |status|
      error, calls = create_probe(read: {status: status, stdout: "{}"}) do |provider, url|
        assert_raises(Ace::Git::ProviderUnknownOutcomeError) do
          provider.create_pull_request(head_repository_url: url, head_ref: "feature/x",
            base_ref: "main", expected_head: SHA, title: "Ship it")
        end
      end
      assert_match(/reconcile.*feature\/x.*main/, error.message)
      assert_equal 1, calls.count { |c| c[1] == "POST" }
    end
    [nil, {}, {"number" => 0}, {"number" => 25}].each do |payload|
      _, calls = create_probe(response: created(payload)) do |provider, url|
        assert_raises(Ace::Git::ProviderUnknownOutcomeError) do
          provider.create_pull_request(head_repository_url: url, head_ref: "feature/x",
            base_ref: "main", expected_head: SHA, title: "Ship it")
        end
      end
      assert_equal 1, calls.count { |c| c[1] == "POST" }
    end
  end

  def test_create_selector_refuses_missing_ambiguous_and_wrong_owner_forks
    [[], [repository_payload("forker/actual")],
      [repository_payload("forker/requested"), repository_payload("forker/other")]].each do |forks|
      _, calls = create_probe(forks: forks, head_url: "https://forge.example.com/forker/requested") do |provider, url|
        assert_raises(Ace::Git::ProviderIdentityMismatchError, Ace::Git::ProviderConflictingMatchesError) do
          provider.create_pull_request(head_repository_url: url, head_ref: "feature/x",
            base_ref: "main", expected_head: SHA, title: "Ship it")
        end
      end
      assert_equal 0, calls.count { |c| c[1] == "POST" }
    end
  end

  def test_create_selector_accepts_direct_fork_and_normalized_clone_url
    parent = repository_payload("forker/parent")
    base = repository_payload(REPO).merge("parent" => parent)
    payload = pr_payload(25, draft: true)
    payload["head"]["repo"] = parent
    result, calls = create_probe(base: ok(base), forks: [parent], response: created(payload), read: ok(payload),
      head_url: "git@forge.example.com:forker/parent.git") do |provider, url|
      provider.create_pull_request(head_repository_url: url, head_ref: "feature/x",
        base_ref: "main", expected_head: SHA, title: "Ship it")
    end
    assert_equal :created, result.idempotency
    assert_equal "forker:feature/x", calls.find { |c| c[1] == "POST" }[3]["head"]
  end

  def test_create_selector_refuses_parent_without_direct_fork_before_post
    parent = repository_payload("forker/parent")
    base = repository_payload(REPO).merge("parent" => parent)
    _, calls = create_probe(base: ok(base), forks: [],
      head_url: "git@forge.example.com:forker/parent.git") do |provider, url|
      assert_raises(Ace::Git::ProviderIdentityMismatchError) do
        provider.create_pull_request(head_repository_url: url, head_ref: "feature/x",
          base_ref: "main", expected_head: SHA, title: "Ship it")
      end
    end
    assert_equal 0, calls.count { |c| c[1] == "POST" }
  end

  def test_create_missing_or_malformed_repository_evidence_refuses_before_post
    [{status: 404, stdout: "{}"}, ok({}), ok(repository_payload(REPO).merge("id" => nil))].each do |base|
      _, calls = create_probe(base: base) do |provider, url|
        assert_raises(Ace::Git::ProviderObjectNotFoundError, Ace::Git::ProviderMalformedOutputError) do
          provider.create_pull_request(head_repository_url: url, head_ref: "feature/x",
            base_ref: "main", expected_head: SHA, title: "Ship it")
        end
      end
      assert_equal 0, calls.count { |c| c[1] == "POST" }
    end
  end

  def repository_payload(full_name)
    {"id" => full_name == REPO ? 1 : 2, "full_name" => full_name,
     "owner" => {"id" => full_name == REPO ? 10 : 20, "login" => full_name.split("/").first}}
  end

  def test_lifecycle_create_reconciles_raced_duplicate_to_existing
    posts = 0
    runner = lambda do |args:, **|
      method = args[1]
      path = args[2].to_s
      if method == "GET" && path == "https://forge.example.com/api/v1/version"
        ok({"version" => "8.0.5"})
      elsif method == "GET" && path.include?("/pulls?state=open")
        page = path[/page=(\d+)/, 1].to_i
        ok(page == 1 && posts.positive? ? [pr_payload(25, draft: true)] : [])
      elsif method == "GET" && path == API
        ok(repository_payload(REPO))
      elsif method == "GET" && path.include?("/forks?")
        ok(path.include?("page=1&") ? [repository_payload("forker/other")] : [])
      elsif method == "POST" && path == "#{API}/pulls"
        posts += 1
        conflict("pull request already exists for these targets")
      else
        flunk("Unexpected #{method} #{path}")
      end
    end
    receipt = build_provider(runner).create_pull_request(
      **CONTRACT::CREATE_IDENTITY, expected_head: SHA, title: "Ship it"
    )
    assert_equal :existing, receipt.idempotency
    assert_equal 1, posts
  end

  def test_lifecycle_ready_is_idempotent_when_already_ready
    runner = lambda do |args:, **|
      method = args[1]
      path = args[2].to_s
      if method == "GET" && path == "#{API}/pulls/25"
        ok(pr_payload(25, draft: false))
      else
        flunk("an already-ready PR must not be mutated: #{method} #{path}")
      end
    end
    receipt = build_provider(runner).ready_pull_request(number: 25, expected_head: SHA)
    assert_equal :ready, receipt.operation
    assert_equal SHA, receipt.pull_request.head_sha
  end

  def test_lifecycle_merge_proves_merge_commit_on_success
    receipt = build_provider(lifecycle_runner(:merge_ok))
      .merge_pull_request(number: 25, expected_head: SHA, method: :squash)
    assert_equal SHA, receipt.pull_request.head_sha
    assert_equal :merged, receipt.pull_request.state
    assert receipt.pull_request.merge_commit_sha
  end

  def test_lifecycle_merge_reconciles_already_merged_refusal
    read = 0
    runner = lambda do |args:, **|
      method = args[1]
      path = args[2].to_s
      if method == "GET" && path == "https://forge.example.com/api/v1/version"
        ok({"version" => "8.0.5"})
      elsif method == "POST" && path == "#{API}/pulls/25/merge"
        conflict("user can only merge one time")
      elsif method == "GET" && path == "#{API}/pulls/25"
        read += 1
        if read > 1
          ok(pr_payload(25, draft: false).merge(
            "state" => "closed", "merged" => true, "merge_commit_sha" => "d" * 40
          ))
        else
          ok(pr_payload(25, draft: false))
        end
      else
        flunk("Unexpected #{method} #{path}")
      end
    end
    receipt = build_provider(runner).merge_pull_request(number: 25, expected_head: SHA, method: :merge)
    assert_equal :merge, receipt.operation
    assert_equal "d" * 40, receipt.pull_request.merge_commit_sha
  end

  private

  # API bodies arrive as Ruby hashes; the transport stringifies them.
  def ok(payload)
    {success: true, status: 200, stdout: payload.is_a?(String) ? payload : JSON.generate(payload),
     stderr: "", exit_code: 0}
  end

  def created(payload)
    {success: true, status: 201, stdout: JSON.generate(payload), stderr: "", exit_code: 0}
  end

  def conflict(message)
    {success: false, status: 409, stdout: JSON.generate({"message" => message}), stderr: "", exit_code: 0}
  end

  # After an accepted merge the PR reports closed+merged with the merge
  # commit; the merged head binding stays the reviewed source SHA.
  def merged_payload
    pr_payload(25, draft: false).merge(
      "state" => "closed", "merged" => true,
      "merged_at" => "2026-10-04T12:00:00Z", "merge_commit_sha" => "d" * 40
    )
  end

  def pr_branch(ref, sha, full_name = REPO)
    {"label" => "#{full_name}:#{ref}", "ref" => ref, "sha" => sha,
     "repo" => repository_payload(full_name)}
  end

  def pr_payload(number, draft:)
    sha = number == 25 ? SHA : CONTRACT::OTHER_SHA
    {
      "number" => number,
      "title" => draft ? "WIP: Ship it" : "Ship it",
      "body" => "Ship the thing",
      "state" => "open",
      "draft" => draft,
      "merged" => false,
      "merged_at" => nil,
      "merge_commit_sha" => nil,
      "user" => {"login" => "lab-builder"},
      "head" => pr_branch("feature/x", sha),
      "base" => pr_branch("main", "e" * 40)
    }
  end
end
