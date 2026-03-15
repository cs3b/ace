# frozen_string_literal: true

module Ace
  module Assign
    module CLI
      module Commands
        # Complete in-progress phase with report content
        class Finish < Ace::Support::Cli::Command
          include Ace::Core::CLI::Base
          include AssignmentTarget

          desc "Complete in-progress phase with report content"

          argument :step, required: false, desc: "Phase number to finish (active assignment only)"
          option :message, aliases: ["-m"], desc: "Report content: string, file path, or pipe stdin"
          option :assignment, desc: "Target specific assignment ID"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def call(step: nil, **options)
            if step && options[:assignment]
              raise Error, "Positional STEP targeting is only supported for active assignment. Use --assignment without STEP for cross-assignment finish."
            end

            target = resolve_assignment_target(options)
            executor = build_executor_for_target(target)
            report_content = resolve_report_content(options)
            result = executor.finish_phase(
              report_content: report_content,
              phase_number: step,
              fork_root: target.scope
            )

            return if options[:quiet]

            completed = result[:completed]
            puts "Phase #{completed.number} (#{completed.name}) completed"

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
              fork_root = target.scope&.strip
              if fork_root && result[:state].subtree_complete?(fork_root)
                puts "Fork subtree #{fork_root} completed."
              elsif result[:state].complete?
                puts "Assignment completed! All phases done."
              else
                puts "No active phase selected."
              end
            end
          end

          private

          def resolve_report_content(options)
            message = options[:message]&.strip
            return File.read(message) if message && !message.empty? && File.exist?(message)
            return message if message && !message.empty?

            content = read_stdin_if_piped

            raise Error, "Missing report input: provide --message <string|file> or pipe stdin." if content.nil? || content.strip.empty?

            content
          end

          def read_stdin_if_piped
            stdin = $stdin
            return nil unless stdin.respond_to?(:tty?) && !stdin.tty?

            stdin.read
          rescue IOError, Errno::EBADF
            nil
          end
        end
      end
    end
  end
end
