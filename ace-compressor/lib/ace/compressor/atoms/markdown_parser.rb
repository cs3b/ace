# frozen_string_literal: true

module Ace
  module Compressor
    module Atoms
      class MarkdownParser
        HEADING_RE = /\A(#+)\s+(.+)\z/
        BULLET_LIST_RE = /\A(?:\s*)[-*+]\s+(.+)\z/
        NUMBERED_LIST_RE = /\A(?:\s*)\d+\.\s+(.+)\z/
        IMAGE_ONLY_RE = /\A!\[[^\]]*\]\([^)]+\)\z/
        TABLE_SEPARATOR_RE = /\A\|?[-\s:|]+\|?\z/
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

            if layout_separator?(stripped)
              flush_paragraph(blocks, paragraph_lines)
              index += 1
              next
            end

            if blockquote_marker?(stripped)
              flush_paragraph(blocks, paragraph_lines)
              index += 1
              next
            end

            if stripped.match?(FENCE_START_RE)
              flush_paragraph(blocks, paragraph_lines)
              language = stripped.sub(FENCE_START_RE, "").strip
              fence_lines = []
              index += 1
              while index < lines.length
                candidate = lines[index]
                break if candidate.strip.match?(FENCE_START_RE)

                fence_lines << candidate
                index += 1
              end
              index += 1 if index < lines.length && lines[index]&.strip&.match?(FENCE_START_RE)
              blocks << {
                type: :fenced_code,
                language: language,
                content: fence_lines.join
              }
              next
            end

            if image_only_line?(stripped)
              flush_paragraph(blocks, paragraph_lines)
              blocks << {
                type: :unresolved,
                text: stripped,
                kind: "image-only"
              }
              index += 1
              next
            end

            if table_start?(lines, index)
              flush_paragraph(blocks, paragraph_lines)
              table_rows = []
              while index < lines.length
                candidate = lines[index]
                break if candidate.strip.empty?
                break unless candidate.include?("|")

                table_rows << candidate.strip
                index += 1
              end
              blocks << {type: :table, rows: table_rows}
              next
            end

            if list_start?(stripped)
              flush_paragraph(blocks, paragraph_lines)
              list_items = []
              ordered = false
              while index < lines.length
                item_line = lines[index].strip
                break unless list_start?(item_line)

                ordered = true if ordered_list_line?(item_line)
                list_items << strip_list_marker(item_line)
                index += 1
              end
              blocks << {
                type: :list,
                ordered: ordered,
                items: list_items
              }
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
          return text unless text.start_with?("---\n", "---\r\n")

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

          blocks << {type: :text, text: lines.join(" ")}
          lines.clear
        end

        def layout_separator?(line)
          line.match?(/\A(?:[-*_]){3,}\z/)
        end

        def image_only_line?(line)
          line.match?(IMAGE_ONLY_RE)
        end

        def blockquote_marker?(line)
          line.match?(/^>+$/)
        end

        def list_start?(line)
          line.match?(BULLET_LIST_RE) || line.match?(NUMBERED_LIST_RE)
        end

        def ordered_list_line?(line)
          line.match?(NUMBERED_LIST_RE)
        end

        def strip_list_marker(line)
          line.sub(BULLET_LIST_RE, "\\1").sub(NUMBERED_LIST_RE, "\\1").strip
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
