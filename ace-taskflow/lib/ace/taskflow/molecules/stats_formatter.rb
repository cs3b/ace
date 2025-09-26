# frozen_string_literal: true

require_relative "../organisms/task_manager"
require_relative "../molecules/idea_loader"
require_relative "../molecules/release_resolver"

module Ace
  module Taskflow
    module Molecules
      # Format statistics headers for list outputs
      class StatsFormatter
        TASK_STATUS_ORDER = ["draft", "pending", "in-progress", "done", "blocked", "skipped"]
        TASK_STATUS_ICONS = {
          "draft" => "⚫",
          "pending" => "⚪",
          "in-progress" => "🟡",
          "done" => "🟢",
          "blocked" => "🔴",
          "skipped" => "🔴",
          "unknown" => "❓"
        }.freeze

        IDEA_STATUS_ORDER = ["new", "refined", "in-progress", "converted"]
        IDEA_STATUS_ICONS = {
          "new" => "💡",
          "refined" => "🔄",
          "in-progress" => "🔄",
          "converted" => "✅",
          "unknown" => "❓"
        }.freeze

        def initialize(root_path = nil)
          @root_path = root_path || Molecules::ConfigLoader.find_root
          @task_manager = Organisms::TaskManager.new
          @idea_loader = Molecules::IdeaLoader.new(@root_path)
          @release_resolver = Molecules::ReleaseResolver.new(@root_path)
        end

        # Generate three-line header for list outputs
        # @param command_type [Symbol] :tasks or :ideas
        # @param displayed_count [Integer] Number of items being displayed
        # @param context [String] Current context (for release identification)
        # @return [String] Formatted three-line header
        def format_header(command_type:, displayed_count: 0, context: "current")
          # Get release information
          release_info = get_release_info(context)
          return minimal_header(command_type, displayed_count) unless release_info

          # Get global statistics (unfiltered)
          task_stats = @task_manager.get_statistics(context: release_info[:context])
          idea_stats = get_idea_statistics(release_info[:path])

          lines = []

          # Line 1: Context line
          lines << format_context_line(command_type, displayed_count,
                                       command_type == :tasks ? task_stats[:total] : idea_stats[:total],
                                       release_info)

          # Line 2: Ideas status
          lines << format_ideas_line(idea_stats)

          # Line 3: Tasks status
          lines << format_tasks_line(task_stats)

          # Separator
          lines << "=" * 40

          lines.join("\n")
        end

        # Format statistics-only view (expanded)
        # @param context [String] Context for statistics
        # @return [String] Formatted detailed statistics
        def format_stats_view(context: "current")
          release_info = get_release_info(context)
          return "No release found for context: #{context}" unless release_info

          task_stats = @task_manager.get_statistics(context: release_info[:context])
          idea_stats = get_idea_statistics(release_info[:path])

          lines = []
          lines << "Release Statistics: #{release_info[:name]}"
          lines << "#{release_info[:codename]}" if release_info[:codename]
          lines << "=" * 50
          lines << ""

          # Ideas section
          lines << "Ideas: #{idea_stats[:total]} total"
          idea_stats[:by_status].each do |status, count|
            icon = IDEA_STATUS_ICONS[status] || IDEA_STATUS_ICONS["unknown"]
            percentage = idea_stats[:total] > 0 ? (count.to_f / idea_stats[:total] * 100).round : 0
            lines << "  #{icon} #{status.capitalize}: #{count} (#{percentage}%)"
          end
          lines << ""

          # Tasks section
          lines << "Tasks: #{task_stats[:total]} total"
          completion_rate = calculate_completion_rate(task_stats)
          lines << "Completion: #{completion_rate}%"
          lines << ""

          TASK_STATUS_ORDER.each do |status|
            count = task_stats[:by_status][status] || 0
            next if count == 0

            icon = TASK_STATUS_ICONS[status] || TASK_STATUS_ICONS["unknown"]
            percentage = task_stats[:total] > 0 ? (count.to_f / task_stats[:total] * 100).round : 0
            lines << "  #{icon} #{status.capitalize}: #{count} (#{percentage}%)"
          end

          # Unknown statuses
          unknown_count = task_stats[:by_status].reject { |s, _| TASK_STATUS_ORDER.include?(s) }.values.sum
          if unknown_count > 0
            lines << "  ❓ Unknown: #{unknown_count}"
          end

          lines.join("\n")
        end

        private

        def get_release_info(context)
          # Resolve context to release
          release = case context
                   when "current", "active"
                     @release_resolver.find_primary_active
                   when "backlog"
                     { name: "Backlog", path: File.join(@root_path, "backlog"), context: "backlog" }
                   when "all"
                     { name: "All Releases", path: @root_path, context: "all" }
                   else
                     @release_resolver.find_release(context)
                   end

          return nil unless release

          # Extract codename from release name if present
          if release[:name] && release[:name].match(/^v\.\d+\.\d+\.\d+/)
            # Try to find a codename file or extract from directory name
            codename = extract_codename(release[:name])
            release[:codename] = codename if codename
          end

          # Ensure context is set
          release[:context] ||= release[:name]

          release
        end

        def extract_codename(release_name)
          # For now, return a placeholder - this could be enhanced to read from metadata
          case release_name
          when /v\.0\.9\.0/
            '"Neptune" Release'
          else
            nil
          end
        end

        def get_idea_statistics(release_path)
          # Extract release name from path for context
          release_name = File.basename(release_path)
          context = if release_name == "backlog"
                     "backlog"
                   elsif release_name.match(/^v\.\d+\.\d+\.\d+/)
                     release_name
                   else
                     "current"
                   end

          ideas = @idea_loader.load_all(context: context, include_content: false)

          stats = {
            total: ideas.size,
            by_status: {}
          }

          ideas.each do |idea|
            status = idea[:status] || "new"
            stats[:by_status][status] ||= 0
            stats[:by_status][status] += 1
          end

          stats
        end

        def format_context_line(command_type, displayed_count, total_count, release_info)
          item_type = command_type == :tasks ? "tasks" : "ideas"
          release_desc = release_info[:codename] || ""

          if displayed_count < total_count
            "#{release_info[:name]}: #{displayed_count}/#{total_count} #{item_type} • #{release_desc}".strip.gsub(/\s+•\s*$/, '')
          else
            "#{release_info[:name]}: #{total_count} #{item_type} • #{release_desc}".strip.gsub(/\s+•\s*$/, '')
          end
        end

        def format_ideas_line(idea_stats)
          parts = []

          IDEA_STATUS_ORDER.each do |status|
            count = idea_stats[:by_status][status] || 0
            next if count == 0

            icon = IDEA_STATUS_ICONS[status] || IDEA_STATUS_ICONS["unknown"]
            parts << "#{icon} #{count}"
          end

          # Add unknown statuses
          unknown_count = idea_stats[:by_status].reject { |s, _| IDEA_STATUS_ORDER.include?(s) }.values.sum
          parts << "❓ #{unknown_count}" if unknown_count > 0

          "Ideas: #{parts.join(' | ')} • #{idea_stats[:total]} total"
        end

        def format_tasks_line(task_stats)
          parts = []

          TASK_STATUS_ORDER.each do |status|
            count = task_stats[:by_status][status] || 0
            icon = TASK_STATUS_ICONS[status] || TASK_STATUS_ICONS["unknown"]
            parts << "#{icon} #{count}"
          end

          # Add unknown statuses
          unknown_count = task_stats[:by_status].reject { |s, _| TASK_STATUS_ORDER.include?(s) }.values.sum
          parts << "❓ #{unknown_count}" if unknown_count > 0

          completion_rate = calculate_completion_rate(task_stats)

          "Tasks: #{parts.join(' | ')} • #{task_stats[:total]} total • #{completion_rate}% complete"
        end

        def calculate_completion_rate(task_stats)
          return 0 if task_stats[:total] == 0

          done_count = task_stats[:by_status]["done"] || 0
          (done_count.to_f / task_stats[:total] * 100).round
        end

        def minimal_header(command_type, displayed_count)
          item_type = command_type == :tasks ? "tasks" : "ideas"
          lines = []
          lines << "#{displayed_count} #{item_type}"
          lines << "=" * 40
          lines.join("\n")
        end
      end
    end
  end
end