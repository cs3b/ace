# frozen_string_literal: true

require_relative "../organisms/retro_manager"
require_relative "../atoms/path_formatter"

module Ace
  module Taskflow
    module Commands
      # Handle retro subcommand (singular - operations on single retros)
      class RetroCommand
        def initialize
          @manager = Organisms::RetroManager.new
        end

        def execute(args)
          subaction = args.shift

          case subaction
          when "create"
            create_retro(args)
          when "show"
            show_retro(args)
          when "done"
            mark_retro_done(args)
          when "--help", "-h"
            show_help
            0
          when nil
            puts "Usage: ace-taskflow retro <subcommand> [options]"
            puts "Run 'ace-taskflow retro --help' for more information"
            1
          else
            # Try to show specific retro by reference
            show_retro([subaction] + args)
          end
        rescue StandardError => e
          puts "Error: #{e.message}"
          1
        end

        private

        def create_retro(args)
          # Parse options
          title_parts = []
          context = "current"

          i = 0
          while i < args.length
            arg = args[i]
            case arg
            when "--release"
              context = args[i + 1]
              i += 2
            when "--current"
              context = "current"
              i += 1
            when "--backlog"
              context = "backlog"
              i += 1
            else
              title_parts << arg
              i += 1
            end
          end

          title = title_parts.join(" ")

          if title.empty?
            puts "Usage: ace-taskflow retro create <title> [options]"
            puts "Options:"
            puts "  --release <version>   Create in specific release"
            puts "  --current             Create in current/active release (default)"
            puts "  --backlog             Create in backlog"
            return 1
          end

          result = @manager.create_retro(title, context: context)

          if result[:success]
            puts result[:message]
            # Use project root for relative path
            root_path = Dir.pwd
            relative_path = Atoms::PathFormatter.format_relative_path(result[:path], root_path)
            puts "Path: #{relative_path}"
            0
          else
            puts "Error: #{result[:message]}"
            1
          end
        end

        def show_retro(args)
          reference = args.shift

          unless reference
            puts "Usage: ace-taskflow retro show <reference>"
            puts "Example: ace-taskflow retro show ace-test-runner"
            return 1
          end

          context = parse_context(args)
          retro = @manager.load_retro(reference, context: context)

          if retro
            display_retro(retro)
            0
          else
            puts "Retro '#{reference}' not found in #{context_name(context)}."
            1
          end
        end

        def mark_retro_done(args)
          reference = args.shift

          unless reference
            puts "Usage: ace-taskflow retro done <reference>"
            puts "Example: ace-taskflow retro done ace-test-runner"
            return 1
          end

          context = parse_context(args)
          result = @manager.mark_retro_done(reference, context: context)

          if result[:success]
            puts result[:message]
            # Use project root for relative path
            root_path = Dir.pwd
            relative_path = Atoms::PathFormatter.format_relative_path(result[:path], root_path)
            puts "Path: #{relative_path}"
            puts "Completed at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
            0
          else
            puts "Error: #{result[:message]}"
            1
          end
        end

        def display_retro(retro)
          puts "Reflection: #{retro[:title]}"
          puts "Date: #{retro[:date]}" if retro[:date]

          if retro[:path]
            root_path = Dir.pwd
            relative_path = Atoms::PathFormatter.format_relative_path(retro[:path], root_path)
            puts "Path: #{relative_path}"
          end

          status = retro[:is_done] ? "✓ Done" : "Active"
          puts "Status: #{status}"

          if retro[:content]
            puts ""
            puts "--- Content ---"
            puts retro[:content]
          end
        end

        def parse_context(args)
          args.each_with_index do |arg, index|
            case arg
            when "--backlog"
              return "backlog"
            when "--release"
              return args[index + 1]
            when "--current"
              return "current"
            end
          end
          "current"
        end

        def context_name(context)
          case context
          when "current", "active"
            "current release"
          when "backlog"
            "backlog"
          else
            "release #{context}"
          end
        end

        def show_help
          puts "Usage: ace-taskflow retro [subcommand] [options]"
          puts ""
          puts "Subcommands:"
          puts "  create <title>      Create new reflection note"
          puts "    --release <ver>   Create in specific release"
          puts "    --current         Create in current/active release (default)"
          puts "    --backlog         Create in backlog"
          puts ""
          puts "  show <reference>    Display specific reflection note"
          puts "  <reference>         Shorthand for show"
          puts ""
          puts "  done <reference>    Mark retro as done (move to done/)"
          puts ""
          puts "Options:"
          puts "  --release <version> Work with specific release"
          puts "  --current           Work with current/active release (default)"
          puts "  --backlog           Work with backlog"
          puts ""
          puts "Examples:"
          puts "  ace-taskflow retro create 'ace-test-runner fixes'"
          puts "  ace-taskflow retro show ace-test-runner"
          puts "  ace-taskflow retro ace-test-runner"
          puts "  ace-taskflow retro done ace-test-runner"
          puts "  ace-taskflow retro create 'API refactor' --release v.0.8.0"
        end
      end
    end
  end
end
