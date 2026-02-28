# frozen_string_literal: true

module Ace
  module Idea
    module Molecules
      # Formats idea objects for terminal display.
      class IdeaDisplayFormatter
        STATUS_SYMBOLS = {
          "pending" => "⚪",
          "in-progress" => "🟡",
          "done" => "🟢",
          "obsolete" => "⚫"
        }.freeze

        # Format a single idea for display
        # @param idea [Idea] Idea to format
        # @param show_content [Boolean] Whether to include full content
        # @return [String] Formatted output
        def self.format(idea, show_content: false)
          status_sym = STATUS_SYMBOLS[idea.status] || "⚪"
          tags_str = idea.tags.any? ? " [#{idea.tags.join(", ")}]" : ""
          folder_str = idea.special_folder ? " (#{idea.special_folder})" : ""

          lines = []
          lines << "#{status_sym} #{idea.id} #{idea.title}#{tags_str}#{folder_str}"

          if show_content && idea.content && !idea.content.strip.empty?
            lines << ""
            lines << idea.content
          end

          if idea.attachments.any?
            lines << ""
            lines << "Attachments: #{idea.attachments.join(", ")}"
          end

          lines.join("\n")
        end

        # Format a list of ideas for display
        # @param ideas [Array<Idea>] Ideas to format
        # @return [String] Formatted list output
        def self.format_list(ideas)
          return "No ideas found." if ideas.empty?

          ideas.map { |idea| format(idea) }.join("\n")
        end
      end
    end
  end
end
