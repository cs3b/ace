# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/task_manager"

module Ace
  module Taskflow
    module CLI
      module Commands
        module TaskSubcommands
          # dry-cli Command class for task undone nested subcommand
          #
          # Reopens a completed task, changing its status back to in-progress.
          class Undone < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc <<~DESC.strip
              Reopen completed task

              Changes task status from done back to in-progress,
              effectively "undoing" the completion.

            DESC

            example [
              '187                    # Reopen task 187',
              'task.187               # Using task ID format',
              'v.0.9.0+187           # Using full reference'
            ]

            argument :task_ref, required: true, desc: "Task reference to reopen"

            # Standard options
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

            def call(task_ref:, **options)
              # Display config summary unless quiet mode
              display_config_summary(options) unless quiet?(options)

              # Call TaskManager
              manager = Ace::Taskflow::Organisms::TaskManager.new
              result = manager.reopen_task(task_ref)

              unless result[:success]
                raise Ace::Core::CLI::Error.new(result[:message])
              end

              puts result[:message]
              puts "Reopened at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
            end

            private

            # Display config summary
            def display_config_summary(options)
              return unless verbose?(options)

              Ace::Core::Atoms::ConfigSummary.display(
                command: "task undone",
                config: Ace::Taskflow.config,
                defaults: Ace::Taskflow.default_config,
                options: options,
                summary_keys: %w[current_release task_dir]
              )
            end
          end
        end
      end
    end
  end
end
