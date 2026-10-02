# frozen_string_literal: true

require "test_helper"

module Github
  class ReviewProviderTest < AceGitGithubTestCase
    SERVER = Ace::Git::ResolvedServer.new(
      name: "named-github", provider: :github, url: "https://github.example.com/owner/repo"
    )
    HEAD = "a" * 40

    def test_valid_empty_collection_preserves_identity
      calls = []
      runner = lambda do |args:, **|
        calls << args
        {success: true, stdout: "[[]]", stderr: "", exit_code: 0}
      end
      provider = Ace::Git::Github::Provider.new(server: SERVER, runner: runner)
      pr = Struct.new(:number, :head_sha).new(42, HEAD)

      evidence = provider.stub(:pull_request, pr) do
        provider.pull_request_review_evidence(number: 42, expected_head: HEAD)
      end

      assert_empty evidence.comments
      assert_empty evidence.reviews
      assert_equal "named-github", evidence.server_name
      assert_equal HEAD, evidence.head_sha
      assert_equal 3, calls.length
      assert calls.all? { |args| args.include?("--hostname") && args.include?("github.example.com") }
    end

    def test_changed_head_prevents_collection
      provider = Ace::Git::Github::Provider.new(server: SERVER,
        runner: ->(**) { flunk("provider API must not be called") })
      pr = Struct.new(:number, :head_sha).new(42, "b" * 40)

      assert_raises(Ace::Git::ProviderExpectedHeadConflictError) do
        provider.stub(:pull_request, pr) do
          provider.pull_request_review_evidence(number: 42, expected_head: HEAD)
        end
      end
    end

    def test_repeat_comment_reconciles_exact_session_without_post
      calls = []
      runner = lambda do |args:, **|
        calls << args
        comment = {"id" => 91, "body" => "Reviewed\n\n<!-- ace-review-session:session-1 -->",
                   "user" => {"login" => "reviewer"}, "html_url" => "https://github.example.com/comment/91"}
        {success: true, stdout: [[comment]].to_json, stderr: "", exit_code: 0}
      end
      provider = Ace::Git::Github::Provider.new(server: SERVER, runner: runner)
      pr = Struct.new(:number, :head_sha).new(42, HEAD)

      receipt = provider.stub(:pull_request, pr) do
        provider.create_pull_request_comment(
          number: 42, expected_head: HEAD, body: "Reviewed", correlation: "session-1"
        )
      end

      assert_equal :existing, receipt.idempotency
      assert_equal 91, receipt.comment.id
      assert calls.none? { |args| args.include?("POST") }
    end

    def test_post_timeout_is_unknown_and_cannot_auto_repeat
      calls = []
      runner = lambda do |args:, **|
        calls << args
        args.include?("POST") ? :timeout : {success: true, stdout: "[[]]", stderr: "", exit_code: 0}
      end
      provider = Ace::Git::Github::Provider.new(server: SERVER, runner: runner)
      pr = Struct.new(:number, :head_sha).new(42, HEAD)

      error = assert_raises(Ace::Git::ProviderUnknownOutcomeError) do
        provider.stub(:pull_request, pr) do
          provider.create_pull_request_comment(
            number: 42, expected_head: HEAD, body: "Reviewed", correlation: "session-1"
          )
        end
      end
      assert_includes error.message, "session-1"
      assert_equal 1, calls.count { |args| args.include?("POST") }
    end

    def test_comment_update_rejects_id_outside_selected_pr
      calls = []
      runner = lambda do |args:, **|
        calls << args
        {success: true, stdout: "[[]]", stderr: "", exit_code: 0}
      end
      provider = Ace::Git::Github::Provider.new(server: SERVER, runner: runner)
      pr = Struct.new(:number, :head_sha).new(42, HEAD)
      assert_raises(Ace::Git::ProviderIdentityMismatchError) do
        provider.stub(:pull_request, pr) do
          provider.update_pull_request_comment(number: 42, expected_head: HEAD, comment_id: 99, body: "edit")
        end
      end
      assert calls.none? { |args| args.include?("PATCH") }
    end
  end
end
