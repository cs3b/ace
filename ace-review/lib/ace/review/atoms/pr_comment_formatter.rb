# frozen_string_literal: true

require "time"
require "yaml"

module Ace
  module Review
    module Atoms
      # Format PR comments into a structured markdown report
      # Pure transformation - no side effects
      class PrCommentFormatter
        # Review state to human-readable status
        REVIEW_STATES = {
          "APPROVED" => "Approved",
          "CHANGES_REQUESTED" => "Changes Requested",
          "COMMENTED" => "Commented",
          "DISMISSED" => "Dismissed",
          "PENDING" => "Pending"
        }.freeze

        # Format comments data into markdown report
        #
        # @param comments_data [Hash] Data from GhPrCommentFetcher
        # @return [String] Formatted markdown report
        def self.format(comments_data)
          return nil unless comments_data && comments_data[:success]

          pr_number = comments_data[:pr_number]
          pr_title = comments_data[:pr_title]
          comments = comments_data[:comments] || []
          reviews = comments_data[:reviews] || []
          review_threads = comments_data[:review_threads] || []

          # Build report sections
          frontmatter = build_frontmatter(comments_data)
          summary = build_summary(comments, reviews, review_threads, pr_number, pr_title)
          inline_section = build_inline_comments_section(review_threads)
          unresolved_section = build_unresolved_section(comments, reviews)
          resolved_section = build_resolved_section(reviews)
          comments_table = build_comments_table(comments, reviews)

          # Combine sections
          sections = [frontmatter, summary]
          sections << inline_section unless inline_section.nil?
          sections << unresolved_section unless unresolved_section.nil?
          sections << resolved_section unless resolved_section.nil?
          sections << comments_table unless comments_table.nil?

          sections.join("\n")
        end

        # Build YAML frontmatter
        #
        # @param comments_data [Hash] Comments data
        # @return [String] YAML frontmatter block
        def self.build_frontmatter(comments_data)
          metadata = {
            "source" => "pr-comments",
            "pr_number" => comments_data[:pr_number],
            "fetched_at" => Time.now.utc.iso8601
          }

          "---\n#{YAML.dump(metadata).sub(/^---\n/, "")}---\n"
        end

        # Build summary section
        #
        # @param comments [Array<Hash>] Issue comments
        # @param reviews [Array<Hash>] Code reviews
        # @param review_threads [Array<Hash>] Inline review threads
        # @param pr_number [Integer] PR number
        # @param pr_title [String] PR title
        # @return [String] Summary markdown
        def self.build_summary(comments, reviews, review_threads, pr_number, pr_title)
          total_comments = comments.size + reviews.size
          inline_thread_count = review_threads.size
          reviewers = extract_reviewers(comments, reviews, review_threads)
          unresolved_count = count_unresolved(comments, reviews, review_threads)

          summary = "# Developer Feedback from PR ##{pr_number}\n\n"
          summary += "> #{pr_title}\n\n" if pr_title && !pr_title.empty?
          summary += "## Summary\n\n"
          summary += "- Total comments: #{total_comments}\n"
          summary += "- Inline code comments: #{inline_thread_count}\n" if inline_thread_count > 0
          summary += "- Unresolved items: #{unresolved_count}\n"
          summary += "- Reviewers: #{reviewers.map { |r| "@#{r}" }.join(", ")}\n" if reviewers.any?
          summary
        end

        # Build unresolved feedback section
        #
        # @param comments [Array<Hash>] Issue comments
        # @param reviews [Array<Hash>] Code reviews
        # @return [String, nil] Unresolved section or nil if empty
        def self.build_unresolved_section(comments, reviews)
          unresolved = []

          # Add comments (all issue comments are considered unresolved/open)
          comments.each do |comment|
            unresolved << {
              author: comment[:author],
              body: comment[:body],
              id: comment[:id],
              type: "comment",
              created_at: comment[:created_at]
            }
          end

          # Add reviews with "CHANGES_REQUESTED" state
          reviews.select { |r| r[:state] == "CHANGES_REQUESTED" }.each do |review|
            unresolved << {
              author: review[:author],
              body: review[:body],
              id: review[:id],
              type: "changes_requested",
              created_at: review[:created_at]
            }
          end

          return nil if unresolved.empty?

          section = "\n## Unresolved Feedback\n\n"

          unresolved.each do |item|
            section += "### @#{item[:author]} (#{item[:type]}: #{item[:id]})\n\n"
            section += format_body(item[:body])
            section += "\n\n"
          end

          section
        end

        # Build inline code comments section
        #
        # @param review_threads [Array<Hash>] Review threads from GraphQL
        # @return [String, nil] Inline comments section or nil if empty
        def self.build_inline_comments_section(review_threads)
          return nil if review_threads.nil? || review_threads.empty?

          section = "\n## Inline Code Comments\n\n"

          review_threads.each do |thread|
            path = thread[:path] || "unknown"
            line = thread[:line]
            thread_id = thread[:id]
            is_resolved = thread[:is_resolved]
            status = is_resolved ? "Resolved" : "Unresolved"

            # Header with file:line, thread ID, and status
            location = line ? "#{path}:#{line}" : path
            section += "### #{location} (thread: #{thread_id}) - #{status}\n\n"

            # Format each comment in the thread
            (thread[:comments] || []).each do |comment|
              author = comment[:author] || "unknown"
              body = comment[:body]&.strip
              next if body.nil? || body.empty?

              # Quote the comment with author prefix
              section += "> @#{author}: #{body.gsub("\n", "\n> ")}\n\n"
            end
          end

          section
        end

        # Build resolved feedback section
        #
        # @param reviews [Array<Hash>] Code reviews
        # @return [String, nil] Resolved section or nil if empty
        def self.build_resolved_section(reviews)
          resolved = []

          # Add approvals
          reviews.select { |r| r[:state] == "APPROVED" }.each do |review|
            resolved << "@#{review[:author]} approved changes"
          end

          return nil if resolved.empty?

          section = "\n## Resolved Feedback\n\n"
          resolved.each do |item|
            section += "- #{item}\n"
          end

          section
        end

        # Build comments table for quick reference
        #
        # @param comments [Array<Hash>] Issue comments
        # @param reviews [Array<Hash>] Code reviews
        # @return [String, nil] Table markdown or nil if empty
        def self.build_comments_table(comments, reviews)
          all_items = []

          comments.each do |c|
            all_items << {
              author: c[:author],
              type: "Comment",
              status: "Open",
              preview: truncate_body(c[:body], 50),
              id: c[:id]
            }
          end

          reviews.each do |r|
            status = REVIEW_STATES[r[:state]] || r[:state]
            all_items << {
              author: r[:author],
              type: "Review",
              status: status,
              preview: truncate_body(r[:body], 50),
              id: r[:id]
            }
          end

          return nil if all_items.empty?

          table = "\n## All Comments\n\n"
          table += "| Author | Type | Status | Comment | ID |\n"
          table += "|--------|------|--------|---------|----|\n"

          all_items.each do |item|
            # Wrap ID in backticks for readability
            table += "| @#{item[:author]} | #{item[:type]} | #{item[:status]} | #{item[:preview]} | `#{item[:id]}` |\n"
          end

          table
        end

        # Extract unique reviewers from comments, reviews, and threads
        #
        # @param comments [Array<Hash>] Issue comments
        # @param reviews [Array<Hash>] Code reviews
        # @param review_threads [Array<Hash>] Inline review threads
        # @return [Array<String>] Unique reviewer usernames
        def self.extract_reviewers(comments, reviews, review_threads = [])
          authors = []
          authors.concat(comments.map { |c| c[:author] })
          authors.concat(reviews.map { |r| r[:author] })
          # Extract authors from review thread comments
          review_threads.each do |thread|
            (thread[:comments] || []).each do |comment|
              authors << comment[:author]
            end
          end
          authors.uniq.compact.sort
        end

        # Count unresolved items
        # Counts actionable items (not informational/FYI comments)
        #
        # @param comments [Array<Hash>] Issue comments
        # @param reviews [Array<Hash>] Code reviews
        # @param review_threads [Array<Hash>] Inline review threads
        # @return [Integer] Count of unresolved items
        def self.count_unresolved(comments, reviews, review_threads = [])
          unresolved_threads = review_threads.count { |t| !t[:is_resolved] }
          actionable_comments = comments.count { |c| actionable_comment?(c[:body]) }
          actionable_comments + reviews.count { |r| r[:state] == "CHANGES_REQUESTED" } + unresolved_threads
        end

        # Check if a comment appears to be actionable (vs informational/FYI)
        # Heuristic: contains question marks, action words, or change requests
        #
        # @param body [String] Comment body
        # @return [Boolean] true if comment seems actionable
        def self.actionable_comment?(body)
          return true if body.nil? || body.empty?  # Default to actionable if can't determine

          lowered = body.downcase
          # Action indicators
          lowered.include?("?") ||                      # Questions
            lowered.include?("please") ||               # Polite requests
            lowered.include?("should") ||               # Suggestions
            lowered.include?("could you") ||            # Requests
            lowered.include?("need to") ||              # Requirements
            lowered.include?("must") ||                 # Requirements
            lowered.include?("fix") ||                  # Fix requests
            lowered.include?("change") ||               # Change requests
            lowered.include?("update") ||               # Update requests
            lowered.include?("consider") ||             # Suggestions
            lowered.match?(/\btodo\b/i)                 # TODOs
        end

        # Format comment body with proper indentation/quoting
        #
        # @param body [String] Comment body
        # @return [String] Formatted body
        def self.format_body(body)
          return "" if body.nil? || body.empty?

          # Quote each line
          body.lines.map { |line| "> #{line.rstrip}" }.join("\n")
        end

        # Truncate body for table preview
        #
        # @param body [String] Comment body
        # @param max_length [Integer] Maximum length
        # @return [String] Truncated body (pipe-safe for markdown tables)
        def self.truncate_body(body, max_length)
          return "" if body.nil?

          # Replace newlines with visual indicator, collapse other whitespace
          cleaned = body.gsub(/[\r\n]+/, " \u21b5 ").gsub(/[ \t]+/, " ").strip

          # Escape pipe characters to prevent breaking markdown tables
          cleaned = cleaned.gsub("|", "\\|")

          if cleaned.length > max_length
            "#{cleaned[0...max_length]}..."
          else
            cleaned
          end
        end

        private_class_method :build_frontmatter, :build_summary, :build_inline_comments_section,
          :build_unresolved_section, :build_resolved_section, :build_comments_table,
          :extract_reviewers, :count_unresolved, :actionable_comment?, :format_body, :truncate_body
      end
    end
  end
end
