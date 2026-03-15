# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "session_discovery"

module Ace
  module Review
    module CLI
      module Commands
        module FeedbackSubcommands
          # ace-support-cli Command class for feedback verify
          #
          # Verifies a draft feedback item by marking it as valid or invalid.
          class Verify < Ace::Support::Cli::Command
            include Ace::Core::CLI::Base
            include SessionDiscovery

            desc <<~DESC.strip
              Verify a draft feedback item

              Marks a draft feedback item as valid, invalid, or skipped.

              Use --valid when: The finding is correct and needs to be fixed
              Use --invalid when: The finding is a false positive (factually incorrect)
              Use --skip when: The finding is correct but not being fixed

              Examples of --invalid (false positive):
                - Claimed code doesn't exist, but it does
                - Claimed missing validation, but it exists elsewhere
                - Claimed issue in CI, but code doesn't run in CI

              Examples of --skip (correct but not fixing):
                - Design decision: Intentionally choosing this approach
                - Deferred: Correct issue, but tracking in a separate task
                - Duplicate: Already covered by another feedback item
            DESC

            example [
              'abc123 --valid                                    # Correct issue, needs fix',
              'abc123 --invalid                                  # False positive (incorrect)',
              'abc123 --skip                                     # Correct but not fixing',
              'abc123 --valid --research "Confirmed: missing null check at line 42"',
              'abc123 --invalid --research "False positive: validation exists in middleware"',
              'abc123 --skip --research "Design: using polling for simplicity"',
              'abc123 --skip --research "Tracked in task 253"',
              'abc123 --skip --research "Duplicate of abc120"',
              'abc123 --valid --session .ace-local/review/sessions/review-xyz'
            ]

            argument :id, required: true, desc: "Feedback ID"
            option :valid, type: :boolean, desc: "Mark as valid (moves to pending)"
            option :invalid, type: :boolean, desc: "Mark as invalid (archives)"
            option :skip, type: :boolean, desc: "Mark as skipped (archives)"
            option :research, type: :string, desc: "Add research notes (what we learned/decided)"
            option :session, type: :string, desc: "Session directory containing feedback"

            # Standard options
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

            def call(id:, **options)
              # Validate: must specify exactly one of --valid, --invalid, or --skip
              mode_count = [options[:valid], options[:invalid], options[:skip]].count { |v| v }

              if mode_count > 1
                raise Ace::Core::CLI::Error.new("Cannot specify multiple modes. Use exactly one of: --valid, --invalid, --skip.")
              end

              unless mode_count == 1
                raise Ace::Core::CLI::Error.new("Must specify exactly one of: --valid, --invalid, --skip.")
              end

              # Resolve feedback path from session context
              base_path = resolve_feedback_path(options)

              unless base_path
                raise Ace::Core::CLI::Error.new("No session found. Run a review first or use --session to specify path.")
              end

              debug_log("Feedback base path: #{base_path}", options)

              # Find item first for partial ID matching
              resolved_id = resolve_full_id(base_path, id)

              unless resolved_id
                raise Ace::Core::CLI::Error.new("Feedback item not found: #{id}")
              end

              # Verify the item
              manager = Organisms::FeedbackManager.new
              result = manager.verify(
                base_path,
                resolved_id,
                valid: options[:valid] == true ? true : (options[:invalid] == true ? false : nil),
                skip: options[:skip] == true ? true : nil,
                research: options[:research]
              )

              if result[:success]
                status = if options[:valid]
                           "valid (pending)"
                         elsif options[:invalid]
                           "invalid (archived)"
                         else
                           "skipped (archived)"
                         end
                puts "Feedback #{resolved_id} marked as #{status}."
                puts "Research: #{options[:research]}" if options[:research] && !quiet?(options)
              else
                raise Ace::Core::CLI::Error.new(result[:error])
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
                raise Ace::Core::CLI::Error.new(
                  "Multiple items match '#{partial_id}': #{files.map { |f| File.basename(f).split('-').first }.join(', ')}. " \
                  "Please provide more characters."
                )
              end

              return nil if files.empty?

              # Extract full ID from filename
              File.basename(files.first).split('-').first
            end
          end
        end
      end
    end
  end
end
