# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Bundle
    module Organisms
      class PrBundleLoaderTest < AceTestCase
        def setup
          @bundle = Models::BundleData.new
        end

        # --- normalize_pr_refs tests ---

        def test_normalize_pr_refs_with_string
          loader = PrBundleLoader.new
          result = loader.send(:normalize_pr_refs, "123")
          assert_equal ["123"], result
        end

        def test_normalize_pr_refs_with_array
          loader = PrBundleLoader.new
          result = loader.send(:normalize_pr_refs, ["123", "456"])
          assert_equal ["123", "456"], result
        end

        def test_normalize_pr_refs_deduplicates
          loader = PrBundleLoader.new
          result = loader.send(:normalize_pr_refs, ["123", "456", "123"])
          assert_equal ["123", "456"], result
        end

        def test_normalize_pr_refs_strips_whitespace
          loader = PrBundleLoader.new
          result = loader.send(:normalize_pr_refs, ["  123  ", " 456 "])
          assert_equal ["123", "456"], result
        end

        def test_normalize_pr_refs_removes_empty_strings
          loader = PrBundleLoader.new
          result = loader.send(:normalize_pr_refs, ["123", "", nil, "456"])
          assert_equal ["123", "456"], result
        end

        def test_normalize_pr_refs_handles_hash_format
          loader = PrBundleLoader.new
          result = loader.send(:normalize_pr_refs, [{number: 123}, {"number" => 456}])
          assert_equal ["123", "456"], result
        end

        def test_normalize_pr_refs_handles_nested_arrays
          loader = PrBundleLoader.new
          result = loader.send(:normalize_pr_refs, [["123"], ["456", "789"]])
          assert_equal ["123", "456", "789"], result
        end

        def test_normalize_pr_refs_returns_empty_for_nil
          loader = PrBundleLoader.new
          result = loader.send(:normalize_pr_refs, nil)
          assert_equal [], result
        end

        # --- process tests with mocking ---

        def test_process_returns_false_for_empty_refs
          loader = PrBundleLoader.new
          result = loader.process(@bundle, [])
          refute result
        end

        def test_process_returns_false_for_nil_refs
          loader = PrBundleLoader.new
          result = loader.process(@bundle, nil)
          refute result
        end

        def test_process_with_successful_pr_fetch
          mock_diff = PrMockFixtures::MOCK_DIFF_STANDARD

          # Stub ace-git public API (PrMetadataFetcher.fetch_diff) instead of Open3.capture3
          mock_response = {
            success: true,
            diff: mock_diff,
            identifier: "123",
            source: "pr:123"
          }

          Ace::Git::Molecules::PrMetadataFetcher.stub(:fetch_diff, ->(_id, **_opts) { mock_response }) do
            loader = PrBundleLoader.new
            result = loader.process(@bundle, "123")

            assert result, "Should return true for successful fetch"
            assert @bundle.sections, "Should have sections"
            assert @bundle.sections["diffs"], "Should have diffs section"
            assert_equal 1, @bundle.sections["diffs"][:_processed_diffs].size
          end
        end

        def test_process_with_multiple_prs
          call_count = 0

          # Stub ace-git public API (PrMetadataFetcher.fetch_diff) instead of Open3.capture3
          mock_fetch = lambda do |id, **_opts|
            diff = (call_count == 0) ? PrMockFixtures::MOCK_DIFF_PR_123 : PrMockFixtures::MOCK_DIFF_PR_456
            call_count += 1
            {success: true, diff: diff, identifier: id, source: "pr:#{id}"}
          end

          Ace::Git::Molecules::PrMetadataFetcher.stub(:fetch_diff, mock_fetch) do
            loader = PrBundleLoader.new
            result = loader.process(@bundle, ["123", "456"])

            assert result
            assert_equal 2, @bundle.sections["diffs"][:_processed_diffs].size
          end
        end

        def test_process_records_errors_in_metadata
          # Stub ace-git public API to return failure
          mock_response = {
            success: false,
            error: "PR not found"
          }

          Ace::Git::Molecules::PrMetadataFetcher.stub(:fetch_diff, ->(_id, **_opts) { mock_response }) do
            loader = PrBundleLoader.new
            result = loader.process(@bundle, "999999")

            refute result, "Should return false when all fetches fail"
            assert @bundle.metadata[:errors], "Should have errors in metadata"
            assert @bundle.metadata[:errors].any? { |e| e.include?("PR fetch failed") }
          end
        end

        def test_process_surfaces_errors_to_content
          # Stub ace-git public API to return failure
          mock_response = {
            success: false,
            error: "PR not found"
          }

          Ace::Git::Molecules::PrMetadataFetcher.stub(:fetch_diff, ->(_id, **_opts) { mock_response }) do
            loader = PrBundleLoader.new
            loader.process(@bundle, "999999")

            assert @bundle.content, "Should have content"
            assert @bundle.content.include?("PR Fetch Errors"), "Should surface errors in content"
          end
        end

        def test_process_uses_custom_timeout
          loader = PrBundleLoader.new(timeout: 120)
          assert_equal 120, loader.instance_variable_get(:@timeout)
        end

        def test_process_handles_invalid_pr_identifier
          loader = PrBundleLoader.new
          result = loader.process(@bundle, "invalid-format")

          # Should handle gracefully, recording error
          refute result
          assert @bundle.metadata[:errors]
        end

        # --- ace-git error type handling tests ---

        def test_process_handles_gh_not_installed_error
          mock_fetch = ->(_id, **_opts) { raise Ace::Git::GhNotInstalledError, "gh not installed" }

          Ace::Git::Molecules::PrMetadataFetcher.stub(:fetch_diff, mock_fetch) do
            loader = PrBundleLoader.new
            result = loader.process(@bundle, "123")

            refute result, "Should return false when gh not installed"
            assert @bundle.metadata[:errors], "Should have errors in metadata"
            assert @bundle.metadata[:errors].any? { |e| e.include?("gh not installed") }
          end
        end

        def test_process_handles_gh_authentication_error
          mock_fetch = ->(_id, **_opts) { raise Ace::Git::GhAuthenticationError, "not authenticated" }

          Ace::Git::Molecules::PrMetadataFetcher.stub(:fetch_diff, mock_fetch) do
            loader = PrBundleLoader.new
            result = loader.process(@bundle, "123")

            refute result, "Should return false when not authenticated"
            assert @bundle.metadata[:errors], "Should have errors in metadata"
            assert @bundle.metadata[:errors].any? { |e| e.include?("not authenticated") }
          end
        end

        def test_process_handles_pr_not_found_error
          mock_fetch = ->(_id, **_opts) { raise Ace::Git::PrNotFoundError, "PR #999 not found" }

          Ace::Git::Molecules::PrMetadataFetcher.stub(:fetch_diff, mock_fetch) do
            loader = PrBundleLoader.new
            result = loader.process(@bundle, "999")

            refute result, "Should return false when PR not found"
            assert @bundle.metadata[:errors], "Should have errors in metadata"
            assert @bundle.metadata[:errors].any? { |e| e.include?("PR #999 not found") }
          end
        end

        def test_process_handles_timeout_error
          mock_fetch = ->(_id, **_opts) { raise Ace::Git::TimeoutError, "command timed out after 30s" }

          Ace::Git::Molecules::PrMetadataFetcher.stub(:fetch_diff, mock_fetch) do
            loader = PrBundleLoader.new
            result = loader.process(@bundle, "123")

            refute result, "Should return false on timeout"
            assert @bundle.metadata[:errors], "Should have errors in metadata"
            assert @bundle.metadata[:errors].any? { |e| e.include?("timed out") }
          end
        end

        def test_process_handles_generic_gh_failure
          # Tests the else branch in fetch_single_diff (lines 94-97)
          # Generic gh failures return {success: false} instead of raising
          mock_response = {
            success: false,
            error: "gh pr command failed: network error"
          }

          Ace::Git::Molecules::PrMetadataFetcher.stub(:fetch_diff, ->(_id, **_opts) { mock_response }) do
            loader = PrBundleLoader.new
            result = loader.process(@bundle, "123")

            refute result, "Should return false on generic failure"
            assert @bundle.metadata[:errors], "Should have errors in metadata"
            assert @bundle.metadata[:errors].any? { |e| e.include?("network error") }
          end
        end

        def test_process_handles_base_git_error
          # Tests the base GitError rescue (for errors not in the specific list)
          mock_fetch = ->(_id, **_opts) { raise Ace::Git::GitError, "unexpected git operation failed" }

          Ace::Git::Molecules::PrMetadataFetcher.stub(:fetch_diff, mock_fetch) do
            loader = PrBundleLoader.new
            result = loader.process(@bundle, "123")

            refute result, "Should return false on GitError"
            assert @bundle.metadata[:errors], "Should have errors in metadata"
            assert @bundle.metadata[:errors].any? { |e| e.include?("unexpected git operation failed") }
          end
        end
      end
    end
  end
end
