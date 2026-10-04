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
  HOST = "forge.example.com"
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
    if method == "GET" && path == "https://forge.example.com/api/v1/version"
      return ok({"version" => "7.0.5"})
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
        assert_equal "New title", body["title"]
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
        ok({"version" => "7.0.5"})
      elsif method == "GET" && path.include?("/pulls?state=open")
        ok([])
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

  def test_lifecycle_create_reconciles_raced_duplicate_to_existing
    posts = 0
    runner = lambda do |args:, **|
      method = args[1]
      path = args[2].to_s
      if method == "GET" && path == "https://forge.example.com/api/v1/version"
        ok({"version" => "7.0.5"})
      elsif method == "GET" && path.include?("/pulls?state=open")
        page = path[/page=(\d+)/, 1].to_i
        ok(page == 1 && posts.positive? ? [pr_payload(25, draft: true)] : [])
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
        ok({"version" => "7.0.5"})
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
     "repo" => {"full_name" => full_name}}
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
