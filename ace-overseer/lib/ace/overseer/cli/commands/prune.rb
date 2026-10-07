# frozen_string_literal: true

module Ace
  module Overseer
    module CLI
      module Commands
        class Prune < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Clean up completed task worktrees with executed preservation and no-writer proofs"

          argument :targets, required: false, type: :array, desc: "Task refs or folder names to prune"

          option :assignment, aliases: ["-a"], type: :string, desc: "Prune a specific assignment by ID"
          option :force, aliases: ["-f"], type: :boolean, default: false,
            desc: "Skip the confirmation prompt for already-safe candidates; never bypasses safety blocks"
          option :yes, aliases: ["-y"], type: :boolean, default: false, desc: "Skip confirmation"
          option :dry_run, type: :boolean, default: false, desc: "Show candidates only (no cleanup side effects)"
          option :quiet, aliases: ["-q"], type: :boolean, default: false,
            desc: "Suppress progress output; failures still print and signal via exit code"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Show debug output"
          option :preservation, type: :string,
            desc: "YAML manifest (version 1) declaring verified cross-repository destinations"

          def initialize(orchestrator: nil, input: $stdin, output: $stdout)
            super()
            @orchestrator = orchestrator || Organisms::PruneOrchestrator.new
            @input = input
            @output = output
          end

          def call(**options)
            raise Ace::Support::Cli::Error, "Prune uses the configured local runtime; protected physical cleanup has its own owner" if options.key?(:runtime)

            Atoms::RepoGuard.ensure_repo!

            targets = Array(options[:targets] || [])
            progress = options[:quiet] ? nil : ->(msg) { puts msg }
            result = @orchestrator.call(
              dry_run: options[:dry_run],
              yes: options[:yes],
              force: options[:force],
              targets: targets,
              assignment_id: options[:assignment],
              preservation_manifest: options[:preservation],
              input: @input,
              output: @output,
              on_progress: progress
            )

            if options[:assignment]
              print_assignment_result(result)
              return if options[:dry_run] || result[:aborted]

              raise Ace::Support::Cli::Error, "Assignment #{options[:assignment]} is blocked: " \
                "#{result[:assignment_candidate].reasons.join(", ")}" if result[:blocked]
              unless result[:pruned_assignments].any?
                raise Ace::Support::Cli::Error, "Failed to remove assignment #{options[:assignment]}"
              end

              return
            end

            if result[:dry_run]
              print_dry_run(result)
              return
            end

            puts "Prune aborted." if result[:aborted]
            return if result[:aborted]

            print_apply(result)

            blocked_count = Array(result[:unsafe]).length + Array(result[:blocked]).length +
              Array(result[:failed]).length
            return if blocked_count.zero?

            raise Ace::Support::Cli::Error,
              "#{blocked_count} candidate(s) blocked or failed; nothing unsafe was removed"
          rescue Ace::Overseer::Error => e
            raise Ace::Support::Cli::Error, e.message
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
              puts "Blocked: assignment #{candidate.assignment_id}: #{candidate.reasons.join(", ")}"
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
            puts "Candidates for cleanup:"
            if result[:safe].empty?
              puts "  (none)"
            else
              result[:safe].each do |candidate|
                puts "  task.#{candidate.task_id} - #{candidate.worktree_path}"
              end
            end
            if result[:unsafe].any?
              puts "Blocked candidates:"
              result[:unsafe].each do |candidate|
                puts "  task.#{candidate.task_id} - #{candidate.worktree_path}"
                candidate.reasons.each { |reason| puts "    - #{reason}" }
              end
            end
            puts
            puts "#{result[:safe].length} worktree(s) can be pruned; " \
              "#{result[:unsafe].length} blocked."
          end

          def print_apply(result)
            result[:pruned].each do |candidate|
              puts "Removed worktree task.#{candidate.task_id}"
            end
            Array(result[:unsafe]).each do |candidate|
              puts "Blocked: task.#{candidate.task_id}: #{candidate.reasons.join(", ")}"
            end
            Array(result[:blocked]).each do |entry|
              puts "Blocked after recheck: task.#{entry[:candidate].task_id}: #{entry[:reasons].join(", ")}"
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
