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

        def test_qualified_url_passes_repo_flag_to_gh
          commands = []
          executor = lambda do |command, args, **_options|
            commands << [command, args]
            {success: true, stdout: (args.first == "view") ? "{\"number\":42}" : "diff", stderr: "", exit_code: 0}
          end
          Ace::Git::Github::CliExecutor.stub(:execute, executor) do
            assert GhPrFetcher.fetch_diff("https://github.com/owner/repo/pull/42")[:success]
            assert GhPrFetcher.fetch_metadata("https://github.com/owner/repo/pull/42")[:success]
          end
          assert_equal ["diff", "42", "--repo", "owner/repo"], commands[0][1]
          assert_equal ["view", "42", "--repo", "owner/repo"], commands[1][1].first(4)
        end

        def test_fetch_pr_retries_when_head_changes_during_diff_fetch
          heads = ["a", "b", "b", "b"]
          diffs = ["old diff", "current diff"]
          metadata = ->(*) do
            {success: true, metadata: {"headRefOid" => heads.shift, "baseRefOid" => "base"}}
          end
          diff = ->(*) { {success: true, diff: diffs.shift, identifier: "42"} }

          GhPrFetcher.stub(:fetch_metadata, metadata) do
            GhPrFetcher.stub(:fetch_diff, diff) do
              GhPrFetcher.stub(:fetch_file_inventory, {success: true, files: []}) do
                result = GhPrFetcher.fetch_pr("42")

                assert result[:success]
                assert_equal "current diff", result[:diff]
                assert_equal "b", result[:metadata]["headRefOid"]
              end
            end
          end
        end

        def test_fetch_pr_rejects_continuously_moving_head
          heads = %w[a b c d]
          metadata = ->(*) do
            {success: true, metadata: {"headRefOid" => heads.shift, "baseRefOid" => "base"}}
          end
          diff = ->(*) { {success: true, diff: "diff"} }

          GhPrFetcher.stub(:fetch_metadata, metadata) do
            GhPrFetcher.stub(:fetch_diff, diff) do
              GhPrFetcher.stub(:fetch_file_inventory, {success: true, files: []}) do
                result = GhPrFetcher.fetch_pr("42")
                refute result[:success]
                assert_match(/changed while fetching/, result[:error])
              end
            end
          end
        end

        def test_file_inventory_retries_transient_failures_and_reports_exhaustion
          calls = 0
          responses = [{success: false, stderr: "connection reset"}, {success: true, stdout: "[\"a.rb\"]\n"}]
          executor = ->(*) {
            calls += 1
            responses.shift
          }
          metadata = {"url" => "https://github.com/acme/repo/pull/42"}
          Ace::Git::Github::CliExecutor.stub(:execute, executor) do
            result = GhPrFetcher.fetch_file_inventory(metadata, initial_backoff: 0)
            assert result[:success]
            assert_equal 2, calls
          end
          Ace::Git::Github::CliExecutor.stub(:execute, {success: false, stderr: "connection reset"}) do
            result = GhPrFetcher.fetch_file_inventory(metadata, max_retries: 2, initial_backoff: 0)
            refute result[:success]
            assert_includes result[:error], "Failed to fetch PR file inventory"
          end
        end

        def test_fetch_file_inventory_reads_all_paginated_pages
          response = {success: true, stdout: "[\"a.rb\"]\n[\"b.rb\"]\n"}
          Ace::Git::Github::CliExecutor.stub(:execute, response) do
            result = GhPrFetcher.fetch_file_inventory({"url" => "https://github.com/acme/repo/pull/42"})
            assert result[:success]
            assert_equal [{"path" => "a.rb"}, {"path" => "b.rb"}], result[:files]
          end
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
              {success: true, stdout: "{\"baseRefOid\":\"#{"a" * 40}\",\"headRefOid\":\"#{"b" * 40}\",\"number\":42}"}
            end
          end

          commands = []
          mock_local = lambda do |*args|
            commands << args
            if args.include?("fetch")
              {success: true, stdout: "", stderr: ""}
            elsif args.include?("rev-parse")
              {success: true, stdout: "#{"b" * 40}\n", stderr: ""}
            elsif args.include?("merge-base")
              {success: true, stdout: "abc123\n", stderr: ""}
            elsif args.include?("update-ref")
              {success: true, stdout: "", stderr: ""}
            else
              {success: true, stdout: "diff --git a/f b/f\n+hello", stderr: ""}
            end
          end

          Ace::Git::Github::PrIdentifier.stub :parse, parse_stub do
            Ace::Git::Github::CliExecutor.stub :execute, mock_executor do
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

          Ace::Git::Github::PrIdentifier.stub :parse, parse_stub do
            Ace::Git::Github::CliExecutor.stub :execute, mock_executor do
              result = GhPrFetcher.send(:fetch_local_diff_fallback, "42")

              refute result[:success]
              assert_match(/failed to fetch PR metadata/, result[:error])
            end
          end
        end

        def test_fallback_returns_error_when_merge_base_fails
          parse_stub = ->(_id) { @parsed }

          mock_executor = lambda do |_cmd, _args, **_opts|
            {success: true, stdout: "{\"baseRefOid\":\"#{"a" * 40}\",\"headRefOid\":\"#{"b" * 40}\",\"number\":42}"}
          end

          mock_local = lambda do |*args|
            if args.include?("fetch") || args.include?("update-ref")
              {success: true, stdout: "", stderr: ""}
            elsif args.include?("rev-parse")
              {success: true, stdout: "#{"b" * 40}\n", stderr: ""}
            else
              {success: false, stdout: "", stderr: "fatal: not a git repo"}
            end
          end

          Ace::Git::Github::PrIdentifier.stub :parse, parse_stub do
            Ace::Git::Github::CliExecutor.stub :execute, mock_executor do
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
            {success: true, stdout: "{\"baseRefOid\":\"#{"a" * 40}\",\"headRefOid\":\"#{"b" * 40}\",\"number\":42}"}
          end

          commands = []
          mock_local = lambda do |*args|
            commands << args
            if args.include?("fetch")
              {success: true, stdout: "", stderr: ""}
            elsif args.include?("rev-parse")
              {success: true, stdout: "#{"b" * 40}\n", stderr: ""}
            elsif args.include?("merge-base")
              {success: true, stdout: "deadbeef\n", stderr: ""}
            elsif args.include?("update-ref")
              {success: true, stdout: "", stderr: ""}
            else
              {success: true, stdout: "diff --git a/lib/foo.rb b/lib/foo.rb\n+new line", stderr: ""}
            end
          end

          Ace::Git::Github::PrIdentifier.stub :parse, parse_stub do
            Ace::Git::Github::CliExecutor.stub :execute, mock_executor do
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
                assert_match(%r{refs/ace/review/pr-42-\d+-base}, merge_base_args[2])
                assert_match(%r{refs/ace/review/pr-42-\d+}, merge_base_args[3])
                base_fetch = commands.find { |args| args[1] == "fetch" && args[4].start_with?("+#{"a" * 40}:") }
                refute_nil base_fetch
                assert_equal "deadbeef", diff_args[2]
                assert_equal merge_base_args[3], diff_args[3]
                assert_equal ["git", "update-ref", "-d"], cleanup_args.first(3)
                assert_equal merge_base_args[3], cleanup_args[3]
              end
            end
          end
        end

        def test_fallback_fetches_qualified_pr_from_its_repository
          metadata = {success: true, metadata: {"baseRefOid" => "a" * 40, "headRefOid" => "b" * 40, "number" => 42}, identifier: "owner/repo#42"}
          commands = []
          local = lambda do |*args|
            commands << args
            stdout = if args[1] == "rev-parse"
              "#{"b" * 40}\n"
            elsif args[1] == "merge-base"
              "abc123\n"
            elsif args[1] == "diff"
              "diff --git a/a b/a\n+change"
            else
              ""
            end
            {success: true, stdout: stdout, stderr: ""}
          end
          GhPrFetcher.stub(:fetch_metadata, metadata) do
            GhPrFetcher.stub(:run_local_command, local) do
              result = GhPrFetcher.send(:fetch_local_diff_fallback, "owner/repo#42")
              assert result[:success]
            end
          end
          assert_equal 2, commands.count { |args| args[1] == "fetch" && args[3] == "https://github.com/owner/repo.git" }
        end

        def test_fetch_diff_reraises_ace_git_authentication_errors
          parse_stub = ->(_id) { @parsed }
          mock_executor = lambda do |_cmd, _args, **_opts|
            raise Ace::Git::ProviderAuthenticationError, "auth required"
          end

          Ace::Git::Github::PrIdentifier.stub :parse, parse_stub do
            Ace::Git::Github::CliExecutor.stub :execute, mock_executor do
              assert_raises(Ace::Git::ProviderAuthenticationError) do
                GhPrFetcher.fetch_diff("42")
              end
            end
          end
        end

        def test_fetch_metadata_reraises_ace_git_not_installed_errors
          parse_stub = ->(_id) { @parsed }
          mock_executor = lambda do |_cmd, _args, **_opts|
            raise Ace::Git::ProviderCliMissingError, "install gh"
          end

          Ace::Git::Github::PrIdentifier.stub :parse, parse_stub do
            Ace::Git::Github::CliExecutor.stub :execute, mock_executor do
              assert_raises(Ace::Git::ProviderCliMissingError) do
                GhPrFetcher.fetch_metadata("42")
              end
            end
          end
        end
      end
    end
  end
end
