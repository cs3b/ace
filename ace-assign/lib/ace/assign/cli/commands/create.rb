# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Create a new workflow assignment from config file
        class Create < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Create a new workflow assignment from YAML config"

          argument :config, required: true, desc: "Path to job.yaml config file"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(config:, **options)
            executor = Organisms::AssignmentExecutor.new
            result = executor.start(config)

            unless options[:quiet]
              print_assignment_header(result[:assignment])
              print_phase_instructions(result[:current])
            end
          end

          private

          def print_assignment_header(assignment)
            puts "Assignment: #{assignment.name} (#{assignment.id})"
            puts "Created: #{assignment.cache_dir}/"
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
            expanded = File.expand_path(path.to_s)
            cwd = Dir.pwd
            return expanded unless expanded.start_with?("#{cwd}/")

            expanded.delete_prefix("#{cwd}/")
          end

          def print_phase_instructions(phase)
            return unless phase

            puts "Phase #{phase.number}: #{phase.name} [#{phase.status}]"
            puts
            puts "Instructions:"
            puts phase.instructions
          end
        end
      end
    end
  end
end
