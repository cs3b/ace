# frozen_string_literal: true

require "open3"
require "date"
require "fileutils"

module Ace
  module Docs
    module Molecules
      # Analyzes git history and file changes for documents
      class ChangeDetector
        # Get git diff for a document since a specific date or commit
        # @param document [Document] The document to analyze
        # @param since [String, Date] Date or commit to diff from
        # @param options [Hash] Options for diff generation
        # @return [Hash] Diff result with content and metadata
        def self.get_diff_for_document(document, since: nil, options: {})
          return empty_diff_result unless document.path

          # Determine the since parameter
          since_param = determine_since(document, since)

          # Get the git diff
          diff_content = generate_git_diff(since_param, options)

          # Filter for relevance to this document
          relevant_diff = filter_relevant_changes(diff_content, document)

          {
            document_path: document.path,
            document_type: document.doc_type,
            since: since_param,
            diff: relevant_diff,
            has_changes: !relevant_diff.strip.empty?,
            timestamp: Time.now.iso8601,
            options: options
          }
        end

        # Get combined diff for multiple documents
        # @param documents [Array<Document>] Documents to analyze
        # @param since [String, Date] Date or commit to diff from
        # @param options [Hash] Options for diff generation
        # @return [Hash] Combined diff results
        def self.get_diff_for_documents(documents, since: nil, options: {})
          # Get global diff once
          since_param = since || default_since_date
          diff_content = generate_git_diff(since_param, options)

          # Map to document-specific results
          document_diffs = documents.map do |doc|
            relevant_diff = filter_relevant_changes(diff_content, doc)
            {
              document: doc,
              diff: relevant_diff,
              has_changes: !relevant_diff.strip.empty?
            }
          end

          {
            total_documents: documents.size,
            documents_with_changes: document_diffs.count { |d| d[:has_changes] },
            since: since_param,
            timestamp: Time.now.iso8601,
            options: options,
            document_diffs: document_diffs
          }
        end

        # Save diff analysis to cache file
        # @param diff_result [Hash] Diff analysis result
        # @return [String] Path to saved file
        def self.save_diff_to_cache(diff_result)
          cache_dir = ".cache/ace-docs"
          FileUtils.mkdir_p(cache_dir)

          timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
          filename = "diff-#{timestamp}.md"
          filepath = File.join(cache_dir, filename)

          content = format_diff_for_saving(diff_result)
          File.write(filepath, content)

          filepath
        end

        # Check if files have been renamed or moved
        # @param since [String] Date or commit to check from
        # @return [Array<Hash>] List of renamed/moved files
        def self.detect_renames(since: nil)
          since_param = since || default_since_date
          cmd = "git diff --name-status --diff-filter=R #{since_param}..HEAD"

          stdout, stderr, status = Open3.capture3(cmd)
          return [] unless status.success?

          renames = []
          stdout.each_line do |line|
            if line.start_with?("R")
              parts = line.strip.split(/\s+/, 3)
              if parts.length >= 3
                old_path, new_path = parts[1], parts[2]
                renames << { old: old_path, new: new_path }
              end
            end
          end

          renames
        end

        private

        def self.empty_diff_result
          {
            document_path: nil,
            diff: "",
            has_changes: false,
            timestamp: Time.now.iso8601
          }
        end

        def self.determine_since(document, since)
          # If explicit since provided, use it
          return format_since(since) if since

          # Use document's last updated date if available
          if document.last_updated
            return document.last_updated.strftime("%Y-%m-%d")
          end

          # Default to 7 days ago
          default_since_date
        end

        def self.format_since(since)
          case since
          when Date
            since.strftime("%Y-%m-%d")
          when Time
            since.strftime("%Y-%m-%d")
          when String
            since
          else
            default_since_date
          end
        end

        def self.default_since_date
          (Date.today - 7).strftime("%Y-%m-%d")
        end

        def self.generate_git_diff(since, options = {})
          # Build git diff command with -w flag (ignore whitespace)
          cmd_parts = ["git", "diff", "-w"]

          # Add filters based on options
          unless options[:include_renames]
            cmd_parts << "--diff-filter=ACMTUXB"  # Exclude R (renames)
          end

          unless options[:include_moves]
            cmd_parts << "--no-renames"
          end

          # Add since parameter
          cmd_parts << "#{since}..HEAD"

          # Add path filters if specified
          if options[:paths]
            cmd_parts.concat(Array(options[:paths]))
          end

          cmd = cmd_parts.join(" ")
          stdout, _stderr, status = Open3.capture3(cmd)

          status.success? ? stdout : ""
        end

        def self.filter_relevant_changes(diff_content, document)
          # Get focus hints from document
          focus = document.focus_hints

          # For now, return full diff for LLM to analyze
          # In future, could pre-filter based on focus paths
          if focus["paths"]
            # Could filter diff to only include specified paths
            # But for now, let LLM handle the relevance filtering
          end

          diff_content
        end

        def self.format_diff_for_saving(diff_result)
          content = []
          content << "# Diff Analysis Report"
          content << "Generated: #{diff_result[:timestamp]}"
          content << "Since: #{diff_result[:since]}"
          content << ""

          if diff_result[:document_diffs]
            # Multiple documents
            content << "## Summary"
            content << "- Total documents analyzed: #{diff_result[:total_documents]}"
            content << "- Documents with changes: #{diff_result[:documents_with_changes]}"
            content << ""

            diff_result[:document_diffs].each do |doc_diff|
              doc = doc_diff[:document]
              content << "## #{doc.display_name}"
              content << "- Type: #{doc.doc_type}"
              content << "- Purpose: #{doc.purpose}"
              content << "- Has changes: #{doc_diff[:has_changes] ? 'Yes' : 'No'}"
              content << ""

              if doc_diff[:has_changes]
                content << "### Relevant Changes"
                content << "```diff"
                content << doc_diff[:diff]
                content << "```"
              else
                content << "No relevant changes detected."
              end
              content << ""
            end
          else
            # Single document
            content << "## Document: #{diff_result[:document_path]}"
            content << "- Type: #{diff_result[:document_type]}"
            content << "- Has changes: #{diff_result[:has_changes] ? 'Yes' : 'No'}"
            content << ""

            if diff_result[:has_changes]
              content << "### Git Diff"
              content << "```diff"
              content << diff_result[:diff]
              content << "```"
            else
              content << "No changes detected."
            end
          end

          content.join("\n")
        end
      end
    end
  end
end