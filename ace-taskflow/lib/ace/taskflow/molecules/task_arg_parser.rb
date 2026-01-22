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
        # @return [Hash] Parsed options with :title and :release
        def self.parse_create_args(args)
          title_parts = []
          release = "current"

          i = 0
          while i < args.length
            arg = args[i]
            case arg
            when "--backlog"
              release = "backlog"
              i += 1
            when "--release"
              release = args[i + 1]
              i += 2
            else
              title_parts << arg
              i += 1
            end
          end

          {
            title: title_parts.join(" "),
            release: release
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
        # @return [Hash] Parsed options with :title, :release, :metadata, and :dry_run
        # @raise [SystemExit] Exits with 0 if --help flag provided
        def self.parse_create_args_with_optparse(args)
          options = {
            title: nil,
            release: "current",
            metadata: {},
            dry_run: false
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
              options[:release] = "backlog"
            end

            opts.on("--release VERSION", "Create task in specific release") do |version|
              options[:release] = version
            end

            opts.on("--child-of PARENT", "-p PARENT", "Create as subtask under parent task") do |parent|
              options[:parent_ref] = parent
            end

            opts.on("--dry-run", "-n", "Preview what would be created without creating") do
              options[:dry_run] = true
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

        # Parse task move arguments with OptionParser
        # @param args [Array<String>] Command arguments
        # @return [Hash] Parsed options with :task_ref, :child_of, :dry_run, :release
        # @raise [SystemExit] Exits with 0 if --help flag provided
        def self.parse_move_args_with_optparse(args)
          options = {
            task_ref: nil,
            child_of: nil,
            dry_run: false,
            release: nil
          }

          positional_args = []

          parser = OptionParser.new do |opts|
            opts.banner = "Usage: ace-taskflow task move TASK_REF [options]"
            opts.separator ""
            opts.separator "Move a task between releases, convert to subtask, or promote to standalone."
            opts.separator ""
            opts.separator "Options:"

            opts.on("--child-of [PARENT]", "-p [PARENT]",
                    "Convert task to subtask under PARENT.",
                    "  Omit PARENT to promote subtask to standalone.",
                    "  Use 'none' to promote subtask to standalone.",
                    "  Use 'self' to convert standalone to orchestrator.") do |parent|
              # When --child-of is provided without value, parent is nil
              # When --child-of is omitted entirely, this block doesn't run
              # Note: Uses :promote symbol for "no parent" to distinguish from strings.
              # The command handler must handle: :promote (symbol), "self" (string), or any other string.
              options[:child_of] = parent.nil? || parent == "none" ? :promote : parent
            end

            opts.on("--dry-run", "-n", "Preview operations without executing") do
              options[:dry_run] = true
            end

            opts.on("--release VERSION", "Move to specific release") do |version|
              options[:release] = version
            end

            opts.on("--backlog", "Move to backlog") do
              options[:release] = "backlog"
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

          # First positional argument is the task reference
          options[:task_ref] = positional_args.first if positional_args.any?

          # Legacy support: second positional can be release target
          # ace-taskflow task move 019 backlog
          if positional_args.length >= 2 && options[:release].nil? && options[:child_of].nil?
            options[:release] = positional_args[1]
          end

          options
        end
      end
    end
  end
end
