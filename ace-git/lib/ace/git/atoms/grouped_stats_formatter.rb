# frozen_string_literal: true

module Ace
  module Git
    module Atoms
      # Render grouped numstat data to aligned plain text or markdown.
      module GroupedStatsFormatter
        LAYER_ICONS = {
          "lib/" => "🧱",
          "test/" => "🧪",
          "handbook/" => "📚"
        }.freeze

        class << self
          def format(grouped_data, markdown: false, collapse_above: 5)
            groups = grouped_data[:groups] || []
            total = grouped_data[:total] || {additions: 0, deletions: 0, files: 0}
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
            lines << header_line(
              additions: group[:additions],
              deletions: group[:deletions],
              file_count: group[:file_count],
              icon: nil,
              label: group[:name]
            )

            Array(group[:layers]).each do |layer|
              unless skip_layer_header?(group, layer)
                icon, label = layer_header_parts(layer[:name], group_name: group[:name])
                lines << header_line(
                  additions: layer[:additions],
                  deletions: layer[:deletions],
                  file_count: layer[:file_count],
                  icon: icon,
                  label: label
                )
              end
              Array(layer[:files]).each_with_index do |file, idx|
                prev_file = layer[:files][idx - 1] if idx > 0
                lines << "#{stats_block(file[:additions], file[:deletions], binary: file[:binary])}#{FILE_INDENT}#{file_line(file, prev_file: prev_file)}"
              end
            end

            trim_trailing_blank(lines)
          end

          def total_line(total)
            "#{stats_block(total[:additions], total[:deletions])}#{files_label(total[:files])}total"
          end

          def file_line(file, prev_file: nil)
            suffix = file[:binary] ? " (binary)" : ""
            path = squashed_path(file[:display_path], prev_file&.dig(:display_path))
            "#{path}#{suffix}"
          end

          def squashed_path(path, prev_path)
            if path.include?(" -> ")
              return compact_rename_path(path) if prev_path.nil? || !prev_path.include?(" -> ")

              return squashed_rename_path(path, prev_path)
            end

            return path unless prev_path

            # Don't compare directory of a rename path — it's not a real filesystem dir
            return path if prev_path.include?(" -> ")

            curr_dir = File.dirname(path)
            prev_dir = File.dirname(prev_path)

            return path if curr_dir == "." || curr_dir != prev_dir

            ".../#{File.basename(path)}"
          end

          # Squash consecutive renames that share from_dir and to_dir.
          # "atoms/old.rb -> atoms/new.rb" becomes "      old.rb ->       new.rb"
          def squashed_rename_path(path, prev_path)
            return path unless prev_path.include?(" -> ")

            from, to = path.split(" -> ", 2)
            prev_from, prev_to = prev_path.split(" -> ", 2)

            from_dir = File.dirname(from)
            to_dir = File.dirname(to)

            return path unless from_dir == File.dirname(prev_from) && to_dir == File.dirname(prev_to)
            return path if from_dir == "." || to_dir == "."

            "#{" " * (from_dir.length + 1)}#{File.basename(from)} -> #{" " * (to_dir.length + 1)}#{File.basename(to)}"
          end

          # Compact shared leading path in a single rename:
          # "a/b/old.rb -> a/b/new.rb" => "a/b/old.rb -> new.rb"
          # "a/b/file -> a/b/_archive/file" => "a/b/file -> _archive/file"
          def compact_rename_path(path)
            from, to = path.split(" -> ", 2)
            return path if from.nil? || to.nil?

            from_segments = from.split("/")
            to_segments = to.split("/")
            common_segments = []

            while !from_segments.empty? && !to_segments.empty? && from_segments.first == to_segments.first
              common_segments << from_segments.shift
              to_segments.shift
            end

            return path if common_segments.empty?

            common_prefix = common_segments.join("/") + "/"
            from_tail = from.delete_prefix(common_prefix)
            to_tail = to.delete_prefix(common_prefix)
            "#{common_prefix}#{from_tail} -> #{to_tail}"
          end

          # Width of a rendered stats block: "%5s, %5s" = 12 chars
          STATS_WIDTH = 12
          # Separator replacing "   N files   " on file lines (= 3 + 2 + 9 = 14 chars)
          FILES_COLUMN_WIDTH = 14
          ICON_COLUMN = 3
          FILE_INDENT = " " * (FILES_COLUMN_WIDTH + ICON_COLUMN)

          def stats_block(additions, deletions, binary: false)
            return " " * STATS_WIDTH if binary

            plus = stat_label(additions, "+")
            minus = stat_label(deletions, "-")
            Kernel.format("%5s, %5s", plus.to_s, minus.to_s)
          end

          # "   NN files   " — always 14 chars (3 + %2d + 9), aligns name column
          def files_label(count)
            Kernel.format("   %2d files   ", count.to_i)
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

          def layer_header_parts(name, group_name:)
            layer = name.to_s
            label = (layer == "other/" && group_name.to_s != "./") ? "" : layer
            [LAYER_ICONS[layer], label]
          end

          def icon_column(icon)
            return " " * ICON_COLUMN if icon.nil?

            "#{icon} "
          end

          def header_line(additions:, deletions:, file_count:, icon:, label:)
            "#{stats_block(additions, deletions)}#{files_label(file_count)}#{icon_column(icon)}#{label}"
          end

          def skip_layer_header?(group, layer)
            group_name = group[:name].to_s
            layer_name = layer[:name].to_s

            return true if group_name == "./" && layer_name == "root/"

            group[:additions].to_i == layer[:additions].to_i &&
              group[:deletions].to_i == layer[:deletions].to_i &&
              group[:file_count].to_i == layer[:file_count].to_i
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
