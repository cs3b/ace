# frozen_string_literal: true

require "dry/cli"
require_relative "../../organisms/task_manager"

module Ace
  module Taskflow
    module Commands
      module Task
        # dry-cli Command class for task add-dependency nested subcommand
        #
        # Adds a dependency relationship between tasks.
        class AddDependency < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Add dependency to task

            Adds a dependency relationship, making the first task depend on the second.

          DESC

          example [
            '034 --depends-on 031    # Make task 034 depend on task 031',
            '034 -d 031             # Short form'
          ]

          argument :task_ref, required: true, desc: "Task reference to add dependency to"
          argument :depends_on, required: true, desc: "Task reference that this task depends on"

          # Standard options
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

          def call(task_ref:, depends_on:, **options)
            # Display config summary unless quiet mode
            display_config_summary(options) unless quiet?(options)

            # Call TaskManager
            manager = Organisms::TaskManager.new
            result = manager.add_dependency(task_ref, depends_on)

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
              command: "task add-dependency",
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
