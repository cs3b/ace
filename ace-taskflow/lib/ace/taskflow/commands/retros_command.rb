# frozen_string_literal: true

require_relative "../organisms/retro_manager"
require_relative "../atoms/path_formatter"

module Ace
  module Taskflow
    module Commands
      # Handle retros subcommand (plural - browse and list retros)
      class RetrosCommand
        def initialize
          @manager = Organisms::RetroManager.new
        end

        def execute(args)
          # Parse options
          options = parse_options(args)

          if options[:help]
            show_help
            exit 0
          end

          # Determine scope from flags
          scope = if options[:all]
                    :all
                  elsif options[:done]
                    :done
                  else
                    :active  # default: excludes done/
                  end

          # List retros
          context = options[:context]
          retros = @manager.list_retros(context: context, filters: { scope: scope })

          # Apply limit if specified
          if options[:limit]
            retros = retros.take(options[:limit])
          end

          # Display results
          if retros.empty?
            display_empty_message(context, scope)
          else
            display_retros(retros, context, scope, options)
          end
        rescue StandardError => e
          puts "Error: #{e.message}"
          exit 1
        end

        private

        def parse_options(args)
          options = {
            context: "current",
            limit: nil,
            all: false,
            done: false,
            help: false
          }

          i = 0
          while i < args.length
            arg = args[i]
            case arg
            when "--release"
              options[:context] = args[i + 1]
              i += 2
            when "--current"
              options[:context] = "current"
              i += 1
            when "--backlog"
              options[:context] = "backlog"
              i += 1
            when "--limit"
              options[:limit] = args[i + 1].to_i
              i += 2
            when "--all"
              options[:all] = true
              i += 1
            when "--done"
              options[:done] = true
              i += 1
            when "--help", "-h"
              options[:help] = true
              i += 1
            else
              i += 1
            end
          end

          options
        end

        def display_retros(retros, context, scope, options)
          # Group by status if showing all
          if scope == :all
            active_retros = retros.reject { |r| r[:is_done] }
            done_retros = retros.select { |r| r[:is_done] }

            puts "Retrospective Notes (#{context_name(context)}):"
            puts ""

            if active_retros.any?
              puts "Active:"
              active_retros.each { |retro| display_retro_line(retro) }
              puts ""
            end

            if done_retros.any?
              puts "Done:"
              done_retros.each { |retro| display_retro_line(retro) }
            end
          elsif scope == :done
            puts "Done Retrospective Notes (#{context_name(context)}):"
            retros.each { |retro| display_retro_line(retro) }
          else
            # Active only (default)
            puts "Active Retrospective Notes (#{context_name(context)}):"
            retros.each { |retro| display_retro_line(retro) }
          end

          puts ""
          puts "Total: #{retros.count} retro#{retros.count == 1 ? '' : 's'}"
        end

        def display_retro_line(retro)
          date = retro[:date] || "unknown"
          title = retro[:title] || File.basename(retro[:filename], ".md")
          status_icon = retro[:is_done] ? "✓" : " "

          puts "  #{status_icon} #{date}  #{title}"
        end

        def display_empty_message(context, scope)
          case scope
          when :all
            puts "No retrospective notes found in #{context_name(context)}."
          when :done
            puts "No done retrospective notes found in #{context_name(context)}."
          else
            puts "No active retrospective notes found in #{context_name(context)}."
          end

          puts "Use 'ace-taskflow retro create <title>' to create your first reflection note."
        end

        def context_name(context)
          case context
          when "current", "active"
            "current release"
          when "backlog"
            "backlog"
          else
            context
          end
        end

        def show_help
          puts "Usage: ace-taskflow retros [options]"
          puts ""
          puts "List retrospective reflection notes with filtering options."
          puts ""
          puts "Options:"
          puts "  --current           List from current/active release (default)"
          puts "  --release <version> List from specific release"
          puts "  --backlog           List from backlog"
          puts "  --all               Include done retros (from retro/done/)"
          puts "  --done              List only done retros"
          puts "  --limit <n>         Limit number of results"
          puts "  -h, --help          Show this help message"
          puts ""
          puts "Default Behavior:"
          puts "  - Lists active retros from current/active release"
          puts "  - Excludes done/ directory by default"
          puts "  - Use --all to include done retros"
          puts "  - Use --done to show only done retros"
          puts ""
          puts "Examples:"
          puts "  ace-taskflow retros                    # List active retros"
          puts "  ace-taskflow retros --all              # Include done retros"
          puts "  ace-taskflow retros --done             # Only done retros"
          puts "  ace-taskflow retros --release v.0.8.0  # From specific release"
          puts "  ace-taskflow retros --limit 10         # Limit to 10 results"
        end
      end
    end
  end
end
