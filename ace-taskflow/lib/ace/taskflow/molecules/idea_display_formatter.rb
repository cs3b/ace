# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Pure logic for formatting idea display
      # Unit testable - no I/O
      class IdeaDisplayFormatter
        # Format context name for display
        # @param context [String] Context identifier
        # @return [String] Human-readable context name
        def self.context_name(context)
          case context
          when "current", "active"
            "current release"
          when "backlog"
            "backlog"
          else
            "release #{context}"
          end
        end

        # Format idea header information
        # @param idea [Hash] Idea data
        # @return [Array<String>] Header lines
        def self.format_idea_header(idea)
          lines = []
          lines << "Idea: #{idea[:id] || idea[:filename]}"
          lines << "Title: #{idea[:title]}" if idea[:title]
          lines << "Created: #{idea[:created_at]}" if idea[:created_at]
          lines << "Context: #{idea[:context]}" if idea[:context]
          lines
        end

        # Format idea display with content
        # @param idea [Hash] Idea data
        # @param include_content [Boolean] Whether to include content
        # @return [String] Complete formatted output
        def self.format_idea_display(idea, include_content: true)
          lines = format_idea_header(idea)

          if idea[:path]
            lines << "Path: #{idea[:path]}"
          end

          if include_content && idea[:content]
            lines << ""
            lines << "--- Content ---"
            lines << idea[:content]
          end

          lines.join("\n")
        end

        # Format capture confirmation message
        # @param path [String] Path to captured idea
        # @return [String] Confirmation message
        def self.format_capture_confirmation(path)
          "Idea captured: #{path}"
        end

        # Format idea done confirmation
        # @param reference [String] Idea reference
        # @param timestamp [Time] Completion timestamp
        # @return [Array<String>] Confirmation lines
        def self.format_done_confirmation(reference, timestamp = Time.now)
          [
            "Idea '#{reference}' marked as done and moved to done/",
            "Completed at: #{timestamp.strftime('%Y-%m-%d %H:%M:%S')}"
          ]
        end

        # Format "not found" error message
        # @param reference [String] Idea reference
        # @param context [String] Context where search was performed
        # @return [String] Error message
        def self.format_not_found_message(reference, context)
          "No idea found matching '#{reference}' in #{context_name(context)}."
        end

        # Format empty state message
        # @return [Array<String>] Empty state message lines
        def self.format_empty_state
          [
            "No ideas found in current release.",
            "Use 'ace-taskflow idea create' to capture a new idea."
          ]
        end
      end
    end
  end
end
