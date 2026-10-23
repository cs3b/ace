# frozen_string_literal: true
require "test_helper"
require "ace/git/providers/formal_approval"

class FormalApprovalTest < AceGitTestCase
  HEAD = "a" * 40

  def setup
    super
    @server = Ace::Git::ResolvedServer.new(name: "test", provider: :forgejo, url: "https://forge.example/owner/repo-#{Process.pid}-#{object_id}")
    @pr = Ace::Git::ProviderPullRequest.new(server_name: "test", number: 1, title: "Change", body: "",
      state: :open, head_ref: "branch", base_ref: "main", head_sha: HEAD, author: "writer",
      url: "#{@server.url}/pulls/1", draft: false, merged_at: nil,
      head_repository_url: @server.url, base_repository_url: @server.url, merge_commit_sha: nil)
    @provider = Object.new
    @provider.define_singleton_method(:server) { @server }
    @provider.instance_variable_set(:@server, @server)
    owner = self
    @provider.define_singleton_method(:pull_request) { |**| owner.instance_variable_get(:@pr) }
    @actor = {"id" => 7, "login" => "reviewer"}
    @rows, @posts = [], []
    @correlation = "test-#{Process.pid}-#{object_id}"
    @policy = policy
  end

  def policy(request = method(:request), list = ->(*) { @rows.map(&:dup) })
    Ace::Git::Providers::FormalApproval.new(provider: @provider,
      request: request, list: list, official: true, pending_reuse: true)
  end

  # Model Forgejo's direct-create reuse semantics; it is not a fresh-object API.
  # A pending-submit would rebind commit_id to current head and is forbidden.
  def request(method, path, payload)
    return @actor if path == :actor
    @posts << [path, payload]
    assert_equal "pulls/1/reviews", path
    assert_equal "APPROVE", payload.fetch("event")
    pending = @rows.find { |row| row["state"] == "PENDING" && row.dig("user", "id") == @actor["id"] }
    row = pending || {"id" => [@rows.map { |r| r["id"] }.max || 0, 41].max + 1, "comments_count" => 0}
    row.merge!("body" => payload.fetch("body"), "user" => @actor.dup,
      "commit_id" => payload.fetch("commit_id"), "state" => "APPROVED", "official" => true,
      "html_url" => "#{@pr.url}#review-#{row['id']}")
    @rows << row unless pending
    raise Ace::Git::ProviderUnreachableError, "lost response" if @lost_reply
    row.dup
  end

  def approve(**options)
    @policy.approve(number: 1, expected_head: HEAD, body: "accepted review\n", correlation: @correlation, **options)
  end

  def test_publish_read_and_repeat_return_normalized_effective_receipt
    first = approve
    assert_equal :created, first.idempotency
    assert_equal :approved, first.state
    assert_equal true, first.official
    assert_equal 7, first.reviewer_id
    assert_equal Digest::SHA256.hexdigest("accepted review\n"), first.evidence_sha256
    assert_equal 1, @posts.length
    assert_equal :existing, approve.idempotency
    assert_equal first.review_id, @policy.read(number: 1, expected_head: HEAD, review_id: 42).review_id
    assert_equal 1, @posts.length
  end

  def test_own_pr_unverified_actor_and_wrong_head_repo_draft_refuse
    @pr = @pr.with(author: "ReViEwEr")
    assert_raises(Ace::Git::ProviderAuthenticationError) { approve }
    @pr = @pr.with(author: "writer")
    [{head_sha: "b" * 40}, {base_repository_url: "https://forge.example/other/repo"}, {draft: true}].each do |change|
      before = @pr
      @pr = before.with(**change)
      assert_raises(Ace::Git::ProviderExpectedHeadConflictError) { approve }
      @pr = before
    end
    @actor = {"login" => "reviewer"}
    assert_raises(Ace::Git::ProviderMalformedOutputError) { approve }
    assert_empty @posts
  end

  def test_nonofficial_stale_dismissed_changed_report_and_wrong_url_never_count
    approve
    [{"official" => false}, {"stale" => true}, {"dismissed" => true}, {"state" => "DISMISSED"},
      {"body" => "tampered"}, {"html_url" => "https://unrelated.example/wrong#review"}].each do |change|
      before = @rows.first.dup
      @rows.first.merge!(change)
      assert_raises(Ace::Git::ProviderIdentityMismatchError) { @policy.read(number: 1, expected_head: HEAD, review_id: 42) }
      @rows[0] = before
    end
  end

  def test_correlation_conflicts_duplicates_and_changed_actor_refuse
    approve
    assert_raises(Ace::Git::ProviderConflictingMatchesError) { approve(body: "different report") }
    @actor = {"id" => 8, "login" => "other-reviewer"}
    assert_raises(Ace::Git::ProviderConflictingMatchesError) { approve }
    @actor = @rows.first["user"]
    @rows << @rows.first.merge("id" => 43)
    assert_raises(Ace::Git::ProviderConflictingMatchesError) { approve }
    assert_equal 1, @posts.length
  end

  def test_lost_direct_create_response_reconciles_submitted_review_without_post
    @lost_reply = true
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { approve }
    assert_equal 1, @posts.length
    @lost_reply = false
    assert_equal :existing, approve.idempotency
    assert_equal 1, @posts.length
  end

  def test_known_comment_free_pending_can_resume_only_with_explicit_commit_preserving_port
    approve
    @rows.first["state"] = "PENDING"
    assert_equal :existing, approve.idempotency
    assert_equal 42, @rows.first["id"]
    assert_equal HEAD, @rows.first["commit_id"]
    assert_equal 2, @posts.length
    @rows.first["state"] = "PENDING"
    @rows.first["comments_count"] = 1
    assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { approve }
    assert_equal 2, @posts.length
    @rows.first["comments_count"] = 0
    @policy = Ace::Git::Providers::FormalApproval.new(provider: @provider, request: method(:request), list: ->(*) { @rows })
    assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { approve }
  end

  def test_manual_pending_body_and_comments_are_preserved
    @rows << {"id" => 9, "state" => "PENDING", "user" => @actor,
      "body" => "manual pending", "comments_count" => 2, "commit_id" => HEAD}
    assert_raises(Ace::Git::ProviderConflictingMatchesError) { approve }
    assert_equal "manual pending", @rows.first["body"]
    assert_equal 2, @rows.first["comments_count"]
    assert_empty @posts
  end

  def test_same_correlation_concurrency_publishes_once
    results = 4.times.map { Thread.new { approve } }.map(&:value)
    assert_equal 1, results.count { |receipt| receipt.idempotency == :created }
    assert_equal 1, @posts.length
  end

  def test_distinct_correlations_share_one_actor_pr_critical_section
    active, maximum = 0, 0
    original = method(:request)
    port = lambda do |*args|
      active += 1
      maximum = [maximum, active].max
      Thread.pass
      original.call(*args)
    ensure
      active -= 1
    end
    policies = 4.times.map { policy(port) }
    results = Dir.stub(:tmpdir, "/ignored-worktree-private-temp") do
      policies.each_with_index.map do |p, i|
        Thread.new do
          p.approve(number: 1, expected_head: HEAD, body: "accepted review\n", correlation: "#{@correlation}-#{i}")
        end
      end.map(&:value)
    end
    assert_equal 4, results.length
    assert_equal 1, maximum
  end

  def test_direct_create_race_never_binds_approval_to_new_unreviewed_head
    original = method(:request)
    port = lambda do |*args|
      @pr = @pr.with(head_sha: "b" * 40) unless args[1] == :actor
      original.call(*args) # explicit commit is preserved even after the push
    end
    @policy = policy(port)
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { approve }
    assert_equal HEAD, @rows.first["commit_id"]
    refute @rows.any? { |row| row["state"] == "APPROVED" && row["commit_id"] == "b" * 40 }
  end

  def test_malformed_selected_evidence_and_relevant_revocation_fail_closed
    @rows << {"id" => 9}
    assert_raises(Ace::Git::ProviderMalformedOutputError) { approve }
    @rows.clear
    approve
    @rows << @rows.first.merge("id" => 43, "state" => "REQUEST_CHANGES", "body" => "new decision")
    assert_raises(Ace::Git::ProviderIdentityMismatchError) { @policy.read(number: 1, expected_head: HEAD, review_id: 42) }
  end

  def test_irrelevant_null_actor_comment_does_not_poison_effective_approval
    @rows << {"id" => 1, "state" => "COMMENT", "user" => nil, "body" => "deleted user's comment", "commit_id" => ""}
    assert approve.effective
    assert @policy.read(number: 1, expected_head: HEAD, review_id: 42).effective
    @rows.last["user"] = nil
    assert_raises(Ace::Git::ProviderMalformedOutputError) { @policy.read(number: 1, expected_head: HEAD, review_id: 42) }
  end

  def test_private_lock_on_real_filesystem_refuses_unsafe_mode_and_symlink
    scope = [@server.provider, Ace::Git::Atoms::ServerUrl.normalize(@server.url), 1]
    path = File.join(Etc.systmpdir, "ace-review-session-approval-#{Process.uid}-#{Digest::SHA256.hexdigest(scope.join("\0"))}.lock")
    File.unlink(path) if File.exist?(path)
    File.write(path, "", perm: 0644)
    assert_raises(Ace::Git::ConfigError) { approve }
    File.unlink(path)
    Dir.mktmpdir do |dir|
      target = File.join(dir, "unrelated")
      File.write(target, "preserve")
      File.symlink(target, path)
      assert_raises(Ace::Git::ConfigError) { approve }
      assert_equal "preserve", File.read(target)
    end
    assert_empty @posts
  ensure
    File.unlink(path) if path && (File.exist?(path) || File.symlink?(path))
  end

  def test_readback_auth_failure_remains_unknown
    original = method(:request)
    port = lambda do |*args|
      result = original.call(*args)
      @submitted = true unless args[1] == :actor
      result
    end
    @policy = policy(port, ->(*) { raise Ace::Git::ProviderAuthenticationError, "read refused" if @submitted; @rows })
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { approve }
  end

  def test_unsupported_provider_and_invalid_report_fail_before_effects
    assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
      Ace::Git::Providers::Base.allocate.approve_pull_request(number: 1, expected_head: HEAD, body: "r", correlation: "r")
    end
    ["", "\xff".b, "bad\0report", "<!-- ace-approval:forged -->", "x" * (64 * 1024 + 1)].each do |body|
      assert_raises(ArgumentError) { approve(body: body) }
    end
    assert_raises(ArgumentError) { approve(correlation: "../escape") }
    assert_empty @posts
  end
end
