# frozen_string_literal: true

require "test_helper"
require "ace/review/molecules/gh_comment_resolver"

module Ace
  module Review
    module Molecules
      class GhCommentResolverTest < AceReviewTest
        # ====================================
        # resolve_thread tests
        # ====================================

        def test_resolve_thread_returns_error_for_nil_thread_id
          result = GhCommentResolver.resolve_thread(nil)

          refute result[:success]
          assert_equal "Thread ID required", result[:error]
        end

        def test_resolve_thread_returns_error_for_empty_thread_id
          result = GhCommentResolver.resolve_thread("")

          refute result[:success]
          assert_equal "Thread ID required", result[:error]
        end

        def test_resolve_thread_validates_thread_id_format
          # Invalid patterns that should be rejected
          invalid_ids = [
            "invalid",              # No PRRT_ prefix
            "PRRT_",               # Empty after prefix
            "PRRT_abc\"def",       # Contains quote (injection attempt)
            "prrt_abc123",         # Wrong case prefix
            "PRRT_abc\n123",       # Contains newline
            "PRRT_abc 123",        # Contains space
            " PRRT_abc123",        # Leading space
            "PRRT_abc123 "        # Trailing space
          ]

          invalid_ids.each do |invalid_id|
            result = GhCommentResolver.resolve_thread(invalid_id)
            refute result[:success], "Expected #{invalid_id.inspect} to be rejected"
            assert_match(/Invalid thread ID format/, result[:error])
          end
        end

        def test_resolve_thread_accepts_valid_thread_id_format
          # Valid patterns that should be accepted (format-wise)
          valid_ids = [
            "PRRT_abc123",
            "PRRT_ABC123",
            "PRRT_a1b2c3",
            "PRRT_kwDOPzGJW85lJfEC",
            "PRRT_abc-def",
            "PRRT_abc_def",
            "PRRT_A-B_C"
          ]

          # Mock GhCliExecutor to simulate successful API response
          mock_executor = lambda do |cmd, args, **opts|
            {
              success: true,
              stdout: '{"data":{"resolveReviewThread":{"thread":{"isResolved":true}}}}'
            }
          end

          valid_ids.each do |valid_id|
            Ace::Git::Molecules::GhCliExecutor.stub :execute, mock_executor do
              result = GhCommentResolver.resolve_thread(valid_id)
              # Should proceed past validation (may fail for other reasons in tests)
              refute_match(/Invalid thread ID format/, result[:error].to_s)
            end
          end
        end

        def test_resolve_thread_success
          mock_response = {
            success: true,
            stdout: '{"data":{"resolveReviewThread":{"thread":{"isResolved":true}}}}'
          }

          Ace::Git::Molecules::GhCliExecutor.stub :execute, mock_response do
            result = GhCommentResolver.resolve_thread("PRRT_kwDOPzGJW85lJfEC")

            assert result[:success]
            assert result[:resolved]
          end
        end

        def test_resolve_thread_handles_api_error
          mock_response = {
            success: true,
            stdout: '{"errors":[{"message":"Could not resolve thread"}]}'
          }

          Ace::Git::Molecules::GhCliExecutor.stub :execute, mock_response do
            result = GhCommentResolver.resolve_thread("PRRT_abc123")

            refute result[:success]
            assert_equal "Could not resolve thread", result[:error]
          end
        end

        def test_resolve_thread_handles_cli_failure
          mock_response = {
            success: false,
            stderr: "gh: Not logged in"
          }

          Ace::Git::Molecules::GhCliExecutor.stub :execute, mock_response do
            result = GhCommentResolver.resolve_thread("PRRT_abc123")

            refute result[:success]
            assert_match(/Failed to resolve thread/, result[:error])
          end
        end

        def test_resolve_thread_handles_json_parse_error
          mock_response = {
            success: true,
            stdout: "not valid json"
          }

          Ace::Git::Molecules::GhCliExecutor.stub :execute, mock_response do
            result = GhCommentResolver.resolve_thread("PRRT_abc123")

            refute result[:success]
            assert_match(/Failed to parse response/, result[:error])
          end
        end

        # ====================================
        # reply tests
        # ====================================

        def test_reply_returns_error_for_nil_commit_sha_and_no_message
          result = GhCommentResolver.reply("69", nil)

          refute result[:success]
          assert_equal "Commit SHA or message required", result[:error]
        end

        def test_reply_returns_error_for_empty_commit_sha_and_no_message
          result = GhCommentResolver.reply("69", "")

          refute result[:success]
          assert_equal "Commit SHA or message required", result[:error]
        end

        def test_reply_allows_nil_commit_sha_with_custom_message
          mock_executor = lambda do |cmd, args, **opts|
            {
              success: true,
              stdout: "https://github.com/owner/repo/pull/69#issuecomment-12345"
            }
          end

          parsed = Ace::Git::Atoms::PrIdentifierParser::ParseResult.new(
            number: "69", repo: nil, gh_format: "69"
          )

          Ace::Git::Molecules::GhCliExecutor.stub :execute, mock_executor do
            Ace::Git::Atoms::PrIdentifierParser.stub :parse, parsed do
              result = GhCommentResolver.reply("69", nil, message: "Custom message without SHA")

              assert result[:success]
              assert_equal "Custom message without SHA", result[:message]
            end
          end
        end

        def test_reply_success
          mock_executor = lambda do |cmd, args, **opts|
            if cmd == "pr" && args.include?("comment")
              {
                success: true,
                stdout: "https://github.com/owner/repo/pull/69#issuecomment-12345"
              }
            end
          end

          parsed = Ace::Git::Atoms::PrIdentifierParser::ParseResult.new(
            number: "69", repo: nil, gh_format: "69"
          )

          Ace::Git::Molecules::GhCliExecutor.stub :execute, mock_executor do
            Ace::Git::Atoms::PrIdentifierParser.stub :parse, parsed do
              result = GhCommentResolver.reply("69", "abc1234")

              assert result[:success]
              assert_match(/github\.com/, result[:comment_url])
              assert_equal "Fixed in abc1234", result[:message]
            end
          end
        end

        def test_reply_with_custom_message
          mock_executor = lambda do |cmd, args, **opts|
            {
              success: true,
              stdout: "https://github.com/owner/repo/pull/69#issuecomment-12345"
            }
          end

          parsed = Ace::Git::Atoms::PrIdentifierParser::ParseResult.new(
            number: "69", repo: nil, gh_format: "69"
          )

          Ace::Git::Molecules::GhCliExecutor.stub :execute, mock_executor do
            Ace::Git::Atoms::PrIdentifierParser.stub :parse, parsed do
              result = GhCommentResolver.reply("69", "abc1234", message: "Custom fix message")

              assert result[:success]
              assert_equal "Custom fix message", result[:message]
            end
          end
        end

        def test_reply_truncates_commit_sha
          captured_body = nil
          custom_executor = lambda do |cmd, args, **opts|
            body_idx = args.index("--body")
            captured_body = args[body_idx + 1] if body_idx
            {
              success: true,
              stdout: "https://github.com/owner/repo/pull/69#issuecomment-12345"
            }
          end

          parsed = Ace::Git::Atoms::PrIdentifierParser::ParseResult.new(
            number: "69", repo: nil, gh_format: "69"
          )

          Ace::Git::Molecules::GhCliExecutor.stub :execute, custom_executor do
            Ace::Git::Atoms::PrIdentifierParser.stub :parse, parsed do
              result = GhCommentResolver.reply("69", "abc1234567890full")

              assert result[:success]
              assert_equal "Fixed in abc1234", result[:message]
            end
          end
        end

        def test_reply_handles_failure
          mock_executor = lambda do |cmd, args, **opts|
            {
              success: false,
              stderr: "gh: PR not found"
            }
          end

          parsed = Ace::Git::Atoms::PrIdentifierParser::ParseResult.new(
            number: "invalid", repo: nil, gh_format: "invalid"
          )

          Ace::Git::Molecules::GhCliExecutor.stub :execute, mock_executor do
            Ace::Git::Atoms::PrIdentifierParser.stub :parse, parsed do
              result = GhCommentResolver.reply("invalid", "abc123")

              refute result[:success]
              assert_match(/Failed to post reply/, result[:error])
            end
          end
        end

        def test_reply_reraises_ace_git_not_installed_error
          parsed = Ace::Git::Atoms::PrIdentifierParser::ParseResult.new(
            number: "69", repo: nil, gh_format: "69"
          )
          mock_executor = lambda do |_cmd, _args, **_opts|
            raise Ace::Git::GhNotInstalledError, "missing gh"
          end

          Ace::Git::Molecules::GhCliExecutor.stub :execute, mock_executor do
            Ace::Git::Atoms::PrIdentifierParser.stub :parse, parsed do
              assert_raises(Ace::Git::GhNotInstalledError) do
                GhCommentResolver.reply("69", "abc123")
              end
            end
          end
        end

        # ====================================
        # reply_and_resolve tests
        # ====================================

        def test_reply_and_resolve_success_with_thread
          call_count = 0
          mock_executor = lambda do |cmd, args, **opts|
            call_count += 1
            if cmd == "pr"
              {
                success: true,
                stdout: "https://github.com/owner/repo/pull/69#issuecomment-12345"
              }
            else
              {
                success: true,
                stdout: '{"data":{"resolveReviewThread":{"thread":{"isResolved":true}}}}'
              }
            end
          end

          parsed = Ace::Git::Atoms::PrIdentifierParser::ParseResult.new(
            number: "69", repo: nil, gh_format: "69"
          )

          Ace::Git::Molecules::GhCliExecutor.stub :execute, mock_executor do
            Ace::Git::Atoms::PrIdentifierParser.stub :parse, parsed do
              result = GhCommentResolver.reply_and_resolve("69", "abc123", thread_id: "PRRT_test123")

              assert result[:success]
              assert result[:reply_result][:success]
              assert result[:resolve_result][:success]
              assert_equal 2, call_count
            end
          end
        end

        def test_reply_and_resolve_without_thread_id
          mock_executor = lambda do |cmd, args, **opts|
            {
              success: true,
              stdout: "https://github.com/owner/repo/pull/69#issuecomment-12345"
            }
          end

          parsed = Ace::Git::Atoms::PrIdentifierParser::ParseResult.new(
            number: "69", repo: nil, gh_format: "69"
          )

          Ace::Git::Molecules::GhCliExecutor.stub :execute, mock_executor do
            Ace::Git::Atoms::PrIdentifierParser.stub :parse, parsed do
              result = GhCommentResolver.reply_and_resolve("69", "abc123")

              assert result[:success]
              assert result[:reply_result][:success]
              assert_nil result[:resolve_result]
            end
          end
        end

        def test_reply_and_resolve_stops_on_reply_failure
          mock_executor = lambda do |cmd, args, **opts|
            {
              success: false,
              stderr: "gh: Authentication required"
            }
          end

          parsed = Ace::Git::Atoms::PrIdentifierParser::ParseResult.new(
            number: "69", repo: nil, gh_format: "69"
          )

          Ace::Git::Molecules::GhCliExecutor.stub :execute, mock_executor do
            Ace::Git::Atoms::PrIdentifierParser.stub :parse, parsed do
              result = GhCommentResolver.reply_and_resolve("69", "abc123", thread_id: "PRRT_test123")

              refute result[:success]
              refute result[:reply_result][:success]
              assert_nil result[:resolve_result]
            end
          end
        end

        def test_reply_and_resolve_partial_success_on_resolve_failure
          call_count = 0
          mock_executor = lambda do |cmd, args, **opts|
            call_count += 1
            if cmd == "pr"
              {
                success: true,
                stdout: "https://github.com/owner/repo/pull/69#issuecomment-12345"
              }
            else
              {
                success: false,
                stderr: "GraphQL error"
              }
            end
          end

          parsed = Ace::Git::Atoms::PrIdentifierParser::ParseResult.new(
            number: "69", repo: nil, gh_format: "69"
          )

          Ace::Git::Molecules::GhCliExecutor.stub :execute, mock_executor do
            Ace::Git::Atoms::PrIdentifierParser.stub :parse, parsed do
              result = GhCommentResolver.reply_and_resolve("69", "abc123", thread_id: "PRRT_test123")

              # Reply succeeded, but thread resolution failed
              assert result[:success] # Overall success because reply worked
              assert result[:partial]
              assert result[:reply_result][:success]
              refute result[:resolve_result][:success]
              assert_match(/Reply posted but thread not resolved/, result[:warning])
            end
          end
        end

        def test_resolve_thread_reraises_ace_git_authentication_error
          mock_executor = lambda do |_cmd, _args, **_opts|
            raise Ace::Git::GhAuthenticationError, "auth required"
          end

          Ace::Git::Molecules::GhCliExecutor.stub :execute, mock_executor do
            assert_raises(Ace::Git::GhAuthenticationError) do
              GhCommentResolver.resolve_thread("PRRT_valid123")
            end
          end
        end
      end
    end
  end
end
