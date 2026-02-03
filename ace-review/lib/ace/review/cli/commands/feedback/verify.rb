# frozen_string_literal: true

require "dry/cli"
require "ace/core"

module Ace
  module Review
    module CLI
      module Commands
        module FeedbackSubcommands
          # dry-cli Command class for feedback verify
          #
          # Verifies a draft feedback item by marking it as valid or invalid.
          class Verify < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc <<~DESC.strip
              Verify a draft feedback item

              Marks a draft feedback item as either valid (moves to pending)
              or invalid (archives the item). You must specify either --valid
              or --invalid.
            DESC

            example [
              'abc123 --valid                    # Mark as valid (pending)',
              'abc123 --invalid                  # Mark as invalid (archived)',
              'abc123 --valid --research "Confirmed: code path is reachable"',
              'abc123 --invalid --research "False positive: handled elsewhere"',
              'abc123 --valid --session .cache/ace-review/sessions/review-xyz'
            ]

            argument :id, required: true, desc: "Feedback ID"
            option :valid, type: :boolean, desc: "Mark as valid (moves to pending)"
            option :invalid, type: :boolean, desc: "Mark as invalid (archives)"
            option :research, type: :string, desc: "Add research notes"
            option :session, type: :string, desc: "Session directory containing feedback"

            # Standard options
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress status messages"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

            def call(id:, **options)
              # Validate: must specify --valid or --invalid (but not both)
              if options[:valid] && options[:invalid]
                raise Ace::Core::CLI::Error.new("Cannot specify both --valid and --invalid.")
              end

              unless options[:valid] || options[:invalid]
                raise Ace::Core::CLI::Error.new("Must specify either --valid or --invalid.")
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
                valid: options[:valid] == true,
                research: options[:research]
              )

              if result[:success]
                status = options[:valid] ? "valid (pending)" : "invalid (archived)"
                puts "Feedback #{resolved_id} marked as #{status}."
                puts "Research: #{options[:research]}" if options[:research] && !quiet?(options)
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
