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
        # Inline code pattern - handles single and double backtick spans
        INLINE_CODE_PATTERN = /``[^`]+``|`[^`]+`/
        HEADING_PATTERN = /^\#{1,6}\s+\S/
        UNORDERED_LIST_PATTERN = /^[*-]\s+\S/
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
          each_fence_aware_line(lines) do |line:, index:, in_code_block:, transition:|
            idx = index
            line_num = idx + 1
            prev_line = idx.positive? ? lines[idx - 1] : nil
            next_line = lines[idx + 1]

            case transition
            when :open
              if prev_line && !prev_line.strip.empty?
                warnings << Models::ValidationError.new(
                  line: line_num,
                  message: "Missing blank line before code block",
                  severity: :warning
                )
              end
              next
            when :close
              if next_line && !next_line.strip.empty?
                warnings << Models::ValidationError.new(
                  line: line_num + 1,
                  message: "Missing blank line after code block",
                  severity: :warning
                )
              end
              next
            end

            # Skip style checks inside fenced code blocks.
            next if in_code_block

            # Check: trailing whitespace
            if line_has_trailing_whitespace?(line)
              warnings << Models::ValidationError.new(
                line: line_num,
                message: "Trailing whitespace found",
                severity: :warning
              )
            end

            # Check: blank line before headers
            if line.match?(HEADING_PATTERN) && prev_line && !prev_line.strip.empty?
              warnings << Models::ValidationError.new(
                line: line_num,
                message: "Missing blank line before heading",
                severity: :warning
              )
            end

            # Check: blank line after headers
            if line.match?(HEADING_PATTERN) && next_line && !next_line.strip.empty?
              warnings << Models::ValidationError.new(
                line: line_num,
                message: "Missing blank line after heading",
                severity: :warning
              )
            end

            # Check: blank line before lists (unless first line or after another list item)
            if line.match?(UNORDERED_LIST_PATTERN) && prev_line && !prev_line.strip.empty? && !prev_line.match?(UNORDERED_LIST_PATTERN)
              warnings << Models::ValidationError.new(
                line: line_num,
                message: "Missing blank line before list",
                severity: :warning
              )
            end

            # Check: blank line after lists
            if prev_line&.match?(UNORDERED_LIST_PATTERN) && !line.match?(UNORDERED_LIST_PATTERN) && !line.strip.empty?
              warnings << Models::ValidationError.new(
                line: line_num,
                message: "Missing blank line after list",
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

        def self.line_has_trailing_whitespace?(line)
          line_without_newline = line.sub(/\r?\n\z/, "")
          line_without_newline.match?(/[ \t]+\z/)
        end

        def self.strip_frontmatter(content)
          extraction = Atoms::FrontmatterExtractor.extract(content)
          return content unless extraction[:has_frontmatter]

          frontmatter_lines = extraction[:frontmatter].to_s.lines.count + 2
          ("\n" * frontmatter_lines) + extraction[:body].to_s
        end

        def self.each_markdown_link(text)
          return enum_for(:each_markdown_link, text) unless block_given?

          cursor = 0
          while (open_bracket = text.index("[", cursor))
            close_bracket = find_matching_closer(text, open_bracket, "[", "]")
            if close_bracket && text[close_bracket + 1] == "("
              close_paren = find_matching_closer(text, close_bracket + 1, "(", ")")
              if close_paren
                yield(
                  start: open_bracket,
                  end_exclusive: close_paren + 1,
                  link_text: text[(open_bracket + 1)...close_bracket],
                  destination: text[(close_bracket + 2)...close_paren]
                )
                cursor = close_paren + 1
                next
              end
            end

            cursor = open_bracket + 1
          end
        end

        def self.strip_link_markup(text)
          output = +""
          cursor = 0

          each_markdown_link(text) do |link|
            output << text[cursor...link[:start]]
            output << link[:link_text]
            cursor = link[:end_exclusive]
          end

          output << (text[cursor..] || "")
          output
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

          each_fence_aware_line(lines) do |line:, index:, in_code_block:, transition:|
            line_num = index + 1

            next if transition || in_code_block

            # Remove inline code spans (handles both single and double backticks)
            # Then remove link markup but keep link text for checking
            line_without_code = strip_link_markup(line.gsub(INLINE_CODE_PATTERN, ""))

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

        def self.each_fence_aware_line(lines)
          return enum_for(:each_fence_aware_line, lines) unless block_given?

          in_code_block = false
          fence_char = nil
          fence_length = 0

          lines.each_with_index do |line, idx|
            transition = nil
            opened_fence_char = nil
            opened_fence_length = nil

            if (match = line.match(FENCE_PATTERN))
              current_fence_char = match[2][0]
              current_fence_length = match[2].length

              if in_code_block
                transition = :close if current_fence_char == fence_char && current_fence_length >= fence_length
              else
                transition = :open
                opened_fence_char = current_fence_char
                opened_fence_length = current_fence_length
              end
            end

            yield(
              line: line,
              index: idx,
              in_code_block: in_code_block,
              transition: transition
            )

            case transition
            when :open
              in_code_block = true
              fence_char = opened_fence_char
              fence_length = opened_fence_length
            when :close
              in_code_block = false
              fence_char = nil
              fence_length = 0
            end
          end
        end

        def self.find_matching_closer(text, opener_index, opener_char, closer_char)
          depth = 0
          idx = opener_index

          while idx < text.length
            char = text[idx]
            if escaped_character?(text, idx)
              idx += 1
              next
            end

            if char == opener_char
              depth += 1
            elsif char == closer_char
              depth -= 1
              return idx if depth.zero?
            end
            idx += 1
          end

          nil
        end

        def self.escaped_character?(text, index)
          backslashes = 0
          idx = index - 1

          while idx >= 0 && text[idx] == "\\"
            backslashes += 1
            idx -= 1
          end

          backslashes.odd?
        end
      end
    end
  end
end
