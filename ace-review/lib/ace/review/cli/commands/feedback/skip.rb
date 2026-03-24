# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "session_discovery"

module Ace
  module Review
    module CLI
      module Commands
        module FeedbackSubcommands
          # ace-support-cli Command class for feedback skip
          #
          # Skips a feedback item (marks as not applicable).
          class Skip < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base
            include SessionDiscovery

            desc <<~DESC.strip
              Skip a feedback item (DEPRECATED - use verify --skip)

              [DEPRECATED] This command is deprecated. Use: verify --skip --research "..."

              Marks a draft or pending feedback item as skipped and archives it.
              Use when the finding is correct but you are not fixing it in this context.

              Examples of when to skip:
                - Design decision: Intentionally choosing this approach
                - Deferred: Correct issue, but tracking in a separate task
                - Duplicate: Already covered by another feedback item

              For false positives (incorrect findings), use: verify --invalid
            DESC

            example [
              "[DEPRECATED] Use: verify --skip instead",
              "abc123                                                   # Skip without reason",
              'abc123 --reason "Design: using polling for simplicity"  # Design decision',
              'abc123 --reason "Tracked in task 253"                    # Deferred to separate task',
              'abc123 --reason "Duplicate of abc120"                    # Already covered',
              "abc123 --session .ace-local/review/sessions/review-xyz"
            ]

            argument :id, required: true, desc: "Feedback ID"
            option :reason, type: :string, desc: "Reason for skipping (aliased to research)"
            option :research, type: :string, desc: "Research notes (preferred over --reason)"
            option :session, type: :string, desc: "Session directory containing feedback"

            # Standard options
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

            def call(id:, **options)
              # Show deprecation warning (unless quiet)
              unless quiet?(options)
                puts "[DEPRECATED] 'skip' command is deprecated. Use: verify --skip --research \"...\""
              end

              # Map --reason to --research for consistency
              research = options[:research] || options[:reason]

              # Resolve feedback path from session context
              base_path = resolve_feedback_path(options)

              unless base_path
                raise Ace::Support::Cli::Error.new("No session found. Run a review first or use --session to specify path.")
              end

              debug_log("Feedback base path: #{base_path}", options)

              # Find item first for partial ID matching
              resolved_id = resolve_full_id(base_path, id)

              unless resolved_id
                raise Ace::Support::Cli::Error.new("Feedback item not found: #{id}")
              end

              # Skip the item using the new verify method with skip: true
              manager = Organisms::FeedbackManager.new
              result = manager.verify(
                base_path,
                resolved_id,
                skip: true,
                research: research
              )

              if result[:success]
                puts "Feedback #{resolved_id} skipped and archived."
                puts "Research: #{research}" if research && !quiet?(options)
              else
                raise Ace::Support::Cli::Error.new(result[:error])
              end
            end

            private

            # Resolve partial ID to full ID
            def resolve_full_id(base_path, partial_id)
              manager = Organisms::FeedbackManager.new
              feedback_dir = manager.directory_manager.feedback_path(base_path)
              return nil unless Dir.exist?(feedback_dir)

              # Find files matching ID pattern
              pattern = File.join(feedback_dir, "#{partial_id}*.s.md")
              files = Dir.glob(pattern)

              if files.length > 1
                raise Ace::Support::Cli::Error.new(
                  "Multiple items match '#{partial_id}': #{files.map { |f| File.basename(f).split("-").first }.join(", ")}. " \
                  "Please provide more characters."
                )
              end

              return nil if files.empty?

              # Extract full ID from filename
              File.basename(files.first).split("-").first
            end
          end
        end
      end
    end
  end
end
