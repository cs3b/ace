# frozen_string_literal: true

require "dry/cli"
require_relative "../../../molecules/config_loader"
require_relative "../../../organisms/idea_scheduler"

module Ace
  module Taskflow
    module CLI
      module Commands
        module IdeaSubcommands
          # dry-cli Command class for idea reschedule nested subcommand
          #
          # Reorders ideas by moving them to different positions within
          # the ideas directory.
          class Reschedule < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc <<~DESC.strip
              Reorder idea position

              Changes the position of an idea within the ideas directory.
              Useful for prioritizing or reorganizing ideas.

            DESC

            example [
              'feature-x --add-next            # Place before other pending ideas',
              'feature-x --add-at-end          # Place after all ideas',
              'feature-x --after feature-y     # Place after specific idea',
              'feature-x --before feature-z    # Place before specific idea'
            ]

            argument :reference, required: true, desc: "Idea reference to reschedule"

            option :"add-next", type: :boolean, desc: "Place before other pending ideas"
            option :"add-at-end", type: :boolean, desc: "Place after all ideas"
            option :after, type: :string, desc: "Place after specific idea reference"
            option :before, type: :string, desc: "Place before specific idea reference"

            # Standard options
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

            def call(reference:, **options)
              # Display config summary unless quiet mode
              display_config_summary(options) unless quiet?(options)

              # Build scheduler options
              scheduler_options = build_scheduler_options(options)

              # Reschedule the idea
              root_path = Ace::Taskflow::Molecules::ConfigLoader.find_root
              scheduler = Ace::Taskflow::Organisms::IdeaScheduler.new(root_path)
              result = scheduler.reschedule(reference, scheduler_options)

              unless result[:success]
                raise Ace::Core::CLI::Error.new(result[:message])
              end

              puts result[:message]
            end

            private

            # Display config summary
            def display_config_summary(options)
              return unless verbose?(options)

              Ace::Core::Atoms::ConfigSummary.display(
                command: "idea reschedule",
                config: Ace::Taskflow.config,
                defaults: Ace::Taskflow.default_config,
                options: options,
                summary_keys: %w[current_release idea_location]
              )
            end

            # Build scheduler options from dry-cli options
            # @param options [Hash] dry-cli parsed options
            # @return [Hash] Options for IdeaScheduler
            def build_scheduler_options(options)
              scheduler_options = {}
              scheduler_options[:add_next] = true if options[:"add-next"]
              scheduler_options[:add_at_end] = true if options[:"add-at-end"]
              scheduler_options[:after] = options[:after] if options[:after]
              scheduler_options[:before] = options[:before] if options[:before]
              scheduler_options
            end
          end
        end
      end
    end
  end
end
