# frozen_string_literal: true

require "test_helper"

module Forgejo
  class ReviewProviderTest < AceGitForgejoTestCase
    SERVER = Ace::Git::ResolvedServer.new(
      name: "forge-lab", provider: :forgejo, url: "https://forge.example.com/owner/repo"
    )
    HEAD = "a" * 40

    def test_valid_empty_collection_preserves_identity
      calls = []
      runner = lambda do |args:, **|
        calls << args
        {success: true, status: 200, stdout: "[]", stderr: "", exit_code: 0}
      end
      provider = Ace::Git::Forgejo::Provider.new(server: SERVER, runner: runner)
      pr = Struct.new(:number, :head_sha, :state).new(42, HEAD, :open)

      evidence = provider.stub(:pull_request, pr) do
        provider.pull_request_review_evidence(number: 42, expected_head: HEAD)
      end

      assert_empty evidence.comments
      assert_empty evidence.reviews
      assert_equal "forge-lab", evidence.server_name
      assert_equal HEAD, evidence.head_sha
      # issues comments + reviews (empty reviews means no per-comment fetch)
      assert_equal 2, calls.length
      assert calls.all? { |args| args[2].start_with?("https://forge.example.com/api/v1/repos/owner/repo/") }
    end

    def test_malformed_collection_is_failure
      runner = ->(**) { {success: true, status: 200, stdout: "{}", stderr: "", exit_code: 0} }
      provider = Ace::Git::Forgejo::Provider.new(server: SERVER, runner: runner)
      pr = Struct.new(:number, :head_sha, :state).new(42, HEAD, :open)

      assert_raises(Ace::Git::ProviderMalformedOutputError) do
        provider.stub(:pull_request, pr) do
          provider.pull_request_review_evidence(number: 42, expected_head: HEAD)
        end
      end
    end

    def test_repeat_comment_reconciles_exact_session_without_post
      calls = []
      runner = lambda do |args:, **|
        calls << args
        # Model real pagination: an empty page after the first content page.
        if calls.count > 1
          {success: true, status: 200, stdout: [].to_json, stderr: "", exit_code: 0}
        else
          comment = {"id" => 91, "body" => "Reviewed\n\n<!-- ace-review-session:session-1 -->",
                     "user" => {"login" => "reviewer"}, "html_url" => "https://forge.example.com/comment/91"}
          {success: true, status: 200, stdout: [comment].to_json, stderr: "", exit_code: 0}
        end
      end
      provider = Ace::Git::Forgejo::Provider.new(server: SERVER, runner: runner)
      pr = Struct.new(:number, :head_sha, :state).new(42, HEAD, :open)

      receipt = provider.stub(:pull_request, pr) do
        provider.create_pull_request_comment(
          number: 42, expected_head: HEAD, body: "Reviewed", correlation: "session-1"
        )
      end

      assert_equal :existing, receipt.idempotency
      assert_equal 91, receipt.comment.id
      assert calls.none? { |args| args[1] == "POST" }
    end

    def test_unrelated_comments_are_excluded_from_match_results
      unrelated = {"id" => 5, "body" => "unrelated chatter", "user" => {"login" => "other"},
                   "html_url" => "https://forge.example.com/comment/5"}
      ours = {"id" => 91, "body" => "Reviewed\n\n<!-- ace-review-session:session-1 -->",
              "user" => {"login" => "reviewer"}, "html_url" => "https://forge.example.com/comment/91"}
      calls = 0
      runner = lambda do |args:, **|
        calls += 1
        page = calls == 1 ? [unrelated, ours] : []
        {success: true, status: 200, stdout: page.to_json, stderr: "", exit_code: 0}
      end
      provider = Ace::Git::Forgejo::Provider.new(server: SERVER, runner: runner)
      pr = Struct.new(:number, :head_sha, :state).new(42, HEAD, :open)

      matches = provider.stub(:pull_request, pr) do
        provider.send(:matching_review_comments, pr, "ace-review-session:session-1", HEAD)
      end

      assert_equal [91], matches.map(&:id)
    end

    def test_post_timeout_is_unknown_and_cannot_auto_repeat
      calls = []
      runner = lambda do |args:, **|
        calls << args
        if args[1] == "POST"
          raise IOError, "socket closed"
        end
        {success: true, status: 200, stdout: "[]", stderr: "", exit_code: 0}
      end
      provider = Ace::Git::Forgejo::Provider.new(server: SERVER, runner: runner)
      pr = Struct.new(:number, :head_sha, :state).new(42, HEAD, :open)

      error = assert_raises(Ace::Git::ProviderUnknownOutcomeError) do
        provider.stub(:pull_request, pr) do
          provider.create_pull_request_comment(
            number: 42, expected_head: HEAD, body: "Reviewed", correlation: "session-1"
          )
        end
      end
      assert_includes error.message, "session-1"
      assert_equal 1, calls.count { |args| args[1] == "POST" }
    end

    def test_thread_resolution_reports_unsupported
      provider = Ace::Git::Forgejo::Provider.new(server: SERVER)
      assert_raises(Ace::Git::ProviderUnsupportedCapabilityError) do
        provider.resolve_pull_request_thread(number: 42, expected_head: HEAD, thread_id: "thread")
      end
    end

    def test_comment_update_rejects_id_outside_selected_pr
      calls = []
      runner = lambda do |args:, **|
        calls << args
        {success: true, status: 200, stdout: "[]", stderr: "", exit_code: 0}
      end
      provider = Ace::Git::Forgejo::Provider.new(server: SERVER, runner: runner)
      pr = Struct.new(:number, :head_sha, :state).new(42, HEAD, :open)
      assert_raises(Ace::Git::ProviderIdentityMismatchError) do
        provider.stub(:pull_request, pr) do
          provider.update_pull_request_comment(number: 42, expected_head: HEAD, comment_id: 99, body: "edit")
        end
      end
      assert calls.none? { |args| args[1] == "PATCH" }
    end
def test_team_review_identity_is_accepted
  team_review = {"id" => 77, "user" => nil, "team" => {"name" => "core-devs"}, "body" => "Team review",
                 "state" => "APPROVED", "html_url" => "https://forge.example.com/review/77"}
  calls = []
  runner = lambda do |args:, **|
    calls << args
    # forgejo-http GET routes carry the API path in args[2].
    path = args[2].to_s
    payload =
      if path.include?("/issues/42/comments")
        []
      elsif path.include?("/pulls/42/reviews/77/comments")
        [{"id" => 91, "user" => {"login" => "reviewer"}, "body" => "Inline note",
          "html_url" => "https://forge.example.com/comment/91"}]
      elsif path.include?("/pulls/42/reviews")
        page = path[/page=(\d+)/, 1].to_i
        page <= 1 ? [team_review] : []
      else
        []
      end
    {success: true, status: 200, stdout: payload.to_json, stderr: "", exit_code: 0}
  end
  provider = Ace::Git::Forgejo::Provider.new(server: SERVER, runner: runner)
  pr = Struct.new(:number, :head_sha, :state).new(42, HEAD, :open)

  evidence = provider.stub(:pull_request, pr) do
    provider.pull_request_review_evidence(number: 42, expected_head: HEAD)
  end

  team = evidence.reviews.find { |r| r.author == "core-devs" }
  assert team, "team-identified reviews must be accepted with the team name as author"
  # Per-review comments are collected even though editing them is
  # unsupported on the observed fj surface.
  assert evidence.comments.any? { |c| c.id == 91 }
end
  end
end
