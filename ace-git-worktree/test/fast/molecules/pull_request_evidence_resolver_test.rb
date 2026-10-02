# frozen_string_literal: true

require "test_helper"
require "ace/git/worktree/molecules/pull_request_evidence_resolver"

class PullRequestEvidenceResolverTest < Minitest::Test
  def setup
    super
    Ace::Git.instance_variable_set(:@config, Ace::Git.config.merge(
      "servers" => [{"name" => "forgejo-lab", "provider" => "resolverfake", "url" => "https://forge.example.com/o/r"}]
    ))
  end

  def teardown
    Ace::Git.reset_config!
    Ace::Git::Providers.reset!
    super
  end

  def test_resolve_returns_server_and_normalized_evidence
    evidence = Ace::Git::ProviderPullRequest.new(
      server_name: "forgejo-lab", number: 25, title: "t", body: nil, state: :open,
      head_ref: "feature", base_ref: "main", head_sha: "a" * 40, author: "u",
      url: nil, draft: true, merged_at: nil, head_repository_url: nil,
      base_repository_url: nil, merge_commit_sha: nil
    )
    singleton = Class.new(Ace::Git::Providers::Base) do
      define_method(:pull_request) { |number:| evidence }
    end
    Ace::Git::Providers.register(:resolverfake, singleton)

    result = Ace::Git::Worktree::Molecules::PullRequestEvidenceResolver
      .new(server_name: "forgejo-lab").resolve(25)

    assert_equal "forgejo-lab", result[:server].name
    assert_equal evidence, result[:evidence]
    assert_equal 25, result[:evidence].number
  end

  def test_resolve_with_explicit_server_selection
    Ace::Git.instance_variable_set(:@config, Ace::Git.config.merge(
      "servers" => [
        {"name" => "forgejo-lab", "provider" => "resolverfake", "url" => "https://forge.example.com/o/r"},
        {"name" => "other", "provider" => "resolverfake", "url" => "https://other.example.com/o/r"}
      ]
    ))
    seen = nil
    singleton = Class.new(Ace::Git::Providers::Base) do
      define_method(:pull_request) do |number:|
        seen = server.name
        Ace::Git::ProviderPullRequest.new(
          server_name: server.name, number: number, title: "t", body: nil, state: :open,
          head_ref: "f", base_ref: "m", head_sha: "a" * 40, author: "u",
          url: nil, draft: nil, merged_at: nil, head_repository_url: nil,
          base_repository_url: nil, merge_commit_sha: nil
        )
      end
    end
    Ace::Git::Providers.register(:resolverfake, singleton)

    result = Ace::Git::Worktree::Molecules::PullRequestEvidenceResolver
      .new(server_name: "other").resolve(7)

    assert_equal "other", result[:server].name
    assert_equal "other", seen
  end

  def test_resolve_without_any_configuration_raises_classified_error
    Ace::Git.instance_variable_set(:@config, {"servers" => []})
    assert_raises(Ace::Git::AmbiguousRemoteError) do
      Ace::Git::Worktree::Molecules::PullRequestEvidenceResolver.new.resolve(25)
    end
  end
end
