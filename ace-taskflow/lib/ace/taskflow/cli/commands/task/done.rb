# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/task_manager"

module Ace
  module Taskflow
    module CLI
      module Commands
        module TaskSubcommands
          # dry-cli Command class for task done nested subcommand
          #
          # Marks a task as completed and moves it to the done directory.
          class Done < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc <<~DESC.strip
              Mark task as complete

              Updates the task status to done, records completion time,
              and moves the task to the done directory.

            DESC

            example [
              '187                    # Mark task 187 as complete',
              'task.187               # Using task ID format',
              'v.0.9.0+187           # Using full reference'
            ]

            argument :task_ref, required: true, desc: "Task reference to complete"
            option :allow_incomplete, type: :boolean, default: false,
                                      desc: "Bypass completion checklist gate with warning"

            # Standard options
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

            def call(task_ref:, allow_incomplete: false, **options)
              # Display config summary unless quiet mode
              display_config_summary(options) unless quiet?(options)

              # Call TaskManager
              manager = Ace::Taskflow::Organisms::TaskManager.new
              result = manager.complete_task(task_ref, allow_incomplete: allow_incomplete)

              unless result[:success]
                raise Ace::Core::CLI::Error.new(result[:message])
              end

              puts "Warning: #{result[:warning]}" if result[:warning]
              puts result[:message]
              puts "Completed at: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}"
            end

            private

            # Display config summary
            def display_config_summary(options)
              return unless verbose?(options)

              Ace::Core::Atoms::ConfigSummary.display(
                command: "task done",
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
