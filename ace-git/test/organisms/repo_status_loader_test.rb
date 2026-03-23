# frozen_string_literal: true

require_relative "../test_helper"
require "ace/git/organisms/repo_status_loader"

class RepoStatusLoaderTest < AceGitTestCase
  def setup
    super
    setup_repo_status_loader_defaults
  end

  # Initialize default mock data for repo status loader tests
  # This provides consistent mock state across all tests
  def setup_repo_status_loader_defaults
    @mock_branch_info = {
      name: "feature-branch",
      tracking: "origin/feature-branch",
      detached: false,
      ahead: 2,
      behind: 0
    }
    # Default empty PR list for fetch_all_prs stub
    @empty_prs = {success: true, prs: []}

    # Default mocks for git status and commits
    @mock_status = {success: true, output: ""}
    @mock_commits = {success: true, commits: []}
  end

  # Consolidated stub helper to reduce nesting overhead
  # This replaces 6-7 levels of nested stubs with a single helper call
  #
  # @param repository_type [Symbol] Repository type: :normal, :not_git, :bare
  # @param usable [Boolean] Whether repository is usable
  # @param repository_state [Symbol] Repository state: :clean, :dirty, :no_repository
  # @param branch_info [Hash] Mock branch information (name, tracking, detached, etc.)
  # @param task_pattern [Hash, nil] Mock task pattern extracted from branch
  # @param prs [Hash, Proc] Mock PR data for fetch_all_prs
  # @param find_pr_for_branch [Hash, nil] Mock PR data for find_pr_for_branch (defaults to nil for hermeticity)
  # @param fetch_metadata [Proc, nil] Custom metadata fetcher stub
  # @param recently_merged [Hash] Mock data for fetch_recently_merged (defaults to empty for hermeticity)
  # @param open_prs [Hash] Mock data for fetch_open_prs (defaults to empty for hermeticity)
  # @param git_status [Hash] Mock git status output
  # @param commits [Hash, Proc] Mock recent commits data
  def with_mock_repo_load(**options)
    # Extract options with defaults
    repository_type = options.fetch(:repository_type, :normal)
    usable = options.fetch(:usable?, true)
    repository_state = options.fetch(:repository_state, :clean)
    branch_info = options.fetch(:branch_info, @mock_branch_info)
    task_pattern = options.fetch(:task_pattern, nil)
    prs = options.fetch(:prs, @empty_prs)
    find_pr_for_branch = options.fetch(:find_pr_for_branch, nil)
    fetch_metadata = options.fetch(:fetch_metadata, nil)
    recently_merged = options.fetch(:recently_merged, {success: true, prs: []})
    open_prs = options.fetch(:open_prs, {success: true, prs: []})
    git_status = options.fetch(:git_status, @mock_status)
    commits = options.fetch(:commits, @mock_commits)

    # Apply all stubs at once - much faster than nested stubs
    # Note: find_pr_for_branch and fetch_metadata defaults ensure test hermeticity
    # by preventing real gh CLI calls when include_pr: true but include_pr_activity: false
    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, repository_type do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, usable do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, repository_state do
          Ace::Git::Molecules::BranchReader.stub :full_info, branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, task_pattern do
              Ace::Git::Molecules::GitStatusFetcher.stub :fetch_status_sb, git_status do
                Ace::Git::Molecules::RecentCommitsFetcher.stub :fetch, commits do
                  Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, prs do
                    Ace::Git::Molecules::PrMetadataFetcher.stub :find_pr_for_branch, find_pr_for_branch do
                      # Default fetch_metadata to failure response for hermeticity
                      stubbed_metadata = fetch_metadata || ->(*) { {success: false} }
                      Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_metadata, stubbed_metadata do
                        # Stub fetch_recently_merged and fetch_open_prs for hermeticity
                        Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_recently_merged, recently_merged do
                          Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_open_prs, open_prs do
                            yield
                          end
                        end
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def test_load_returns_context_with_branch_info
    with_mock_repo_load do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert_equal "feature-branch", context.branch
      assert_equal "origin/feature-branch", context.tracking
      assert_equal :normal, context.repository_type
      assert_equal :clean, context.repository_state
    end
  end

  def test_load_extracts_task_pattern_from_branch
    task_pattern = {prefix: "123", full: "123-feature"}

    with_mock_repo_load(task_pattern: task_pattern) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert_equal task_pattern, context.task_pattern
    end
  end

  def test_load_returns_unusable_context_when_not_in_repo
    with_mock_repo_load(
      repository_type: :not_git,
      usable?: false,
      repository_state: :no_repository
    ) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert_nil context.branch
      assert_equal :not_git, context.repository_type
      assert_equal :no_repository, context.repository_state
    end
  end

  def test_load_skips_pr_when_include_pr_false
    with_mock_repo_load do
      # Should NOT call fetch_pr_for_branch
      context = Ace::Git::Organisms::RepoStatusLoader.load(include_pr: false)

      assert_nil context.pr_metadata
      refute context.has_pr?
    end
  end

  def test_load_skips_pr_when_detached_head
    detached_branch_info = @mock_branch_info.merge(detached: true, name: "HEAD")

    with_mock_repo_load(branch_info: detached_branch_info) do
      # Should NOT call fetch_pr_for_branch because branch is detached
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert_nil context.pr_metadata
    end
  end

  def test_load_fetches_pr_metadata_when_pr_found
    # PR for current branch with matching headRefName
    mock_pr = {"number" => 42, "title" => "Test PR", "headRefName" => "feature-branch"}
    mock_prs = build_mock_prs(current_pr: mock_pr)

    with_mock_repo_load(prs: mock_prs) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert context.has_pr?
      assert_equal 42, context.pr_metadata["number"]
    end
  end

  def test_load_minimal_returns_context_without_pr
    with_mock_repo_load do
      context = Ace::Git::Organisms::RepoStatusLoader.load_minimal

      assert_equal "feature-branch", context.branch
      assert_nil context.pr_metadata
    end
  end

  def test_load_for_pr_fetches_specific_pr
    mock_pr_metadata = {"number" => 99, "title" => "Specific PR"}
    fetch_metadata_stub = ->(id, **_opts) {
      {success: true, metadata: mock_pr_metadata} if id == "99"
    }

    with_mock_repo_load(fetch_metadata: fetch_metadata_stub) do
      context = Ace::Git::Organisms::RepoStatusLoader.load_for_pr("99")

      assert context.has_pr?
      assert_equal mock_pr_metadata, context.pr_metadata
    end
  end

  def test_load_handles_gh_not_installed_gracefully
    prs_stub = ->(**_) {
      raise Ace::Git::GhNotInstalledError, "gh not installed"
    }

    with_mock_repo_load(prs: prs_stub) do
      # Should not raise, just skip PR metadata
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert_equal "feature-branch", context.branch
      assert_nil context.pr_metadata
    end
  end

  def test_load_handles_pr_not_found_gracefully
    with_mock_repo_load do
      # No PR matching current branch (default @empty_prs)
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert_equal "feature-branch", context.branch
      assert_nil context.pr_metadata
    end
  end

  def test_load_handles_timeout_gracefully
    prs_stub = ->(**_) {
      raise Ace::Git::TimeoutError, "Timeout"
    }

    with_mock_repo_load(prs: prs_stub) do
      # Should not raise, just skip PR metadata
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert_equal "feature-branch", context.branch
      assert_nil context.pr_metadata
    end
  end

  def test_load_respects_timeout_option
    captured_timeout = nil
    prs_stub = ->(timeout:, **_) {
      captured_timeout = timeout
      @empty_prs
    }

    with_mock_repo_load(prs: prs_stub) do
      Ace::Git::Organisms::RepoStatusLoader.load(timeout: 60)

      assert_equal 60, captured_timeout
    end
  end

  # PR Activity tests

  def test_load_fetches_pr_activity_by_default
    mock_merged = [{"number" => 84, "title" => "Merged PR", "mergedAt" => "2025-01-01"}]
    mock_open = [{"number" => 85, "title" => "Open PR", "headRefName" => "other-branch"}]
    mock_prs = build_mock_prs(merged_prs: mock_merged, open_prs: mock_open)

    with_mock_repo_load(prs: mock_prs) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert context.has_pr_activity?
      assert_equal 1, context.pr_activity[:merged].length
      assert_equal 1, context.pr_activity[:open].length
    end
  end

  def test_load_skips_pr_activity_when_include_pr_activity_false
    with_mock_repo_load do
      # Should NOT call fetch_all_prs when only include_pr is true
      context = Ace::Git::Organisms::RepoStatusLoader.load(include_pr_activity: false)

      assert_nil context.pr_activity
      refute context.has_pr_activity?
    end
  end

  def test_load_excludes_current_branch_from_open_prs
    # Open PR on current branch should be treated as current PR, not open activity
    current_pr = {"number" => 83, "headRefName" => "feature-branch"}
    other_pr = {"number" => 85, "headRefName" => "other-branch"}
    mock_prs = build_mock_prs(current_pr: current_pr, open_prs: [other_pr])

    with_mock_repo_load(prs: mock_prs) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      # Current PR is separate from activity
      assert context.has_pr?
      assert_equal 83, context.pr_metadata["number"]
      # Open activity should only include other branch
      assert_equal 1, context.pr_activity[:open].length
      assert_equal "other-branch", context.pr_activity[:open][0]["headRefName"]
    end
  end

  def test_load_minimal_skips_pr_activity
    with_mock_repo_load do
      context = Ace::Git::Organisms::RepoStatusLoader.load_minimal

      assert_nil context.pr_activity
      refute context.has_pr_activity?
    end
  end

  def test_load_handles_pr_activity_failure_gracefully
    failed_prs = {success: false, prs: []}

    with_mock_repo_load(prs: failed_prs) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      # Should have nil pr_activity when API fails
      assert_nil context.pr_activity
    end
  end

  def test_load_includes_pr_activity_when_partial_success
    # Only merged PRs returned, no open ones
    mock_merged = [{"number" => 84, "mergedAt" => "2025-01-01"}]
    mock_prs = build_mock_prs(merged_prs: mock_merged)

    with_mock_repo_load(prs: mock_prs) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      # Should have pr_activity with merged but empty open
      assert context.has_pr_activity?
      assert_equal 1, context.pr_activity[:merged].length
      assert_empty context.pr_activity[:open]
    end
  end

  def test_load_finds_merged_pr_for_current_branch
    merged_pr = {"number" => 90, "title" => "Merged PR", "headRefName" => "feature-branch", "mergedAt" => "2025-06-01"}
    mock_prs = {success: true, prs: [merged_pr.merge("state" => "MERGED")]}

    with_mock_repo_load(prs: mock_prs) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert context.has_pr?
      assert_equal 90, context.pr_metadata["number"]
    end
  end

  def test_load_prefers_open_pr_over_merged_for_current_branch
    open_pr = {"number" => 91, "title" => "Open PR", "headRefName" => "feature-branch"}
    merged_pr = {"number" => 90, "title" => "Merged PR", "headRefName" => "feature-branch", "mergedAt" => "2025-06-01"}
    mock_prs = {success: true, prs: [
      merged_pr.merge("state" => "MERGED"),
      open_pr.merge("state" => "OPEN")
    ]}

    with_mock_repo_load(prs: mock_prs) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert context.has_pr?
      assert_equal 91, context.pr_metadata["number"]
    end
  end

  # Git status and recent commits tests

  def test_load_fetches_git_status
    mock_status = "## feature-branch...origin/feature-branch\n M file.rb"
    git_status_mock = {success: true, output: mock_status}

    with_mock_repo_load(git_status: git_status_mock) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert context.has_git_status?
      assert_equal mock_status, context.git_status_sb
    end
  end

  def test_load_fetches_recent_commits
    mock_commits = [
      {hash: "a7404e9", subject: "feat: Add feature"},
      {hash: "74e8f77", subject: "chore: Update config"}
    ]
    commits_mock = {success: true, commits: mock_commits}

    with_mock_repo_load(commits: commits_mock) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert context.has_recent_commits?
      assert_equal 2, context.recent_commits.length
      assert_equal "a7404e9", context.recent_commits[0][:hash]
    end
  end

  def test_load_respects_commits_limit
    captured_limit = nil
    commits_stub = ->(limit:) {
      captured_limit = limit
      {success: true, commits: []}
    }

    with_mock_repo_load(commits: commits_stub) do
      Ace::Git::Organisms::RepoStatusLoader.load(commits_limit: 5)

      assert_equal 5, captured_limit
    end
  end

  def test_load_skips_commits_when_include_commits_false
    with_mock_repo_load do
      # Should NOT call fetch on RecentCommitsFetcher
      context = Ace::Git::Organisms::RepoStatusLoader.load(include_commits: false)

      refute context.has_recent_commits?
    end
  end

  def test_load_minimal_skips_commits_and_status
    with_mock_repo_load do
      context = Ace::Git::Organisms::RepoStatusLoader.load_minimal

      refute context.has_recent_commits?
      refute context.has_pr_activity?
    end
  end
end
