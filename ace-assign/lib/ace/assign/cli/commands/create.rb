# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Create a new workflow assignment from YAML or preset-backed task refs
        class Create < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Create a new workflow assignment"

          option :yaml, desc: "Path to job.yaml config file"
          option :task, aliases: ["-t"], type: :array,
            desc: "Task reference(s), repeatable and comma-separated"
          option :preset, aliases: ["-p"], desc: "Assignment preset name (task mode only)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(yaml: nil, task: nil, preset: nil, **options)
            validate_modes!(yaml, task, preset)

            result = if yaml
              Organisms::AssignmentExecutor.new.start(yaml)
            else
              Organisms::TaskAssignmentCreator.new.call(
                task_refs: task,
                preset_name: preset || Organisms::TaskAssignmentCreator::DEFAULT_PRESET
              )
            end

            unless options[:quiet]
              print_terminal_skip_summary(result[:skipped_terminal])
              print_assignment_header(result[:assignment])
              print_step_instructions(result[:current])
            end
          end

          private

          def validate_modes!(yaml, task, preset)
            task_refs = Array(task).flat_map { |entry| entry.to_s.split(",") }.map(&:strip).reject(&:empty?)
            selected = 0
            selected += 1 if yaml && !yaml.to_s.strip.empty?
            selected += 1 if task_refs.any?

            raise Ace::Support::Cli::Error, "Exactly one of --yaml or --task is required" if selected.zero?
            raise Ace::Support::Cli::Error, "--yaml and --task are mutually exclusive" if selected > 1
            raise Ace::Support::Cli::Error, "--preset requires --task" if preset && task_refs.empty?
          end

          def print_terminal_skip_summary(skipped_terminal)
            return if skipped_terminal.nil? || skipped_terminal.empty?

            puts "Skipped terminal tasks (done/skipped/cancelled): #{skipped_terminal.join(', ')}"
          end

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
