# frozen_string_literal: true

module Ace
  module Overseer
    module Atoms
      module StatusFormatter
        # Location header columns
        COL_LOCATION = 15
        COL_PR = 10
        COL_GIT = 6

        # Assignment sub-row columns
        COL_ASSIGN_ID = 8
        COL_ASSIGN_NAME = 25
        COL_STATE = 3
        COL_PROGRESS = 30
        PROGRESS_BAR_WIDTH = 10

        # ANSI color helpers
        COLOR = {
          green: "\e[32m",
          red: "\e[31m",
          blue: "\e[34m",
          yellow: "\e[33m",
          dim: "\e[2m",
          reset: "\e[0m"
        }.freeze

        # Assignment state icons
        STATE_DISPLAY = {
          "completed" => { icon: "\u2713", color: :green },   # ✓
          "running"   => { icon: "\u25B6", color: :blue },    # ►
          "failed"    => { icon: "\u2717", color: :red },     # ✗
          "stalled"   => { icon: "\u25FC", color: :yellow },  # ◼
          "paused"    => { icon: "\u2016", color: :dim },     # ‖
          "none"      => { icon: "-",      color: :dim }
        }.freeze

        # PR state colors
        PR_STATE_COLORS = {
          "OPN" => :green,
          "MRG" => :blue,
          "CLS" => :dim,
          "DFT" => :yellow
        }.freeze

        def self.format_dashboard(contexts)
          return "No active assignments." if contexts.empty?

          rows = []
          rows << format_header
          rows << separator_line
          sorted = sort_contexts(contexts)
          sorted.each_with_index do |context, idx|
            rows << "" if idx > 0
            rows << format_location_row(context)
            context.assignments.each do |assignment|
              rows << format_assignment_row(assignment)
            end
          end
          rows.join("\n")
        end

        def self.format_location_row(context)
          location = if context.location_type == :main
                       colorize("main".ljust(COL_LOCATION), :dim)
                     else
                       File.basename(context.worktree_path).ljust(COL_LOCATION)
                     end

          format(
            "%s %s %s",
            location,
            colorized_pr(context),
            colorized_git(context)
          )
        end

        def self.format_assignment_row(assignment)
          id = assignment.dig("assignment", "id") || "-"
          name = assignment.dig("assignment", "name") || "-"
          state_str = assignment.dig("assignment", "state") || "none"
          display = STATE_DISPLAY[state_str] || STATE_DISPLAY["none"]

          state_icon = colorize(display[:icon].to_s.ljust(COL_STATE), display[:color])
          progress_str = format_progress(assignment)

          format(
            "  %-#{COL_ASSIGN_ID}s %-#{COL_ASSIGN_NAME}s %s %-#{COL_PROGRESS}s",
            id,
            truncate(name, COL_ASSIGN_NAME),
            state_icon,
            progress_str
          )
        end

        def self.sort_contexts(contexts)
          contexts.sort_by do |ctx|
            location_type = ctx.respond_to?(:location_type) ? ctx.location_type : :worktree
            main_sort = location_type == :main ? 1 : 0
            pr_num = extract_pr_number(ctx)
            pr_sort = pr_num ? [1, -pr_num] : [0, -(ctx.task_id.to_f)]
            [main_sort] + pr_sort
          end
        end
        private_class_method :sort_contexts

        def self.extract_pr_number(context)
          data = context.git_status
          return nil unless data.is_a?(Hash)

          pr = data[:pr_metadata] || data["pr_metadata"]
          return nil unless pr.is_a?(Hash)

          pr["number"] || pr[:number]
        end
        private_class_method :extract_pr_number

        def self.format_progress(assignment)
          summary = assignment["step_summary"] || assignment[:step_summary]
          return "-" unless summary.is_a?(Hash)

          total = summary["total"] || summary[:total]
          done = summary["done"] || summary[:done]
          return "-" unless total && done

          failed = (summary["failed"] || summary[:failed]).to_i
          bar = progress_bar(done.to_i, total.to_i)
          counts = "#{done}/#{total}"
          counts = "#{counts} (#{failed} failed)" if failed.positive?
          current = assignment["current_step"] || assignment[:current_step]
          parts = "#{bar} #{counts}"
          parts = "#{parts} #{colorize(current, :dim)}" if current
          parts
        end
        private_class_method :format_progress

        def self.progress_bar(done, total)
          return "[\u2500" * PROGRESS_BAR_WIDTH + "]" if total.zero?

          filled = (done.to_f / total * PROGRESS_BAR_WIDTH).round
          empty = PROGRESS_BAR_WIDTH - filled
          colorize("\u2588" * filled, :green) + colorize("\u2500" * empty, :dim) + ""
        end
        private_class_method :progress_bar

        def self.pr_info_parts(context)
          data = context.git_status
          return nil unless data.is_a?(Hash)

          pr = data[:pr_metadata] || data["pr_metadata"]
          return nil unless pr.is_a?(Hash)

          number = pr["number"] || pr[:number]
          return nil unless number

          state = if pr["isDraft"] || pr[:isDraft]
                    "DFT"
                  else
                    case (pr["state"] || pr[:state]).to_s.upcase
                    when "OPEN" then "OPN"
                    when "MERGED" then "MRG"
                    when "CLOSED" then "CLS"
                    else "?"
                    end
                  end
          [number, state]
        end
        private_class_method :pr_info_parts

        def self.colorized_pr(context)
          parts = pr_info_parts(context)
          unless parts
            return colorize("-".ljust(COL_PR), :dim)
          end

          number, state = parts
          color = PR_STATE_COLORS[state] || :dim
          text = "##{number} #{state}".ljust(COL_PR)
          colorize(text, color)
        end
        private_class_method :colorized_pr

        def self.git_state_parts(context)
          data = context.git_status
          return [:unknown, nil] unless data.is_a?(Hash)
          return [:clean, nil] if data["clean"] == true || data[:clean] == true

          dirty = data["dirty_files"] || data[:dirty_files]
          return [:dirty, dirty] if dirty

          [:dirty, nil]
        end
        private_class_method :git_state_parts

        def self.colorized_git(context)
          state, count = git_state_parts(context)
          color = case state
                  when :clean then :green
                  when :dirty then :yellow
                  else :dim
                  end
          text = case state
                 when :clean
                   "\u2713"
                 when :dirty
                   count ? "\u2717 #{count}" : "\u2717"
                 else
                   "?"
                 end
          padded = text.ljust(COL_GIT)
          colorize(padded, color)
        end
        private_class_method :colorized_git

        def self.format_header
          format("  %-#{COL_ASSIGN_ID}s %-#{COL_ASSIGN_NAME}s %-#{COL_STATE}s %-#{COL_PROGRESS}s",
                 "ID", "Name", "\u2B24", "Progress")
        end
        private_class_method :format_header

        def self.separator_line
          "\u2500" * (2 + COL_ASSIGN_ID + 1 + COL_ASSIGN_NAME + 1 + COL_STATE + 1 + COL_PROGRESS)
        end
        private_class_method :separator_line

        def self.format_watch_footer(next_full_refresh_secs)
          now = Time.now.strftime("%H:%M:%S")
          mins, secs = next_full_refresh_secs.divmod(60)
          remaining = mins > 0 ? "#{mins}m #{secs}s" : "#{secs}s"
          colorize("Updated: #{now} \u00B7 full refresh in #{remaining}", :dim)
        end

        def self.colorize(text, color)
          "#{COLOR[color]}#{text}#{COLOR[:reset]}"
        end
        private_class_method :colorize

        def self.truncate(value, max)
          str = value.to_s
          return str if str.length <= max

          str[0..max - 4] + "..."
        end
        private_class_method :truncate
      end
    end
  end
end
