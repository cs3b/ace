# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/task_manager"

module Ace
  module Taskflow
    module CLI
      module Commands
        module TaskSubcommands
          # dry-cli Command class for task remove-dependency nested subcommand
          #
          # Removes a dependency relationship between tasks.
          class RemoveDependency < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc <<~DESC.strip
              Remove dependency from task

              Removes a dependency relationship, allowing tasks to proceed independently.

            DESC

            example [
              '034 --depends-on 031    # Remove dependency of task 034 on task 031',
              '034 -d 031             # Short form'
            ]

            argument :task_ref, required: true, desc: "Task reference to remove dependency from"
            argument :depends_on, required: true, desc: "Task reference to remove as dependency"

            # Standard options
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

            def call(task_ref:, depends_on:, **options)
              # Display config summary unless quiet mode
              display_config_summary(options) unless quiet?(options)

              # Call TaskManager
              manager = Ace::Taskflow::Organisms::TaskManager.new
              result = manager.remove_dependency(task_ref, depends_on)

              if result[:success]
                puts result[:message]
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
                command: "task remove-dependency",
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
