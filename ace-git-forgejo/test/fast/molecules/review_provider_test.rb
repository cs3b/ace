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
      pr = Struct.new(:number, :head_sha).new(42, HEAD)

      evidence = provider.stub(:pull_request, pr) do
        provider.pull_request_review_evidence(number: 42, expected_head: HEAD)
      end

      assert_empty evidence.comments
      assert_empty evidence.reviews
      assert_equal "forge-lab", evidence.server_name
      assert_equal HEAD, evidence.head_sha
      assert_equal 3, calls.length
      assert calls.all? { |args| args[2].start_with?("https://forge.example.com/api/v1/repos/owner/repo/") }
    end

    def test_malformed_collection_is_failure
      runner = ->(**) { {success: true, status: 200, stdout: "{}", stderr: "", exit_code: 0} }
      provider = Ace::Git::Forgejo::Provider.new(server: SERVER, runner: runner)
      pr = Struct.new(:number, :head_sha).new(42, HEAD)

      assert_raises(Ace::Git::ProviderMalformedOutputError) do
        provider.stub(:pull_request, pr) do
          provider.pull_request_review_evidence(number: 42, expected_head: HEAD)
        end
      end
    end
  end
end
