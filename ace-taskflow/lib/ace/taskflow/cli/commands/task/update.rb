# frozen_string_literal: true

require "dry/cli"
require_relative "../../../organisms/task_manager"
require_relative "../../../molecules/task_field_updater"

module Ace
  module Taskflow
    module CLI
      module Commands
        module TaskSubcommands
          # dry-cli Command class for task update nested subcommand
          #
          # Updates task metadata fields.
          class Update < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc <<~DESC.strip
              Update task metadata

              Updates arbitrary task metadata fields using dot notation for nested values.

            DESC

            example [
              '187 --field priority=high',
              '187 --field worktree.branch=feature-name',
              '187 --field priority=high --field estimate="2 weeks"'
            ]

            argument :task_ref, required: true, desc: "Task reference to update"

            option :field, type: :string, repeat: true,
                   desc: "Field update in key=value format (can be repeated)"

            # Standard options
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

            def call(task_ref:, **options)
              # Display config summary unless quiet mode
              display_config_summary(options) unless quiet?(options)

              # Validate field arguments
              field_args = options[:field]
              if field_args.nil? || field_args.empty?
                puts "Error: At least one --field argument required"
                puts ""
                puts "Usage: ace-taskflow task update <reference> --field <key=value> [--field <key2=value2>]"
                puts ""
                puts "Examples:"
                puts "  ace-taskflow task update 090 --field priority=high"
                puts "  ace-taskflow task update 090 --field worktree.branch=feature-name"
                puts "  ace-taskflow task update 090 --field priority=high --field estimate='2 weeks'"
                raise Ace::Core::CLI::Error.new("At least one --field argument required")
              end

              # Parse field updates
              begin
                field_updates = Ace::Taskflow::Molecules::TaskFieldUpdater.parse_field_updates(field_args)
              rescue Ace::Taskflow::Molecules::TaskFieldUpdater::FieldUpdateError => e
                puts ""
                puts "Expected format: --field key=value"
                puts "Examples:"
                puts "  --field priority=high"
                puts "  --field 'estimate=2 weeks'"
                puts "  --field worktree.branch=feature-name"
                raise Ace::Core::CLI::Error.new(e.message)
              end

              # Call TaskManager
              manager = Ace::Taskflow::Organisms::TaskManager.new
              result = manager.update_task_fields(task_ref, field_updates)

              unless result[:success]
                raise Ace::Core::CLI::Error.new(result[:message])
              end

              puts "Task updated: #{result[:task][:id] || task_ref}"
              puts "Updated fields:"
              result[:updated_fields].each do |field|
                value = field_updates[field]
                puts "  #{field}: #{value.inspect}"
              end
              puts "Task path: #{result[:path]}"
            end

            private

            # Display config summary
            def display_config_summary(options)
              return unless verbose?(options)

              Ace::Core::Atoms::ConfigSummary.display(
                command: "task update",
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
