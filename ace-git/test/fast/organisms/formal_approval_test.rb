# frozen_string_literal: true
require "test_helper"
require "ace/git/providers/formal_approval"

class FormalApprovalTest < AceGitTestCase
  HEAD = "a" * 40

  def setup
    super
    @server = Ace::Git::ResolvedServer.new(name: "test", provider: :forgejo, url: "https://forge.example/owner/repo")
    @pr = Ace::Git::ProviderPullRequest.new(server_name: "test", number: 1, title: "Change", body: "",
      state: :open, head_ref: "branch", base_ref: "main", head_sha: HEAD, author: "writer",
      url: "https://forge.example/owner/repo/pulls/1", draft: false, merged_at: nil,
      head_repository_url: @server.url, base_repository_url: @server.url, merge_commit_sha: nil)
    @provider = Object.new
    @provider.define_singleton_method(:server) { @server }
    @provider.instance_variable_set(:@server, @server)
    owner = self
    @provider.define_singleton_method(:pull_request) { |**| owner.instance_variable_get(:@pr) }
    @actor = {"id" => 7, "login" => "reviewer"}
    @rows, @posts = [], []
    @correlation = "test-#{Process.pid}-#{object_id}"
    @policy = Ace::Git::Providers::FormalApproval.new(provider: @provider,
      request: method(:request), list: ->(*) { @rows.map(&:dup) }, official: true)
  end

  def request(method, path, payload)
    return @actor if path == :actor
    @posts << [path, payload]
    if path.end_with?("/submit")
      @rows.first["state"] = "APPROVED"
    else
      @rows << {"id" => 42, "body" => payload.fetch("body"), "user" => @actor.dup,
        "commit_id" => payload.fetch("commit_id"), "state" => "PENDING", "official" => true,
        "html_url" => "https://forge.example/owner/repo/pulls/1#review-42"}
    end
    raise Ace::Git::ProviderUnreachableError, "lost response" if @lost_reply
    @rows.first.dup
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
    assert_equal 2, @posts.length
    assert_equal :existing, approve.idempotency
    read = @policy.read(number: 1, expected_head: HEAD, review_id: 42)
    assert_equal first.review_id, read.review_id
    assert_equal 2, @posts.length
  end

  def test_own_pr_and_unverified_actor_refuse_before_mutation
    @pr = @pr.with(author: "ReViEwEr")
    assert_raises(Ace::Git::ProviderAuthenticationError) { approve }
    assert_empty @posts
    @pr = @pr.with(author: "writer")
    @actor = {"login" => "reviewer"}
    assert_raises(Ace::Git::ProviderMalformedOutputError) { approve }
    assert_empty @posts
  end

  def test_wrong_head_repo_or_draft_refuse
    [{head_sha: "b" * 40}, {base_repository_url: "https://forge.example/other/repo"}, {draft: true}].each do |change|
      before = @pr
      @pr = before.with(**change)
      assert_raises(Ace::Git::ProviderExpectedHeadConflictError) { approve }
      @pr = before
    end
    assert_empty @posts
  end

  def test_nonofficial_stale_dismissed_and_changed_report_never_count
    approve
    [{"official" => false}, {"stale" => true}, {"dismissed" => true}, {"state" => "DISMISSED"},
      {"body" => "tampered"}, {"html_url" => "https://unrelated.example/wrong#review"}].each do |change|
      before = @rows.first.dup
      @rows.first.merge!(change)
      assert_raises(Ace::Git::ProviderIdentityMismatchError) { @policy.read(number: 1, expected_head: HEAD, review_id: 42) }
      @rows[0] = before
    end
  end

  def test_correlation_conflict_and_ambiguous_review_refuse_without_post
    approve
    before = @posts.length
    assert_raises(Ace::Git::ProviderConflictingMatchesError) { approve(body: "different report") }
    @rows << @rows.first.merge("id" => 43)
    assert_raises(Ace::Git::ProviderConflictingMatchesError) { approve }
    assert_equal before, @posts.length
  end

  def test_lost_create_reply_is_unknown_and_resume_submits_existing_pending_once
    @lost_reply = true
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { approve }
    assert_equal 1, @posts.length
    @lost_reply = false
    assert_equal :existing, approve.idempotency
    assert_equal 2, @posts.length
    assert_equal 1, @rows.length
  end

  def test_lost_submit_reply_reconciles_without_another_mutation
    request_method = method(:request)
    port = lambda do |method, path, body|
      result = request_method.call(method, path, body)
      raise Ace::Git::ProviderUnknownOutcomeError, "lost submit" if path.to_s.end_with?("/submit")
      result
    end
    policy = Ace::Git::Providers::FormalApproval.new(provider: @provider, request: port,
      list: ->(*) { @rows }, official: true)
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) do
      policy.approve(number: 1, expected_head: HEAD, body: "accepted review\n", correlation: @correlation)
    end
    assert_equal :existing, approve.idempotency
    assert_equal 2, @posts.length
  end

  def test_concurrent_publication_has_one_create_and_one_submit
    results = 4.times.map { Thread.new { approve } }.map(&:value)
    assert_equal 1, results.count { |receipt| receipt.idempotency == :created }
    assert_equal 2, @posts.length
    assert_equal 1, @rows.length
  end

  def test_head_race_after_send_remains_unknown
    original = method(:request)
    port = lambda do |*args|
      result = original.call(*args)
      @pr = @pr.with(head_sha: "b" * 40) if args[1].to_s.end_with?("/submit")
      result
    end
    policy = Ace::Git::Providers::FormalApproval.new(provider: @provider, request: port, list: ->(*) { @rows })
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) do
      policy.approve(number: 1, expected_head: HEAD, body: "accepted review\n", correlation: @correlation)
    end
    assert_equal 2, @posts.length
  end

  def test_malformed_review_list_and_later_revocation_fail_closed
    @rows << {"id" => 9}
    assert_raises(Ace::Git::ProviderMalformedOutputError) { approve }
    @rows.clear
    approve
    @rows << @rows.first.merge("id" => 43, "state" => "CHANGES_REQUESTED", "body" => "new decision")
    assert_raises(Ace::Git::ProviderIdentityMismatchError) { @policy.read(number: 1, expected_head: HEAD, review_id: 42) }
  end

  def test_unsafe_real_filesystem_lock_refuses_without_provider_mutation
    key = Digest::SHA256.hexdigest([@server.provider, @server.name, @server.url, 1, @correlation].join("\0"))
    path = File.join(Dir.tmpdir, "ace-review-session-approval-#{Process.uid}-#{key}.lock")
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
    File.unlink(path) if path && File.symlink?(path)
  end

  def test_unsupported_provider_does_not_fall_back_to_comments
    provider = Ace::Git::Providers::Base.allocate
    assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
      provider.approve_pull_request(number: 1, expected_head: HEAD, body: "report", correlation: @correlation)
    end
    assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
      provider.pull_request_approval(number: 1, expected_head: HEAD, review_id: 42)
    end
  end

  def test_changed_actor_visible_under_same_correlation_conflicts
    approve
    @actor = {"id" => 8, "login" => "another-reviewer"}
    assert_raises(Ace::Git::ProviderConflictingMatchesError) { approve }
    assert_equal 2, @posts.length
  end

  def test_readback_auth_failure_after_successful_post_remains_unknown
    original = method(:request)
    submitted = false
    port = lambda do |*args|
      value = original.call(*args)
      submitted = true if args[1].to_s.end_with?("/submit")
      value
    end
    policy = Ace::Git::Providers::FormalApproval.new(provider: @provider, request: port,
      list: ->(*) { raise Ace::Git::ProviderAuthenticationError, "read refused" if submitted; @rows })
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) do
      policy.approve(number: 1, expected_head: HEAD, body: "accepted review\n", correlation: @correlation)
    end
    assert_equal 2, @posts.length
  end

  def test_invalid_report_and_correlation_refuse_before_any_io
    ["", "\xff".b, "bad\0report", "<!-- ace-approval:forged -->", "x" * (64 * 1024 + 1)].each do |body|
      assert_raises(ArgumentError) { approve(body: body) }
    end
    assert_raises(ArgumentError) { approve(correlation: "../escape") }
    assert_empty @posts
  end
end
