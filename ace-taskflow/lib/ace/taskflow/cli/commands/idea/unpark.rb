# frozen_string_literal: true

require "dry/cli"
require_relative "../../../molecules/idea_loader"
require_relative "../../../molecules/idea_directory_mover"

module Ace
  module Taskflow
    module CLI
      module Commands
        module IdeaSubcommands
          # dry-cli Command class for idea unpark nested subcommand
          #
          # Restores an idea from the maybe/ subdirectory back to the
          # active ideas directory.
          class Unpark < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc <<~DESC.strip
              Restore parked idea

              Restores an idea from the maybe/ subdirectory back to
              the active ideas directory.

            DESC

            example [
              'future-feature        # Restore idea by partial name',
              'idea.123             # Using idea ID format'
            ]

            argument :reference, required: true, desc: "Idea reference (partial name or ID)"

            option :backlog, type: :boolean, desc: "Work with backlog ideas"
            option :release, type: :string, aliases: %w[-r], desc: "Work with specific release"
            option :current, type: :boolean, desc: "Work with current/active release (default)"

            # Standard options
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

            def call(reference:, **options)
              # Display config summary unless quiet mode
              display_config_summary(options) unless quiet?(options)

              # Parse release from options
              release = parse_release(options)

              # Find the idea
              root_path = Ace::Taskflow::Molecules::ConfigLoader.find_root
              idea_loader = Ace::Taskflow::Molecules::IdeaLoader.new(root_path)
              idea = idea_loader.find_by_partial_name(reference, release: release)

              unless idea
                puts "No idea found matching '#{reference}' in #{release_name(release)}."
                return exit_failure
              end

              # Restore idea from parked (maybe/)
              mover = Ace::Taskflow::Molecules::IdeaDirectoryMover.new
              result = mover.restore_from_maybe(idea[:path])

              if result[:success]
                maybe_dir = Ace::Taskflow.configuration.maybe_dir
                puts "Idea '#{reference}' restored from #{maybe_dir}/"
                puts "Moved back to active ideas"
                exit_success
              else
                puts "Error: #{result[:message]}"
                exit_failure
              end
            end

            private

            # Display config summary
            def display_config_summary(options)
              return unless verbose?(options)

              Ace::Core::Atoms::ConfigSummary.display(
                command: "idea unpark",
                config: Ace::Taskflow.config,
                defaults: Ace::Taskflow.default_config,
                options: options,
                summary_keys: %w[current_release idea_location]
              )
            end

            # Parse release from options
            # @param options [Hash] dry-cli parsed options
            # @return [String] Release identifier
            def parse_release(options)
              return "backlog" if options[:backlog]
              return options[:release] if options[:release]
              return "current" if options[:current]
              "current"
            end

            # Get human-readable release name
            # @param release [String] Release identifier
            # @return [String] Human-readable name
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
          end
        end
      end
    end
  end
end
