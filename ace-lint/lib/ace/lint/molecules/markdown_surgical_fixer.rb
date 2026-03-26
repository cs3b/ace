# frozen_string_literal: true

require_relative "../atoms/frontmatter_extractor"
require_relative "markdown_linter"

module Ace
  module Lint
    module Molecules
      # Applies low-risk, line-level markdown fixes without re-serializing the document.
      class MarkdownSurgicalFixer
        SMART_QUOTE_REPLACEMENTS = {
          "\u201C" => '"',
          "\u201D" => '"',
          "\u2018" => "'",
          "\u2019" => "'"
        }.freeze

        class << self
          def fix_file(file_path)
            content = File.binread(file_path).dup.force_encoding(Encoding::UTF_8)
            unless content.valid_encoding?
              return {
                success: true,
                formatted: false,
                errors: [],
                warnings: ["Skipped non-UTF8 file: #{file_path}"]
              }
            end

            result = fix_content(content)
            return {success: false, formatted: false, errors: result[:errors], warnings: result[:warnings]} unless result[:success]

            File.write(file_path, result[:formatted_content]) if result[:formatted]

            {
              success: true,
              formatted: result[:formatted],
              errors: [],
              warnings: result[:warnings]
            }
          rescue Errno::ENOENT
            {success: false, formatted: false, errors: ["File not found: #{file_path}"], warnings: []}
          rescue => e
            {success: false, formatted: false, errors: ["Error fixing file: #{e.message}"], warnings: []}
          end

          def fix_content(content)
            extraction = Atoms::FrontmatterExtractor.extract(content)
            if extraction[:has_frontmatter]
              body = extraction[:body].to_s
              # FrontmatterExtractor returns body as the exact suffix after frontmatter delimiters.
              frontmatter_prefix = content[0...(content.length - body.length)]
            else
              body = content
              frontmatter_prefix = ""
            end

            fixed_body = apply_body_fixes(body)
            formatted_content = frontmatter_prefix + fixed_body

            {
              success: true,
              formatted: formatted_content != content,
              formatted_content: formatted_content,
              errors: [],
              warnings: []
            }
          rescue => e
            {
              success: false,
              formatted: false,
              formatted_content: content,
              errors: ["Error fixing markdown content: #{e.message}"],
              warnings: []
            }
          end

          private

          def apply_body_fixes(body)
            return body if body.empty?

            lines = body.lines
            transformed = transform_lines(lines)
            with_spacing_fixes = apply_spacing_rules(transformed)
            fixed_body = with_spacing_fixes.join
            ensure_trailing_newline(fixed_body)
          end

          def transform_lines(lines)
            transformed = []
            MarkdownLinter.each_fence_aware_line(lines) do |line:, in_code_block:, transition:, **|
              case transition
              when :open
                transformed << trim_trailing_whitespace(line)
                next
              when :close
                transformed << line
                next
              end

              if in_code_block
                transformed << line
                next
              end

              normalized_line = trim_trailing_whitespace(line)
              transformed << replace_typography_outside_inline_code(normalized_line)
            end

            transformed
          end

          def apply_spacing_rules(lines)
            output = []
            MarkdownLinter.each_fence_aware_line(lines) do |line:, index:, in_code_block:, transition:|
              idx = index
              next_line = lines[idx + 1]
              previous_line = output.last

              case transition
              when :open
                ensure_blank_line_before(output, previous_line || line)
                output << line
                next
              when :close
                output << line
                ensure_blank_line_after(output, line) if next_line && !blank_line?(next_line)
                next
              end

              if in_code_block
                output << line
                next
              end

              if line.match?(MarkdownLinter::HEADING_PATTERN)
                ensure_blank_line_before(output, previous_line || line)
              end

              if line.match?(MarkdownLinter::UNORDERED_LIST_PATTERN) &&
                  previous_line &&
                  !blank_line?(previous_line) &&
                  !previous_line.match?(MarkdownLinter::UNORDERED_LIST_PATTERN)
                ensure_blank_line_before(output, previous_line)
              end

              if previous_line&.match?(MarkdownLinter::UNORDERED_LIST_PATTERN) &&
                  !line.match?(MarkdownLinter::UNORDERED_LIST_PATTERN) &&
                  !blank_line?(line)
                ensure_blank_line_before(output, previous_line)
              end

              output << line

              if line.match?(MarkdownLinter::HEADING_PATTERN) && next_line && !blank_line?(next_line)
                ensure_blank_line_after(output, line)
              end
            end

            output
          end

          def replace_typography_outside_inline_code(line)
            body, line_ending = split_line_ending(line)
            result = +""
            cursor = 0

            body.to_enum(:scan, MarkdownLinter::INLINE_CODE_PATTERN).each do
              match = Regexp.last_match
              result << replace_typography_outside_links(body[cursor...match.begin(0)])
              result << match[0]
              cursor = match.end(0)
            end
            result << replace_typography_outside_links(body[cursor..] || "")

            result + line_ending
          end

          def replace_typography_outside_links(text)
            result = +""
            cursor = 0

            MarkdownLinter.each_markdown_link(text) do |link|
              result << normalize_typography(text[cursor...link[:start]])
              link_text = normalize_typography(link[:link_text])
              result << "[#{link_text}](#{link[:destination]})"
              cursor = link[:end_exclusive]
            end
            result << normalize_typography(text[cursor..] || "")

            result
          end

          def normalize_typography(text)
            normalized = text.gsub(MarkdownLinter::EM_DASH, "--")
            SMART_QUOTE_REPLACEMENTS.each do |source, target|
              normalized = normalized.gsub(source, target)
            end
            normalized
          end

          def trim_trailing_whitespace(line)
            body, line_ending = split_line_ending(line)
            body.sub(/[ \t]+\z/, "") + line_ending
          end

          def split_line_ending(line)
            if line.end_with?("\r\n")
              [line[0...-2], "\r\n"]
            elsif line.end_with?("\n")
              [line[0...-1], "\n"]
            else
              [line, ""]
            end
          end

          def blank_line?(line)
            line.nil? || line.strip.empty?
          end

          def ensure_blank_line_before(lines, reference_line)
            return if lines.empty? || blank_line?(lines.last)

            lines << blank_line_for(reference_line)
          end

          def ensure_blank_line_after(lines, reference_line)
            return if lines.empty? || blank_line?(lines.last)

            lines << blank_line_for(reference_line)
          end

          def blank_line_for(reference_line)
            reference_line&.end_with?("\r\n") ? "\r\n" : "\n"
          end

          def ensure_trailing_newline(content)
            return content if content.empty? || content.end_with?("\n")

            "#{content}\n"
          end
        end
      end
    end
  end
end
