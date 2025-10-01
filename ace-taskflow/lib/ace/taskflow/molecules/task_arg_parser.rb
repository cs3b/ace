# frozen_string_literal: true

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
      end
    end
  end
end
