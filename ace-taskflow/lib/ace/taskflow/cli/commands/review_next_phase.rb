# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../../organisms/next_phase_simulation_runner"

module Ace
  module Taskflow
    module CLI
      module Commands
        # Runs next-phase simulation and persists cache artifacts for auditability.
        class ReviewNextPhase < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc <<~DESC.strip
            Run next-phase simulation and persist cache artifacts

            SYNTAX:
              ace-taskflow review-next-phase --source <idea|task-ref|path> [--modes draft,plan] [--no-writeback]

            EXAMPLES:
              $ ace-taskflow review-next-phase --source 285.01 --modes plan --no-writeback
              $ ace-taskflow review-next-phase --source 8poz4f --modes draft,plan
          DESC

          option :source, type: :string, desc: "Source idea/task reference or artifact path"
          option :modes, type: :string, desc: "Comma-separated simulation modes (draft, plan, work)"
          option :next_phase_modes, type: :string, desc: "Override next-phase modes (draft,plan,work)"
          option :next_phase_review, type: :boolean, desc: "Force-enable next-phase simulation"
          option :no_next_phase_review, type: :boolean, desc: "Force-disable next-phase simulation"
          option :auto_trigger, type: :boolean, desc: "Apply auto-trigger policy instead of manual execution"
          option :no_writeback, type: :boolean, desc: "Disable write-back and generate preview only"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(**options)
            source = options[:source]
            if source.nil? || source.strip.empty?
              raise Ace::Core::CLI::Error.new("Missing required option: --source")
            end

            modes = modes_option(options)
            result = runner.run(
              source: source,
              modes: modes,
              no_writeback: !!options[:no_writeback],
              manual: !options[:auto_trigger],
              cli_enable: !!options[:next_phase_review],
              cli_disable: !!options[:no_next_phase_review]
            )

            output_result(result, quiet: !!options[:quiet], verbose: !!options[:verbose])
          rescue ArgumentError => e
            raise Ace::Core::CLI::Error.new(e.message)
          rescue StandardError => e
            raise Ace::Core::CLI::Error.new("Next-phase simulation failed: #{e.message}")
          end

          private

          def runner
            @runner ||= Organisms::NextPhaseSimulationRunner.new
          end

          def modes_option(options)
            options[:next_phase_modes] || options[:modes]
          end

          def output_result(result, quiet:, verbose:)
            if result[:skipped]
              if quiet
                puts "skipped"
                return
              end

              puts "Simulation skipped"
              puts "Reason: #{result[:reason]}"
              return
            end

            if quiet
              puts result[:run_id]
              return
            end

            puts "Simulation run complete"
            puts "Run ID: #{result[:run_id]}"
            puts "Session directory: #{result[:session_dir]}"
            puts "Summary: #{result[:summary_path]}"

            if verbose
              puts "Artifacts:"
              Array(result.dig(:session, :artifacts, :stages)).each { |stage| puts "  - #{stage}" }
              puts "  - #{result.dig(:session, :artifacts, :request)}"
              puts "  - #{result.dig(:session, :artifacts, :synthesis)}"
              puts "  - #{result.dig(:session, :artifacts, :writeback_preview)}"
              puts "  - #{result.dig(:session, :artifacts, :summary)}"
            end
          end
        end
      end
    end
  end
end
