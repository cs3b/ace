# frozen_string_literal: true

module Ace
  module Overseer
    module CLI
      module Commands
        class Prune < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Clean up completed task worktrees"

          option :yes, aliases: ["-y"], type: :boolean, default: false, desc: "Skip confirmation"
          option :dry_run, type: :boolean, default: false, desc: "Show candidates only"
          option :quiet, aliases: ["-q"], type: :boolean, default: false, desc: "Suppress output"
          option :debug, aliases: ["-d"], type: :boolean, default: false, desc: "Enable debug output"

          def initialize(orchestrator: nil, input: $stdin, output: $stdout)
            super()
            @orchestrator = orchestrator || Organisms::PruneOrchestrator.new
            @input = input
            @output = output
          end

          def call(**options)
            result = @orchestrator.call(
              dry_run: options[:dry_run],
              yes: options[:yes],
              input: @input,
              output: @output
            )

            return if options[:quiet]

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
            raise Ace::Core::CLI::Error.new(e.message)
          end

          private

          def print_dry_run(result)
            puts "Candidates for cleanup:"
            if result[:safe].empty?
              puts "  (none)"
            else
              result[:safe].each do |candidate|
                puts "  task.#{candidate.task_id} - #{candidate.worktree_path}"
              end
            end
            puts
            puts "#{result[:safe].length} worktree(s) can be safely pruned."
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
