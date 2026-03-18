# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Create a new workflow assignment from config file
        class Create < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Create a new workflow assignment from YAML config"

          argument :config, required: true, desc: "Path to job.yaml config file"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(config:, **options)
            executor = Organisms::AssignmentExecutor.new
            result = executor.start(config)

            unless options[:quiet]
              print_assignment_header(result[:assignment])
              print_step_instructions(result[:current])
            end
          end

          private

          def print_assignment_header(assignment)
            puts "Assignment: #{assignment.name} (#{assignment.id})"
            puts "Created: #{display_path(assignment.cache_dir)}/"
            if hidden_spec_path?(assignment.source_config)
              puts "Created from hidden spec: #{display_path(assignment.source_config)}"
            end
            puts
          end

          def hidden_spec_path?(path)
            expanded = File.expand_path(path.to_s).tr("\\", "/")
            expanded.include?("/.ace-local/assign/jobs/")
          end

          def display_path(path)
            expanded = File.expand_path(path.to_s).tr("\\", "/")
            cwd = Dir.pwd.tr("\\", "/")
            return expanded unless expanded.start_with?("#{cwd}/")

            expanded.delete_prefix("#{cwd}/")
          end

          def print_step_instructions(step)
            return unless step

            puts "Step #{step.number}: #{step.name} [#{step.status}]"
            puts
            puts "Instructions:"
            puts step.instructions
          end
        end
      end
    end
  end
end
