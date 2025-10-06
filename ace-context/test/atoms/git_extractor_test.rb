# frozen_string_literal: true

require "test_helper"
require "ace/context/atoms/git_extractor"

module Ace
  module Context
    module Atoms
      class GitExtractorTest < Minitest::Test
        def test_in_git_repo_returns_true_in_git_repo
          # This test runs in a git repo
          assert GitExtractor.in_git_repo?
        end

        def test_current_branch_returns_branch_name
          branch = GitExtractor.current_branch
          refute_nil branch
          assert_kind_of String, branch
        end

        def test_repo_root_returns_path
          root = GitExtractor.repo_root
          refute_nil root
          assert_kind_of String, root
          assert Dir.exist?(root)
        end

        def test_git_diff_with_invalid_range_returns_empty
          result = GitExtractor.git_diff("invalid-ref...HEAD")
          assert_equal "", result
        end

        def test_extract_diff_with_invalid_range_returns_failure
          result = GitExtractor.extract_diff("invalid-ref...HEAD")
          refute result[:success]
          assert_kind_of String, result[:error]
          assert_equal "invalid-ref...HEAD", result[:range]
        end

        def test_staged_diff_returns_string
          result = GitExtractor.staged_diff
          assert_kind_of String, result
        end

        def test_working_diff_returns_string
          result = GitExtractor.working_diff
          assert_kind_of String, result
        end

        def test_changed_files_with_invalid_range_returns_empty_array
          result = GitExtractor.changed_files("invalid-ref...HEAD")
          assert_equal [], result
        end

        def test_tracking_branch_returns_string_or_nil
          result = GitExtractor.tracking_branch
          # May be nil if no tracking branch is set
          assert(result.nil? || result.is_a?(String))
        end

        def test_commit_count_with_invalid_refs_returns_zero
          count = GitExtractor.commit_count("invalid-from", "invalid-to")
          assert_equal 0, count
        end
      end
    end
  end
end
