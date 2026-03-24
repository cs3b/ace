# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "session_discovery"

module Ace
  module Review
    module CLI
      module Commands
        module FeedbackSubcommands
          # ace-support-cli Command class for feedback show
          #
          # Displays detailed information about a feedback item.
          class Show < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base
            include SessionDiscovery

            desc <<~DESC.strip
              Show detailed information about a feedback item

              Displays full content including finding, context, research notes,
              and resolution (if any). Supports partial ID matching with minimum
              3 characters.
            DESC

            example [
              "abc123                     # Show by full ID (latest session)",
              "abc                        # Show by partial ID (min 3 chars)",
              "abc123 --session .ace-local/review/sessions/review-xyz  # From specific session"
            ]

            argument :id, required: true, desc: "Feedback ID (minimum 3 characters for partial match)"
            option :session, type: :string, desc: "Session directory containing feedback"

            # Standard options
            option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
            option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
            option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

            def call(id:, **options)
              # Validate ID length
              if id.length < 3
                raise Ace::Support::Cli::Error.new("ID must be at least 3 characters for matching.")
              end

              # Resolve feedback path from session context
              base_path = resolve_feedback_path(options)

              unless base_path
                raise Ace::Support::Cli::Error.new("No session found. Run a review first or use --session to specify path.")
              end

              debug_log("Feedback base path: #{base_path}", options)

              # Find item by ID (supports partial matching)
              item = find_item_by_id(base_path, id, include_archived: true)

              unless item
                raise Ace::Support::Cli::Error.new("Feedback item not found: #{id}")
              end

              display_item(item)
            end

            private

            # Find item by ID with partial matching
            #
            # @param base_path [String] Base path for feedback directory
            # @param id [String] Full or partial ID
            # @param include_archived [Boolean] Whether to search archived items
            # @return [Models::FeedbackItem, nil] Found item or nil
            def find_item_by_id(base_path, id, include_archived: false)
              manager = Organisms::FeedbackManager.new
              dir_manager = manager.directory_manager
              file_reader = manager.file_reader

              # Search in active directory
              feedback_dir = dir_manager.feedback_path(base_path)
              item = search_directory_for_id(feedback_dir, id, file_reader)
              return item if item

              # Search in archive if requested
              if include_archived
                archive_dir = dir_manager.archive_path(base_path)
                item = search_directory_for_id(archive_dir, id, file_reader) if Dir.exist?(archive_dir)
              end

              item
            end

            # Search a directory for an item matching the ID
            def search_directory_for_id(directory, id, file_reader)
              return nil unless Dir.exist?(directory)

              # Find files matching ID pattern (supports partial)
              pattern = File.join(directory, "#{id}*.s.md")
              files = Dir.glob(pattern)

              # If multiple matches, require more specific ID
              if files.length > 1
                raise Ace::Support::Cli::Error.new(
                  "Multiple items match '#{id}': #{files.map { |f| File.basename(f).split("-").first }.join(", ")}. " \
                  "Please provide more characters."
                )
              end

              return nil if files.empty?

              result = file_reader.read(files.first)
              result[:success] ? result[:feedback_item] : nil
            end

            # Display item details
            def display_item(item)
              puts "=" * 60
              puts "Feedback: #{item.id}"
              puts "=" * 60
              puts
              puts "Title:    #{item.title}"
              puts "Status:   #{status_with_icon(item.status)}"
              puts "Priority: #{item.priority}"
              puts "Reviewer: #{item.reviewer}"
              puts "Created:  #{item.created}"
              puts "Updated:  #{item.updated}"
              puts

              if item.files && !item.files.empty?
                puts "Files:"
                item.files.each { |f| puts "  - #{f}" }
                puts
              end

              if item.finding
                puts "--- Finding ---"
                puts item.finding
                puts
              end

              if item.context
                puts "--- Context ---"
                puts item.context
                puts
              end

              if item.research
                puts "--- Research ---"
                puts item.research
                puts
              end

              if item.resolution
                puts "--- Resolution ---"
                puts item.resolution
                puts
              end
            end

            # Status with emoji icon
            def status_with_icon(status)
              icon = case status
              when "draft" then "[D]"
              when "pending" then "[P]"
              when "invalid" then "[X]"
              when "skip" then "[S]"
              when "done" then "[+]"
              else "[?]"
              end
              "#{icon} #{status}"
            end
          end
        end
      end
    end
  end
end
