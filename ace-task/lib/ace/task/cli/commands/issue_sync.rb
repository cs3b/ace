# frozen_string_literal: true

require "ace/support/cli"

module Ace
  module Task
    module CLI
      module Commands
        class IssueSync < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc "Synchronize the exact stored issue link for one task or a selected task set"
          argument :ref, required: false, desc: "Task reference"
          option :all, type: :boolean, desc: "Sync all linked tasks"
          option :pending, type: :boolean, desc: "Replay deferred issue synchronization"

          def call(ref: nil, **options)
            if options[:all] && options[:pending] || ref && (options[:all] || options[:pending])
              raise Ace::Support::Cli::Error, "Choose REF, --all, or --pending"
            end
            unless ref || options[:all] || options[:pending]
              raise Ace::Support::Cli::Error, "Provide REF, --all, or --pending"
            end
            result = Ace::Task::Organisms::TaskManager.new.issue_sync(
              ref: ref, all: options[:all], pending: options[:pending]
            )
            raise Ace::Support::Cli::Error, "Task #{ref.inspect} not found" unless result

            Array(result[:failures]).each do |failure|
              warn "Issue sync failed for #{failure[:task_id]} (#{failure[:remote_issues].inspect}): #{failure[:error]}"
            end
            summary = "Issue sync: synced #{result[:synced]}, failed #{result[:failed]}, " \
              "pending #{result[:pending]}, skipped #{result[:skipped]}"
            raise Ace::Support::Cli::Error, summary if result[:failed].positive? || result[:pending].positive?

            puts summary
          end
        end
      end
    end
  end
end
