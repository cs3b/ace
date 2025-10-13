# frozen_string_literal: true

require_relative '../atoms/kramdown_parser'
require_relative '../models/lint_result'
require_relative '../models/validation_error'

module Ace
  module Lint
    module Molecules
      # Validates markdown syntax via kramdown
      class MarkdownLinter
        # Validate markdown file
        # @param file_path [String] Path to markdown file
        # @param options [Hash] Kramdown options
        # @return [Models::LintResult] Validation result
        def self.lint(file_path, options: {})
          content = File.read(file_path)
          lint_content(file_path, content, options: options)
        rescue Errno::ENOENT
          Models::LintResult.new(
            file_path: file_path,
            success: false,
            errors: [Models::ValidationError.new(message: "File not found: #{file_path}")]
          )
        rescue StandardError => e
          Models::LintResult.new(
            file_path: file_path,
            success: false,
            errors: [Models::ValidationError.new(message: "Error reading file: #{e.message}")]
          )
        end

        # Validate markdown content
        # @param file_path [String] Path for reference
        # @param content [String] Markdown content
        # @param options [Hash] Kramdown options
        # @return [Models::LintResult] Validation result
        def self.lint_content(file_path, content, options: {})
          result = Atoms::KramdownParser.parse(content, options: options)

          errors = result[:errors].map do |msg|
            Models::ValidationError.new(message: msg, severity: :error)
          end

          warnings = result[:warnings].map do |msg|
            Models::ValidationError.new(message: msg, severity: :warning)
          end

          # Add style checks
          style_warnings = check_markdown_style(content)
          warnings.concat(style_warnings)

          Models::LintResult.new(
            file_path: file_path,
            success: result[:success],
            errors: errors,
            warnings: warnings
          )
        end

        # Check markdown style best practices
        # @param content [String] Markdown content
        # @return [Array<Models::ValidationError>] Style warnings
        def self.check_markdown_style(content)
          warnings = []
          lines = content.lines

          lines.each_with_index do |line, idx|
            line_num = idx + 1
            next_line = lines[idx + 1]

            # Check: blank line after headers
            if line.match?(/^\#{1,6}\s+\S/) && next_line && !next_line.strip.empty?
              warnings << Models::ValidationError.new(
                line: line_num,
                message: 'Missing blank line after heading',
                severity: :warning
              )
            end

            # Check: blank line before lists (unless first line or after another list item)
            prev_line = idx.positive? ? lines[idx - 1] : nil
            if line.match?(/^[\*\-]\s+\S/) && prev_line && !prev_line.strip.empty? && !prev_line.match?(/^[\*\-]\s+\S/)
              warnings << Models::ValidationError.new(
                line: line_num,
                message: 'Missing blank line before list',
                severity: :warning
              )
            end

            # Check: blank line after lists
            if prev_line&.match?(/^[\*\-]\s+\S/) && !line.match?(/^[\*\-]\s+\S/) && !line.strip.empty?
              warnings << Models::ValidationError.new(
                line: line_num,
                message: 'Missing blank line after list',
                severity: :warning
              )
            end

            # Check: blank line before code blocks
            if line.match?(/^```/) && prev_line && !prev_line.strip.empty?
              warnings << Models::ValidationError.new(
                line: line_num,
                message: 'Missing blank line before code block',
                severity: :warning
              )
            end

            # Check: blank line after code blocks (closing ```)
            if prev_line&.match?(/^```$/) && !line.strip.empty?
              warnings << Models::ValidationError.new(
                line: line_num,
                message: 'Missing blank line after code block',
                severity: :warning
              )
            end
          end

          warnings
        end
      end
    end
  end
end
