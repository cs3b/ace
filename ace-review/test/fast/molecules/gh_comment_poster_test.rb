# frozen_string_literal: true

require "test_helper"
require "ace/review/molecules/gh_comment_poster"

module Ace
  module Review
    module Molecules
      class GhCommentPosterTest < AceReviewTest
        # Test: Sanitize markdown with well-formed content
        def test_sanitize_markdown_with_well_formed_content
          content = "# Review\n\nThis is a review with proper formatting."
          result = GhCommentPoster.send(:sanitize_markdown, content)

          assert_match(/<details>/, result)
          assert_match(/<summary><b>📋 Full Review<\/b>/, result)
          assert_match(/This is a review with proper formatting/, result)
          assert_match(/<\/details>/, result)
        end

        # Test: Sanitize markdown closes unclosed code fence
        def test_sanitize_markdown_closes_unclosed_code_fence
          content = "# Review\n\n```ruby\nclass Foo\nend"
          result = GhCommentPoster.send(:sanitize_markdown, content)

          # Should close the code fence
          assert_match(/```ruby\nclass Foo\nend\n```/, result)
          assert_match(/<details>/, result)
          assert_match(/<\/details>/, result)
        end

        # Test: Sanitize markdown with properly closed code fence
        def test_sanitize_markdown_with_closed_code_fence
          content = "# Review\n\n```ruby\nclass Foo\nend\n```"
          result = GhCommentPoster.send(:sanitize_markdown, content)

          # Should not add extra closing fence
          refute_match(/```\n```/, result)
          assert_match(/```ruby\nclass Foo\nend\n```/, result)
        end

        # Test: Sanitize markdown with multiple code fences
        def test_sanitize_markdown_with_multiple_code_fences
          content = <<~MARKDOWN
            # Review

            ```ruby
            def foo
            end
            ```

            Some text

            ```javascript
            function bar() {}
            ```
          MARKDOWN

          result = GhCommentPoster.send(:sanitize_markdown, content)

          # All fences are closed, should not add extra
          refute_match(/```\n```/, result)
          assert_match(/<details>/, result)
        end

        # Test: Sanitize markdown with odd number of fences
        def test_sanitize_markdown_with_odd_fences
          content = <<~MARKDOWN
            # Review

            ```ruby
            def foo
            end
            ```

            Some text

            ```javascript
            function bar() {}
          MARKDOWN

          result = GhCommentPoster.send(:sanitize_markdown, content)

          # Should close the last unclosed fence (note: \n``` is added at the end)
          assert_match(/function bar\(\) {}\n\n```/, result)
          # Ensure details wrapper is present
          assert_match(/<details>/, result)
          assert_match(/<\/details>/, result)
        end

        # Test: Sanitize empty content
        def test_sanitize_markdown_with_empty_content
          content = ""
          result = GhCommentPoster.send(:sanitize_markdown, content)

          assert_match(/<details>/, result)
          assert_match(/<\/details>/, result)
        end

        # Test: Sanitize nil content
        def test_sanitize_markdown_with_nil_content
          content = nil
          result = GhCommentPoster.send(:sanitize_markdown, content)

          assert_match(/<details>/, result)
          assert_match(/<\/details>/, result)
        end

        # Test: Sanitize markdown wraps content in details tag
        def test_sanitize_markdown_wraps_in_details
          content = "Test content"
          result = GhCommentPoster.send(:sanitize_markdown, content)

          # Check structure
          assert_match(/^<details>/, result)
          assert_match(/<summary><b>📋 Full Review<\/b> \(click to expand\)<\/summary>/, result)
          assert_match(/Test content/, result)
          assert_match(/<\/details>$/, result.strip)
        end

        # Test: Sanitize markdown with inline code
        def test_sanitize_markdown_with_inline_code
          content = "Review with `inline code` and more text"
          result = GhCommentPoster.send(:sanitize_markdown, content)

          # Inline code (single backticks) should not affect fence counting
          assert_match(/Review with `inline code` and more text/, result)
          assert_match(/<details>/, result)
          refute_match(/```\n$/, result) # Should not add fence closure
        end

        # Test: Sanitize markdown with code fence not at line start
        def test_sanitize_markdown_with_indented_fence
          content = "Review\n  ```ruby\n  code\n  ```"
          result = GhCommentPoster.send(:sanitize_markdown, content)

          # Indented fences (not at line start) should not be counted
          # The regex /^```/ only matches fences at the start of a line
          assert_match(/<details>/, result)
          assert_match(/Review/, result)
        end

        # Test: Sanitize markdown preserves formatting
        def test_sanitize_markdown_preserves_formatting
          content = <<~MARKDOWN
            # Main Header

            ## Subheader

            - List item 1
            - List item 2

            **Bold text** and *italic text*

            > Quote block
          MARKDOWN

          result = GhCommentPoster.send(:sanitize_markdown, content)

          # All original content should be preserved
          assert_match(/# Main Header/, result)
          assert_match(/## Subheader/, result)
          assert_match(/- List item 1/, result)
          assert_match(/\*\*Bold text\*\*/, result)
          assert_match(/\*italic text\*/, result)
          assert_match(/> Quote block/, result)
        end

        # Test: Sanitize markdown with complex unclosed fence scenario
        def test_sanitize_markdown_complex_unclosed_scenario
          content = <<~MARKDOWN
            # Review

            Here's some code:

            ```ruby
            def broken_method
              # Missing closing
          MARKDOWN

          result = GhCommentPoster.send(:sanitize_markdown, content)

          # Should add closing fence (note: \n``` is added at the end)
          assert_match(/# Missing closing\n\n```/, result)
          assert_match(/<details>/, result)
          assert_match(/<\/details>/, result)
        end

        # Test: extract_comment_url with URL in output
        def test_extract_comment_url_from_output
          output = "https://github.com/owner/repo/pull/123#issuecomment-456789"
          parsed = {number: "123", repo: "owner/repo", gh_format: "owner/repo#123"}

          result = GhCommentPoster.send(:extract_comment_url, output, parsed)

          assert_equal "https://github.com/owner/repo/pull/123#issuecomment-456789", result
        end

        # Test: extract_comment_url fallback with repo in combined format
        def test_extract_comment_url_fallback_with_combined_repo
          output = ""  # No URL in output
          parsed = {number: "123", repo: "owner/repo", gh_format: "owner/repo#123"}

          result = GhCommentPoster.send(:extract_comment_url, output, parsed)

          assert_equal "https://github.com/owner/repo/pull/123", result
        end

        # Test: extract_comment_url fallback using gh_format when repo is nil
        def test_extract_comment_url_fallback_from_gh_format
          output = ""  # No URL in output
          parsed = {number: "123", repo: nil, gh_format: "owner/repo#123"}

          result = GhCommentPoster.send(:extract_comment_url, output, parsed)

          assert_equal "https://github.com/owner/repo/pull/123", result
        end

        # Test: extract_comment_url fallback with simple PR number (no repo)
        def test_extract_comment_url_fallback_simple_number
          output = ""  # No URL in output
          parsed = {number: "123", repo: nil, gh_format: "123"}

          result = GhCommentPoster.send(:extract_comment_url, output, parsed)

          # When no repo info, falls back to just the number (malformed but graceful)
          assert_equal "https://github.com/123/pull/123", result
        end

        def test_post_comment_reraises_ace_git_authentication_error
          parsed = Ace::Git::Atoms::PrIdentifierParser::ParseResult.new(
            number: "69", repo: nil, gh_format: "69"
          )
          mock_executor = lambda do |_cmd, _args, **_opts|
            raise Ace::Git::GhAuthenticationError, "auth required"
          end

          Ace::Git::Atoms::PrIdentifierParser.stub :parse, parsed do
            Ace::Git::Molecules::GhCliExecutor.stub :execute, mock_executor do
              assert_raises(Ace::Git::GhAuthenticationError) do
                GhCommentPoster.post_comment("69", "review")
              end
            end
          end
        end
      end
    end
  end
end
