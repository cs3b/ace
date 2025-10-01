# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Pure logic for parsing tasks command arguments
      # Unit testable - no I/O
      class TasksArgParser
        # Parse additional filters from command line arguments
        # @param args [Array<String>] Command line arguments
        # @return [Hash] Parsed filters
        def self.parse_filters(args)
          filters = {}

          i = 0
          while i < args.length
            arg = args[i]
            case arg
            when "--status"
              filters[:status] = parse_csv_value(args, i + 1)
              i += 2
            when "--priority"
              filters[:priority] = parse_csv_value(args, i + 1)
              i += 2
            when "--days"
              filters[:days] = parse_int_value(args, i + 1)
              i += 2
            when "--limit"
              filters[:limit] = parse_int_value(args, i + 1)
              i += 2
            when "--stats"
              filters[:stats] = true
              i += 1
            when "--tree"
              filters[:tree] = true
              i += 1
            when "--path"
              filters[:path] = true
              i += 1
            when "--list"
              filters[:list] = true
              i += 1
            when "--backlog"
              filters[:context] = "backlog"
              i += 1
            when "--release"
              filters[:context] = parse_string_value(args, i + 1)
              i += 2
            when "--recent"
              filters[:_preset_override] = "recent"
              i += 1
            when "--sort"
              filters[:sort] = parse_sort_spec(args, i + 1)
              i += 2
            else
              i += 1
            end
          end

          filters
        end

        # Parse reschedule arguments
        # @param args [Array<String>] Command line arguments
        # @return [Hash] Parsed reschedule options with :tasks and :options
        def self.parse_reschedule_args(args)
          tasks_to_reschedule = []
          options = { strategy: nil }

          i = 0
          while i < args.length
            arg = args[i]
            case arg
            when "--add-next"
              options[:strategy] = :add_next
              i += 1
            when "--add-at-end"
              options[:strategy] = :add_at_end
              i += 1
            when "--after"
              options[:strategy] = :after
              options[:reference_task] = parse_string_value(args, i + 1)
              i += 2
            when "--before"
              options[:strategy] = :before
              options[:reference_task] = parse_string_value(args, i + 1)
              i += 2
            else
              # This is a task identifier
              tasks_to_reschedule << arg unless arg.start_with?('-')
              i += 1
            end
          end

          { tasks: tasks_to_reschedule, options: options }
        end

        private

        def self.parse_csv_value(args, index)
          return nil if index >= args.length
          args[index].split(',')
        end

        def self.parse_int_value(args, index)
          return nil if index >= args.length
          args[index].to_i
        end

        def self.parse_string_value(args, index)
          return nil if index >= args.length
          args[index]
        end

        def self.parse_sort_spec(args, index)
          sort_spec = parse_string_value(args, index)
          return nil unless sort_spec

          if sort_spec.include?(':')
            field, direction = sort_spec.split(':')
            { by: field.to_sym, ascending: direction == 'asc' }
          else
            { by: sort_spec.to_sym, ascending: true }
          end
        end
      end
    end
  end
end
