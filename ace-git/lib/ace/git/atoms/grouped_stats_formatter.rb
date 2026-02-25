# frozen_string_literal: true

module Ace
  module Git
    module Atoms
      # Render grouped numstat data to aligned plain text or markdown.
      module GroupedStatsFormatter
        class << self
          def format(grouped_data, markdown: false, collapse_above: 5)
            groups = grouped_data[:groups] || []
            total = grouped_data[:total] || { additions: 0, deletions: 0, files: 0 }
            return "" if total[:files].to_i.zero?

            markdown ? format_markdown(groups, total, collapse_above) : format_plain(groups, total)
          end

          private

          def format_plain(groups, total)
            lines = []
            lines << total_line(total)
            lines << ""

            groups.each do |group|
              lines.concat(render_group_plain(group))
              lines << ""
            end

            trim_trailing_blank(lines).join("\n")
          end

          def format_markdown(groups, total, collapse_above)
            lines = []
            lines << "```text"
            lines << total_line(total)
            lines << "```"
            lines << ""

            groups.each do |group|
              if group[:file_count] > collapse_above
                lines << "<details>"
                lines << "<summary>#{group[:name]} (#{inline_totals(group)}) - #{group[:file_count]} files</summary>"
                lines << ""
                lines << "```text"
                render_group_plain(group).each { |line| lines << line }
                lines << "```"
                lines << "</details>"
              else
                lines << "```text"
                render_group_plain(group).each { |line| lines << line }
                lines << "```"
              end
              lines << ""
            end

            trim_trailing_blank(lines).join("\n")
          end

          def render_group_plain(group)
            lines = []
            lines << "#{stats_block(group[:additions], group[:deletions])}   #{group[:file_count]} files   #{group[:name]}"
            lines << ""

            Array(group[:layers]).each do |layer|
              lines << "#{stats_block(layer[:additions], layer[:deletions])}   #{layer[:file_count]} files   #{layer[:name]}"
              Array(layer[:files]).each do |file|
                lines << "#{stats_block(file[:additions], file[:deletions], binary: file[:binary])}     #{file_line(file)}"
              end
              lines << ""
            end

            trim_trailing_blank(lines)
          end

          def total_line(total)
            "#{stats_block(total[:additions], total[:deletions])}   #{total[:files]} files   total"
          end

          def file_line(file)
            suffix = file[:binary] ? " (binary)" : ""
            "#{file[:display_path]}#{suffix}"
          end

          def stats_block(additions, deletions, binary: false)
            return " " * 10 if binary

            plus = stat_label(additions, "+")
            minus = stat_label(deletions, "-")
            Kernel.format("%4s, %4s", plus.to_s, minus.to_s)
          end

          def stat_label(value, prefix)
            return nil if value.nil?

            "#{prefix}#{value}"
          end

          def inline_totals(group)
            add = group[:additions].to_i.positive? ? "+#{group[:additions]}" : "+0"
            del = group[:deletions].to_i.positive? ? "-#{group[:deletions]}" : "-0"
            "#{add}, #{del}"
          end

          def trim_trailing_blank(lines)
            lines.pop while lines.last == ""
            lines
          end
        end
      end
    end
  end
end
