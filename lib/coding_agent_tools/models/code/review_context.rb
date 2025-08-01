# frozen_string_literal: true

module CodingAgentTools
  module Models
    module Code
      # Represents project context loaded for a code review
      # This is a pure data structure with no external dependencies
      ReviewContext = Struct.new(
        :mode,        # Context mode: 'auto', 'none', 'custom'
        :documents,   # Array of context documents: [{type: String, path: String, content: String}]
        :loaded_at,   # Timestamp when context was loaded
        keyword_init: true
      ) do
        # Validate required fields
        def validate!
          raise ArgumentError, 'mode is required' if mode.nil? || mode.empty?

          valid_modes = %w[auto none custom]
          raise ArgumentError, "mode must be one of: #{valid_modes.join(', ')}" unless valid_modes.include?(mode)

          if mode == 'custom' && (documents.nil? || documents.empty?)
            raise ArgumentError, 'documents required for custom mode'
          end

          true
        end

        # Check if context was loaded
        def loaded?
          mode != 'none' && !documents.nil? && !documents.empty?
        end

        # Get document count
        def document_count
          documents&.size || 0
        end

        # Get total content size in characters
        def total_size
          return 0 unless documents

          documents.sum { |doc| doc[:content]&.size || 0 }
        end

        # Get document by type
        def document_by_type(type)
          return nil unless documents

          documents.find { |doc| doc[:type] == type }
        end

        # Get all document types
        def document_types
          return [] unless documents

          documents.map { |doc| doc[:type] }.uniq
        end

        # Standard document types for auto mode
        def self.auto_document_types
          %w[blueprint vision architecture]
        end

        # Check if using default auto documents
        def using_auto_defaults?
          mode == 'auto' && document_types.sort == self.class.auto_document_types.sort
        end
      end
    end
  end
end
