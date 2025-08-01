# frozen_string_literal: true

require 'pathname'

module CodingAgentTools
  module Molecules
    module Code
      # ReportCollector handles collection and validation of review report files
      # This molecule focuses on file input handling and validation
      class ReportCollector
        # Result class for report collection
        class CollectionResult
          attr_reader :reports, :error

          def initialize(reports: [], error: nil)
            @reports = reports
            @error = error
          end

          def valid?
            @error.nil? && !@reports.empty?
          end

          def invalid?
            !valid?
          end
        end

        # Collect and validate review report files
        # @param report_paths [Array<String>] Array of file paths or glob patterns
        # @return [CollectionResult] Result containing validated reports or error
        def collect_reports(report_paths)
          return CollectionResult.new(error: 'No report paths provided') if report_paths.nil? || report_paths.empty?

          # Expand glob patterns and validate files
          expanded_reports = []

          report_paths.each do |path|
            if path.include?('*') || path.include?('?') || path.include?('[')
              # Handle glob patterns
              glob_matches = Dir.glob(path)
              return CollectionResult.new(error: "No files found matching pattern: #{path}") if glob_matches.empty?

              expanded_reports.concat(glob_matches)
            else
              # Handle direct file paths
              expanded_reports << path
            end
          end

          # Remove duplicates and sort
          expanded_reports = expanded_reports.uniq.sort

          # Validate each report file
          validation_result = validate_report_files(expanded_reports)
          return validation_result unless validation_result.valid?

          # Filter for review report files
          review_reports = filter_review_reports(expanded_reports)

          return CollectionResult.new(error: 'No valid review report files found') if review_reports.empty?

          if review_reports.length < 2
            return CollectionResult.new(error: 'At least 2 review reports are required for synthesis')
          end

          CollectionResult.new(reports: review_reports)
        end

        private

        # Validate that all report files exist and are readable
        # @param file_paths [Array<String>] File paths to validate
        # @return [CollectionResult] Validation result
        def validate_report_files(file_paths)
          file_paths.each do |path|
            return CollectionResult.new(error: "File not found: #{path}") unless File.exist?(path)

            return CollectionResult.new(error: "File not readable: #{path}") unless File.readable?(path)

            return CollectionResult.new(error: "Path is not a file: #{path}") unless File.file?(path)

            # Check file size (avoid extremely large files)
            file_size = File.size(path)
            max_size = 50 * 1024 * 1024 # 50MB
            return CollectionResult.new(error: "File too large (#{file_size} bytes): #{path}") if file_size > max_size
          end

          CollectionResult.new(reports: file_paths)
        end

        # Filter files to include only review report files
        # @param file_paths [Array<String>] All file paths
        # @return [Array<String>] Filtered review report files
        def filter_review_reports(file_paths)
          file_paths.select do |path|
            review_report_file?(path)
          end
        end

        # Check if a file appears to be a review report
        # @param file_path [String] Path to check
        # @return [Boolean] True if file appears to be a review report
        def review_report_file?(file_path)
          basename = File.basename(file_path)
          extension = File.extname(file_path).downcase

          # Must be a markdown file
          return false unless %w[.md .markdown].include?(extension)

          # Check filename patterns that indicate review reports
          review_patterns = [
            /^cr-report/i,           # cr-report*.md
            /review.*report/i,       # *review*report*.md
            /report.*review/i,       # *report*review*.md
            /code.*review/i,         # *code*review*.md
            /review.*synthesis/i,    # *review*synthesis*.md
            /synthesis.*review/i     # *synthesis*review*.md
          ]

          # Check if filename matches any review pattern
          pattern_match = review_patterns.any? { |pattern| basename =~ pattern }

          # Also check file content for review indicators if filename check fails
          content_match = false
          content_match = review_content_indicators?(file_path) if !pattern_match && file_readable_sample?(file_path)

          pattern_match || content_match
        end

        # Check if file is small enough for content sampling
        # @param file_path [String] Path to check
        # @return [Boolean] True if file can be sampled safely
        def file_readable_sample?(file_path)
          File.size(file_path) < 1024 * 1024 # 1MB
        end

        # Check file content for review indicators
        # @param file_path [String] Path to check
        # @return [Boolean] True if content indicates review report
        def review_content_indicators?(file_path)
          # Read first 2KB to check for review content markers
          sample = File.read(file_path, 2048, encoding: 'UTF-8')

          # Look for common review report section headers
          review_headers = [
            /## Executive Summary/i,
            /## Prioritised.*Action Items/i,
            /## Implementation Recommendation/i,
            /## Code Quality/i,
            /## Test Coverage/i,
            /## Documentation/i,
            /## Security/i,
            /## Performance/i,
            /## Findings/i,
            /## Recommendations/i
          ]

          # Check for review metadata patterns
          metadata_patterns = [
            /provider:\s*(google|anthropic|openai)/i,
            /model:\s*(gemini|claude|gpt)/i,
            /focus:\s*(code|tests|docs)/i,
            /review.*timestamp/i
          ]

          # File is likely a review if it contains review headers or metadata
          has_headers = review_headers.any? { |pattern| sample =~ pattern }
          has_metadata = metadata_patterns.any? { |pattern| sample =~ pattern }

          has_headers || has_metadata
        rescue StandardError
          # If we can't read the file for content check, assume it's not a review
          false
        end
      end
    end
  end
end
