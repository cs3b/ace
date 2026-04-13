# frozen_string_literal: true

require "test_helper"
require "ace/review/atoms/pr_comment_formatter"

module Ace
  module Review
    module Atoms
      class PrCommentFormatterTest < AceReviewTest
        def setup
          super
          @formatter = PrCommentFormatter
        end

        # Test: Format with comments and reviews
        def test_format_complete
          comments_data = {
            success: true,
            pr_number: 123,
            pr_title: "Add new feature",
            comments: [
              {type: "issue_comment", id: "IC_123", author: "bob", body: "Please add tests", created_at: "2025-12-08T10:00:00Z"}
            ],
            reviews: [
              {type: "review", id: "PRR_456", author: "alice", state: "CHANGES_REQUESTED", body: "Needs refactoring", created_at: "2025-12-08T11:00:00Z"},
              {type: "review", id: "PRR_789", author: "charlie", state: "APPROVED", body: "LGTM!", created_at: "2025-12-08T12:00:00Z"}
            ]
          }

          result = @formatter.format(comments_data)

          assert_match(/# Developer Feedback from PR #123/, result)
          assert_match(/Add new feature/, result)
          assert_match(/Total comments: 3/, result)
          assert_match(/Unresolved items: 2/, result)  # 1 comment + 1 changes_requested
        end

        # Test: Format with empty comments
        def test_format_empty
          comments_data = {
            success: true,
            pr_number: 123,
            pr_title: "Empty PR",
            comments: [],
            reviews: []
          }

          result = @formatter.format(comments_data)

          assert_match(/# Developer Feedback from PR #123/, result)
          assert_match(/Total comments: 0/, result)
          assert_match(/Unresolved items: 0/, result)
        end

        # Test: Format returns nil for failed data
        def test_format_nil_on_failure
          result = @formatter.format(nil)
          assert_nil result

          result = @formatter.format({success: false})
          assert_nil result
        end

        # Test: YAML frontmatter
        def test_format_has_frontmatter
          comments_data = {
            success: true,
            pr_number: 123,
            pr_title: "Test",
            comments: [],
            reviews: []
          }

          result = @formatter.format(comments_data)

          # Check YAML frontmatter structure
          assert result.start_with?("---\n")
          assert_match(/source: pr-comments/, result)
          assert_match(/pr_number: 123/, result)
        end

        # Test: Unresolved section includes changes requested
        def test_unresolved_section
          comments_data = {
            success: true,
            pr_number: 123,
            pr_title: "Test",
            comments: [],
            reviews: [
              {type: "review", id: "PRR_1", author: "alice", state: "CHANGES_REQUESTED", body: "fix this", created_at: "2025-12-08T10:00:00Z"}
            ]
          }

          result = @formatter.format(comments_data)

          # Check unresolved section
          assert_match(/## Unresolved Feedback/, result)
          assert_match(/@alice/, result)
        end

        # Test: Resolved section includes approvals
        def test_resolved_section
          comments_data = {
            success: true,
            pr_number: 123,
            pr_title: "Test",
            comments: [],
            reviews: [
              {type: "review", id: "PRR_1", author: "alice", state: "APPROVED", body: "lgtm", created_at: "2025-12-08T10:00:00Z"}
            ]
          }

          result = @formatter.format(comments_data)

          assert_match(/## Resolved Feedback/, result)
          assert_match(/@alice approved changes/, result)
        end

        # Test: Inline code comments section
        def test_inline_comments_section
          comments_data = {
            success: true,
            pr_number: 123,
            pr_title: "Test",
            comments: [],
            reviews: [],
            review_threads: [
              {
                type: "review_thread",
                id: "PRRT_abc123",
                path: "lib/foo.rb",
                line: 42,
                is_resolved: false,
                comments: [
                  {id: "C1", author: "alice", body: "This needs null checking", created_at: "2025-12-08T10:00:00Z"},
                  {id: "C2", author: "bob", body: "Agreed, will fix", created_at: "2025-12-08T10:30:00Z"}
                ]
              }
            ]
          }

          result = @formatter.format(comments_data)

          assert_match(/## Inline Code Comments/, result)
          assert_match(/lib\/foo\.rb:42/, result)
          assert_match(/thread: PRRT_abc123/, result)
          assert_match(/Unresolved/, result)
          assert_match(/@alice: This needs null checking/, result)
          assert_match(/@bob: Agreed, will fix/, result)
        end

        # Test: Inline comments section with resolved thread
        def test_inline_comments_section_resolved
          comments_data = {
            success: true,
            pr_number: 123,
            pr_title: "Test",
            comments: [],
            reviews: [],
            review_threads: [
              {
                type: "review_thread",
                id: "PRRT_def456",
                path: "lib/bar.rb",
                line: 15,
                is_resolved: true,
                comments: [
                  {id: "C1", author: "alice", body: "Typo in variable name", created_at: "2025-12-08T10:00:00Z"}
                ]
              }
            ]
          }

          result = @formatter.format(comments_data)

          assert_match(/## Inline Code Comments/, result)
          assert_match(/lib\/bar\.rb:15/, result)
          assert_match(/Resolved/, result)
        end

        # Test: Summary includes inline thread count
        def test_summary_includes_inline_thread_count
          comments_data = {
            success: true,
            pr_number: 123,
            pr_title: "Test",
            comments: [],
            reviews: [],
            review_threads: [
              {id: "T1", path: "a.rb", line: 1, is_resolved: false, comments: [{author: "x", body: "y"}]},
              {id: "T2", path: "b.rb", line: 2, is_resolved: false, comments: [{author: "z", body: "w"}]}
            ]
          }

          result = @formatter.format(comments_data)

          assert_match(/Inline code comments: 2/, result)
        end

        # Test: Unresolved count includes unresolved threads
        def test_unresolved_count_includes_threads
          comments_data = {
            success: true,
            pr_number: 123,
            pr_title: "Test",
            comments: [{type: "issue_comment", id: "IC_1", author: "a", body: "Please fix this issue"}],
            reviews: [],
            review_threads: [
              {id: "T1", path: "a.rb", line: 1, is_resolved: false, comments: [{author: "x", body: "y"}]},
              {id: "T2", path: "b.rb", line: 2, is_resolved: true, comments: [{author: "z", body: "w"}]}
            ]
          }

          result = @formatter.format(comments_data)

          # 1 actionable comment + 1 unresolved thread = 2 unresolved
          assert_match(/Unresolved items: 2/, result)
        end

        # Test: Reviewers includes thread authors
        def test_reviewers_includes_thread_authors
          comments_data = {
            success: true,
            pr_number: 123,
            pr_title: "Test",
            comments: [{type: "issue_comment", id: "IC_1", author: "alice", body: "Can you check this?"}],
            reviews: [],
            review_threads: [
              {id: "T1", path: "a.rb", line: 1, is_resolved: false, comments: [{author: "bob", body: "y"}]}
            ]
          }

          result = @formatter.format(comments_data)

          assert_match(/@alice/, result)
          assert_match(/@bob/, result)
        end

        # Test: Empty review threads doesn't show section
        def test_no_inline_section_when_empty
          comments_data = {
            success: true,
            pr_number: 123,
            pr_title: "Test",
            comments: [],
            reviews: [],
            review_threads: []
          }

          result = @formatter.format(comments_data)

          refute_match(/## Inline Code Comments/, result)
        end
      end
    end
  end
end
