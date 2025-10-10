# frozen_string_literal: true

module CodingAgentTools
  module Models
    module Code
      # Represents a complete review prompt ready for LLM processing
      # This is a pure data structure with no external dependencies
      ReviewPrompt = Struct.new(
        :session_id,         # Reference to the review session
        :focus_areas,        # Array of focus area descriptions
        :system_prompt_path, # Path to the system prompt template file
        :combined_content,   # The complete prompt content with all sections
        :metadata,           # Additional metadata (e.g., generated timestamp)
        keyword_init: true
      ) do
        # Validate required fields
        def validate!
          raise ArgumentError, "session_id is required" if session_id.nil? || session_id.empty?
          raise ArgumentError, "focus_areas is required" if focus_areas.nil? || focus_areas.empty?
          raise ArgumentError, "system_prompt_path is required" if system_prompt_path.nil? || system_prompt_path.empty?
          raise ArgumentError, "combined_content is required" if combined_content.nil? || combined_content.empty?

          true
        end

        # Get content size in characters
        def content_size
          combined_content&.size || 0
        end

        # Get content size in words (approximate)
        def word_count
          return 0 unless combined_content

          combined_content.split(/\s+/).size
        end

        # Check if prompt is for multi-focus review
        def multi_focus?
          focus_areas.size > 1
        end

        # Get primary focus area
        def primary_focus
          focus_areas.first
        end

        # Standard focus area mappings
        def self.focus_area_descriptions
          {
            "code" => [
              "Code quality, architecture, security, performance",
              "Architecture compliance (see docs/architecture.md)",
              "Ruby best practices and conventions"
            ],
            "tests" => [
              "Test coverage, quality, maintainability",
              "RSpec best practices",
              "Test architecture and organization"
            ],
            "docs" => [
              "Documentation gaps, updates, cross-references",
              "Architecture documentation alignment",
              "User experience and clarity"
            ]
          }
        end

        # Get descriptions for a focus type
        def self.get_focus_descriptions(focus_type)
          focus_area_descriptions[focus_type] || []
        end

        # Check if using standard focus areas
        def using_standard_focus_areas?
          return false unless focus_areas

          # Check if all focus areas match standard descriptions
          standard_areas = self.class.focus_area_descriptions.values.flatten
          focus_areas.all? { |area| standard_areas.include?(area) }
        end

        # Extract YAML frontmatter if present
        def frontmatter
          return {} unless combined_content

          if combined_content =~ /\A---\n(.*?)\n---\n/m
            require "yaml"
            YAML.safe_load(::Regexp.last_match(1)) || {}
          else
            {}
          end
        rescue
          {}
        end
      end
    end
  end
end
