# frozen_string_literal: true

require_relative "../test_helper"
require "ace/git/organisms/repo_status_loader"

class RepoStatusLoaderTest < AceGitTestCase
  def setup
    super
    @mock_branch_info = {
      name: "feature-branch",
      tracking: "origin/feature-branch",
      detached: false,
      ahead: 2,
      behind: 0
    }
    # Default empty PR list for fetch_all_prs stub
    @empty_prs = { success: true, prs: [] }
  end

  # Helper to build mock PR data for fetch_all_prs
  def build_mock_prs(current_pr: nil, merged_prs: [], open_prs: [])
    prs = []
    prs << current_pr.merge("state" => "OPEN") if current_pr
    merged_prs.each { |pr| prs << pr.merge("state" => "MERGED") }
    open_prs.each { |pr| prs << pr.merge("state" => "OPEN") }
    { success: true, prs: prs }
  end

  def test_load_returns_context_with_branch_info
    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, @empty_prs do
                context = Ace::Git::Organisms::RepoStatusLoader.load

                assert_equal "feature-branch", context.branch
                assert_equal "origin/feature-branch", context.tracking
                assert_equal :normal, context.repository_type
                assert_equal :clean, context.repository_state
              end
            end
          end
        end
      end
    end
  end

  def test_load_extracts_task_pattern_from_branch
    task_pattern = { prefix: "123", full: "123-feature" }

    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, task_pattern do
              Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, @empty_prs do
                context = Ace::Git::Organisms::RepoStatusLoader.load

                assert_equal task_pattern, context.task_pattern
              end
            end
          end
        end
      end
    end
  end

  def test_load_returns_unusable_context_when_not_in_repo
    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :not_git do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, false do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :no_repository do
          context = Ace::Git::Organisms::RepoStatusLoader.load

          assert_nil context.branch
          assert_equal :not_git, context.repository_type
          assert_equal :no_repository, context.repository_state
        end
      end
    end
  end

  def test_load_skips_pr_when_include_pr_false
    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, @empty_prs do
                # Should NOT call fetch_pr_for_branch
                context = Ace::Git::Organisms::RepoStatusLoader.load(include_pr: false)

                assert_nil context.pr_metadata
                refute context.has_pr?
              end
            end
          end
        end
      end
    end
  end

  def test_load_skips_pr_when_detached_head
    detached_branch_info = @mock_branch_info.merge(detached: true, name: "HEAD")

    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, detached_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              # Should NOT call fetch_pr_for_branch because branch is detached
              context = Ace::Git::Organisms::RepoStatusLoader.load

              assert_nil context.pr_metadata
            end
          end
        end
      end
    end
  end

  def test_load_fetches_pr_metadata_when_pr_found
    # PR for current branch with matching headRefName
    mock_pr = { "number" => 42, "title" => "Test PR", "headRefName" => "feature-branch" }

    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              mock_prs = build_mock_prs(current_pr: mock_pr)
              Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, mock_prs do
                context = Ace::Git::Organisms::RepoStatusLoader.load

                assert context.has_pr?
                assert_equal 42, context.pr_metadata["number"]
              end
            end
          end
        end
      end
    end
  end

  def test_load_minimal_returns_context_without_pr
    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              context = Ace::Git::Organisms::RepoStatusLoader.load_minimal

              assert_equal "feature-branch", context.branch
              assert_nil context.pr_metadata
            end
          end
        end
      end
    end
  end

  def test_load_for_pr_fetches_specific_pr
    mock_pr_metadata = { "number" => 99, "title" => "Specific PR" }

    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, @empty_prs do
                Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_metadata, ->(id, **_opts) {
                  { success: true, metadata: mock_pr_metadata } if id == "99"
                } do
                  context = Ace::Git::Organisms::RepoStatusLoader.load_for_pr("99")

                  assert context.has_pr?
                  assert_equal mock_pr_metadata, context.pr_metadata
                end
              end
            end
          end
        end
      end
    end
  end

  def test_load_handles_gh_not_installed_gracefully
    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, ->(**_) {
                raise Ace::Git::GhNotInstalledError, "gh not installed"
              } do
                # Should not raise, just skip PR metadata
                context = Ace::Git::Organisms::RepoStatusLoader.load

                assert_equal "feature-branch", context.branch
                assert_nil context.pr_metadata
              end
            end
          end
        end
      end
    end
  end

  def test_load_handles_pr_not_found_gracefully
    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              # No PR matching current branch
              Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, @empty_prs do
                context = Ace::Git::Organisms::RepoStatusLoader.load

                assert_equal "feature-branch", context.branch
                assert_nil context.pr_metadata
              end
            end
          end
        end
      end
    end
  end

  def test_load_handles_timeout_gracefully
    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, ->(**_) {
                raise Ace::Git::TimeoutError, "Timeout"
              } do
                # Should not raise, just skip PR metadata
                context = Ace::Git::Organisms::RepoStatusLoader.load

                assert_equal "feature-branch", context.branch
                assert_nil context.pr_metadata
              end
            end
          end
        end
      end
    end
  end

  def test_load_respects_timeout_option
    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              captured_timeout = nil
              Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, ->(timeout:, **_) {
                captured_timeout = timeout
                @empty_prs
              } do
                Ace::Git::Organisms::RepoStatusLoader.load(timeout: 60)

                assert_equal 60, captured_timeout
              end
            end
          end
        end
      end
    end
  end

  # PR Activity tests

  def test_load_fetches_pr_activity_by_default
    mock_merged = [{ "number" => 84, "title" => "Merged PR", "mergedAt" => "2025-01-01" }]
    mock_open = [{ "number" => 85, "title" => "Open PR", "headRefName" => "other-branch" }]

    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              mock_prs = build_mock_prs(merged_prs: mock_merged, open_prs: mock_open)
              Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, mock_prs do
                context = Ace::Git::Organisms::RepoStatusLoader.load

                assert context.has_pr_activity?
                assert_equal 1, context.pr_activity[:merged].length
                assert_equal 1, context.pr_activity[:open].length
              end
            end
          end
        end
      end
    end
  end

  def test_load_skips_pr_activity_when_include_pr_activity_false
    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, @empty_prs do
                Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_metadata, { success: false } do
                  # Should NOT call fetch_all_prs when only include_pr is true
                  context = Ace::Git::Organisms::RepoStatusLoader.load(include_pr_activity: false)

                  assert_nil context.pr_activity
                  refute context.has_pr_activity?
                end
              end
            end
          end
        end
      end
    end
  end

  def test_load_excludes_current_branch_from_open_prs
    # Open PR on current branch should be treated as current PR, not open activity
    current_pr = { "number" => 83, "headRefName" => "feature-branch" }
    other_pr = { "number" => 85, "headRefName" => "other-branch" }

    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              mock_prs = build_mock_prs(current_pr: current_pr, open_prs: [other_pr])
              Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, mock_prs do
                context = Ace::Git::Organisms::RepoStatusLoader.load

                # Current PR is separate from activity
                assert context.has_pr?
                assert_equal 83, context.pr_metadata["number"]
                # Open activity should only include other branch
                assert_equal 1, context.pr_activity[:open].length
                assert_equal "other-branch", context.pr_activity[:open][0]["headRefName"]
              end
            end
          end
        end
      end
    end
  end

  def test_load_minimal_skips_pr_activity
    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              context = Ace::Git::Organisms::RepoStatusLoader.load_minimal

              assert_nil context.pr_activity
              refute context.has_pr_activity?
            end
          end
        end
      end
    end
  end

  def test_load_handles_pr_activity_failure_gracefully
    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              # API call fails
              Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, { success: false, prs: [] } do
                context = Ace::Git::Organisms::RepoStatusLoader.load

                # Should have nil pr_activity when API fails
                assert_nil context.pr_activity
              end
            end
          end
        end
      end
    end
  end

  def test_load_includes_pr_activity_when_partial_success
    # Only merged PRs returned, no open ones
    mock_merged = [{ "number" => 84, "mergedAt" => "2025-01-01" }]

    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              mock_prs = build_mock_prs(merged_prs: mock_merged)
              Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, mock_prs do
                context = Ace::Git::Organisms::RepoStatusLoader.load

                # Should have pr_activity with merged but empty open
                assert context.has_pr_activity?
                assert_equal 1, context.pr_activity[:merged].length
                assert_empty context.pr_activity[:open]
              end
            end
          end
        end
      end
    end
  end

  # Git status and recent commits tests

  def test_load_fetches_git_status
    mock_status = "## feature-branch...origin/feature-branch\n M file.rb"

    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              Ace::Git::Molecules::GitStatusFetcher.stub :fetch_status_sb, { success: true, output: mock_status } do
                Ace::Git::Molecules::RecentCommitsFetcher.stub :fetch, { success: true, commits: [] } do
                  Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, @empty_prs do
                    context = Ace::Git::Organisms::RepoStatusLoader.load

                    assert context.has_git_status?
                    assert_equal mock_status, context.git_status_sb
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def test_load_fetches_recent_commits
    mock_commits = [
      { hash: "a7404e9", subject: "feat: Add feature" },
      { hash: "74e8f77", subject: "chore: Update config" }
    ]

    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              Ace::Git::Molecules::GitStatusFetcher.stub :fetch_status_sb, { success: true, output: "" } do
                Ace::Git::Molecules::RecentCommitsFetcher.stub :fetch, { success: true, commits: mock_commits } do
                  Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, @empty_prs do
                    context = Ace::Git::Organisms::RepoStatusLoader.load

                    assert context.has_recent_commits?
                    assert_equal 2, context.recent_commits.length
                    assert_equal "a7404e9", context.recent_commits[0][:hash]
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def test_load_respects_commits_limit
    captured_limit = nil

    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              Ace::Git::Molecules::GitStatusFetcher.stub :fetch_status_sb, { success: true, output: "" } do
                Ace::Git::Molecules::RecentCommitsFetcher.stub :fetch, ->(limit:) {
                  captured_limit = limit
                  { success: true, commits: [] }
                } do
                  Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, @empty_prs do
                    Ace::Git::Organisms::RepoStatusLoader.load(commits_limit: 5)

                    assert_equal 5, captured_limit
                  end
                end
              end
            end
          end
        end
      end
    end
  end

  def test_load_skips_commits_when_include_commits_false
    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              Ace::Git::Molecules::GitStatusFetcher.stub :fetch_status_sb, { success: true, output: "" } do
                Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_all_prs, @empty_prs do
                  # Should NOT call fetch on RecentCommitsFetcher
                  context = Ace::Git::Organisms::RepoStatusLoader.load(include_commits: false)

                  refute context.has_recent_commits?
                end
              end
            end
          end
        end
      end
    end
  end

  def test_load_minimal_skips_commits_and_status
    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              Ace::Git::Molecules::GitStatusFetcher.stub :fetch_status_sb, { success: true, output: "" } do
                context = Ace::Git::Organisms::RepoStatusLoader.load_minimal

                refute context.has_recent_commits?
                refute context.has_pr_activity?
              end
            end
          end
        end
      end
    end
  end
end
