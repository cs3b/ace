# frozen_string_literal: true

require_relative "../atoms/kramdown_parser"
require_relative "../atoms/frontmatter_extractor"
require_relative "../models/lint_result"
require_relative "../models/validation_error"

module Ace
  module Lint
    module Molecules
      # Validates markdown syntax via kramdown
      class MarkdownLinter
        # Typography characters to detect
        EM_DASH = "\u2014"
        SMART_QUOTES = [
          "\u201C", # Left double quotation mark "
          "\u201D", # Right double quotation mark "
          "\u2018", # Left single quotation mark '
          "\u2019"  # Right single quotation mark '
        ].freeze

        # Fenced code block pattern (``` or ~~~, with optional up to 3 leading spaces per CommonMark)
        # Captures the fence character and length for proper matching
        FENCE_PATTERN = /^(\s{0,3})(`{3,}|~{3,})/
        # Markdown link pattern [text](url) - captures link text for typography checking
        LINK_PATTERN = /\[([^\]]*)\]\([^)]*\)/
        # Inline code pattern - handles single and double backtick spans
        INLINE_CODE_PATTERN = /``[^`]+``|`[^`]+`/
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
        rescue => e
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
          markdown_content = strip_frontmatter(content)
          result = Atoms::KramdownParser.parse(markdown_content, options: options)

          errors = result[:errors].map do |msg|
            Models::ValidationError.new(message: msg, severity: :error)
          end

          warnings = result[:warnings].map do |msg|
            Models::ValidationError.new(message: msg, severity: :warning)
          end

          # Add style checks
          style_warnings = check_markdown_style(markdown_content)
          warnings.concat(style_warnings)

          # Add typography checks
          config = Ace::Lint.markdown_config
          typography_issues = check_typography(markdown_content, config)
          typography_issues.each do |issue|
            if issue.severity == :error
              errors << issue
            else
              warnings << issue
            end
          end

          Models::LintResult.new(
            file_path: file_path,
            success: result[:success] && errors.empty?,
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
                message: "Missing blank line after heading",
                severity: :warning
              )
            end

            # Check: blank line before lists (unless first line or after another list item)
            prev_line = idx.positive? ? lines[idx - 1] : nil
            if line.match?(/^[*-]\s+\S/) && prev_line && !prev_line.strip.empty? && !prev_line.match?(/^[*-]\s+\S/)
              warnings << Models::ValidationError.new(
                line: line_num,
                message: "Missing blank line before list",
                severity: :warning
              )
            end

            # Check: blank line after lists
            if prev_line&.match?(/^[*-]\s+\S/) && !line.match?(/^[*-]\s+\S/) && !line.strip.empty?
              warnings << Models::ValidationError.new(
                line: line_num,
                message: "Missing blank line after list",
                severity: :warning
              )
            end

            # Check: blank line before code blocks
            if line.match?(/^```/) && prev_line && !prev_line.strip.empty?
              warnings << Models::ValidationError.new(
                line: line_num,
                message: "Missing blank line before code block",
                severity: :warning
              )
            end

            # Check: blank line after code blocks (closing ```)
            if prev_line&.match?(/^```$/) && !line.strip.empty?
              warnings << Models::ValidationError.new(
                line: line_num,
                message: "Missing blank line after code block",
                severity: :warning
              )
            end
          end

          # Check: file should end with newline
          unless content.end_with?("\n")
            warnings << Models::ValidationError.new(
              message: "Missing trailing newline at end of file",
              severity: :warning
            )
          end

          warnings
        end

        def self.strip_frontmatter(content)
          extraction = Atoms::FrontmatterExtractor.extract(content)
          return content unless extraction[:has_frontmatter]

          frontmatter_lines = extraction[:frontmatter].to_s.lines.count + 2
          ("\n" * frontmatter_lines) + extraction[:body].to_s
        end

        # Check typography issues (em-dashes, smart quotes)
        # Skips content inside fenced code blocks and inline code
        # @param content [String] Markdown content
        # @param config [Hash] Markdown configuration with typography settings
        # @return [Array<Models::ValidationError>] Typography issues
        def self.check_typography(content, config)
          issues = []
          typography_config = config["typography"] || {}
          em_dash_severity = typography_config["em_dash"] || "warn"
          smart_quotes_severity = typography_config["smart_quotes"] || "warn"

          # Return early if both checks are disabled
          return issues if em_dash_severity == "off" && smart_quotes_severity == "off"

          lines = content.lines
          in_code_block = false
          fence_char = nil
          fence_length = 0

          lines.each_with_index do |line, idx|
            line_num = idx + 1

            # Track fenced code block state with proper fence matching
            if (match = line.match(FENCE_PATTERN))
              current_fence_char = match[2][0] # First char (` or ~)
              current_fence_length = match[2].length

              if in_code_block
                # Only close if same char and at least same length
                if current_fence_char == fence_char && current_fence_length >= fence_length
                  in_code_block = false
                  fence_char = nil
                  fence_length = 0
                end
              else
                # Opening fence
                in_code_block = true
                fence_char = current_fence_char
                fence_length = current_fence_length
              end
              next
            end

            # Skip lines inside code blocks
            next if in_code_block

            # Remove inline code spans (handles both single and double backticks)
            # Then remove link markup but keep link text for checking
            line_without_code = line.gsub(INLINE_CODE_PATTERN, "")
              .gsub(LINK_PATTERN, '\1')

            # Check for em-dashes
            if em_dash_severity != "off" && line_without_code.include?(EM_DASH)
              severity = (em_dash_severity == "error") ? :error : :warning
              issues << Models::ValidationError.new(
                line: line_num,
                message: "Em-dash character found; use double hyphens (--) instead",
                severity: severity
              )
            end

            # Check for smart quotes
            if smart_quotes_severity != "off"
              SMART_QUOTES.each do |quote|
                if line_without_code.include?(quote)
                  severity = (smart_quotes_severity == "error") ? :error : :warning
                  quote_type = ["\u201C", "\u201D"].include?(quote) ? "double" : "single"
                  issues << Models::ValidationError.new(
                    line: line_num,
                    message: "Smart #{quote_type} quote (#{quote}) found; use ASCII quotes instead",
                    severity: severity
                  )
                end
              end
            end
          end

          issues
        end
      end
    end
  end
end
