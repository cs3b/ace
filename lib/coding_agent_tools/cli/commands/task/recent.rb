# frozen_string_literal: true

require 'dry/cli'
require_relative '../../../organisms/taskflow_management/task_manager'
require_relative '../../../atoms/project_root_detector'
require_relative '../../../molecules/taskflow_management/unified_task_formatter'
require_relative '../../../molecules/taskflow_management/task_status_summary'

module CodingAgentTools
  module Cli
    module Commands
      module Task
        # Recent command for finding recently modified tasks
        class Recent < Dry::CLI::Command
          desc 'Find recently modified tasks'

          option :last, type: :string,
            desc: "Time period to search (e.g., '2.days', '1.week', '3.hours'). Default: 1.day when no --limit specified"

          option :limit, type: :integer, default: 10,
            desc: 'Maximum number of tasks to return (default: 10)'

          option :verbose, type: :boolean, default: false,
            desc: 'Show detailed task information'

          option :debug, type: :boolean, default: false, aliases: ['d'],
            desc: 'Enable debug output for verbose error information'

          option :release, type: :string,
            desc: 'Release to work with (version, codename, fullname, or path). Note: Recent command searches across all releases by default.'

          example [
            '',
            '--last 2.days',
            '--last 1.week --limit 5',
            '--limit 3',
            '--debug'
          ]

          def call(**options)
            # Check if user explicitly provided --limit (not just default)
            explicit_limit = ARGV.any? { |arg| arg.start_with?('--limit') }

            limit = validate_limit(options[:limit]) if options[:limit]
            limit ||= options[:limit] || 10

            # Determine time filtering behavior:
            # - If --last is specified: use that time filter
            # - If --last not specified and --limit explicitly specified: no time filter (get most recent X)
            # - If neither specified: default to 1 day filter
            since_seconds = if options[:last]
              parse_time_period(options[:last])
            elsif explicit_limit
              nil # No time filter when --limit explicitly specified
            else
              parse_time_period('1.day') # Default behavior
            end

            # Use ProjectRootDetector for reliable path resolution
            project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
            task_manager = CodingAgentTools::Organisms::TaskflowManagement::TaskManager.new(base_path: project_root)

            # Get all tasks from current release for status summary
            all_tasks_result = task_manager.get_list_tasks(release_path: options[:release])
            status_summary = if all_tasks_result.success?
              CodingAgentTools::Molecules::TaskflowManagement::TaskStatusSummary.generate_summary(all_tasks_result.tasks)
            else
              CodingAgentTools::Molecules::TaskflowManagement::TaskStatusSummary.generate_summary([])
            end

            result = task_manager.find_recent_tasks(
              since_seconds: since_seconds,
              statuses: ['done', 'in-progress', 'pending', 'blocked'],
              release_path: options[:release]
            )

            handle_result(result, options.merge(limit: limit), status_summary)
            0
          rescue => e
            handle_error(e, options[:debug])
            1
          end

          private

          def validate_limit(limit)
            limit_int = limit.to_i
            raise ArgumentError, "Limit must be a positive integer, got: #{limit}" unless limit_int.positive?

            limit_int
          end

          def parse_time_period(period_str)
            # Parse time periods like "2.days", "1.week", "3.hours"
            case period_str
            when /^(\d+)\.day(s)?$/
              ::Regexp.last_match(1).to_i * 24 * 60 * 60
            when /^(\d+)\.week(s)?$/
              ::Regexp.last_match(1).to_i * 7 * 24 * 60 * 60
            when /^(\d+)\.hour(s)?$/
              ::Regexp.last_match(1).to_i * 60 * 60
            when /^(\d+)\.minute(s)?$/
              ::Regexp.last_match(1).to_i * 60
            else
              # Default to 1 day
              24 * 60 * 60
            end
          end

          def handle_result(result, options, status_summary = nil)
            unless result.success?
              error_output("Error: #{result.message}")
              return
            end

            if result.tasks.empty?
              puts status_summary.formatted_text if status_summary
              puts 'No recent tasks found'
              return
            end

            # Limit results
            limited_tasks = result.tasks.take(options[:limit])

            # Show status summary first
            puts status_summary.formatted_text if status_summary

            puts "Recent Tasks (#{limited_tasks.size}/#{result.count} shown):"
            puts '=' * 50

            limited_tasks.each_with_index do |task, index|
              puts '' if index > 0 && options[:verbose] # Add blank line between tasks in verbose mode
              Molecules::TaskflowManagement::UnifiedTaskFormatter.format_task(
                task,
                verbose: options[:verbose],
                show_time: true,
                show_path: !options[:verbose] # Show path in compact mode
              )
            end
          end

          def handle_error(error, debug_enabled)
            if debug_enabled
              error_output("Error: #{error.class.name}: #{error.message}")
              error_output("\nBacktrace:")
              error.backtrace.each { |line| error_output("  #{line}") }
            else
              error_output("Error: #{error.message}")
              error_output('Use --debug flag for more information')
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
