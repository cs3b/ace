# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../../organisms/retro_manager"
require_relative "../../atoms/path_formatter"
require_relative "../../molecules/command_option_parser"

module Ace
  module Taskflow
    module CLI
      module Commands
        # dry-cli Command class for the retro command
        #
        # This command handles operations on single retrospectives.
        class Retro < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Operations on single retrospective notes"
          example [
            '                         # List active retros',
            'create "Session learnings" # Create new retro',
            'show ace-test-runner       # Show specific retro'
          ]

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Debug output"
          option :release, type: :string, desc: "Work with specific release"
          option :backlog, type: :boolean, desc: "Work with backlog"
          option :current, type: :boolean, desc: "Work with current/active release"

          def call(**options)
            args = options[:args] || []
            clean_options = options.reject { |k, _| k == :args }
            execute_retro(args, clean_options)
          end

          private

          def execute_retro(args, thor_options = {})
            @manager = Organisms::RetroManager.new
            @create_parser = build_create_parser

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
              exit_success
            when nil, "list"
              show_active_retros
            else
              show_retro([subaction] + args)
            end
          rescue StandardError => e
            puts "Error: #{e.message}"
            exit_failure
          end

          def build_create_parser
            Molecules::CommandOptionParser.new(
              option_sets: [:release, :help],
              banner: "Usage: ace-taskflow retro create <title> [options]"
            )
          end

          def create_retro(args)
            result = @create_parser.parse(args)
            return exit_success if result[:help_requested]

            options = result[:parsed]
            title = result[:remaining].join(" ")

            if title.empty?
              puts @create_parser.help_text
              return exit_failure
            end

            release = options[:release] || "current"
            create_result = @manager.create_retro(title, release: release)

            if create_result[:success]
              puts create_result[:message]
              root_path = Dir.pwd
              relative_path = Atoms::PathFormatter.format_relative_path(create_result[:path], root_path)
              puts "Path: #{relative_path}"
              exit_success
            else
              puts "Error: #{create_result[:message]}"
              exit_failure
            end
          end

          def show_retro(args)
            reference = args.shift

            unless reference
              puts "Usage: ace-taskflow retro show <reference>"
              puts "Example: ace-taskflow retro show ace-test-runner"
              return exit_failure
            end

            release = parse_release(args)
            retro = @manager.load_retro(reference, release: release)

            if retro
              display_retro(retro)
              exit_success
            else
              puts "Retro '#{reference}' not found in #{release_name(release)}."
              exit_failure
            end
          end

          def mark_retro_done(args)
            reference = args.shift

            unless reference
              puts "Usage: ace-taskflow retro done <reference>"
              puts "Example: ace-taskflow retro done ace-test-runner"
              return exit_failure
            end

            release = parse_release(args)
            result = @manager.mark_retro_done(reference, release: release)

            if result[:success]
              puts result[:message]
              root_path = Dir.pwd
              relative_path = Atoms::PathFormatter.format_relative_path(result[:path], root_path)
              puts "Path: #{relative_path}"
              puts "Completed at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
              exit_success
            else
              puts "Error: #{result[:message]}"
              exit_failure
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

          def show_active_retros
            retros = @manager.list_retros(release: "current", filters: { scope: :active })

            if retros.empty?
              puts "No active retrospective notes found in current release."
              puts ""
              puts "Use 'ace-taskflow retro create <title>' to create your first reflection note."
              return exit_success
            end

            puts "Active Retrospective Notes (current release):"
            puts ""
            retros.each { |retro| display_retro_line(retro) }
            puts ""
            puts "Total: #{retros.count} retro#{retros.count == 1 ? '' : 's'}"
            exit_success
          end

          def display_retro_line(retro)
            date = retro[:date] || "unknown"
            title = retro[:title] || File.basename(retro[:filename], ".md")
            status_icon = retro[:is_done] ? "✓" : " "

            puts "  #{status_icon} #{date}  #{title}"
          end

          def show_help
            puts "Usage: ace-taskflow retro [subcommand] [options]"
            puts ""
            puts "Subcommands:"
            puts "  create <title>      Create new reflection note"
            puts "  show <reference>    Display specific reflection note"
            puts "  <reference>         Shorthand for show"
            puts "  done <reference>    Mark retro as done (move to _archive/)"
            puts "  list                List active retros (default when no subcommand)"
            puts ""
            puts "Options:"
            puts "  --release <version> Work with specific release"
            puts "  --current           Work with current/active release (default)"
            puts "  --backlog           Work with backlog"
          end
        end
      end
    end
  end
end
