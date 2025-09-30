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
          @release_resolver = Molecules::ReleaseResolver.new
        end

        # Generate three-line header for list outputs
        # @param command_type [Symbol] :tasks or :ideas
        # @param displayed_count [Integer] Number of items being displayed
        # @param context [String] Current context (for release identification)
        # @param total_count [Integer] Optional override for total count (for filtered views)
        # @return [String] Formatted three-line header
        def format_header(command_type:, displayed_count: 0, context: "current", total_count: nil)
          # Get release information
          release_info = get_release_info(context)
          return minimal_header(command_type, displayed_count) unless release_info

          # Get global statistics (unfiltered)
          task_stats = @task_manager.get_statistics(context: release_info[:context])
          idea_stats = get_idea_statistics(release_info[:path])

          lines = []

          # Use provided total_count or fall back to calculated stats
          actual_total = total_count || (command_type == :tasks ? task_stats[:total] : idea_stats[:total])

          # Line 1: Context line
          lines << format_context_line(command_type, displayed_count,
                                       actual_total,
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
            if status == "blocked"
              # Combine blocked and skipped counts
              count = (task_stats[:by_status]["blocked"] || 0) +
                      (task_stats[:by_status]["skipped"] || 0)
            elsif status == "skipped"
              # Skip since combined with blocked
              next
            else
              count = task_stats[:by_status][status] || 0
            end
            next if count == 0

            icon = TASK_STATUS_ICONS[status] || TASK_STATUS_ICONS["unknown"]
            percentage = task_stats[:total] > 0 ? (count.to_f / task_stats[:total] * 100).round : 0
            display_status = status == "blocked" ? "blocked/skipped" : status
            lines << "  #{icon} #{display_status.capitalize}: #{count} (#{percentage}%)"
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
                     # Try to find release or create a release info from version string
                     found_release = @release_resolver.find_release(context)
                     if found_release
                       found_release
                     elsif context&.match(/^v\.\d+\.\d+\.\d+/)
                       # Create release info from version string
                       {
                         name: context,
                         path: File.join(@root_path, ".ace-taskflow", context),
                         context: context
                       }
                     else
                       nil
                     end
                   end

          return nil unless release

          # Extract codename from release name if present
          if release[:name] && release[:name].match(/^v\.\d+\.\d+\.\d+/)
            # Try to find a codename file or extract from directory name
            codename = extract_codename_from_path(release[:path])
            release[:codename] = codename if codename
          end

          # Ensure context is set
          release[:context] ||= release[:name]

          release
        end

        def extract_codename_from_path(release_path)
          # Read codename from the release's main markdown file
          # Format: first header line of the file (e.g., "# v.0.9.0 Mono-Repo Multiple Gems")
          return nil unless release_path && File.directory?(release_path)

          # Find the main markdown file (usually the only .md file in the release root)
          md_files = Dir.glob(File.join(release_path, "*.md"))
          return nil if md_files.empty?

          # Read the first markdown file found
          main_file = md_files.first
          begin
            content = File.read(main_file)
            # Extract first header (# Header Text)
            if match = content.match(/^#\s+(.+)$/)
              header = match[1]
              # Extract the descriptive part after the version
              # e.g., "v.0.9.0 Mono-Repo Multiple Gems" -> "Mono-Repo Multiple Gems"
              if header.match(/^v\.\d+\.\d+\.\d+\s+(.+)$/)
                $1
              else
                header
              end
            else
              nil
            end
          rescue
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

          # Get ALL ideas including done for accurate stats
          ideas = @idea_loader.load_all(context: context, include_content: false, scope: :all)

          stats = {
            total: ideas.size,
            by_status: {}
          }

          ideas.each do |idea|
            # Determine status based on path
            status = if idea[:path] && idea[:path].include?("/done/")
                      "done"
                     else
                      idea[:status] || "new"
                     end
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

          # Show pending ideas (new) and done ideas
          new_count = idea_stats[:by_status]["new"] || 0
          done_count = idea_stats[:by_status]["done"] || 0

          parts << "💡 #{new_count}" if new_count > 0
          parts << "✅ #{done_count}" if done_count > 0

          # Add other statuses from IDEA_STATUS_ORDER
          IDEA_STATUS_ORDER.each do |status|
            next if status == "new" # Already handled
            count = idea_stats[:by_status][status] || 0
            next if count == 0

            icon = IDEA_STATUS_ICONS[status] || IDEA_STATUS_ICONS["unknown"]
            parts << "#{icon} #{count}"
          end

          # Add unknown statuses
          unknown_statuses = idea_stats[:by_status].reject { |s, _| IDEA_STATUS_ORDER.include?(s) || s == "done" }
          unknown_count = unknown_statuses.values.sum
          parts << "❓ #{unknown_count}" if unknown_count > 0

          "Ideas: #{parts.join(' | ')} • #{idea_stats[:total]} total"
        end

        def format_tasks_line(task_stats)
          parts = []

          TASK_STATUS_ORDER.each do |status|
            if status == "blocked"
              # Combine blocked and skipped counts
              count = (task_stats[:by_status]["blocked"] || 0) +
                      (task_stats[:by_status]["skipped"] || 0)
            elsif status == "skipped"
              # Skip since combined with blocked
              next
            else
              count = task_stats[:by_status][status] || 0
            end
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