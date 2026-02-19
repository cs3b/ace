# frozen_string_literal: true

module Ace
  module Overseer
    module Atoms
      module StatusFormatter
        COL_TASK = 8
        COL_STATE = 3
        COL_PROGRESS = 17
        COL_PR = 10
        COL_GIT = 6
        COL_ASSIGN = 10

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
          if contexts.empty?
            return "No active assignments."
          end

          rows = []
          rows << format_header
          rows << "\u2500" * (COL_TASK + COL_STATE + COL_PROGRESS + COL_PR + COL_GIT + COL_ASSIGN + 5) # 6 cols, 5 spaces
          sorted = sort_contexts(contexts)
          sorted.each { |context| rows << format_row(context) }
          rows.join("\n")
        end

        def self.format_row(context)
          location_type = context.respond_to?(:location_type) ? context.location_type : :worktree
          task_display = location_type == :main ? colorize("main".ljust(COL_TASK), :dim) : context.task_id.ljust(COL_TASK)

          # State, PR, Git, Assign are pre-padded to avoid ANSI code length issues
          # Order: Assign, Task, State, PR, Git, Progress
          format(
            "%s %s %s %s %s %-#{COL_PROGRESS}s",
            colorized_assign(context),
            task_display,
            colorized_state(context),
            colorized_pr(context),
            colorized_git(context),
            truncate(progress(context), COL_PROGRESS)
          )
        end

        def self.format_header
          format(
            "%-#{COL_ASSIGN}s %-#{COL_TASK}s %-#{COL_STATE}s %-#{COL_PR}s %-#{COL_GIT}s %-#{COL_PROGRESS}s",
            "Assign", "Task", "\u2B24", "PR", "Git", "Progress"
          )
        end
        private_class_method :format_header

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

        def self.assignment_state(context)
          data = context.assignment_status
          return "none" unless data.is_a?(Hash)

          data.dig("assignment", "state") || data.dig(:assignment, :state) ||
            data["state"] || data[:state] || "unknown"
        end
        private_class_method :assignment_state

        def self.colorized_state(context)
          state = assignment_state(context)
          display = STATE_DISPLAY[state] || STATE_DISPLAY["none"]
          # Pad visible text before colorizing so format width works correctly
          padded = display[:icon].to_s.ljust(COL_STATE)
          colorize(padded, display[:color])
        end
        private_class_method :colorized_state

        def self.progress(context)
          data = context.assignment_status
          return "-" unless data.is_a?(Hash)

          summary = data["phase_summary"] || data[:phase_summary]
          return "-" unless summary.is_a?(Hash)

          total = summary["total"] || summary[:total]
          done = summary["done"] || summary[:done]
          return "-" unless total && done

          failed = (summary["failed"] || summary[:failed]).to_i
          base = "#{done}/#{total}"
          failed.positive? ? "#{base} (#{failed} failed)" : base
        end
        private_class_method :progress

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
          # Pad visible text before colorizing so format width works correctly
          padded = text.ljust(COL_GIT)
          colorize(padded, color)
        end
        private_class_method :colorized_git

        def self.assignment_id(context)
          data = context.assignment_status
          return nil unless data.is_a?(Hash)

          data.dig("assignment", "id") || data.dig(:assignment, :id)
        end
        private_class_method :assignment_id

        def self.colorized_assign(context)
          id = assignment_id(context)
          base = id || "-"
          count = context.respond_to?(:assignment_count) ? context.assignment_count : 0
          text = count > 1 ? "#{base} (#{count})" : base
          colorize(text.ljust(COL_ASSIGN), :dim)
        end
        private_class_method :colorized_assign

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
