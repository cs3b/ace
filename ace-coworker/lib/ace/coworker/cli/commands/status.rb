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
                if result[:current].context
                  puts "Context: #{result[:current].context}"
                end
                puts

                if result[:current].fork?
                  # Fork context: output Task tool instructions
                  print_fork_instructions(result[:current], result[:session])
                else
                  puts "Instructions:"
                  puts result[:current].instructions
                end
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

          # Print Task tool instructions for a fork context job
          def print_fork_instructions(step, session)
            escaped_name = step.name.gsub('"', '\\"')
            # Derive project root from cache_dir: /project/.cache/ace-coworker/session-id -> /project
            project_root = session.cache_dir ? File.expand_path("../../..", session.cache_dir) : Dir.pwd

            puts "Execute this job in a forked context:"
            puts
            puts "  Task tool parameters:"
            puts "    description: \"#{escaped_name}\""
            puts "    prompt: (see below)"
            puts
            puts "  Prompt for forked agent:"
            puts "  ========================"
            puts step.instructions
            puts "  ========================"
            puts
            puts "  Working directory: #{project_root}"
            puts "  Session: #{session.id}"
            puts
            puts "After completing, create a report file and run:"
            puts "  ace-coworker report <report-file.md>"
          end
        end
      end
    end
  end
end
