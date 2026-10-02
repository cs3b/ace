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
  end
end
