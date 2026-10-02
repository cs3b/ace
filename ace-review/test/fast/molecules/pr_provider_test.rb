# frozen_string_literal: true

require "test_helper"

class PrProviderTest < AceReviewTest
  def test_projects_forge_neutral_snapshot_with_exact_identity
    %i[github forgejo].each do |provider_type|
      server = (provider_type == :github) ? "public" : "lab"
      repository = (provider_type == :github) ?
        "https://github.com/owner/repo" : "https://forge.example.com/owner/repo"
      pr = Ace::Git::ProviderPullRequest.new(
        server_name: server, number: 42, title: "Review", state: :open, body: nil,
        head_ref: "feature", base_ref: "main", head_sha: "a" * 40,
        author: "dev", url: "#{repository}/pulls/42", draft: false,
        merged_at: nil, head_repository_url: repository,
        base_repository_url: repository, merge_commit_sha: nil
      )
      comment = Ace::Git::ProviderReviewComment.new(
        server_name: server, repository_url: repository, pr_number: 42,
        id: 9, author: "reviewer", body: "Please fix", url: "#{repository}/comments/9",
        path: nil, line: nil, head_sha: nil, resolved: nil, thread_id: nil
      )
      review_evidence = Ace::Git::ProviderReviewEvidence.new(
        server_name: server, repository_url: repository, pr_number: 42,
        head_sha: "a" * 40, comments: [comment], reviews: []
      )
      snapshot = Ace::Git::ProviderReviewSnapshot.new(
        provider: provider_type, pull_request: pr, base_sha: "b" * 40,
        files: ["lib/a.rb"], diff: "diff --git a/lib/a.rb b/lib/a.rb\n",
        review_evidence: review_evidence, checks: []
      )
      lifecycle = Object.new
      lifecycle.define_singleton_method(:review_snapshot) { |_identifier, **_kwargs| snapshot }

      result = Ace::Review::Molecules::PrProvider.new(lifecycle: lifecycle).fetch("42")

      assert result[:success]
      assert_equal server, result[:metadata]["server_name"]
      assert_equal provider_type.to_s, result[:metadata]["provider"]
      assert_equal repository, result[:metadata]["repository_url"]
      assert_equal "a" * 40, result[:metadata]["headRefOid"]
      assert_equal "b" * 40, result[:metadata]["baseRefOid"]
    assert_equal "Please fix", result[:comments][:comments].first[:body]
  end

  def test_inline_comment_without_thread_id_is_not_presented_as_resolvable
    server = "public"
    repository = "https://github.com/owner/repo"
    pr = Ace::Git::ProviderPullRequest.new(
      server_name: server, number: 42, title: "Review", body: nil, state: :open,
      head_ref: "feature", base_ref: "main", head_sha: "a" * 40,
      author: "dev", url: "#{repository}/pulls/42", draft: false,
      merged_at: nil, head_repository_url: repository,
      base_repository_url: repository, merge_commit_sha: nil
    )
    inline = Ace::Git::ProviderReviewComment.new(
      server_name: server, repository_url: repository, pr_number: 42,
      id: 9, author: "reviewer", body: "Please fix", url: "#{repository}/comments/9",
      path: "lib/a.rb", line: 3, head_sha: "a" * 40, resolved: nil, thread_id: nil
    )
    review_evidence = Ace::Git::ProviderReviewEvidence.new(
      server_name: server, repository_url: repository, pr_number: 42,
      head_sha: "a" * 40, comments: [inline], reviews: []
    )
    snapshot = Ace::Git::ProviderReviewSnapshot.new(
      provider: :github, pull_request: pr, base_sha: "b" * 40,
      files: ["lib/a.rb"], diff: "diff --git a/lib/a.rb b/lib/a.rb\n",
      review_evidence: review_evidence, checks: []
    )
    lifecycle = Object.new
    lifecycle.define_singleton_method(:review_snapshot) { |_identifier, **_kwargs| snapshot }

    result = Ace::Review::Molecules::PrProvider.new(lifecycle: lifecycle).fetch("42")

    thread = result[:comments][:review_threads].first
    assert_nil thread[:id], "a fetched comment without a provider thread id must not advertise the comment id as a resolvable thread"
    assert_equal 9, thread[:comments].first[:id]
    assert_nil thread[:is_resolved]
  end

  def test_metadata_projects_pr_body_for_task_spec_resolution
    server = "public"
    repository = "https://github.com/owner/repo"
    pr = Ace::Git::ProviderPullRequest.new(
      server_name: server, number: 42, title: "Review", body: "Task: 8wr.t.qk1.1", state: :open,
      head_ref: "feature", base_ref: "main", head_sha: "a" * 40,
      author: "dev", url: "#{repository}/pulls/42", draft: false,
      merged_at: nil, head_repository_url: repository,
      base_repository_url: repository, merge_commit_sha: nil
    )
    review_evidence = Ace::Git::ProviderReviewEvidence.new(
      server_name: server, repository_url: repository, pr_number: 42,
      head_sha: "a" * 40, comments: [], reviews: []
    )
    snapshot = Ace::Git::ProviderReviewSnapshot.new(
      provider: :github, pull_request: pr, base_sha: "b" * 40,
      files: [], diff: "", review_evidence: review_evidence, checks: []
    )
    lifecycle = Object.new
    lifecycle.define_singleton_method(:review_snapshot) { |_identifier, **_kwargs| snapshot }

    result = Ace::Review::Molecules::PrProvider.new(lifecycle: lifecycle).fetch("42")

    assert_equal "Task: 8wr.t.qk1.1", result[:metadata]["body"]
  end
end

  def test_provider_failure_is_not_empty_success
    lifecycle = Object.new
    lifecycle.define_singleton_method(:review_snapshot) do |_identifier, **_kwargs|
      raise Ace::Git::ProviderAuthenticationError, "login required"
    end

    result = Ace::Review::Molecules::PrProvider.new(lifecycle: lifecycle).fetch("42")
    refute result[:success]
    assert_match(/ProviderAuthenticationError/, result[:error])
  end

  def test_posted_review_contains_metadata_and_closes_unbalanced_fence
    body = Ace::Review::Molecules::PrProvider.format_comment(
      "Finding\n```ruby\nputs :ok", preset: "code-valid", model: "reviewer"
    )
    assert_includes body, "**Preset**: code-valid"
    assert_includes body, "**Model**: reviewer"
    assert_equal 2, body.scan(/^```/).length
    assert_includes body, "<details>"
  end
end
