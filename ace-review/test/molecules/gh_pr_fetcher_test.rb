# frozen_string_literal: true

require "test_helper"
require "ace/review/molecules/gh_pr_fetcher"

module Ace
  module Review
    module Molecules
      class GhPrFetcherTest < AceReviewTest
        def setup
          super
          @parsed = mock_parse_result(number: "42")
        end

        # ====================================
        # handle_fetch_error: 406 detection
        # ====================================

        def test_handle_fetch_error_raises_diff_too_large_on_406
          result = {stderr: "HTTP 406: diff too large", exit_code: 1}

          assert_raises(Ace::Review::Errors::DiffTooLargeError) do
            GhPrFetcher.send(:handle_fetch_error, result, "42")
          end
        end

        def test_handle_fetch_error_raises_diff_too_large_on_exceeded_maximum
          result = {stderr: "exceeded the maximum number of files", exit_code: 1}

          assert_raises(Ace::Review::Errors::DiffTooLargeError) do
            GhPrFetcher.send(:handle_fetch_error, result, "42")
          end
        end

        def test_handle_fetch_error_still_raises_pr_not_found
          result = {stderr: "not found", exit_code: 1}

          assert_raises(Ace::Review::Errors::PrNotFoundError) do
            GhPrFetcher.send(:handle_fetch_error, result, "42")
          end
        end

        # ====================================
        # fetch_diff: fallback on DiffTooLargeError
        # ====================================

        def test_fetch_diff_falls_back_to_local_on_diff_too_large
          # Stub parse
          parse_stub = ->(_id) { @parsed }

          # First call (diff) returns 406
          call_count = 0
          mock_executor = lambda do |cmd, args, **opts|
            call_count += 1
            if call_count == 1
              # pr diff → 406
              {success: false, stdout: "", stderr: "HTTP 406", exit_code: 1}
            else
              # pr view (metadata fetch for fallback)
              {success: true, stdout: '{"baseRefName":"main","number":42}'}
            end
          end

          commands = []
          mock_local = lambda do |*args|
            commands << args
            if args.include?("fetch")
              {success: true, stdout: "", stderr: ""}
            elsif args.include?("merge-base")
              {success: true, stdout: "abc123\n", stderr: ""}
            elsif args.include?("update-ref")
              {success: true, stdout: "", stderr: ""}
            else
              {success: true, stdout: "diff --git a/f b/f\n+hello", stderr: ""}
            end
          end

          Ace::Git::Atoms::PrIdentifierParser.stub :parse, parse_stub do
            GhCliExecutor.stub :execute, mock_executor do
              GhPrFetcher.stub :run_local_command, mock_local do
                result = GhPrFetcher.fetch_diff("42")

                assert result[:success]
                assert_equal :local_git_diff, result[:fallback]
                assert_match(/\+hello/, result[:diff])
                refute commands.any? { |args| args.include?("HEAD") }
              end
            end
          end
        end

        # ====================================
        # fetch_local_diff_fallback
        # ====================================

        def test_fallback_returns_error_when_metadata_fails
          parse_stub = ->(_id) { @parsed }

          mock_executor = lambda do |_cmd, _args, **_opts|
            {success: false, stdout: "", stderr: "not found", exit_code: 1}
          end

          Ace::Git::Atoms::PrIdentifierParser.stub :parse, parse_stub do
            GhCliExecutor.stub :execute, mock_executor do
              result = GhPrFetcher.send(:fetch_local_diff_fallback, "42")

              refute result[:success]
              assert_match(/failed to fetch PR metadata/, result[:error])
            end
          end
        end

        def test_fallback_returns_error_when_merge_base_fails
          parse_stub = ->(_id) { @parsed }

          mock_executor = lambda do |_cmd, _args, **_opts|
            {success: true, stdout: '{"baseRefName":"main","number":42}'}
          end

          mock_local = lambda do |*args|
            if args.include?("fetch") || args.include?("update-ref")
              {success: true, stdout: "", stderr: ""}
            else
              {success: false, stdout: "", stderr: "fatal: not a git repo"}
            end
          end

          Ace::Git::Atoms::PrIdentifierParser.stub :parse, parse_stub do
            GhCliExecutor.stub :execute, mock_executor do
              GhPrFetcher.stub :run_local_command, mock_local do
                result = GhPrFetcher.send(:fetch_local_diff_fallback, "42")

                refute result[:success]
                assert_match(/merge-base failed/, result[:error])
              end
            end
          end
        end

        def test_fallback_produces_local_diff
          parse_stub = ->(_id) { @parsed }

          mock_executor = lambda do |_cmd, _args, **_opts|
            {success: true, stdout: '{"baseRefName":"main","number":42}'}
          end

          commands = []
          mock_local = lambda do |*args|
            commands << args
            if args.include?("fetch")
              {success: true, stdout: "", stderr: ""}
            elsif args.include?("merge-base")
              {success: true, stdout: "deadbeef\n", stderr: ""}
            elsif args.include?("update-ref")
              {success: true, stdout: "", stderr: ""}
            else
              {success: true, stdout: "diff --git a/lib/foo.rb b/lib/foo.rb\n+new line", stderr: ""}
            end
          end

          Ace::Git::Atoms::PrIdentifierParser.stub :parse, parse_stub do
            GhCliExecutor.stub :execute, mock_executor do
              GhPrFetcher.stub :run_local_command, mock_local do
                result = GhPrFetcher.send(:fetch_local_diff_fallback, "42")

                assert result[:success]
                assert_equal :local_git_diff, result[:fallback]
                assert_match(/\+new line/, result[:diff])
                fetch_args = commands.find { |args| args[1] == "fetch" }
                merge_base_args = commands.find { |args| args[1] == "merge-base" }
                diff_args = commands.find { |args| args[1] == "diff" }
                cleanup_args = commands.find { |args| args[1] == "update-ref" }

                assert_equal ["git", "fetch", "--no-tags", "origin"], fetch_args.first(4)
                assert_match(%r{\+refs/pull/42/head:refs/ace/review/pr-42-\d+}, fetch_args[4])
                assert_equal "origin/main", merge_base_args[2]
                assert_match(%r{refs/ace/review/pr-42-\d+}, merge_base_args[3])
                assert_equal "deadbeef", diff_args[2]
                assert_equal merge_base_args[3], diff_args[3]
                assert_equal ["git", "update-ref", "-d"], cleanup_args.first(3)
                assert_equal merge_base_args[3], cleanup_args[3]
              end
            end
          end
        end
      end
    end
  end
end
