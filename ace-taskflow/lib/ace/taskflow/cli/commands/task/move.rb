# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/task_manager"

module Ace
  module Taskflow
    module CLI
      module Commands
        module TaskSubcommands
          # dry-cli Command class for task move nested subcommand
          #
          # Moves tasks between releases, converts to subtasks, or promotes to standalone.
          class Move < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc <<~DESC.strip
              Move or reorganize task

              Move tasks between releases, convert to subtasks, promote to standalone,
              or convert standalone tasks to orchestrators.

            DESC

            example [
              '187 --child-of 150      # Make 187 a subtask of 150',
              '187.12 --child-of none  # Promote 187.12 from subtask to standalone',
              '187 --child-of self     # Convert 187 to orchestrator',
              '187 --release v.1.0.0   # Move 187 to release v.1.0.0',
              '187 --dry-run           # Preview operations without executing'
            ]

            argument :task_ref, required: true, desc: "Task reference to move"

            option :"child-of", type: :string, aliases: ["-p"],
                   desc: "Make subtask of PARENT (use 'none' to promote to standalone, 'self' to convert to orchestrator)"
            option :release, type: :string, desc: "Move to specific release"
            option :backlog, type: :boolean, desc: "Move to backlog"
            option :"dry-run", type: :boolean, aliases: ["-n"], desc: "Preview operations without executing"

            # Standard options
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

            def call(task_ref:, **options)
              # Display config summary unless quiet mode
              display_config_summary(options) unless quiet?(options)

              # Resolve child-of option
              # dry-cli passes empty string for flag without value
              child_of_value = options[:"child-of"]
              child_of = if child_of_value.nil?
                nil
              elsif child_of_value.empty?
                :promote  # --child-of without value = promote (backwards compat)
              elsif child_of_value == "none"
                :promote  # --child-of none = promote to standalone
              else
                child_of_value  # --child-of PARENT or "self" = demote/convert
              end

              # Resolve release
              release = options[:backlog] ? "backlog" : options[:release]

              # Call TaskManager based on operation type
              manager = Ace::Taskflow::Organisms::TaskManager.new
              result = case child_of
              when :promote
                # Promote subtask to standalone
                manager.promote_to_standalone(task_ref, dry_run: options[:"dry-run"])
              when "self"
                # Convert to orchestrator
                manager.convert_to_orchestrator(task_ref, dry_run: options[:"dry-run"])
              when String
                # Demote to subtask
                manager.demote_to_subtask(task_ref, child_of, dry_run: options[:"dry-run"])
              else
                # Release move (no --child-of)
                unless release
                  puts ""
                  puts "Usage: ace-taskflow task move TASK_REF --release VERSION"
                  puts "   or: ace-taskflow task move TASK_REF --backlog"
                  puts "   or: ace-taskflow task move TASK_REF --child-of PARENT"
                  raise Ace::Core::CLI::Error.new("Target release required (use --release VERSION or --backlog)")
                end

                if options[:"dry-run"]
                  puts "Note: --dry-run is not yet supported for release moves. Showing what would happen:"
                  puts "  - Move task #{task_ref} to release #{release}"
                  return
                end

                manager.move_task(task_ref, release)
              end

              # Display result
              unless result[:success]
                raise Ace::Core::CLI::Error.new(result[:message])
              end

              puts result[:message]
              if result[:dry_run] && result[:operations]
                puts "\nOperations that would be performed:"
                result[:operations].each { |op| puts "  - #{op}" }
              end
              puts "New reference: #{result[:new_reference]}" if result[:new_reference]
              puts "Subtask: #{result[:subtask_id]}" if result[:subtask_id] && !result[:dry_run]
              puts "Orchestrator: #{result[:orchestrator_path]}" if result[:orchestrator_path] && !result[:dry_run]
              puts "Subtask file: #{result[:subtask_path]}" if result[:subtask_path] && !result[:dry_run]
              puts "Path: #{result[:new_path]}" if result[:new_path] && !result[:dry_run]
            end

            private

            # Display config summary
            def display_config_summary(options)
              return unless verbose?(options)

              Ace::Core::Atoms::ConfigSummary.display(
                command: "task move",
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
