# frozen_string_literal: true

require "test_helper"
require "ace/git/worktree/molecules/pull_request_checkout_preparer"
require "fileutils"

class PullRequestCheckoutPreparerTest < Minitest::Test
  def setup
    super
    @preparer = Ace::Git::Worktree::Molecules::PullRequestCheckoutPreparer.new
    @base_repo = nil
    @fork_repo = nil
    @work_dir = nil
  end

  def teardown
    FileUtils.rm_rf(@work_dir) if @work_dir && Dir.exist?(@work_dir)
    super
  end

  # Build a canonical source repo (origin) plus a fork repo and a clone
  # whose origin points at the canonical repo; fetches run in the clone.
  def in_git_sandbox
    @work_dir = Dir.mktmpdir("qk1-preparer")
    @base_repo = File.join(@work_dir, "base")
    @fork_repo = File.join(@work_dir, "fork")
    clone = File.join(@work_dir, "clone")

    git("init", "--quiet", "-b", "main", @base_repo)
    File.write(File.join(@base_repo, "file.txt"), "base\n")
    git("-C", @base_repo, "add", ".")
    git("-C", @base_repo, "-c", "user.email=t@example.com", "-c", "user.name=T", "commit", "--quiet", "-m", "init")

    git("clone", "--quiet", @base_repo, clone)
    git("-C", clone, "-c", "user.email=t@example.com", "-c", "user.name=T", "checkout", "--quiet", "-b", "feature/x")
    File.write(File.join(clone, "file.txt"), "feature\n")
    git("-C", clone, "add", ".")
    git("-C", clone, "-c", "user.email=t@example.com", "-c", "user.name=T", "commit", "--quiet", "-m", "feature")
    git("-C", clone, "push", "--quiet", "origin", "feature/x")
    @feature_sha = git_out("-C", clone, "rev-parse", "HEAD")

    git("init", "--quiet", "-b", "main", @fork_repo)
    git("-C", @fork_repo, "fetch", "--quiet", clone, "feature/x")
    git("-C", @fork_repo, "update-ref", "refs/heads/feature/x", @feature_sha)

    Dir.chdir(clone) do
      yield
    end
  end

  def evidence(head_url:, head_ref: "feature/x", head_sha: @feature_sha)
    Ace::Git::ProviderPullRequest.new(
      server_name: "forgejo-lab", number: 25, title: "t", state: :open,
      head_ref: head_ref, base_ref: "main", head_sha: head_sha, author: "u",
      url: nil, draft: true, merged_at: nil,
      head_repository_url: head_url, base_repository_url: "https://forge.example.com/o/r",
      merge_commit_sha: nil
    )
  end

  def test_fetches_via_matching_local_remote_and_tracks_it
    in_git_sandbox do
      result = @preparer.prepare(evidence(head_url: @base_repo))
      assert result[:success], result[:error]
      assert_equal "FETCH_HEAD", result[:local_ref]
      assert_equal @feature_sha, result[:sha]
      assert_equal "origin/feature/x", result[:remote_tracking]
    end
  end

  def test_fetches_fork_source_by_explicit_url
    in_git_sandbox do
      result = @preparer.prepare(evidence(head_url: @fork_repo))
      assert result[:success], result[:error]
      assert_equal "FETCH_HEAD", result[:local_ref]
      assert_equal @feature_sha, result[:sha]
      assert_nil result[:remote_tracking], "URL fetches must not create remote-tracking refs"
    end
  end

  def test_rejects_sha_mismatch_between_fetch_and_evidence
    in_git_sandbox do
      result = @preparer.prepare(evidence(head_url: @base_repo, head_sha: "b" * 40))
      refute result[:success]
      assert_match(/does not match PR evidence head/, result[:error])
    end
  end

  def test_rejects_evidence_without_source_provenance
    in_git_sandbox do
      result = @preparer.prepare(evidence(head_url: nil))
      refute result[:success]
      assert_match(/missing the source repository URL/, result[:error])

      result = @preparer.prepare(evidence(head_url: @base_repo, head_ref: nil))
      refute result[:success]
      assert_match(/missing the source branch/, result[:error])
    end
  end

  def test_rejects_evidence_without_exact_head
    in_git_sandbox do
      result = @preparer.prepare(evidence(head_url: @base_repo, head_sha: nil))
      refute result[:success]
      assert_match(/missing the exact head SHA/, result[:error])
    end
  end

  private

  def git(*args)
    system("git", *args) || flunk("git #{args.join(" ")} failed")
  end

  def git_out(*args)
    out, status = Open3.capture2("git", *args)
    flunk("git #{args.join(" ")} failed") unless status.success?
    out.strip
  end
end
