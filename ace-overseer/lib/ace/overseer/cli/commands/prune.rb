# frozen_string_literal: true

module Ace
  module Overseer
    module CLI
      module Commands
        class Prune < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Clean up completed task worktrees"

          argument :targets, required: false, type: :array, desc: "Task refs or folder names to prune"

          option :assignment, aliases: ["-a"], type: :string, desc: "Prune a specific assignment by ID"
          option :force, aliases: ["-f"], type: :boolean, default: false, desc: "Force-remove unsafe worktrees"
          option :yes, aliases: ["-y"], type: :boolean, default: false, desc: "Skip confirmation"
          option :dry_run, type: :boolean, default: false, desc: "Show candidates only"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress non-essential output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"

          def initialize(orchestrator: nil, input: $stdin, output: $stdout)
            super()
            @orchestrator = orchestrator || Organisms::PruneOrchestrator.new
            @input = input
            @output = output
          end

          def call(**options)
            targets = Array(options[:targets] || [])
            progress = options[:quiet] ? nil : ->(msg) { puts msg }
            result = @orchestrator.call(
              dry_run: options[:dry_run],
              yes: options[:yes],
              force: options[:force],
              targets: targets,
              assignment_id: options[:assignment],
              input: @input,
              output: @output,
              on_progress: progress
            )

            return if options[:quiet]

            if options[:assignment]
              print_assignment_result(result)
              return
            end

            if result[:dry_run]
              print_dry_run(result)
              return
            end

            if result[:aborted]
              puts "Prune aborted."
              return
            end

            print_apply(result)
          rescue StandardError => e
            raise Ace::Support::Cli::Error.new(e.message)
          end

          private

          def print_assignment_result(result)
            candidate = result[:assignment_candidate]
            if result[:dry_run]
              puts "Assignment: #{candidate.assignment_id} (#{candidate.assignment_name})"
              puts "  State: #{candidate.assignment_state}"
              puts "  Safe to prune: #{candidate.safe_to_prune? ? "yes" : "no"}"
              puts "  Reasons: #{candidate.reasons.join(", ")}" if candidate.reasons.any?
              return
            end

            if result[:aborted]
              puts "Prune aborted."
              return
            end

            if result[:blocked]
              return
            end

            pruned = result[:pruned_assignments]
            if pruned.any?
              puts "Removed assignment #{candidate.assignment_id}."
            else
              puts "Failed to remove assignment #{candidate.assignment_id}."
            end
          end

          def print_dry_run(result)
            forced = Array(result[:forced])
            puts "Candidates for cleanup:"
            if result[:safe].empty? && forced.empty?
              puts "  (none)"
            else
              result[:safe].each do |candidate|
                puts "  task.#{candidate.task_id} - #{candidate.worktree_path}"
              end
              forced.each do |candidate|
                puts "  task.#{candidate.task_id} - #{candidate.worktree_path} [FORCE]"
              end
            end
            puts
            total = result[:safe].length + forced.length
            puts "#{total} worktree(s) can be pruned."
          end

          def print_apply(result)
            result[:pruned].each do |candidate|
              puts "Removed worktree task.#{candidate.task_id}"
            end
            result[:failed].each do |entry|
              puts "Failed to remove task.#{entry[:candidate].task_id}: #{entry[:error]}"
            end
            puts "#{result[:pruned].length} worktree(s) pruned."
          end
        end
      end
    end
  end
end
