# frozen_string_literal: true

require_relative "../organisms/retro_manager"
require_relative "../atoms/path_formatter"
require_relative "../molecules/command_option_parser"

module Ace
  module Taskflow
    module Commands
      # Handle retros subcommand (plural - browse and list retros)
      class RetrosCommand
        def initialize
          @manager = Organisms::RetroManager.new
          @option_parser = build_option_parser
        end

        def execute(args)
          # Parse options using CommandOptionParser
          result = @option_parser.parse(args)
          return 0 if result[:help_requested]

          options = result[:parsed]

          # Determine scope from flags
          scope = if options[:all]
                    :all
                  elsif options[:done]
                    :done
                  else
                    :active  # default: excludes done/
                  end

          # List retros
          release = options[:release] || "current"
          retros = @manager.list_retros(release: release, filters: { scope: scope })

          # Apply limit if specified
          if options[:limit]
            retros = retros.take(options[:limit])
          end

          # Display results
          if retros.empty?
            display_empty_message(release, scope)
          else
            display_retros(retros, release, scope, options)
          end

          0
        rescue StandardError => e
          puts "Error: #{e.message}"
          1
        end

        private

        def build_option_parser
          Molecules::CommandOptionParser.new(
            option_sets: [:release, :limits, :help],
            banner: "Usage: ace-taskflow retros [options]"
          ) do |opts, parsed|
            opts.on("--done", "Show only done retros") { parsed[:done] = true }
          end
        end

        def display_retros(retros, release, scope, options)
          # Group by status if showing all
          if scope == :all
            active_retros = retros.reject { |r| r[:is_done] }
            done_retros = retros.select { |r| r[:is_done] }

            puts "Retrospective Notes (#{release_name(release)}):"
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
            puts "Done Retrospective Notes (#{release_name(release)}):"
            retros.each { |retro| display_retro_line(retro) }
          else
            # Active only (default)
            puts "Active Retrospective Notes (#{release_name(release)}):"
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

        def display_empty_message(release, scope)
          case scope
          when :all
            puts "No retrospective notes found in #{release_name(release)}."
          when :done
            puts "No done retrospective notes found in #{release_name(release)}."
          else
            puts "No active retrospective notes found in #{release_name(release)}."
          end

          puts "Use 'ace-taskflow retro create <title>' to create your first reflection note."
        end

        def release_name(release)
          case release
          when "current", "active"
            "current release"
          when "backlog"
            "backlog"
          else
            release
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
