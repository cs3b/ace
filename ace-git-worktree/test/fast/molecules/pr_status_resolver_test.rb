# frozen_string_literal: true

require_relative "../../test_helper"

class PrStatusResolverTest < Minitest::Test
  WorktreeInfo = Ace::Git::Worktree::Models::WorktreeInfo
  Resolver = Ace::Git::Worktree::Molecules::PrStatusResolver

  def pr(number:, state: :open, draft: false, head_ref: nil, head_sha: nil, title: "", body: "")
    {
      number: number, state: state, draft: draft, head_ref: head_ref, head_sha: head_sha,
      title: title, body: body
    }
  end

  def worktree(branch: "feat", commit: "abc123")
    WorktreeInfo.new(path: "/wt/x", branch: branch, commit: commit)
  end

  def resolver_with(prs)
    calls = []
    resolver = Resolver.new(query: lambda { |limit:|
      calls << limit
      prs
    })
    [resolver, calls]
  end

  def test_branch_match_prefers_open_over_merged
    prs = [
      pr(number: 140, state: :merged, head_ref: "feat"),
      pr(number: 142, state: :open, head_ref: "feat"),
      pr(number: 143, state: :open, head_ref: "other")
    ]
    resolver, = resolver_with(prs)

    resolved = resolver.resolve(worktree(branch: "feat"), nil)

    assert_equal 142, resolved[:number]
    assert_equal "open", resolved[:state]
    assert_equal "branch", resolved[:matched_by]
  end

  def test_head_sha_match_for_detached_worktrees
    prs = [pr(number: 142, state: :open, head_ref: "other", head_sha: "abc123")]
    resolver, = resolver_with(prs)

    resolved = resolver.resolve(worktree(branch: nil, commit: "abc123"), nil)

    assert_equal 142, resolved[:number]
    assert_equal "head_sha", resolved[:matched_by]
  end

  def test_task_reference_match
    prs = [pr(number: 142, title: "feat(8xg.t.k9y): active worktree table")]
    resolver, = resolver_with(prs)

    resolved = resolver.resolve(worktree(branch: "unknown-branch", commit: "zzz"), "k9y")

    assert_equal 142, resolved[:number]
    assert_equal "task_reference", resolved[:matched_by]
  end

  def test_task_reference_requires_bounded_token
    prs = [pr(number: 142, title: "feat(k9ya): unrelated")]
    resolver, = resolver_with(prs)

    assert_nil resolver.resolve(worktree(branch: "unknown", commit: "zzz"), "k9y")
  end

  def test_task_reference_ambiguity_yields_no_pr
    prs = [
      pr(number: 142, title: "feat(k9y): one"),
      pr(number: 143, body: "closes 8xg.t.k9y")
    ]
    resolver, = resolver_with(prs)

    assert_nil resolver.resolve(worktree(branch: "unknown", commit: "zzz"), "k9y")
  end

  def test_provider_failure_is_swallowed
    resolver = Resolver.new(query: ->(limit:) { raise Ace::Git::ProviderUnreachableError, "offline" })

    assert_nil resolver.resolve(worktree, nil)
  end

  def test_single_bounded_query_per_run
    prs = [pr(number: 1, head_ref: "a"), pr(number: 2, head_ref: "b")]
    resolver, calls = resolver_with(prs)

    3.times { resolver.resolve(worktree, nil) }

    assert_equal 1, calls.length
    assert_equal Resolver::PR_QUERY_LIMIT, calls.first
  end

  def test_cell_rendering
    assert_equal "-", Resolver.cell(nil)
    assert_equal "#142", Resolver.cell(number: 142, state: "open", draft: false)
    assert_equal "#142 draft", Resolver.cell(number: 142, state: "open", draft: true)
    assert_equal "#142 merged", Resolver.cell(number: 142, state: "merged", draft: false)
    assert_equal "#142 closed", Resolver.cell(number: 142, state: "closed", draft: false)
  end

  def test_accepts_provider_evidence_objects
    evidence = Struct.new(:number, :state, :draft, :head_ref, :head_sha, :title, :body).new(
      142, :open, true, "feat", "abc123", "title", "body"
    )
    resolver, = resolver_with([evidence])

    resolved = resolver.resolve(worktree(branch: "feat"), nil)

    assert_equal 142, resolved[:number]
    assert_equal true, resolved[:draft]
  end

  def test_no_pr_returns_nil
    resolver, = resolver_with([])
    assert_nil resolver.resolve(worktree, nil)
  end
end
