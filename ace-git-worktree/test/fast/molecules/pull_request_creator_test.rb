# frozen_string_literal: true

require "test_helper"
require "ace/git/worktree/molecules/pull_request_creator"

class PullRequestCreatorTest < Minitest::Test
  def setup
    super
    Ace::Git.instance_variable_set(:@config, Ace::Git.config.merge(
      "servers" => [{"name" => "forgejo-lab", "provider" => "creatorfake", "url" => "https://forge.example.com/o/r"}]
    ))
  end

  def teardown
    Ace::Git.reset_config!
    Ace::Git::Providers.reset!
    super
  end

  def registered_provider(responses)
    singleton = Class.new(Ace::Git::Providers::Base) do
      responses.each do |name, block|
        define_method(name, block)
      end
    end
    Ace::Git::Providers.register(:creatorfake, singleton)
  end

  def evidence(number: 31, head_sha: "c" * 40)
    Ace::Git::ProviderPullRequest.new(
      server_name: "forgejo-lab", number: number, title: "t", body: nil, state: :open,
      head_ref: "081-fix", base_ref: "main", head_sha: head_sha, author: "u",
      url: "https://forge.example.com/o/r/pull/#{number}", draft: true, merged_at: nil,
      head_repository_url: "https://forge.example.com/o/r",
      base_repository_url: "https://forge.example.com/o/r", merge_commit_sha: nil
    )
  end

  def creator(**kwargs)
    Ace::Git::Worktree::Molecules::PullRequestCreator.new(**kwargs)
  end

  def test_create_draft_proves_pushed_head_sha_to_provider
    seen = {}
    pr = evidence
    registered_provider(
      create_pull_request: ->(head_ref:, head_repository_url:, base_ref:, expected_head:, title:, body: nil, draft: true) {
        seen = {
          head_ref: head_ref, head_repository_url: head_repository_url,
          base_ref: base_ref, expected_head: expected_head, draft: draft
        }
        Ace::Git::ProviderMutationReceipt.new(
          server_name: server.name, operation: :create, pull_request: pr, idempotency: :created
        )
      }
    )

    result = creator(server_name: "forgejo-lab").create_draft(
      branch: "081-fix", base: "main", title: "081 fix",
      expected_head: "c" * 40, head_repository_url: "https://forge.example.com/o/r"
    )

    assert result[:success]
    refute result[:existing]
    assert_equal 31, result[:pr_number]
    assert_equal "c" * 40, result[:head_sha]
    assert_equal "081-fix", seen[:head_ref]
    assert_equal "c" * 40, seen[:expected_head], "pushed SHA proof must reach the provider"
    assert_equal true, seen[:draft]
    assert_equal "https://forge.example.com/o/r", seen[:head_repository_url]
  end

  def test_create_draft_reports_existing_pr_without_duplicates
    pr = evidence
    registered_provider(
      create_pull_request: ->(**_kw) {
        Ace::Git::ProviderMutationReceipt.new(
          server_name: server.name, operation: :create, pull_request: pr, idempotency: :existing
        )
      }
    )

    result = creator(server_name: "forgejo-lab").create_draft(branch: "081-fix", base: "main", title: "t", expected_head: "c" * 40)
    assert result[:success]
    assert result[:existing]
  end

  def test_classified_failures_map_to_error_results
    registered_provider(
      create_pull_request: ->(**_kw) {
        raise Ace::Git::ProviderExpectedHeadConflictError, "PR #31 head changed: expected c, found d"
      }
    )

    result = creator(server_name: "forgejo-lab").create_draft(branch: "081-fix", base: "main", title: "t", expected_head: "c" * 40)
    refute result[:success]
    assert_match(/head changed/, result[:error])
    assert_nil result[:pr_number]
  end

  def test_local_only_selection_never_resolves_a_server
    # No server resolvable: the remote URL matches nothing configured, and
    # the failure is returned as a classified error result rather than a
    # silent fallback.
    Ace::Git.instance_variable_set(:@config, {"servers" => []})
    result = creator.create_draft(branch: "081-fix", base: "main", title: "t", expected_head: "c" * 40)
    refute result[:success]
    assert_match(/matches no configured server|No default server/i, result[:error])
  end
end
