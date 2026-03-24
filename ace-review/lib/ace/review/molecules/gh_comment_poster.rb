# frozen_string_literal: true

require "tempfile"

module Ace
  module Review
    module Molecules
      # Post review comments to GitHub PR
      class GhCommentPoster
        # Post a review comment to a PR
        #
        # @param pr_identifier [String] PR identifier
        # @param review_text [String] Review content
        # @param options [Hash] Posting options
        # @option options [Boolean] :dry_run Don't actually post (default: false)
        # @option options [Hash] :metadata Review metadata (preset, model, timestamp)
        # @return [Hash] Result with :success, :comment_url, :preview, :error
        def self.post_comment(pr_identifier, review_text, options = {})
          # Parse identifier using ace-git
          parsed = Ace::Git::Atoms::PrIdentifierParser.parse(pr_identifier)
          gh_format = parsed.gh_format

          # Check PR state before posting
          state_check = check_pr_state(gh_format)
          return state_check unless state_check[:success]

          # Format comment with metadata
          formatted_comment = format_review_comment(review_text, options[:metadata] || {})

          # Handle dry run
          if options[:dry_run]
            return {
              success: true,
              dry_run: true,
              preview: formatted_comment,
              pr_identifier: gh_format
            }
          end

          # Post comment via gh CLI
          result = post_via_gh(gh_format, formatted_comment)

          if result[:success]
            comment_url = extract_comment_url(result[:stdout], parsed.to_h)
            {
              success: true,
              comment_url: comment_url,
              pr_identifier: gh_format
            }
          else
            {
              success: false,
              error: "Failed to post comment: #{result[:stderr]}"
            }
          end
        rescue Ace::Review::Errors::GhCliNotInstalledError, Ace::Review::Errors::GhAuthenticationError
          raise
        rescue => e
          {
            success: false,
            error: "Failed to post comment: #{e.message}"
          }
        end

        # Check if PR is in a state that allows comments
        #
        # @param gh_format [String] PR identifier in gh format
        # @return [Hash] Result with :success or :error
        def self.check_pr_state(gh_format)
          # Fetch PR metadata
          result = Ace::Review::Molecules::GhCliExecutor.execute(
            "pr",
            ["view", gh_format, "--json", "state,number"]
          )

          unless result[:success]
            return {
              success: false,
              error: "Failed to check PR state: #{result[:stderr]}"
            }
          end

          metadata = JSON.parse(result[:stdout])
          state = metadata["state"]
          number = metadata["number"]

          # Check if state allows posting
          unless state == "OPEN"
            raise Ace::Review::Errors::PrStateError.new(number, state.downcase)
          end

          {success: true}
        rescue JSON::ParserError => e
          {
            success: false,
            error: "Failed to parse PR state: #{e.message}"
          }
        end

        # Format review comment with metadata header
        #
        # @param review_text [String] Raw review content
        # @param metadata [Hash] Review metadata
        # @option metadata [String] :preset Review preset name
        # @option metadata [String] :model LLM model used
        # @option metadata [String] :timestamp Generation timestamp
        # @return [String] Formatted comment
        def self.format_review_comment(review_text, metadata = {})
          header = "## Code Review - ace-review\n\n"

          if metadata[:preset]
            header += "**Preset**: #{metadata[:preset]}\n"
          end

          if metadata[:model]
            header += "**Model**: #{metadata[:model]}\n"
          end

          if metadata[:timestamp]
            header += "**Generated**: #{metadata[:timestamp]}\n"
          end

          header += "\n" unless metadata.empty?

          # Sanitize review text (escape any problematic characters)
          sanitized_review = sanitize_markdown(review_text)

          header + sanitized_review
        end

        # Sanitize markdown content to prevent formatting issues
        #
        # Ensures code fences are properly closed and wraps content in a
        # collapsible details tag to contain any formatting issues.
        #
        # @param content [String] Content to sanitize
        # @return [String] Sanitized and wrapped content
        def self.sanitize_markdown(content)
          sanitized = content.to_s

          # Ensure code fences are closed
          # Count occurrences of code fence markers (```)
          fence_count = sanitized.scan(/^```/).count
          if fence_count.odd?
            # Unclosed code fence - close it
            sanitized += "\n```\n"
          end

          # Wrap in collapsible details to contain any formatting issues
          <<~MARKDOWN
            <details>
            <summary><b>📋 Full Review</b> (click to expand)</summary>

            #{sanitized}

            </details>
          MARKDOWN
        end

        # Post comment via gh CLI using a temp file for the body
        #
        # @param gh_format [String] PR identifier in gh format
        # @param comment_body [String] Comment content
        # @return [Hash] Result from gh CLI
        def self.post_via_gh(gh_format, comment_body)
          # Write comment to temp file (gh pr comment reads from file)
          Tempfile.create(["review-comment", ".md"]) do |file|
            file.write(comment_body)
            file.flush

            # Post using gh pr comment
            Ace::Review::Molecules::GhCliExecutor.execute(
              "pr",
              ["comment", gh_format, "--body-file", file.path]
            )
          end
        end

        # Extract comment URL from gh CLI output
        #
        # @param output [String] gh CLI stdout
        # @param parsed [Hash] Parsed PR identifier with :repo (owner/repo format), :number
        # @return [String] Comment URL
        def self.extract_comment_url(output, parsed)
          # gh pr comment returns the comment URL on success
          # Format: https://github.com/owner/repo/pull/123#issuecomment-123456
          url_match = output.match(%r{(https://[^\s]+)})

          if url_match
            url_match[1]
          else
            # Fallback: construct URL from parsed identifier
            # ace-git's ParseResult provides :repo in "owner/repo" combined format
            repo = parsed[:repo] || parsed[:gh_format].to_s.split("#").first
            number = parsed[:number]
            "https://github.com/#{repo}/pull/#{number}"
          end
        end

        private_class_method :check_pr_state, :format_review_comment, :sanitize_markdown,
          :post_via_gh, :extract_comment_url
      end
    end
  end
end
