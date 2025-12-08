# frozen_string_literal: true

require "test_helper"
require "ace/review/molecules/gh_pr_comment_fetcher"
require "ace/review/molecules/gh_cli_executor"
require "ace/review/molecules/pr_identifier_parser"

module Ace
  module Review
    module Molecules
      class GhPrCommentFetcherTest < AceReviewTest
        def setup
          super
          @fetcher = GhPrCommentFetcher
        end

        # Test: Fetch comments successfully
        def test_fetch_success
          parsed = {
            owner: "test", repo: "repo", number: 123,
            gh_format: "test/repo#123"
          }

          response_json = {
            number: 123,
            title: "Test PR",
            author: { login: "alice" },
            comments: [
              {
                id: "IC_123",
                author: { login: "bob" },
                body: "Please add tests",
                createdAt: "2025-12-08T10:00:00Z",
                url: "https://github.com/test/repo/pull/123#issuecomment-123"
              }
            ],
            reviews: [
              {
                id: "PRR_456",
                author: { login: "charlie" },
                state: "CHANGES_REQUESTED",
                body: "Needs refactoring",
                submittedAt: "2025-12-08T11:00:00Z"
              }
            ]
          }.to_json

          PrIdentifierParser.stub(:parse, parsed) do
            result = { success: true, stdout: response_json, stderr: "", exit_code: 0 }
            GhCliExecutor.stub(:execute, result) do
              response = @fetcher.fetch("123")

              assert response[:success]
              assert_equal 123, response[:pr_number]
              assert_equal "Test PR", response[:pr_title]
              assert_equal 1, response[:comments].size
              assert_equal 1, response[:reviews].size
            end
          end
        end

        # Test: has_comments? helper with comments
        def test_has_comments_true
          result = {
            success: true,
            comments: [{ id: "IC_1", author: "bob", body: "test" }],
            reviews: []
          }

          assert @fetcher.has_comments?(result)
        end

        # Test: has_comments? helper without comments
        def test_has_comments_false_empty
          result = {
            success: true,
            comments: [],
            reviews: []
          }

          refute @fetcher.has_comments?(result)
        end

        # Test: has_comments? helper on failure
        def test_has_comments_false_failed
          result = { success: false, error: "some error" }

          refute @fetcher.has_comments?(result)
        end

        # Test: Bot filtering
        def test_filters_bot_comments
          parsed = { owner: "test", repo: "repo", number: 123, gh_format: "123" }

          response_json = {
            number: 123,
            title: "Test PR",
            author: { login: "alice" },
            comments: [
              { id: "IC_1", author: { login: "dependabot[bot]" }, body: "Bump version", createdAt: "2025-12-08T10:00:00Z" },
              { id: "IC_2", author: { login: "bob" }, body: "Real comment", createdAt: "2025-12-08T10:00:00Z" }
            ],
            reviews: []
          }.to_json

          PrIdentifierParser.stub(:parse, parsed) do
            result = { success: true, stdout: response_json, stderr: "", exit_code: 0 }
            GhCliExecutor.stub(:execute, result) do
              response = @fetcher.fetch("123")

              assert response[:success]
              assert_equal 1, response[:comments].size
              assert_equal "bob", response[:comments].first[:author]
            end
          end
        end

        # Test: JSON parse error
        def test_fetch_json_parse_error
          parsed = { owner: "test", repo: "repo", number: 123, gh_format: "123" }

          PrIdentifierParser.stub(:parse, parsed) do
            result = { success: true, stdout: "invalid json", stderr: "", exit_code: 0 }
            GhCliExecutor.stub(:execute, result) do
              response = @fetcher.fetch("123")

              refute response[:success]
              assert_match(/Failed to parse PR comments/, response[:error])
            end
          end
        end

        # Test: Authentication error re-raised
        def test_fetch_reraises_authentication_error
          parsed = { owner: "test", repo: "repo", number: 123, gh_format: "123" }

          PrIdentifierParser.stub(:parse, parsed) do
            assert_raises(Ace::Review::Errors::GhAuthenticationError) do
              GhCliExecutor.stub(:execute, ->(*_args) {
                raise Ace::Review::Errors::GhAuthenticationError
              }) do
                @fetcher.fetch("123")
              end
            end
          end
        end

        # Test: CLI not installed error re-raised
        def test_fetch_reraises_cli_not_installed
          parsed = { owner: "test", repo: "repo", number: 123, gh_format: "123" }

          PrIdentifierParser.stub(:parse, parsed) do
            assert_raises(Ace::Review::Errors::GhCliNotInstalledError) do
              GhCliExecutor.stub(:execute, ->(*_args) {
                raise Ace::Review::Errors::GhCliNotInstalledError
              }) do
                @fetcher.fetch("123")
              end
            end
          end
        end

        # Test: Fetch includes review threads
        def test_fetch_includes_review_threads
          parsed = {
            owner: "test", repo: "repo", number: 123,
            gh_format: "test/repo#123"
          }

          pr_response_json = {
            number: 123,
            title: "Test PR",
            author: { login: "alice" },
            comments: [],
            reviews: []
          }.to_json

          graphql_response_json = {
            data: {
              repository: {
                pullRequest: {
                  reviewThreads: {
                    nodes: [
                      {
                        id: "PRRT_abc123",
                        isResolved: false,
                        path: "lib/foo.rb",
                        line: 42,
                        comments: {
                          nodes: [
                            {
                              id: "PRRC_xyz789",
                              body: "This needs null checking",
                              author: { login: "bob" },
                              createdAt: "2025-12-08T10:00:00Z"
                            }
                          ]
                        }
                      }
                    ]
                  }
                }
              }
            }
          }.to_json

          call_count = 0
          execute_stub = lambda do |subcommand, args, **_options|
            call_count += 1
            if subcommand == "pr"
              { success: true, stdout: pr_response_json, stderr: "", exit_code: 0 }
            else
              { success: true, stdout: graphql_response_json, stderr: "", exit_code: 0 }
            end
          end

          PrIdentifierParser.stub(:parse, parsed) do
            GhCliExecutor.stub(:execute, execute_stub) do
              response = @fetcher.fetch("123")

              assert response[:success]
              assert_equal 1, response[:review_threads].size

              thread = response[:review_threads].first
              assert_equal "PRRT_abc123", thread[:id]
              assert_equal "lib/foo.rb", thread[:path]
              assert_equal 42, thread[:line]
              refute thread[:is_resolved]
              assert_equal 1, thread[:comments].size
              assert_equal "bob", thread[:comments].first[:author]
            end
          end
        end

        # Test: has_comments? true with review threads only
        def test_has_comments_true_with_threads
          result = {
            success: true,
            comments: [],
            reviews: [],
            review_threads: [{ id: "PRRT_1", path: "foo.rb", line: 1, comments: [{ author: "bob", body: "test" }] }]
          }

          assert @fetcher.has_comments?(result)
        end

        # Test: Review threads skips resolved by default
        def test_extract_review_threads_skips_resolved
          graphql_data = {
            "data" => {
              "repository" => {
                "pullRequest" => {
                  "reviewThreads" => {
                    "nodes" => [
                      {
                        "id" => "PRRT_1",
                        "isResolved" => false,
                        "path" => "foo.rb",
                        "line" => 10,
                        "comments" => { "nodes" => [{ "id" => "C1", "body" => "test", "author" => { "login" => "alice" }, "createdAt" => "2025-12-08T10:00:00Z" }] }
                      },
                      {
                        "id" => "PRRT_2",
                        "isResolved" => true,
                        "path" => "bar.rb",
                        "line" => 20,
                        "comments" => { "nodes" => [{ "id" => "C2", "body" => "resolved", "author" => { "login" => "bob" }, "createdAt" => "2025-12-08T11:00:00Z" }] }
                      }
                    ]
                  }
                }
              }
            }
          }

          # Access the private method via send
          threads = @fetcher.send(:extract_review_threads, graphql_data, false)

          assert_equal 1, threads.size
          assert_equal "PRRT_1", threads.first[:id]
        end

        # Test: Review threads includes resolved when requested
        def test_extract_review_threads_includes_resolved
          graphql_data = {
            "data" => {
              "repository" => {
                "pullRequest" => {
                  "reviewThreads" => {
                    "nodes" => [
                      {
                        "id" => "PRRT_1",
                        "isResolved" => false,
                        "path" => "foo.rb",
                        "line" => 10,
                        "comments" => { "nodes" => [{ "id" => "C1", "body" => "test", "author" => { "login" => "alice" }, "createdAt" => "2025-12-08T10:00:00Z" }] }
                      },
                      {
                        "id" => "PRRT_2",
                        "isResolved" => true,
                        "path" => "bar.rb",
                        "line" => 20,
                        "comments" => { "nodes" => [{ "id" => "C2", "body" => "resolved", "author" => { "login" => "bob" }, "createdAt" => "2025-12-08T11:00:00Z" }] }
                      }
                    ]
                  }
                }
              }
            }
          }

          threads = @fetcher.send(:extract_review_threads, graphql_data, true)

          assert_equal 2, threads.size
        end

        # Test: fetch_review_threads returns empty array without owner/repo
        def test_fetch_review_threads_empty_without_owner_repo
          parsed = { number: 123, gh_format: "123" }  # No owner/repo

          # Should output debug warning
          output = capture_io do
            threads = @fetcher.send(:fetch_review_threads, parsed, {})
            assert_equal [], threads
          end

          assert_match(/missing owner\/repo/, output[1])
        end

        # Test: fetch_review_threads surfaces GraphQL errors as warnings
        def test_fetch_review_threads_graphql_errors_warning
          parsed = { owner: "test", repo: "repo", number: 123, gh_format: "test/repo#123" }

          # GraphQL response with errors but partial data
          graphql_response = {
            "data" => {
              "repository" => {
                "pullRequest" => {
                  "reviewThreads" => { "nodes" => [] }
                }
              }
            },
            "errors" => [
              { "message" => "Resource not accessible by integration" }
            ]
          }.to_json

          result = { success: true, stdout: graphql_response, stderr: "", exit_code: 0 }

          output = capture_io do
            GhCliExecutor.stub(:execute, result) do
              threads = @fetcher.send(:fetch_review_threads, parsed, {})
              assert_equal [], threads
            end
          end

          # Should warn about GraphQL errors
          assert_match(/GraphQL errors.*Resource not accessible/, output[1])
        end

        # Test: fetch_review_threads surfaces JSON parse errors as warnings
        def test_fetch_review_threads_json_error_warning
          parsed = { owner: "test", repo: "repo", number: 123, gh_format: "test/repo#123" }

          # Invalid JSON response
          result = { success: true, stdout: "not valid json{", stderr: "", exit_code: 0 }

          output = capture_io do
            GhCliExecutor.stub(:execute, result) do
              threads = @fetcher.send(:fetch_review_threads, parsed, {})
              assert_equal [], threads
            end
          end

          # Should warn about parse error
          assert_match(/Failed to parse review threads/, output[1])
        end
      end
    end
  end
end
