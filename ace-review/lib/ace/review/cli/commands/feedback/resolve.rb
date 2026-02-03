# frozen_string_literal: true

require "dry/cli"
require "ace/core"

module Ace
  module Review
    module CLI
      module Commands
        module FeedbackSubcommands
          # dry-cli Command class for feedback resolve
          #
          # Resolves a pending feedback item by marking it as done.
          class Resolve < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc <<~DESC.strip
              Resolve a pending feedback item

              Marks a pending feedback item as done and archives it.
              A resolution description is required to document how the issue was addressed.
            DESC

            example [
              'abc123 --resolution "Fixed in commit def456"',
              'abc123 --resolution "Added input validation in UserController"',
              'abc123 --resolution "Refactored to use parameterized queries"',
              'abc123 --resolution "Fixed" --session .cache/ace-review/sessions/review-xyz'
            ]

            argument :id, required: true, desc: "Feedback ID"
            option :resolution, type: :string, required: true, desc: "How the issue was resolved"
            option :session, type: :string, desc: "Session directory containing feedback"

            # Standard options
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress status messages"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

            def call(id:, **options)
              # Validate resolution is provided
              unless options[:resolution] && !options[:resolution].strip.empty?
                raise Ace::Core::CLI::Error.new("Resolution is required. Use --resolution to describe how the issue was fixed.")
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

              # Resolve the item
              manager = Organisms::FeedbackManager.new
              result = manager.resolve(
                base_path,
                resolved_id,
                resolution: options[:resolution].strip
              )

              if result[:success]
                puts "Feedback #{resolved_id} resolved and archived."
                puts "Resolution: #{options[:resolution]}" unless quiet?(options)
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
