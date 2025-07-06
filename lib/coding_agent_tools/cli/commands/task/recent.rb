# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/task_management/task_manager"

module CodingAgentTools
  module Cli
    module Commands
      module Task
        # Recent command for finding recently modified tasks
        class Recent < Dry::CLI::Command
          desc "Find recently modified tasks"

          option :last, type: :string, default: "1.day",
            desc: "Time period to search (e.g., '2.days', '1.week', '3.hours')"

          option :limit, type: :integer, default: 10,
            desc: "Maximum number of tasks to return (default: 10)"

          option :debug, type: :boolean, default: false, aliases: ["d"],
            desc: "Enable debug output for verbose error information"

          example [
            "",
            "--last 2.days",
            "--last 1.week --limit 5",
            "--limit 3",
            "--debug"
          ]

          def call(**options)
            limit = validate_limit(options[:limit]) if options[:limit]
            limit ||= options[:limit] || 10
            
            since_seconds = parse_time_period(options[:last])
            # Use parent directory as base path when in dev-tools
            base_path = Dir.pwd.end_with?("dev-tools") ? ".." : "."
            task_manager = CodingAgentTools::Organisms::TaskManagement::TaskManager.new(base_path: base_path)

            result = task_manager.find_recent_tasks(
              since_seconds: since_seconds,
              statuses: %w[done in-progress pending blocked]
            )

            handle_result(result, options.merge(limit: limit))
            0
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def validate_limit(limit)
            limit_int = limit.to_i
            unless limit_int.positive?
              raise ArgumentError, "Limit must be a positive integer, got: #{limit}"
            end
            limit_int
          end

          def parse_time_period(period_str)
            # Parse time periods like "2.days", "1.week", "3.hours"
            case period_str
            when /^(\d+)\.day(s)?$/
              $1.to_i * 24 * 60 * 60
            when /^(\d+)\.week(s)?$/
              $1.to_i * 7 * 24 * 60 * 60
            when /^(\d+)\.hour(s)?$/
              $1.to_i * 60 * 60
            when /^(\d+)\.minute(s)?$/
              $1.to_i * 60
            else
              # Default to 1 day
              24 * 60 * 60
            end
          end

          def handle_result(result, options)
            unless result.success?
              error_output("Error: #{result.message}")
              return
            end

            if result.tasks.empty?
              puts "No recent tasks found"
              return
            end

            # Limit results
            limited_tasks = result.tasks.take(options[:limit])
            
            puts "Recent Tasks (#{limited_tasks.size}/#{result.count} shown):"
            puts "=" * 50

            limited_tasks.each_with_index do |task, index|
              puts "" if index > 0  # Add blank line between tasks
              display_task_info(task)
            end
          end

          def display_task_info(task)
            puts "  ID:    #{task.id}"
            puts "  Title: #{task.title || extract_title_from_content(task)}"
            puts "  Path:  #{task.path}"
            puts "  Status: #{task.status}"
            
            if task.respond_to?(:mtime)
              puts "  Modified: #{format_time(task.mtime)}"
            end
            
            if task.dependencies && !task.dependencies.empty?
              deps = task.dependencies.is_a?(Array) ? task.dependencies.join(", ") : task.dependencies
              puts "  Dependencies: #{deps}"
            end
          end

          def extract_title_from_content(task)
            # Try to extract title from content if not available in metadata
            return "Unknown" unless task.respond_to?(:content) && task.content

            # Look for first heading
            lines = task.content.split("\n")
            heading_line = lines.find { |line| line.start_with?("# ") }
            if heading_line
              heading_line.sub(/^# /, "").strip
            else
              "Unknown"
            end
          end

          def format_time(time)
            now = Time.now
            diff = now - time

            case diff
            when 0..60
              "#{diff.to_i} seconds ago"
            when 60..3600
              "#{(diff / 60).to_i} minutes ago"
            when 3600..86400
              "#{(diff / 3600).to_i} hours ago"
            when 86400..604800
              "#{(diff / 86400).to_i} days ago"
            else
              time.strftime("%Y-%m-%d %H:%M")
            end
          end

          def handle_error(error, debug_enabled)
            if debug_enabled
              error_output("Error: #{error.class.name}: #{error.message}")
              error_output("\nBacktrace:")
              error.backtrace.each { |line| error_output("  #{line}") }
            else
              error_output("Error: #{error.message}")
              error_output("Use --debug flag for more information")
            end
          end

          def error_output(message)
            warn message
          end
        end
      end
    end
  end
end