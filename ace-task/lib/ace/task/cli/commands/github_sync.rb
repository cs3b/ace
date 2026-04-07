# frozen_string_literal: true

require "ace/support/cli"

module Ace
  module Task
    module CLI
      module Commands
        # ace-support-cli Command class for ace-task github-sync
        class GithubSync < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc <<~DESC.strip
            Synchronize linked GitHub issues for a task or all linked tasks
          DESC

          example [
            "q7w                         # Sync one task",
            "--all                       # Sync all linked tasks"
          ]

          argument :ref, required: false, desc: "Task reference (full ID, short ref, or suffix)"
          option :all, type: :boolean, aliases: %w[-a], desc: "Sync all linked tasks"

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(ref: nil, **options)
            all = options[:all]

            if !all && (ref.nil? || ref.strip.empty?)
              raise Ace::Support::Cli::Error.new("Provide a task reference or use --all")
            end

            manager = Ace::Task::Organisms::TaskManager.new
            result = manager.github_sync(ref: ref, all: all)
            raise Ace::Support::Cli::Error.new("Task '#{ref}' not found") if result.nil?
            print_failures(result[:failures])

            if result[:failed].to_i.positive?
              raise Ace::Support::Cli::Error.new(
                "GitHub sync incomplete: synced #{result[:synced]}, failed #{result[:failed]}, skipped #{result[:skipped]}"
              )
            elsif all
              puts "GitHub sync complete: synced #{result[:synced]} linked task(s), skipped #{result[:skipped]} task(s)"
            elsif result[:synced].positive?
              puts "GitHub sync complete: #{result[:task_id]}"
            else
              puts "No linked GitHub issues for task #{result[:task_id]}"
            end
          end

          private

          def print_failures(failures)
            Array(failures).each do |failure|
              warn "GitHub sync failed for #{failure[:task_id]}: #{failure[:error]}"
            end
          end
        end
      end
    end
  end
end
