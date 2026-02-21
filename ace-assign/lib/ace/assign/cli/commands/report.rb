# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Complete current phase with a report file
        class Report < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base
          include AssignmentTarget

          desc "Complete current phase with report content"

          argument :file, required: true, desc: "Path to report file"
          option :assignment, desc: "Target specific assignment ID"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Enable debug output"

          def call(file:, **options)
            target = resolve_assignment_target(options)
            executor = build_executor_for_target(target)
            result = executor.advance(file)

            unless options[:quiet]
              completed = result[:completed]
              if completed.nil?
                fork_root = ENV["ACE_ASSIGN_FORK_ROOT"]&.strip
                puts "Fork subtree #{fork_root} already complete. Nothing to advance."
              else
                puts "Phase #{completed.number} (#{completed.name}) completed"
                # Report the actual report file path, not the phase file
                assignment = result[:assignment]
                report_filename = Atoms::PhaseFileParser.generate_report_filename(completed.number, completed.name)
                report_path = File.join(assignment.reports_dir, report_filename)
                puts "Report saved to: #{report_path}"

                if result[:current]
                  puts "Advancing to phase #{result[:current].number}: #{result[:current].name}"
                  puts
                  puts "Instructions:"
                  puts result[:current].instructions
                else
                  puts
                  fork_root = ENV["ACE_ASSIGN_FORK_ROOT"]&.strip
                  if fork_root && result[:state].subtree_complete?(fork_root)
                    puts "Fork subtree #{fork_root} completed."
                  elsif result[:state].complete?
                    puts "Assignment completed! All phases done."
                  else
                    puts "No active phase selected."
                  end
                end
              end
            end
          end

          private
        end
      end
    end
  end
end
