# frozen_string_literal: true

module Ace
  module Bundle
    module Atoms
      # Pure functions for checking section content types
      # Used by both SectionProcessor and ContextLoader
      module ContentChecker
        class << self
          # Checks if section has diffs content
          # Note: For _processed_diffs, we check for non-empty arrays to avoid treating
          # empty arrays as valid diff content (which would trigger merge logic unnecessarily)
          # @param section_data [Hash] section data with symbol or string keys
          # @return [Boolean] true if section has ranges, diffs, or non-empty _processed_diffs
          def has_diffs_content?(section_data)
            ranges = section_data[:ranges] || section_data["ranges"]
            diffs = section_data[:diffs] || section_data["diffs"]
            processed_diffs = section_data[:_processed_diffs] || section_data["_processed_diffs"]
            !!(ranges || diffs || (processed_diffs.is_a?(Array) && processed_diffs.any?))
          end

          # Checks if section has files content
          # @param section_data [Hash] section data with symbol or string keys
          # @return [Boolean] true if section has files
          def has_files_content?(section_data)
            !!(section_data[:files] || section_data["files"])
          end

          # Checks if section has commands content
          # @param section_data [Hash] section data with symbol or string keys
          # @return [Boolean] true if section has commands
          def has_commands_content?(section_data)
            !!(section_data[:commands] || section_data["commands"])
          end

          # Checks if section has inline content
          # @param section_data [Hash] section data with symbol or string keys
          # @return [Boolean] true if section has content
          def has_content_content?(section_data)
            !!(section_data[:content] || section_data["content"])
          end
        end
      end
    end
  end
end
