# frozen_string_literal: true

require "open3"
require "date"
require "fileutils"
require "yaml"

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
        #   For single subject: returns hash with :diff key containing single diff
        #   For multi-subject: returns hash with :diffs key containing {name => content}
        def self.get_diff_for_document(document, since: nil, options: {})
          return empty_diff_result unless document.path

          # Determine the since parameter
          since_param = determine_since(document, since)

          # Check if document has multi-subject configuration
          if document.multi_subject?
            # Generate separate diffs for each subject
            diffs_hash = get_diffs_for_subjects(document, since_param, options)

            {
              document_path: document.path,
              document_type: document.doc_type,
              since: since_param,
              diffs: diffs_hash,
              multi_subject: true,
              has_changes: diffs_hash.values.any? { |diff| !diff.strip.empty? },
              timestamp: Time.now.iso8601,
              options: options
            }
          else
            # Single subject - backward compatible behavior
            filters = document.subject_diff_filters
            if filters && !filters.empty?
              options = options.merge(paths: filters)
            end

            diff_content = generate_git_diff(since_param, options)

            {
              document_path: document.path,
              document_type: document.doc_type,
              since: since_param,
              diff: diff_content,
              multi_subject: false,
              has_changes: !diff_content.strip.empty?,
              timestamp: Time.now.iso8601,
              options: options
            }
          end
        end

        # Generate diffs for multiple subjects
        # @param document [Document] The document with multi-subject configuration
        # @param since [String] Date or commit to diff from
        # @param options [Hash] Base options for diff generation
        # @return [Hash] Hash mapping subject names to diff content {name => diff_string}
        def self.get_diffs_for_subjects(document, since, options = {})
          subject_configs = document.subject_configurations

          result = {}
          subject_configs.each do |subject|
            name = subject[:name]
            filters = subject[:filters]

            # Build options for this subject
            subject_options = options.merge(paths: filters)

            # Generate diff for this subject
            diff_content = generate_git_diff(since, subject_options)

            # Store diff (even if empty - caller can decide whether to keep)
            result[name] = diff_content
          end

          result
        end

        # Get combined diff for multiple documents
        # @param documents [Array<Document>] Documents to analyze
        # @param since [String, Date] Date or commit to diff from
        # @param options [Hash] Options for diff generation
        # @return [Hash] Combined diff results
        def self.get_diff_for_documents(documents, since: nil, options: {})
          # Get document-specific diffs with subject filtering
          since_param = since || default_since_date

          document_diffs = documents.map do |doc|
            # Extract subject diff filters for this document
            doc_options = options.dup
            filters = doc.subject_diff_filters
            if filters && !filters.empty?
              doc_options = doc_options.merge(paths: filters)
            end

            # Get filtered diff for this document
            diff_content = generate_git_diff(since_param, doc_options)

            {
              document: doc,
              diff: diff_content,
              has_changes: !diff_content.strip.empty?
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

        # Generate batch diff for analysis
        # @param documents [Array<Document>] Documents to analyze
        # @param since [String] Time range for diff
        # @param options [Hash] Options for diff generation
        # @return [String] Raw git diff
        def self.generate_batch_diff(documents, since, options = {})
          # Generate the full codebase diff for the time period
          generate_git_diff(since, options)
        end

        # Save diff analysis to cache folder with session structure
        # @param diff_result [Hash] Diff analysis result
        # @return [String] Path to saved analysis file
        def self.save_diff_to_cache(diff_result)
          cache_dir = ".cache/ace-docs"
          timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
          session_dir = File.join(cache_dir, "diff-#{timestamp}")

          FileUtils.mkdir_p(session_dir)

          # Save raw git diff
          if diff_result[:diff] && !diff_result[:diff].empty?
            raw_diff_path = File.join(session_dir, "repo-diff.diff")
            File.write(raw_diff_path, diff_result[:diff])
          end

          # Save formatted analysis report
          analysis_path = File.join(session_dir, "analysis.md")
          content = format_diff_for_saving(diff_result)
          File.write(analysis_path, content)

          # Save metadata
          metadata_path = File.join(session_dir, "metadata.yml")
          metadata = {
            "generated" => diff_result[:timestamp],
            "since" => diff_result[:since],
            "document_count" => diff_result[:total_documents] || 1,
            "has_changes" => diff_result[:has_changes] || (diff_result[:documents_with_changes] || 0) > 0,
            "options" => diff_result[:options] || {}
          }
          File.write(metadata_path, metadata.to_yaml)

          analysis_path
        end

        # Check if files have been renamed or moved
        # @param since [String] Date or commit to check from
        # @return [Array<Hash>] List of renamed/moved files
        def self.detect_renames(since: nil)
          since_param = since || default_since_date
          since_ref = resolve_since_to_commit(since_param)
          cmd = "git diff --name-status --diff-filter=R #{since_ref}..HEAD"

          stdout, stderr, status = Open3.capture3(cmd, chdir: git_root)
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
          # Resolve since to a commit SHA
          since_ref = resolve_since_to_commit(since)

          # Build git diff command with -w flag (ignore whitespace)
          cmd_parts = ["git", "diff", "-w"]

          # Add filters based on options
          unless options[:include_renames]
            cmd_parts << "--diff-filter=ACMTUXB"  # Exclude R (renames)
          end

          unless options[:include_moves]
            cmd_parts << "--no-renames"
          end

          # Add since parameter with resolved commit
          cmd_parts << "#{since_ref}..HEAD"

          # Add path filters if specified
          if options[:paths]
            cmd_parts << "--"
            cmd_parts.concat(Array(options[:paths]))
          end

          cmd = cmd_parts.join(" ")
          stdout, _stderr, status = Open3.capture3(cmd, chdir: git_root)

          status.success? ? stdout : ""
        end

        def self.resolve_since_to_commit(since)
          # If it looks like a commit SHA, use as-is
          return since if since =~ /^[0-9a-f]{7,40}$/i

          # It's a date - find the first commit since that date
          cmd = "git log --since=\"#{since}\" --format=%H --reverse --all"
          stdout, _stderr, status = Open3.capture3(cmd, chdir: git_root)

          if status.success? && !stdout.strip.empty?
            first_commit = stdout.strip.split("\n").first

            # Get parent of first commit to include all changes since date
            parent_cmd = "git rev-parse #{first_commit}~1 2>/dev/null"
            parent_stdout, _, parent_status = Open3.capture3(parent_cmd, chdir: git_root)

            if parent_status.success? && !parent_stdout.strip.empty?
              return parent_stdout.strip
            else
              # First commit has no parent (initial commit), use it directly
              return first_commit
            end
          end

          # Fallback: use date string and let git handle it
          since
        end

        def self.git_root
          @git_root ||= begin
            stdout, _, status = Open3.capture3("git rev-parse --show-toplevel")
            status.success? ? stdout.strip : Dir.pwd
          end
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