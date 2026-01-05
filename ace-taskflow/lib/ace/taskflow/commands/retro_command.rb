# frozen_string_literal: true

require_relative "../organisms/retro_manager"
require_relative "../atoms/path_formatter"
require_relative "../molecules/command_option_parser"

module Ace
  module Taskflow
    module Commands
      # Handle retro subcommand (singular - operations on single retros)
      class RetroCommand
        def initialize
          @manager = Organisms::RetroManager.new
          @create_parser = build_create_parser
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
          when nil, "list"
            # Show active retros by default (delegates to retros command behavior)
            show_active_retros
          else
            # Try to show specific retro by reference
            show_retro([subaction] + args)
          end
        rescue StandardError => e
          puts "Error: #{e.message}"
          1
        end

        private

        def build_create_parser
          Molecules::CommandOptionParser.new(
            option_sets: [:release, :help],
            banner: "Usage: ace-taskflow retro create <title> [options]"
          )
        end

        def create_retro(args)
          # Parse options using CommandOptionParser
          result = @create_parser.parse(args)
          return 0 if result[:help_requested]

          options = result[:parsed]
          title = result[:remaining].join(" ")

          if title.empty?
            puts @create_parser.help_text
            return 1
          end

          release = options[:release] || "current"
          create_result = @manager.create_retro(title, release: release)

          if create_result[:success]
            puts create_result[:message]
            # Use project root for relative path
            root_path = Dir.pwd
            relative_path = Atoms::PathFormatter.format_relative_path(create_result[:path], root_path)
            puts "Path: #{relative_path}"
            0
          else
            puts "Error: #{create_result[:message]}"
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

          release = parse_release(args)
          retro = @manager.load_retro(reference, release: release)

          if retro
            display_retro(retro)
            0
          else
            puts "Retro '#{reference}' not found in #{release_name(release)}."
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

          release = parse_release(args)
          result = @manager.mark_retro_done(reference, release: release)

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

        def parse_release(args)
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

        def release_name(release)
          case release
          when "current", "active"
            "current release"
          when "backlog"
            "backlog"
          else
            "release #{release}"
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
          puts "  done <reference>    Mark retro as done (move to _archive/)"
          puts ""
          puts "  list                List active retros (default when no subcommand)"
          puts ""
          puts "Options:"
          puts "  --release <version> Work with specific release"
          puts "  --current           Work with current/active release (default)"
          puts "  --backlog           Work with backlog"
          puts ""
          puts "Examples:"
          puts "  ace-taskflow retro                  # List active retros (default)"
          puts "  ace-taskflow retro create 'ace-test-runner fixes'"
          puts "  ace-taskflow retro show ace-test-runner"
          puts "  ace-taskflow retro ace-test-runner"
          puts "  ace-taskflow retro done ace-test-runner"
          puts "  ace-taskflow retro create 'API refactor' --release v.0.8.0"
        end

        def show_active_retros
          # Reuse retros command behavior for listing active retros
          retros = @manager.list_retros(release: "current", filters: { scope: :active })

          if retros.empty?
            puts "No active retrospective notes found in current release."
            puts ""
            puts "Use 'ace-taskflow retro create <title>' to create your first reflection note."
            return 0
          end

          puts "Active Retrospective Notes (current release):"
          puts ""
          retros.each { |retro| display_retro_line(retro) }
          puts ""
          puts "Total: #{retros.count} retro#{retros.count == 1 ? '' : 's'}"
          0
        end

        def display_retro_line(retro)
          date = retro[:date] || "unknown"
          title = retro[:title] || File.basename(retro[:filename], ".md")
          status_icon = retro[:is_done] ? "✓" : " "

          puts "  #{status_icon} #{date}  #{title}"
        end
      end
    end
  end
end
