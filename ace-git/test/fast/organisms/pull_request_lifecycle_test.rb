# frozen_string_literal: true

require "test_helper"
require "ace/git/organisms/pull_request_lifecycle"

module Organisms
  class PullRequestLifecycleTest < AceGitTestCase
    SERVER = Ace::Git::ResolvedServer.new(
      name: "forgejo-lab", provider: :testforge, url: "https://forge.example.com/cs3b/ace"
    )
    FORK_SERVER = Ace::Git::ResolvedServer.new(
      name: "github-public", provider: :testforge2, url: "https://git.example.com/cs3b/ace"
    )

    def setup
      super
      Ace::Git.instance_variable_set(:@config, Ace::Git.config.merge(
        "servers" => [
          {"name" => "forgejo-lab", "provider" => "testforge", "url" => SERVER.url},
          {"name" => "github-public", "provider" => "testforge2", "url" => FORK_SERVER.url, "default" => true}
        ]
      ))
      @calls = []
      @runner = lambda do |args:, timeout: nil, env: nil|
        @calls << args
        {success: true, stdout: "{}", stderr: "", exit_code: 0}
      end
    end

    def teardown
      Ace::Git.reset_config!
      super
    end

    def with_test_providers
      Ace::Git::Providers.register(:testforge, RecordingProvider)
      Ace::Git::Providers.register(:testforge2, RecordingProvider)
      yield
    ensure
      Ace::Git::Providers.reset!
    end

    def test_show_with_bare_number_resolves_remote_once
      with_test_providers do
        in_temp_repo_with_remote do
          lifecycle = Ace::Git::Organisms::PullRequestLifecycle.new
          pr = lifecycle.show("25")
          assert_equal 25, pr.number
          assert_equal "forgejo-lab", pr.server_name
        end
      end
    end

    def test_show_with_url_matching_one_server_uses_it_without_selection
      with_test_providers do
        lifecycle = Ace::Git::Organisms::PullRequestLifecycle.new
        pr = lifecycle.show("https://forge.example.com/cs3b/ace/pull/25")
        assert_equal "forgejo-lab", pr.server_name
      end
    end

    def test_show_with_url_contradicting_explicit_selection_fails_before_mutation
      with_test_providers do
        lifecycle = Ace::Git::Organisms::PullRequestLifecycle.new(server_name: "github-public")
        error = assert_raises(Ace::Git::ProviderIdentityMismatchError) do
          lifecycle.show("https://forge.example.com/cs3b/ace/pull/25")
        end
        assert_match(/does not match the selected server/, error.message)
        assert_empty @calls, "provider must not be invoked on identity mismatch"
      end
    end

    def test_show_with_ambiguous_owner_repo_requires_explicit_selection
      with_test_providers do
        Ace::Git.instance_variable_set(:@config, Ace::Git.config.merge(
          "servers" => [
            {"name" => "forgejo-lab", "provider" => "testforge", "url" => "https://forge.example.com/cs3b/ace"},
            {"name" => "forgejo-mirror", "provider" => "testforge", "url" => "https://mirror.example.com/cs3b/ace"}
          ]
        ))
        lifecycle = Ace::Git::Organisms::PullRequestLifecycle.new
        error = assert_raises(Ace::Git::AmbiguousRemoteError) do
          lifecycle.show("cs3b/ace#25")
        end
        assert_match(/matches multiple configured servers/, error.message)

        selected = Ace::Git::Organisms::PullRequestLifecycle.new(server_name: "forgejo-mirror")
        assert_equal "forgejo-mirror", selected.show("cs3b/ace#25").server_name
      end
    end

    def test_create_without_head_repo_uses_selected_server_repository
      with_test_providers do
        lifecycle = Ace::Git::Organisms::PullRequestLifecycle.new(server_name: "forgejo-lab")
        receipt = lifecycle.create(
          head_ref: "feature", base_ref: "main", expected_head: "a" * 40,
          title: "Add feature", body: "body"
        )
        assert_equal :created, receipt.idempotency
        assert_equal SERVER.url, receipt.pull_request.head_repository_url
        assert_equal SERVER.url, receipt.pull_request.base_repository_url
      end
    end

    def test_create_with_explicit_head_repo_preserves_fork_provenance
      with_test_providers do
        lifecycle = Ace::Git::Organisms::PullRequestLifecycle.new(use_default: true)
        receipt = lifecycle.create(
          head_ref: "feature", head_repository_url: "https://git.example.com/fork/ace",
          base_ref: "main", expected_head: "a" * 40, title: "Fork PR"
        )
        assert_equal "https://git.example.com/fork/ace", receipt.pull_request.head_repository_url
        assert_equal FORK_SERVER.url, receipt.pull_request.base_repository_url
      end
    end

    def test_create_rejects_unreadable_body_file
      with_test_providers do
        lifecycle = Ace::Git::Organisms::PullRequestLifecycle.new(server_name: "forgejo-lab")
        error = assert_raises(ArgumentError) do
          lifecycle.create(
            head_ref: "feature", base_ref: "main", expected_head: "a" * 40,
            title: "t", body_file: "/nonexistent/body.md"
          )
        end
        assert_match(/Body file not found/, error.message)
        assert_empty @calls
      end
    end

    def test_merge_rejects_invalid_and_missing_methods
      with_test_providers do
        lifecycle = Ace::Git::Organisms::PullRequestLifecycle.new(server_name: "forgejo-lab")
        assert_raises(ArgumentError) { lifecycle.merge("25", expected_head: "a" * 40, method: "fast-forward") }
        assert_raises(ArgumentError) { lifecycle.merge("25", expected_head: "a" * 40, method: "") }
      end
    end

    def test_selection_flags_are_mutually_exclusive
      with_test_providers do
        lifecycle = Ace::Git::Organisms::PullRequestLifecycle.new(
          server_name: "forgejo-lab", use_default: true
        )
        assert_raises(Ace::Git::ConfigError) { lifecycle.show("25") }
        assert_empty @calls
      end
    end

    private

    def in_temp_repo_with_remote
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          system("git", "init", "--quiet", "-b", "main", ".")
          system("git", "config", "user.email", "test@example.com")
          system("git", "config", "user.name", "Test")
          system("git", "remote", "add", "origin", "#{SERVER.url}.git")
          yield
        end
      end
    end

    # Minimal provider double returning fixed normalized evidence; the
    # shared @calls runner additionally proves when real commands would run.
    class RecordingProvider < Ace::Git::Providers::Base
      PR = Ace::Git::ProviderPullRequest.new(
        server_name: "x", number: 25, title: "t", state: :open, head_ref: "feature",
        base_ref: "main", head_sha: "a" * 40, author: "u", url: nil, draft: true,
        merged_at: nil, head_repository_url: nil, base_repository_url: nil, merge_commit_sha: nil
      ).freeze

      def pull_request(number:)
        Ace::Git::ProviderPullRequest.new(**PR.to_h.merge(
          server_name: server.name, number: number, base_repository_url: server.url
        ))
      end

      def create_pull_request(head_ref:, head_repository_url:, base_ref:, expected_head:, title:, body: nil, draft: true)
        Ace::Git::ProviderMutationReceipt.new(
          server_name: server.name, operation: :create,
          pull_request: Ace::Git::ProviderPullRequest.new(**PR.to_h.merge(
            server_name: server.name,
            head_repository_url: head_repository_url,
            base_repository_url: server.url
          )),
          idempotency: :created
        )
      end

      def update_pull_request(number:, expected_head:, title: nil, body: nil)
        Ace::Git::ProviderMutationReceipt.new(
          server_name: server.name, operation: :update,
          pull_request: pull_request(number: number), idempotency: nil
        )
      end

      def ready_pull_request(number:, expected_head:)
        Ace::Git::ProviderMutationReceipt.new(
          server_name: server.name, operation: :ready,
          pull_request: pull_request(number: number), idempotency: nil
        )
      end

      def merge_pull_request(number:, expected_head:, method:)
        Ace::Git::ProviderMutationReceipt.new(
          server_name: server.name, operation: :merge,
          pull_request: pull_request(number: number), idempotency: nil
        )
      end
    end
  end
end
