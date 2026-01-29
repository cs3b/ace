# frozen_string_literal: true

module Ace
  module Coworker
    module CLI
      module Commands
        # Display current queue status
        class Status < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Display current workflow queue status"

          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress detailed output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Enable debug output"

          def call(**options)
            executor = Organisms::WorkflowExecutor.new
            result = executor.status

            unless options[:quiet]
              print_queue_status(result[:session], result[:state])

              if result[:current]
                puts
                puts "Current Step: #{result[:current].number} - #{result[:current].name}"
                if result[:current].skill
                  puts "Skill: #{result[:current].skill}"
                end
                puts
                puts "Instructions:"
                puts result[:current].instructions
              elsif result[:state].complete?
                puts
                puts "Session completed!"
              end
            end
          end

          private

          def print_queue_status(session, state)
            puts "QUEUE - Session: #{session.name} (#{session.id})"
            puts

            # Calculate column widths
            file_width = [30, state.steps.map { |s| File.basename(s.file_path || "").length }.max || 20].max
            status_width = 12
            name_width = 20

            # Header
            puts format("%-#{file_width}s %-#{status_width}s %-#{name_width}s", "FILE", "STATUS", "NAME")

            # Rows
            state.steps.each do |step|
              file = File.basename(step.file_path || "#{step.number}-#{step.name}.j.md")
              status = format_status(step.status)
              name = step.name

              row = format("%-#{file_width}s %-#{status_width}s %-#{name_width}s", file, status, name)

              # Add error message for failed steps
              if step.status == :failed && step.error
                row += "  (#{step.error})"
              end

              puts row
            end
          end

          def format_status(status)
            case status
            when :done then "Done"
            when :in_progress then "In Progress"
            when :pending then "Pending"
            when :failed then "Failed"
            else status.to_s.capitalize
            end
          end
        end
      end
    end
  end
end
