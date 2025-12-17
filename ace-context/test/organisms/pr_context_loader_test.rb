# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Context
    module Organisms
      class PrContextLoaderTest < AceTestCase
        def setup
          @context = Models::ContextData.new
        end

        # --- normalize_pr_refs tests ---

        def test_normalize_pr_refs_with_string
          loader = PrContextLoader.new
          result = loader.send(:normalize_pr_refs, "123")
          assert_equal ["123"], result
        end

        def test_normalize_pr_refs_with_array
          loader = PrContextLoader.new
          result = loader.send(:normalize_pr_refs, ["123", "456"])
          assert_equal ["123", "456"], result
        end

        def test_normalize_pr_refs_deduplicates
          loader = PrContextLoader.new
          result = loader.send(:normalize_pr_refs, ["123", "456", "123"])
          assert_equal ["123", "456"], result
        end

        def test_normalize_pr_refs_strips_whitespace
          loader = PrContextLoader.new
          result = loader.send(:normalize_pr_refs, ["  123  ", " 456 "])
          assert_equal ["123", "456"], result
        end

        def test_normalize_pr_refs_removes_empty_strings
          loader = PrContextLoader.new
          result = loader.send(:normalize_pr_refs, ["123", "", nil, "456"])
          assert_equal ["123", "456"], result
        end

        def test_normalize_pr_refs_handles_hash_format
          loader = PrContextLoader.new
          result = loader.send(:normalize_pr_refs, [{ number: 123 }, { "number" => 456 }])
          assert_equal ["123", "456"], result
        end

        def test_normalize_pr_refs_handles_nested_arrays
          loader = PrContextLoader.new
          result = loader.send(:normalize_pr_refs, [["123"], ["456", "789"]])
          assert_equal ["123", "456", "789"], result
        end

        def test_normalize_pr_refs_returns_empty_for_nil
          loader = PrContextLoader.new
          result = loader.send(:normalize_pr_refs, nil)
          assert_equal [], result
        end

        # --- process tests with mocking ---

        def test_process_returns_false_for_empty_refs
          loader = PrContextLoader.new
          result = loader.process(@context, [])
          refute result
        end

        def test_process_returns_false_for_nil_refs
          loader = PrContextLoader.new
          result = loader.process(@context, nil)
          refute result
        end

        def test_process_with_successful_pr_fetch
          mock_diff = PrMockFixtures::MOCK_DIFF_STANDARD

          mock_status = Object.new
          mock_status.define_singleton_method(:success?) { true }

          Open3.stub(:popen3, ->(*_args, &block) {
            stdin = StringIO.new
            stdout = StringIO.new(mock_diff)
            stderr = StringIO.new("")
            wait_thr = Minitest::Mock.new
            wait_thr.expect(:pid, 12345)
            wait_thr.expect(:value, mock_status)
            block.call(stdin, stdout, stderr, wait_thr) if block
          }) do
            loader = PrContextLoader.new
            result = loader.process(@context, "123")

            assert result, "Should return true for successful fetch"
            assert @context.sections, "Should have sections"
            assert @context.sections["diffs"], "Should have diffs section"
            assert_equal 1, @context.sections["diffs"][:_processed_diffs].size
          end
        end

        def test_process_with_multiple_prs
          call_count = 0
          mock_status = Object.new
          mock_status.define_singleton_method(:success?) { true }

          Open3.stub(:popen3, ->(*_args, &block) {
            diff = call_count == 0 ? PrMockFixtures::MOCK_DIFF_PR_123 : PrMockFixtures::MOCK_DIFF_PR_456
            call_count += 1
            stdin = StringIO.new
            stdout = StringIO.new(diff)
            stderr = StringIO.new("")
            wait_thr = Minitest::Mock.new
            wait_thr.expect(:pid, 12345)
            wait_thr.expect(:value, mock_status)
            block.call(stdin, stdout, stderr, wait_thr) if block
          }) do
            loader = PrContextLoader.new
            result = loader.process(@context, ["123", "456"])

            assert result
            assert_equal 2, @context.sections["diffs"][:_processed_diffs].size
          end
        end

        def test_process_records_errors_in_metadata
          mock_status = Object.new
          mock_status.define_singleton_method(:success?) { false }
          mock_status.define_singleton_method(:exitstatus) { 1 }

          Open3.stub(:popen3, ->(*_args, &block) {
            stdin = StringIO.new
            stdout = StringIO.new("")
            stderr = StringIO.new("Error: PR not found")
            wait_thr = Minitest::Mock.new
            wait_thr.expect(:pid, 12345)
            wait_thr.expect(:value, mock_status)
            block.call(stdin, stdout, stderr, wait_thr) if block
          }) do
            loader = PrContextLoader.new
            result = loader.process(@context, "999999")

            refute result, "Should return false when all fetches fail"
            assert @context.metadata[:errors], "Should have errors in metadata"
            assert @context.metadata[:errors].any? { |e| e.include?("PR fetch failed") }
          end
        end

        def test_process_surfaces_errors_to_content
          mock_status = Object.new
          mock_status.define_singleton_method(:success?) { false }
          mock_status.define_singleton_method(:exitstatus) { 1 }

          Open3.stub(:popen3, ->(*_args, &block) {
            stdin = StringIO.new
            stdout = StringIO.new("")
            stderr = StringIO.new("Error: PR not found")
            wait_thr = Minitest::Mock.new
            wait_thr.expect(:pid, 12345)
            wait_thr.expect(:value, mock_status)
            block.call(stdin, stdout, stderr, wait_thr) if block
          }) do
            loader = PrContextLoader.new
            loader.process(@context, "999999")

            assert @context.content, "Should have content"
            assert @context.content.include?("PR Fetch Errors"), "Should surface errors in content"
          end
        end

        def test_process_uses_custom_timeout
          loader = PrContextLoader.new(timeout: 120)
          assert_equal 120, loader.instance_variable_get(:@timeout)
        end

        def test_process_handles_invalid_pr_identifier
          loader = PrContextLoader.new
          result = loader.process(@context, "invalid-format")

          # Should handle gracefully, recording error
          refute result
          assert @context.metadata[:errors]
        end
      end
    end
  end
end
