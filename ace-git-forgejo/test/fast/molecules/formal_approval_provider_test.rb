# frozen_string_literal: true
require "test_helper"

class FormalApprovalProviderTest < AceGitForgejoTestCase
  HEAD = "a" * 40
  NEW_HEAD = "b" * 40
  SERVER = Ace::Git::ResolvedServer.new(name: "approval", provider: :forgejo,
    url: "https://forge.example/owner/repo")

  def setup
    super
    @rows, @writes = [], []
    @head, @version = HEAD, "16.0.5"
    @actor = {"id" => 7, "login" => "reviewer"}
    @correlation = "provider-#{Process.pid}-#{object_id}"
    @pr = Ace::Git::ProviderPullRequest.new(server_name: SERVER.name, number: 1, title: "Change", body: "",
      state: :open, head_ref: "branch", base_ref: "main", head_sha: HEAD, author: "writer",
      url: "#{SERVER.url}/pulls/1", draft: false, merged_at: nil,
      head_repository_url: SERVER.url, base_repository_url: SERVER.url, merge_commit_sha: nil)
    @provider = Ace::Git::Forgejo::Provider.new(server: SERVER, runner: method(:run_api))
  end

  # Protocol fixture derived from Forgejo v11.0.0/v16.0.5 CreatePullReview,
  # SubmitReview and ToPullReviewList. Direct creation REUSES actor pending;
  # explicit commit_id is retained. Pending-submit would rebind current head.
  def run_api(args:, **)
    assert_equal "forgejo-http", args[0]
    method, path, payload = args[1], args[2].delete_prefix("https://forge.example"), args[3]
    path = path.delete_prefix("/api/v1/repos/owner/repo/")
    result = case path
    when "/api/v1/version" then {"version" => @version}
    when "/api/v1/user" then @actor
    when /reviews\?page=\d+&limit=50\z/
      path.include?("page=2") ? [] : @rows
    when "pulls/1/reviews"
      assert_equal "POST", method
      assert_equal "APPROVED", payload.fetch("event")
      assert_equal HEAD, payload.fetch("commit_id")
      @head = NEW_HEAD if @push_before_create
      @writes << [path, payload]
      pending = @rows.find { |row| row["state"] == "PENDING" && row.dig("user", "id") == @actor["id"] }
      row = pending || {"id" => [@rows.map { |r| r["id"] }.max || 0, 98].max + 1, "comments_count" => 0}
      @rows.each { |r| r["official"] = false if r.dig("user", "id") == @actor["id"] }
      row.merge!("body" => payload.fetch("body"), "commit_id" => payload.fetch("commit_id"),
        "state" => "APPROVED", "official" => true, "stale" => false, "dismissed" => false,
        "user" => @actor.dup, "html_url" => "#{@pr.url}#review-#{row['id']}")
      @rows << row unless pending
      raise Ace::Git::ProviderUnknownOutcomeError, "lost direct-create reply" if @lost_reply
      row
    when %r{reviews/\d+\z}
      flunk("Unsafe pending-submit path used: #{path}; it would rebind review to #{@head}")
    else
      flunk("Unexpected provider call: #{args.inspect}")
    end
    {success: true, status: 200, stdout: JSON.generate(result), stderr: "", exit_code: 0}
  end

  def with_pr
    @provider.stub(:pull_request, ->(**) { @pr.with(head_sha: @head) }) { yield }
  end

  def approve(correlation = @correlation)
    with_pr do
      @provider.approve_pull_request(number: 1, expected_head: HEAD, body: "accepted report", correlation: correlation)
    end
  end

  def read
    with_pr { @provider.pull_request_approval(number: 1, expected_head: HEAD, review_id: 99) }
  end

  def test_direct_approval_and_readback_work_on_current_and_verified_floor
    @version = "11.0.0"
    receipt = approve
    assert_equal :created, receipt.idempotency
    assert_equal true, receipt.official
    assert_equal :existing, approve.idempotency
    assert read.effective
    assert_equal 1, @writes.length
  end

  def test_older_unverified_formal_api_is_refused_before_writes
    @version = "10.0.0"
    assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { approve }
    assert_empty @writes
  end

  def test_push_during_create_never_publishes_approval_for_unreviewed_head
    @push_before_create = true
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { approve }
    assert_equal HEAD, @rows.first["commit_id"]
    refute @rows.any? { |r| r["state"] == "APPROVED" && r["commit_id"] == NEW_HEAD }
    assert_equal ["pulls/1/reviews"], @writes.map(&:first)
  end

  def test_user_team_requests_and_deleted_user_comments_do_not_poison_approval
    @rows += [
      {"id" => 1, "state" => "REQUEST_REVIEW", "body" => "", "commit_id" => "",
       "user" => {"id" => 8, "login" => "requested"}, "team" => nil},
      {"id" => 2, "state" => "REQUEST_REVIEW", "body" => "", "commit_id" => "",
       "user" => nil, "team" => {"id" => 3, "name" => "review-team"}},
      {"id" => 3, "state" => "COMMENT", "body" => "historical", "commit_id" => "", "user" => nil}
    ]
    assert approve.effective
    assert read.effective
    @rows.last["user"] = nil
    assert_raises(Ace::Git::ProviderMalformedOutputError) { read }
  end

  def test_unrelated_manual_pending_comments_are_not_overwritten
    manual = {"id" => 88, "state" => "PENDING", "user" => @actor, "body" => "manual report",
      "commit_id" => HEAD, "comments_count" => 2}
    @rows << manual
    before = Marshal.dump(@rows)
    assert_raises(Ace::Git::ProviderConflictingMatchesError) { approve }
    assert_equal before, Marshal.dump(@rows)
    assert_empty @writes
  end

  def test_exact_owned_pending_resumes_via_direct_create_without_implicit_head
    approve
    @rows.first["state"] = "PENDING"
    assert_equal :existing, approve.idempotency
    assert_equal 99, @rows.first["id"]
    assert_equal HEAD, @rows.first["commit_id"]
    assert_equal 2, @writes.length
    @rows.first["state"] = "PENDING"
    @rows.first["comments_count"] = 1
    assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { approve }
    assert_equal 2, @writes.length
  end

  def test_lost_owned_pending_recovery_reply_reconciles_without_another_post
    approve
    @rows.first["state"] = "PENDING"
    @lost_reply = true
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { approve }
    @lost_reply = false
    assert_equal :existing, approve.idempotency
    assert_equal 2, @writes.length
  end

  def test_different_correlations_publish_serially_without_pending_carryover
    receipts = with_pr do
      ["one", "two"].map do |suffix|
        Thread.new do
          @provider.approve_pull_request(number: 1, expected_head: HEAD, body: "accepted report",
            correlation: "#{@correlation}-#{suffix}")
        end
      end.map(&:value)
    end
    assert_equal 2, receipts.length
    assert_equal 2, @writes.length
    assert_equal 2, @rows.length
    assert @rows.all? { |row| row["state"] == "APPROVED" && row["commit_id"] == HEAD }
  end

  def test_author_denied_without_writes
    @pr = @pr.with(author: "reviewer")
    assert_raises(Ace::Git::ProviderAuthenticationError) { approve }
    assert_empty @writes
  end
end
