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
        # dry-cli Command class for the retros command
        #
        # This command lists and browses retrospective notes.
        class Retros < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "List retrospective reflection notes"
          example [
            '                 # List active retros',
            '--all           # Include done retros',
            '--done          # List only done retros'
          ]

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          option :release, type: :string, desc: "Work with specific release"
          option :backlog, type: :boolean, desc: "Work with backlog"
          option :current, type: :boolean, desc: "Work with current/active release"
          option :all, type: :boolean, desc: "Include done retros"
          option :done, type: :boolean, desc: "Show only done retros"
          option :limit, type: :integer, desc: "Limit number of results"

          def call(**options)
            args = options[:args] || []
            clean_options = options.reject { |k, _| k == :args }
            execute_retros(args, clean_options)
          end

          private

          def execute_retros(args, thor_options = {})
            @manager = Organisms::RetroManager.new
            @option_parser = build_option_parser

            result = @option_parser.parse(args, thor_options: thor_options)
            return if result[:help_requested]

            options = result[:parsed]

            scope = if options[:all]
                      :all
                    elsif options[:done]
                      :done
                    else
                      :active
                    end

            release = options[:release] || "current"
            retros = @manager.list_retros(release: release, filters: { scope: scope })

            if options[:limit]
              retros = retros.take(options[:limit])
            end

            if retros.empty?
              display_empty_message(release, scope)
            else
              display_retros(retros, release, scope, options)
            end

          rescue StandardError => e
            raise Ace::Core::CLI::Error.new(e.message)
          end

          def build_option_parser
            Molecules::CommandOptionParser.new(
              option_sets: [:release, :limits, :help],
              banner: "Usage: ace-taskflow retros [options]"
            ) do |opts, parsed|
              opts.on("--done", "Show only done retros") { parsed[:done] = true }
            end
          end

          def display_retros(retros, release, scope, options)
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
        end
      end
    end
  end
end
