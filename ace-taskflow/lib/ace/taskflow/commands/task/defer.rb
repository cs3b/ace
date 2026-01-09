# frozen_string_literal: true

require "dry/cli"
require_relative "../../organisms/task_manager"

module Ace
  module Taskflow
    module Commands
      module Task
        # dry-cli Command class for task defer nested subcommand
        #
        # Defers a task to a future release by moving it to the deferred directory.
        class Defer < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Defer task to future release

            Moves the task to the deferred directory, marking it as deferred.
            Use 'task undefer' to restore it later.

          DESC

          example [
            '187                    # Defer task 187',
            'task.187               # Using task ID format',
            'v.0.9.0+187           # Using full reference'
          ]

          argument :task_ref, required: true, desc: "Task reference to defer"

          # Standard options
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

          def call(task_ref:, **options)
            # Display config summary unless quiet mode
            display_config_summary(options) unless quiet?(options)

            # Call TaskManager
            manager = Organisms::TaskManager.new
            result = manager.defer_task(task_ref)

            if result[:success]
              puts result[:message]
              puts "Deferred at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
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
              command: "task defer",
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
