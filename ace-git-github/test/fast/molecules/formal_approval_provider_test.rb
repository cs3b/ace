# frozen_string_literal: true
require "test_helper"

class FormalApprovalProviderTest < AceGitGithubTestCase
  HEAD = "a" * 40
  SERVER = Ace::Git::ResolvedServer.new(name: "approval", provider: :github,
    url: "https://forge.example/owner/repo")

  def setup
    super
    @rows, @writes = [], []
    @actor = {"id" => 7, "login" => "reviewer"}
    @runner = lambda do |args:, **options|
      path, payload, method = decode(args, options)
      response = case path
      when "/api/v1/version" then {"version" => "11.0.0"}
      when "user", "/api/v1/user" then @actor
      when /reviews(?:\?page=\d+&limit=50)?\z/
        if method == "POST"
          @writes << [path, payload]
          @rows << {"id" => 99, "body" => payload.fetch("body"), "commit_id" => payload.fetch("commit_id"),
            "state" => "PENDING", "official" => true, "user" => @actor.dup,
            "html_url" => "https://forge.example/owner/repo/pulls/1#review-99"}
          @rows.first
        else
          path.include?("page=2") ? [] : @rows
        end
      when /reviews\/99(?:\/events)?\z/
        @writes << [path, payload]
        assert_equal "APPROVE", payload.fetch("event")
        @rows.first["state"] = "APPROVED"
        @rows.first
      else
        flunk("Unexpected provider call: #{args.inspect}")
      end
      raise Ace::Git::ProviderUnreachableError, "lost response" if @lost_reply && method == "POST"
      response = [response] if "github" == "github" && args.include?("--slurp")
      {success: true, status: 200, stdout: JSON.generate(response), stderr: "", exit_code: 0}
    end
    @provider = Ace::Git::Github::Provider.new(server: SERVER, runner: @runner)
    @pr = Ace::Git::ProviderPullRequest.new(server_name: SERVER.name, number: 1, title: "Change", body: "",
      state: :open, head_ref: "branch", base_ref: "main", head_sha: HEAD, author: "writer",
      url: "https://forge.example/owner/repo/pulls/1", draft: false, merged_at: nil,
      head_repository_url: SERVER.url, base_repository_url: SERVER.url, merge_commit_sha: nil)
  end

  def decode(args, options)
    assert_equal ["gh", "api"], args.first(2)
    assert args.include?("--hostname")
    path = args[2].delete_prefix("repos/owner/repo/")
    refute args.join(" ").include?("accepted report")
    payload = options[:stdin] && JSON.parse(options[:stdin])
    [path, payload, args.include?("POST") ? "POST" : "GET"]
  end

  def approve
    @provider.stub(:pull_request, @pr) do
      @provider.approve_pull_request(number: 1, expected_head: HEAD, body: "accepted report",
        correlation: "provider-#{Process.pid}-#{object_id}")
    end
  end

  def test_formal_pending_submit_readback_and_repeat
    receipt = approve
    assert_equal :created, receipt.idempotency
    assert_equal :approved, receipt.state
    assert_equal 99, receipt.review_id
    assert_equal "reviewer", receipt.reviewer
    assert_equal 2, @writes.length
    assert_equal :existing, approve.idempotency
    assert_equal 2, @writes.length
    @provider.stub(:pull_request, @pr) do
      assert @provider.pull_request_approval(number: 1, expected_head: HEAD, review_id: 99).effective
    end
  end

  def test_lost_create_response_is_not_retried_and_pending_is_reconciled
    @lost_reply = true
    assert_raises(Ace::Git::ProviderUnknownOutcomeError) { approve }
    assert_equal 1, @writes.length
    @lost_reply = false
    assert_equal :existing, approve.idempotency
    assert_equal 2, @writes.length
  end

  def test_author_denied_with_zero_writes
    @pr = @pr.with(author: "reviewer")
    assert_raises(Ace::Git::ProviderAuthenticationError) { approve }
    assert_empty @writes
  end
end
