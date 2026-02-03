# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require "json"

module Ace
  module Review
    module CLI
      module Commands
        module FeedbackSubcommands
          # dry-cli Command class for feedback list
          #
          # Lists feedback items with optional filters.
          class List < Dry::CLI::Command
            include Ace::Core::CLI::DryCli::Base

            desc <<~DESC.strip
              List feedback items with optional filters

              Displays feedback items from the current task context or specified task.
              By default shows active (non-archived) items in table format.
            DESC

            example [
              '                           # List all active items (latest session)',
              '--status pending           # Filter by status',
              '--priority high            # Filter by priority',
              '--status pending --priority critical',
              '--archived                 # Include archived items',
              '--format json              # Output as JSON',
              '--session .cache/ace-review/sessions/review-abc123  # From specific session'
            ]

            option :status, type: :string, desc: "Filter by status (draft/pending/invalid/skip/done)"
            option :priority, type: :string, desc: "Filter by priority (critical/high/medium/low)"
            option :session, type: :string, desc: "Session directory containing feedback"
            option :archived, type: :boolean, default: false, desc: "Include archived items"
            option :format, type: :string, default: "table", desc: "Output format (table/json)"

            # Standard options
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress status messages"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

            def call(**options)
              # Resolve feedback path from session or task context
              base_path = resolve_feedback_path(options)

              unless base_path
                raise Ace::Core::CLI::Error.new("Could not determine feedback path. Use --session or --task to specify context.")
              end

              debug_log("Feedback base path: #{base_path}", options)

              # Get feedback manager
              manager = Organisms::FeedbackManager.new

              # List items with filters
              items = manager.list(
                base_path,
                status: options[:status],
                priority: options[:priority]
              )

              # Include archived items if requested
              if options[:archived]
                archive_dir = manager.directory_manager.archive_path(base_path)
                if Dir.exist?(archive_dir)
                  archived_items = manager.file_reader.read_all(archive_dir)
                  # Apply filters to archived items
                  archived_items = archived_items.select { |i| i.status == options[:status] } if options[:status]
                  archived_items = archived_items.select { |i| i.priority == options[:priority] } if options[:priority]
                  items.concat(archived_items)
                end
              end

              # Sort by ID (chronological)
              items.sort_by!(&:id)

              # Output in requested format
              case options[:format]
              when "json"
                output_json(items)
              else
                output_table(items, options)
              end
            end

            private

            # Resolve feedback path from session context
            #
            # Priority:
            # 1. --session flag (explicit session directory)
            # 2. Most recent session in cache directory (default)
            #
            # @param options [Hash] Command options
            # @return [String, nil] Base path for feedback directory
            def resolve_feedback_path(options)
              # Check explicit session flag first
              if options[:session]
                session_path = File.expand_path(options[:session])
                return session_path if Dir.exist?(session_path)

                raise Ace::Core::CLI::Error.new("Session not found: #{session_path}")
              end

              # Default: use most recent session
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

            # Output items as table
            def output_table(items, options)
              if items.empty?
                puts "No feedback items found."
                return
              end

              # Header
              puts format("%-8s %-8s %-10s %s", "ID", "STATUS", "PRIORITY", "TITLE")
              puts "-" * 60

              # Rows
              items.each do |item|
                # Truncate title if too long
                title = item.title.to_s
                title = title[0..38] + "..." if title.length > 41

                puts format("%-8s %-8s %-10s %s", item.id, item.status, item.priority, title)
              end

              # Summary
              puts
              puts "Total: #{items.length} item(s)"
            end

            # Output items as JSON
            def output_json(items)
              json_items = items.map(&:to_h)
              puts JSON.pretty_generate(json_items)
            end
          end
        end
      end
    end
  end
end
