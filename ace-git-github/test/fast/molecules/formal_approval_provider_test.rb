# frozen_string_literal: true
require "test_helper"

class FormalApprovalProviderTest < AceGitGithubTestCase
  HEAD = "a" * 40
  SERVER = Ace::Git::ResolvedServer.new(name: "approval", provider: :github,
    url: "https://github.example/owner/repo")

  def setup
    super
    @rows, @writes, @calls = [], [], []
    @actor = {"id" => 7, "login" => "review-app[bot]", "type" => "Bot"}
    @correlation = "provider-#{Process.pid}-#{object_id}"
    @pr = Ace::Git::ProviderPullRequest.new(server_name: SERVER.name, number: 1, title: "Change", body: "",
      state: :open, head_ref: "branch", base_ref: "main", head_sha: HEAD, author: "writer",
      url: "#{SERVER.url}/pull/1", draft: false, merged_at: nil,
      head_repository_url: SERVER.url, base_repository_url: SERVER.url, merge_commit_sha: nil)
    @provider = Ace::Git::Github::Provider.new(server: SERVER, runner: method(:run_api))
  end

  def run_api(args:, **options)
    assert_equal ["gh", "api"], args.first(2)
    assert args.include?("--hostname")
    @calls << args
    path = args[2].delete_prefix("repos/owner/repo/")
    payload = options[:stdin] && JSON.parse(options[:stdin])
    refute args.join(" ").include?("accepted report")
    result = case path
    when "user"
      # Real installation-token behavior: REST /user is not available.
      return {success: false, stderr: "Resource not accessible by integration (HTTP 403)", stdout: "", exit_code: 1}
    when "graphql"
      assert_equal "query { viewer { login databaseId } }", payload.fetch("query")
      if @integration_denied
        return {success: false, stderr: "Resource not accessible by integration (HTTP 403)", stdout: "", exit_code: 1}
      end
      @viewer_failure ? {"data" => {"viewer" => nil}, "errors" => [{"type" => "FORBIDDEN"}]} :
        {"data" => {"viewer" => {"login" => @actor["login"], "databaseId" => @actor["id"]}}}
    when "pulls/1/reviews"
      if args.include?("POST")
        @writes << [path, payload]
        assert_equal "APPROVE", payload.fetch("event")
        assert_equal HEAD, payload.fetch("commit_id")
        @rows << {"id" => 99, "body" => payload.fetch("body"), "commit_id" => payload.fetch("commit_id"),
          "state" => "APPROVED", "user" => @actor.dup, "html_url" => "#{@pr.url}#pullrequestreview-99"}
        raise Ace::Git::ProviderUnreachableError, "lost create reply" if @lost_reply
        @rows.first
      else
        [@rows] # gh --paginate --slurp
      end
    else
      flunk("Unexpected provider call: #{args.inspect}")
    end
    {success: true, status: 200, stdout: JSON.generate(result), stderr: "", exit_code: 0}
  end

  def approve
    @provider.stub(:pull_request, @pr) do
      @provider.approve_pull_request(number: 1, expected_head: HEAD, body: "accepted report", correlation: @correlation)
    end
  end

  def test_installation_actor_uses_authenticated_graphql_viewer_not_rest_user
    receipt = approve
    assert_equal "review-app[bot]", receipt.reviewer
    assert_equal 7, receipt.reviewer_id
    assert_equal :approved, receipt.state
    assert_equal 1, @writes.length
    assert_equal :existing, approve.idempotency
    refute @calls.any? { |args| args[2] == "user" }
    assert_equal 1, @writes.length
  end

  def test_pat_or_app_user_token_uses_same_verified_viewer_contract
    @actor = {"id" => 8, "login" => "human-reviewer", "type" => "User"}
    assert_equal "human-reviewer", approve.reviewer
  end

  def test_graphql_integration_refusal_is_capability_not_unreachable
    @integration_denied = true
    assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { approve }
    assert_empty @writes
    @integration_denied = false
    @viewer_failure = true
    assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { approve }
    assert_empty @writes
  end

  def test_lost_direct_create_reply_is_unknown_and_reconciles_without_post
    @lost_reply = true
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { approve }
    @lost_reply = false
    assert_equal :existing, approve.idempotency
    assert_equal 1, @writes.length
  end

  def test_manual_or_owned_pending_is_preserved_when_no_verified_safe_resume_port
    approve
    @rows.first["state"] = "PENDING"
    assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) { approve }
    assert_equal "PENDING", @rows.first["state"]
    assert_equal 1, @writes.length
    @rows.first["body"] = "manual pending review"
    @rows.first["id"] = 100
    assert_raises(Ace::Git::ProviderConflictingMatchesError) { approve }
    assert_equal 1, @writes.length
  end

  def test_author_denied_under_app_or_user_identity
    @pr = @pr.with(author: "review-app[bot]")
    assert_raises(Ace::Git::ProviderAuthenticationError) { approve }
    assert_empty @writes
  end
end
