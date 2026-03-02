# frozen_string_literal: true

require "dry/cli"

module Ace
  module Task
    module CLI
      module Commands
        # dry-cli Command class for ace-task status
        class Status < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Show task status overview

            Displays up-next tasks, summary stats, and recently completed tasks.
          DESC

          example [
            "                             # Default status view",
            "--up-next-limit 5            # Show 5 up-next tasks",
            "--recently-done-limit 3      # Show 3 recently done tasks"
          ]

          option :up_next_limit, type: :integer, desc: "Max up-next tasks to show"
          option :recently_done_limit, type: :integer, desc: "Max recently-done tasks to show"

          def call(**options)
            manager = Ace::Task::Organisms::TaskManager.new
            all_tasks = manager.list(in_folder: "all")

            config = Ace::Task::Molecules::TaskConfigLoader.load
            limits = resolve_limits(config, options)

            categorized = Ace::Support::Items::Molecules::StatusCategorizer.categorize(
              all_tasks,
              up_next_limit: limits[:up_next],
              recently_done_limit: limits[:recently_done],
              pending_statuses: %w[pending],
              done_statuses: %w[done]
            )

            puts Ace::Task::Molecules::TaskDisplayFormatter.format_status(
              categorized, all_tasks: all_tasks
            )
          end

          private

          def resolve_limits(config, options)
            status_config = config.dig("task", "status") || {}
            {
              up_next: (options[:up_next_limit] || status_config["up_next_limit"] || 3).to_i,
              recently_done: (options[:recently_done_limit] || status_config["recently_done_limit"] || 9).to_i
            }
          end
        end
      end
    end
  end
end
