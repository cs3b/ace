# frozen_string_literal: true

require "dry/cli"
require "ace/core"

module Ace
  module Review
    module CLI
      module Commands
        module FeedbackSubcommands
          # dry-cli Command class for feedback skip
          #
          # Skips a feedback item (marks as not applicable).
          class Skip < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc <<~DESC.strip
              Skip a feedback item (not applicable)

              Marks a draft or pending feedback item as skipped and archives it.
              Use when a finding is not applicable to the current context.
            DESC

            example [
              'abc123                           # Skip without reason (latest session)',
              'abc123 --reason "Out of scope"   # Skip with reason',
              'abc123 --reason "Technical debt, tracking separately"',
              'abc123 --session .cache/ace-review/sessions/review-xyz'
            ]

            argument :id, required: true, desc: "Feedback ID"
            option :reason, type: :string, desc: "Reason for skipping"
            option :session, type: :string, desc: "Session directory containing feedback"

            # Standard options
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress status messages"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

            def call(id:, **options)
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

              # Skip the item
              manager = Organisms::FeedbackManager.new
              result = manager.skip(
                base_path,
                resolved_id,
                reason: options[:reason]
              )

              if result[:success]
                puts "Feedback #{resolved_id} skipped and archived."
                puts "Reason: #{options[:reason]}" if options[:reason] && !quiet?(options)
              else
                raise Ace::Core::CLI::Error.new(result[:error])
              end
            end

            private

            # Resolve feedback path from session context
            #
            # @param options [Hash] Command options
            # @return [String, nil] Base path for feedback directory
            def resolve_feedback_path(options)
              # Explicit session path
              if options[:session]
                session_path = File.expand_path(options[:session])
                return session_path if Dir.exist?(session_path)

                raise Ace::Core::CLI::Error.new("Session not found: #{session_path}")
              end

              # Default: latest session
              find_latest_session
            end

            # Find the most recent session directory
            #
            # @return [String, nil] Path to latest session or nil
            def find_latest_session
              cache_dir = File.join(Dir.pwd, ".cache", "ace-review", "sessions")
              return nil unless Dir.exist?(cache_dir)

              sessions = Dir.glob(File.join(cache_dir, "review-*"))
                            .select { |p| File.directory?(p) }
              return nil if sessions.empty?

              sessions.max_by { |p| File.mtime(p) }
            end

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
