# frozen_string_literal: true

require_relative "../test_helper"
require "ace/git/organisms/repo_context_loader"

class RepoContextLoaderTest < AceGitTestCase
  def setup
    super
    @mock_branch_info = {
      name: "feature-branch",
      tracking: "origin/feature-branch",
      detached: false,
      ahead: 2,
      behind: 0
    }
  end

  def test_load_returns_context_with_branch_info
    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              Ace::Git::Molecules::PrMetadataFetcher.stub :find_pr_for_branch, nil do
                context = Ace::Git::Organisms::RepoContextLoader.load

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
              Ace::Git::Molecules::PrMetadataFetcher.stub :find_pr_for_branch, nil do
                context = Ace::Git::Organisms::RepoContextLoader.load

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
          context = Ace::Git::Organisms::RepoContextLoader.load

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
              # Should NOT call fetch_pr_for_branch
              context = Ace::Git::Organisms::RepoContextLoader.load(include_pr: false)

              assert_nil context.pr_metadata
              refute context.has_pr?
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
              context = Ace::Git::Organisms::RepoContextLoader.load

              assert_nil context.pr_metadata
            end
          end
        end
      end
    end
  end

  def test_load_fetches_pr_metadata_when_pr_found
    mock_pr_metadata = { "number" => 42, "title" => "Test PR", "state" => "OPEN" }

    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              Ace::Git::Molecules::PrMetadataFetcher.stub :find_pr_for_branch, "42" do
                Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_metadata, { success: true, metadata: mock_pr_metadata } do
                  context = Ace::Git::Organisms::RepoContextLoader.load

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

  def test_load_minimal_returns_context_without_pr
    Ace::Git::Atoms::RepositoryChecker.stub :repository_type, :normal do
      Ace::Git::Atoms::RepositoryChecker.stub :usable?, true do
        Ace::Git::Atoms::RepositoryStateDetector.stub :detect, :clean do
          Ace::Git::Molecules::BranchReader.stub :full_info, @mock_branch_info do
            Ace::Git::Atoms::TaskPatternExtractor.stub :extract, nil do
              context = Ace::Git::Organisms::RepoContextLoader.load_minimal

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
              Ace::Git::Molecules::PrMetadataFetcher.stub :fetch_metadata, ->(id, **_opts) {
                { success: true, metadata: mock_pr_metadata } if id == "99"
              } do
                context = Ace::Git::Organisms::RepoContextLoader.load_for_pr("99")

                assert context.has_pr?
                assert_equal mock_pr_metadata, context.pr_metadata
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
              Ace::Git::Molecules::PrMetadataFetcher.stub :find_pr_for_branch, ->(**_) {
                raise Ace::Git::GhNotInstalledError, "gh not installed"
              } do
                # Should not raise, just skip PR metadata
                context = Ace::Git::Organisms::RepoContextLoader.load

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
              Ace::Git::Molecules::PrMetadataFetcher.stub :find_pr_for_branch, ->(**_) {
                raise Ace::Git::PrNotFoundError, "No PR"
              } do
                # Should not raise, just skip PR metadata
                context = Ace::Git::Organisms::RepoContextLoader.load

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
              Ace::Git::Molecules::PrMetadataFetcher.stub :find_pr_for_branch, ->(**_) {
                raise Ace::Git::TimeoutError, "Timeout"
              } do
                # Should not raise, just skip PR metadata
                context = Ace::Git::Organisms::RepoContextLoader.load

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
              Ace::Git::Molecules::PrMetadataFetcher.stub :find_pr_for_branch, ->(timeout:) {
                captured_timeout = timeout
                nil
              } do
                Ace::Git::Organisms::RepoContextLoader.load(timeout: 60)

                assert_equal 60, captured_timeout
              end
            end
          end
        end
      end
    end
  end
end
