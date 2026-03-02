# frozen_string_literal: true

require "dry/cli"

module Ace
  module Idea
    module CLI
      module Commands
        # dry-cli Command class for ace-idea status
        class Status < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Show idea status overview

            Displays up-next ideas, summary stats, and recently completed ideas.
          DESC

          example [
            "                             # Default status view",
            "--up-next-limit 5            # Show 5 up-next ideas",
            "--recently-done-limit 3      # Show 3 recently done ideas"
          ]

          option :up_next_limit, type: :integer, desc: "Max up-next ideas to show"
          option :recently_done_limit, type: :integer, desc: "Max recently-done ideas to show"

          def call(**options)
            manager = Ace::Idea::Organisms::IdeaManager.new
            all_ideas = manager.list(in_folder: "all")

            config = Ace::Idea::Molecules::IdeaConfigLoader.load
            limits = resolve_limits(config, options)

            categorized = Ace::Support::Items::Molecules::StatusCategorizer.categorize(
              all_ideas,
              up_next_limit: limits[:up_next],
              recently_done_limit: limits[:recently_done],
              pending_statuses: %w[pending],
              done_statuses: %w[done]
            )

            puts Ace::Idea::Molecules::IdeaDisplayFormatter.format_status(
              categorized, all_ideas: all_ideas
            )
          end

          private

          def resolve_limits(config, options)
            status_config = config.dig("idea", "status") || {}
            {
              up_next: (options[:up_next_limit] || status_config["up_next_limit"] || 7).to_i,
              recently_done: (options[:recently_done_limit] || status_config["recently_done_limit"] || 7).to_i
            }
          end
        end
      end
    end
  end
end
