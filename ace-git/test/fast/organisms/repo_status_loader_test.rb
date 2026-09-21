# frozen_string_literal: true

require "test_helper"
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

    # Default mocks for git status and commits
    @mock_status = {success: true, output: ""}
    @mock_commits = {success: true, commits: []}
  end

  # Consolidated stub helper to reduce nesting overhead
  #
  # @param repository_type [Symbol] Repository type: :normal, :not_git, :bare
  # @param usable [Boolean] Whether repository is usable
  # @param repository_state [Symbol] Repository state: :clean, :dirty, :no_repository
  # @param branch_info [Hash] Mock branch information (name, tracking, detached, etc.)
  # @param task_pattern [Hash, nil] Mock task pattern extracted from branch
  # @param provider [Object, nil] Fake provider for the default server; nil means
  #   no server is configured (enrichment skipped)
  # @param git_status [Hash] Mock git status output
  # @param commits [Hash, Proc] Mock recent commits data
  def with_mock_repo_load(**options)
    repository_type = options.fetch(:repository_type, :normal)
    usable = options.fetch(:usable?, true)
    repository_state = options.fetch(:repository_state, :clean)
    branch_info = options.fetch(:branch_info, @mock_branch_info)
    task_pattern = options.fetch(:task_pattern, nil)
    provider = options.fetch(:provider, nil)
    git_status = options.fetch(:git_status, @mock_status)
    commits = options.fetch(:commits, @mock_commits)

    resolve_default = if provider
      -> { SERVER }
    else
      -> { raise Ace::Git::NoDefaultServerConfiguredError, "no default" }
    end

    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, repository_type do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, usable do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, repository_state do
          Ace::Git::Molecules::BranchReader.stub :full_info, branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, task_pattern do
              Ace::Git::Molecules::GitStatusFetcher.stub :fetch_status_sb, git_status do
                Ace::Git::Molecules::RecentCommitsFetcher.stub :fetch, commits do
                  Ace::Git::ServerRegistry.stub :resolve_default, resolve_default do
                    Ace::Git::Providers.stub :for, ->(_server, **_opts) { provider } do
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

  SERVER = Ace::Git::ResolvedServer.new(name: "forge", provider: :fakeforge, url: "https://forge.example.com/owner/repo")

  # Build normalized PR evidence the way providers do
  def pr_evidence(number:, state: :open, head_ref: "feature-branch", merged_at: nil)
    Ace::Git::ProviderPullRequest.new(
      server_name: SERVER.name,
      number: number,
      title: "PR #{number}",
      state: state,
      head_ref: head_ref,
      base_ref: "main",
      head_sha: "a" * 40,
      author: "lab-builder",
      url: "#{SERVER.url}/pulls/#{number}",
      draft: false,
      merged_at: merged_at
    )
  end

  # Fake provider double standing in for a registered provider package
  class FakeProvider
    attr_reader :calls

    def initialize(branch_pr: nil, recent: [], specific: {})
      @branch_pr = branch_pr
      @recent = recent
      @specific = specific
      @calls = []
    end

    def pull_request_for_branch(branch:)
      @calls << [:branch, branch]
      @branch_pr
    end

    def recent_pull_requests(limit:)
      @calls << [:recent, limit]
      @recent
    end

    def pull_request(number:)
      @calls << [:pull_request, number]
      @specific[number.to_s]
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

  def test_load_skips_pr_enrichment_without_server_configured
    with_mock_repo_load do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert_equal "feature-branch", context.branch
      assert_nil context.pr_metadata
      refute context.has_pr?
      assert_nil context.pr_activity
    end
  end

  def test_load_skips_pr_when_include_pr_false
    provider = FakeProvider.new(branch_pr: pr_evidence(number: 42))
    with_mock_repo_load(provider: provider) do
      context = Ace::Git::Organisms::RepoStatusLoader.load(include_pr: false)

      assert_nil context.pr_metadata
      refute context.has_pr?
      refute provider.calls.any? { |(kind, _)| kind == :branch }
    end
  end

  def test_load_skips_pr_when_detached_head
    detached_branch_info = @mock_branch_info.merge(detached: true, name: "HEAD")
    provider = FakeProvider.new(branch_pr: pr_evidence(number: 42))

    with_mock_repo_load(branch_info: detached_branch_info, provider: provider) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert_nil context.pr_metadata
      refute provider.calls.any? { |(kind, _)| kind == :branch }
    end
  end

  def test_load_fetches_pr_evidence_when_pr_found
    provider = FakeProvider.new(branch_pr: pr_evidence(number: 42))

    with_mock_repo_load(provider: provider) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert context.has_pr?
      assert_equal 42, context.pr_metadata.number
      assert_instance_of Ace::Git::ProviderPullRequest, context.pr_metadata
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
    provider = FakeProvider.new(specific: {"99" => pr_evidence(number: 99, head_ref: "other")})

    with_mock_repo_load(provider: provider) do
      context = Ace::Git::Organisms::RepoStatusLoader.load_for_pr("99")

      assert context.has_pr?
      assert_equal 99, context.pr_metadata.number
    end
  end

  def test_load_handles_cli_missing_gracefully
    provider = FakeProvider.new
    def provider.pull_request_for_branch(branch:)
      raise Ace::Git::ProviderCliMissingError, "provider cli missing"
    end

    with_mock_repo_load(provider: provider) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert_equal "feature-branch", context.branch
      assert_nil context.pr_metadata
    end
  end

  def test_load_handles_no_branch_pr_gracefully
    provider = FakeProvider.new(branch_pr: nil)

    with_mock_repo_load(provider: provider) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert_equal "feature-branch", context.branch
      assert_nil context.pr_metadata
    end
  end

  def test_load_handles_unreachable_gracefully
    provider = FakeProvider.new
    def provider.pull_request_for_branch(branch:)
      raise Ace::Git::ProviderUnreachableError, "offline"
    end

    with_mock_repo_load(provider: provider) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert_equal "feature-branch", context.branch
      assert_nil context.pr_metadata
    end
  end

  def test_load_respects_timeout_option
    captured_timeout = nil
    provider = FakeProvider.new

    resolve_default = -> { SERVER }
    for_provider = ->(_server, **opts) {
      captured_timeout = opts[:timeout]
      provider
    }

    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              Ace::Git::Molecules::GitStatusFetcher.stub :fetch_status_sb, @mock_status do
                Ace::Git::Molecules::RecentCommitsFetcher.stub :fetch, @mock_commits do
                  Ace::Git::ServerRegistry.stub :resolve_default, resolve_default do
                    Ace::Git::Providers.stub :for, for_provider do
                      Ace::Git::Organisms::RepoStatusLoader.load(timeout: 60)
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    assert_equal 60, captured_timeout
  end

  # PR Activity tests

  def test_load_fetches_pr_activity_by_default
    provider = FakeProvider.new(
      recent: [
        pr_evidence(number: 84, state: :merged, head_ref: "merged-branch", merged_at: "2025-01-01"),
        pr_evidence(number: 85, state: :open, head_ref: "other-branch")
      ]
    )

    with_mock_repo_load(provider: provider) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert context.has_pr_activity?
      assert_equal 1, context.pr_activity[:merged].length
      assert_equal 1, context.pr_activity[:open].length
    end
  end

  def test_load_skips_pr_activity_when_include_pr_activity_false
    provider = FakeProvider.new(recent: [pr_evidence(number: 84, state: :merged, head_ref: "m")])

    with_mock_repo_load(provider: provider) do
      context = Ace::Git::Organisms::RepoStatusLoader.load(include_pr_activity: false)

      assert_nil context.pr_activity
      refute context.has_pr_activity?
      refute provider.calls.any? { |(kind, _)| kind == :recent }
    end
  end

  def test_load_excludes_current_branch_from_open_prs
    provider = FakeProvider.new(
      branch_pr: pr_evidence(number: 83),
      recent: [
        pr_evidence(number: 83),
        pr_evidence(number: 85, head_ref: "other-branch")
      ]
    )

    with_mock_repo_load(provider: provider) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert context.has_pr?
      assert_equal 83, context.pr_metadata.number
      assert_equal 1, context.pr_activity[:open].length
      assert_equal "other-branch", context.pr_activity[:open][0].head_ref
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
    provider = FakeProvider.new
    def provider.recent_pull_requests(limit:)
      raise Ace::Git::ProviderUnreachableError, "offline"
    end

    with_mock_repo_load(provider: provider) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert_nil context.pr_metadata
      assert_nil context.pr_activity
    end
  end

  def test_load_includes_pr_activity_when_partial_success
    provider = FakeProvider.new(
      recent: [pr_evidence(number: 84, state: :merged, head_ref: "merged-branch", merged_at: "2025-01-01")]
    )

    with_mock_repo_load(provider: provider) do
      context = Ace::Git::Organisms::RepoStatusLoader.load

      assert context.has_pr_activity?
      assert_equal 1, context.pr_activity[:merged].length
      assert_empty context.pr_activity[:open]
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
