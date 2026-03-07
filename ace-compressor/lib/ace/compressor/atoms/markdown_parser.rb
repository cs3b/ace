# frozen_string_literal: true

module Ace
  module Compressor
    module Atoms
      class MarkdownParser
        HEADING_RE = /\A(#+)\s+(.+)\z/
        IMAGE_ONLY_RE = /\A!\[[^\]]*\]\([^)]+\)\z/
        TABLE_SEPARATOR_RE = /\A\|?[\-\s:|]+\|?\z/
        FENCE_START_RE = /\A```/

        def call(text)
          body = strip_frontmatter(text.to_s)
          return [] if body.strip.empty?

          blocks = []
          paragraph_lines = []
          lines = body.lines
          index = 0
          while index < lines.length
            stripped = lines[index].strip

            if stripped.empty?
              flush_paragraph(blocks, paragraph_lines)
              index += 1
              next
            end

            if stripped.match?(FENCE_START_RE)
              flush_paragraph(blocks, paragraph_lines)
              fallback_lines = [stripped]
              index += 1
              while index < lines.length
                candidate = lines[index].strip
                fallback_lines << candidate
                index += 1
                break if candidate.match?(FENCE_START_RE)
              end
              blocks << {
                type: :fallback,
                text: "kind=fenced-code|raw=#{fallback_lines.join(' ')}"
              }
              next
            end

            if image_only_line?(stripped)
              flush_paragraph(blocks, paragraph_lines)
              blocks << {
                type: :unresolved,
                text: "kind=image-only|raw=#{stripped}"
              }
              index += 1
              next
            end

            if table_start?(lines, index)
              flush_paragraph(blocks, paragraph_lines)
              table_lines = [stripped]
              index += 1
              while index < lines.length
                candidate = lines[index].strip
                break if candidate.empty? || !candidate.include?("|")

                table_lines << candidate
                index += 1
              end
              blocks << { type: :table, text: table_lines.join(" ||ROW|| ") }
              next
            end

            heading_match = stripped.match(HEADING_RE)
            if heading_match && heading_match[1].length <= 6
              flush_paragraph(blocks, paragraph_lines)
              blocks << {
                type: :heading,
                level: heading_match[1].length,
                text: heading_match[2].strip
              }
            else
              paragraph_lines << stripped
            end

            index += 1
          end

          flush_paragraph(blocks, paragraph_lines)
          blocks
        end

        private

        def strip_frontmatter(text)
          return text unless text.start_with?("---\n") || text.start_with?("---\r\n")

          lines = text.lines
          end_index = nil

          lines[1..].each_with_index do |line, idx|
            if line.strip == "---"
              end_index = idx + 1
              break
            end
          end

          return text if end_index.nil?

          lines[(end_index + 1)..]&.join.to_s
        end

        def flush_paragraph(blocks, lines)
          return if lines.empty?

          blocks << { type: :text, text: lines.join(" ") }
          lines.clear
        end

        def image_only_line?(line)
          line.match?(IMAGE_ONLY_RE)
        end

        def table_start?(lines, index)
          current = lines[index]&.strip.to_s
          next_line = lines[index + 1]&.strip.to_s
          return false unless current.include?("|")

          next_line.match?(TABLE_SEPARATOR_RE)
        end
      end
    end
  end
end
