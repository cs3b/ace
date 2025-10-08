# frozen_string_literal: true

require "optparse"

module Ace
  module Taskflow
    module Molecules
      # Pure logic for parsing task command arguments
      # Unit testable - no I/O
      class TaskArgParser
        # Parse display mode flags from arguments
        # Modifies args array by removing matched flags
        # @param args [Array<String>] Command arguments (modified in place)
        # @return [String] Display mode: "path", "content", "tree", or "formatted"
        def self.parse_display_mode(args)
          if index = args.index("--path")
            args.delete_at(index)
            return "path"
          elsif index = args.index("--content")
            args.delete_at(index)
            return "content"
          elsif index = args.index("--tree")
            args.delete_at(index)
            return "tree"
          end
          "formatted"
        end

        # Parse task create arguments
        # @param args [Array<String>] Command arguments
        # @return [Hash] Parsed options with :title and :context
        def self.parse_create_args(args)
          title_parts = []
          context = "current"

          i = 0
          while i < args.length
            arg = args[i]
            case arg
            when "--backlog"
              context = "backlog"
              i += 1
            when "--release"
              context = args[i + 1]
              i += 2
            else
              title_parts << arg
              i += 1
            end
          end

          {
            title: title_parts.join(" "),
            context: context
          }
        end

        # Parse dependency command arguments
        # @param args [Array<String>] Command arguments
        # @return [Hash] Parsed with :task_ref and :depends_on_ref
        def self.parse_dependency_args(args)
          task_ref = args.first
          depends_on_ref = nil

          args.each_with_index do |arg, index|
            if arg == "--depends-on" || arg == "-d"
              depends_on_ref = args[index + 1]
              break
            end
          end

          {
            task_ref: task_ref,
            depends_on_ref: depends_on_ref
          }
        end

        # Parse task create arguments with OptionParser (new flexible version)
        # @param args [Array<String>] Command arguments
        # @return [Hash] Parsed options with :title, :context, and :metadata
        # @raise [SystemExit] Exits with 0 if --help flag provided
        def self.parse_create_args_with_optparse(args)
          options = {
            title: nil,
            context: "current",
            metadata: {}
          }

          positional_args = []

          parser = OptionParser.new do |opts|
            opts.banner = "Usage: ace-taskflow task create [TITLE] [options]"

            opts.on("--title TITLE", "Task title") do |title|
              options[:title] = title
            end

            opts.on("--status STATUS", "Initial status (pending, draft, in-progress, done, blocked)") do |status|
              options[:metadata][:status] = status
            end

            opts.on("--estimate ESTIMATE", "Effort estimate (e.g., 2h, 1d, TBD)") do |estimate|
              options[:metadata][:estimate] = estimate
            end

            opts.on("--dependencies DEPS", "Comma-separated dependency list (e.g., 018,019)") do |deps|
              options[:metadata][:dependencies] = deps.split(',').map(&:strip)
            end

            opts.on("--backlog", "Create task in backlog") do
              options[:context] = "backlog"
            end

            opts.on("--release VERSION", "Create task in specific release") do |version|
              options[:context] = version
            end

            opts.on("-h", "--help", "Show this help message") do
              puts opts
              exit 0
            end
          end

          # Parse known options, leaving unknown args in positional_args
          parser.order!(args) do |non_option|
            positional_args << non_option
          end

          # Positional title takes precedence (backwards compatibility)
          if !positional_args.empty?
            options[:title] = positional_args.join(" ")
          end

          options
        end
      end
    end
  end
end
