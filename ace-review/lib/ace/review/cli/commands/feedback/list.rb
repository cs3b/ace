# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require "json"
require_relative "session_discovery"

module Ace
  module Review
    module CLI
      module Commands
        module FeedbackSubcommands
          # ace-support-cli Command class for feedback list
          #
          # Lists feedback items with optional filters.
          class List < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base
            include SessionDiscovery

            desc <<~DESC.strip
              List feedback items with optional filters

              Displays feedback items from the latest review session or specified session.
              By default shows active (non-archived) items in table format.
            DESC

            example [
              "                           # List all active items (latest session)",
              "--status pending           # Filter by status",
              "--priority high            # Filter by priority",
              "--status pending --priority critical",
              "--archived                 # Include archived items",
              "--format json              # Output as JSON",
              "--session .ace-local/review/sessions/review-abc123  # From specific session",
              "--session all              # List from all sessions"
            ]

            option :status, type: :string, desc: "Filter by status (draft/pending/invalid/skip/done)"
            option :priority, type: :string, desc: "Filter by priority (critical/high/medium/low, append + for 'and higher')"
            option :session, type: :string, desc: "Session directory or 'all' for all sessions"
            option :archived, type: :boolean, default: false, desc: "Include archived items"
            option :format, type: :string, default: "table", desc: "Output format (table/json)"

            # Standard options
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

            def call(**options)
              # Handle --session all
              if options[:session] == "all"
                call_all_sessions(options)
                return
              end

              # Resolve feedback path from session context
              base_path = resolve_feedback_path(options)

              unless base_path
                raise Ace::Support::Cli::Error.new("Could not determine feedback path. Use --session to specify a review session.")
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

              # Get archived count for summary (always, for UX awareness)
              archived_count = count_archived_items(base_path, manager)

              # Include archived items if requested
              if options[:archived]
                archive_dir = manager.directory_manager.archive_path(base_path)
                if Dir.exist?(archive_dir)
                  archived_items = manager.file_reader.read_all(archive_dir)
                  # Apply filters to archived items
                  archived_items = archived_items.select { |i| i.status == options[:status] } if options[:status]
                  archived_items = archived_items.select { |i| Atoms::PriorityFilter.matches?(i.priority, options[:priority]) } if options[:priority]
                  items.concat(archived_items)
                end
              end

              # Sort by status priority, then by ID (chronological)
              items.sort_by! { |item| [status_sort_order(item.status), item.id] }

              # Output in requested format
              case options[:format]
              when "json"
                output_json(items)
              else
                output_table(items, archived_count, options)
              end
            end

            # Handle --session all: aggregate feedback from all sessions
            #
            # @param options [Hash] Command options
            def call_all_sessions(options)
              sessions = find_all_sessions

              if sessions.empty?
                puts "No sessions found."
                return
              end

              debug_log("Found #{sessions.length} sessions", options)

              manager = Organisms::FeedbackManager.new
              all_items = []
              total_archived = 0

              sessions.each do |session_path|
                session_name = File.basename(session_path)

                # List items with filters
                items = manager.list(
                  session_path,
                  status: options[:status],
                  priority: options[:priority]
                )

                # Tag items with session name
                items.each { |item| item.instance_variable_set(:@_session_name, session_name) }

                # Get archived count
                total_archived += count_archived_items(session_path, manager)

                # Include archived items if requested
                if options[:archived]
                  archive_dir = manager.directory_manager.archive_path(session_path)
                  if Dir.exist?(archive_dir)
                    archived_items = manager.file_reader.read_all(archive_dir)
                    archived_items = archived_items.select { |i| i.status == options[:status] } if options[:status]
                    archived_items = archived_items.select { |i| Atoms::PriorityFilter.matches?(i.priority, options[:priority]) } if options[:priority]
                    archived_items.each { |item| item.instance_variable_set(:@_session_name, session_name) }
                    items.concat(archived_items)
                  end
                end

                all_items.concat(items)
              end

              # Sort by status priority, then by ID
              all_items.sort_by! { |item| [status_sort_order(item.status), item.id] }

              # Output in requested format
              case options[:format]
              when "json"
                output_json_all_sessions(all_items)
              else
                output_table_all_sessions(all_items, total_archived, options)
              end
            end

            private

            # Count archived items for UX awareness
            #
            # @param base_path [String] Base path for feedback directory
            # @param manager [Organisms::FeedbackManager] Feedback manager instance
            # @return [Integer] Count of archived items
            def count_archived_items(base_path, manager)
              archive_dir = manager.directory_manager.archive_path(base_path)
              return 0 unless Dir.exist?(archive_dir)

              Dir.glob(File.join(archive_dir, "*.s.md")).count
            end

            # Status sort order for display
            # Priority: draft, pending, done, skip, invalid (unknown statuses at end)
            STATUS_SORT_ORDER = {
              "draft" => 0,
              "pending" => 1,
              "done" => 2,
              "skip" => 3,
              "invalid" => 4
            }.freeze

            # Get sort order for a status
            #
            # @param status [String] Status value
            # @return [Integer] Sort order (unknown statuses sort last)
            def status_sort_order(status)
              STATUS_SORT_ORDER.fetch(status.to_s, 99)
            end

            # Output items as table
            def output_table(items, archived_count, options)
              if items.empty?
                if archived_count > 0
                  puts "No active feedback items. #{archived_count} archived item(s) exist."
                  puts "Use --archived to include them."
                else
                  puts "No feedback items found."
                end
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

              # Summary with archived hint
              puts
              archived_hint = (archived_count > 0 && !options[:archived]) ? " (#{archived_count} archived)" : ""
              puts "Total: #{items.length} item(s)#{archived_hint}"
            end

            # Output items as JSON
            def output_json(items)
              json_items = items.map(&:to_h)
              puts JSON.pretty_generate(json_items)
            end

            # Output all sessions items as table
            def output_table_all_sessions(items, archived_count, options)
              if items.empty?
                if archived_count > 0
                  puts "No active feedback items. #{archived_count} archived item(s) exist across all sessions."
                  puts "Use --archived to include them."
                else
                  puts "No feedback items found across all sessions."
                end
                return
              end

              # Header with SESSION column
              puts format("%-14s %-8s %-8s %-10s %s", "SESSION", "ID", "STATUS", "PRIORITY", "TITLE")
              puts "-" * 72

              # Rows
              items.each do |item|
                session_name = item.instance_variable_get(:@_session_name) || "unknown"
                # Truncate session name if too long
                session_name = session_name[0..11] + ".." if session_name.length > 13

                # Truncate title if too long
                title = item.title.to_s
                title = title[0..28] + "..." if title.length > 31

                puts format("%-14s %-8s %-8s %-10s %s", session_name, item.id, item.status, item.priority, title)
              end

              # Summary with archived hint
              puts
              archived_hint = (archived_count > 0 && !options[:archived]) ? " (#{archived_count} archived)" : ""
              puts "Total: #{items.length} item(s)#{archived_hint}"
            end

            # Output all sessions items as JSON
            def output_json_all_sessions(items)
              json_items = items.map do |item|
                h = item.to_h
                h[:session] = item.instance_variable_get(:@_session_name)
                h
              end
              puts JSON.pretty_generate(json_items)
            end
          end
        end
      end
    end
  end
end
