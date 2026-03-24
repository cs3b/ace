# frozen_string_literal: true

module Ace
  module Review
    module Atoms
      # Validates preset references and detects circular dependencies
      class PresetValidator
        # Maximum recursion depth for preset composition
        # A sane limit to prevent stack overflows from deep, non-circular nesting
        MAX_DEPTH = 10

        # Validate preset name format
        # Returns { success: true } if valid
        # Returns { success: false, error: "..." } if invalid
        def self.validate_preset_name(preset_name)
          return {success: false, error: "Preset name cannot be nil or empty"} if preset_name.nil? || preset_name.empty?

          # Check for path traversal attempts
          if preset_name.start_with?("/", "\\")
            return {
              success: false,
              error: "Invalid preset name '#{preset_name}': absolute paths are not allowed"
            }
          end

          if preset_name.include?("..") || preset_name.include?("/") || preset_name.include?("\\")
            return {
              success: false,
              error: "Invalid preset name '#{preset_name}': cannot contain path separators or '..' sequences"
            }
          end

          # Check for reasonable length
          if preset_name.length > 100
            return {
              success: false,
              error: "Preset name too long (max 100 characters): '#{preset_name[0..20]}...'"
            }
          end

          {success: true}
        end

        # Check if a preset exists in the preset manager
        def self.preset_exists?(preset_name, preset_manager)
          preset_manager.preset_exists?(preset_name)
        end

        # Detect circular dependencies in preset composition
        # Returns { success: true } if no circular dependency
        # Returns { success: false, error: "..." } if circular dependency found
        def self.check_circular_dependency(preset_name, preset_chain)
          if preset_chain.include?(preset_name)
            {
              success: false,
              error: "Circular dependency detected: #{(preset_chain + [preset_name]).join(" -> ")}"
            }
          elsif preset_chain.size >= MAX_DEPTH
            {
              success: false,
              error: "Maximum preset nesting depth (#{MAX_DEPTH}) exceeded: #{preset_chain.join(" -> ")}"
            }
          else
            {success: true}
          end
        end

        # Validate a list of preset names
        # Returns { success: true, valid: [], missing: [] }
        def self.validate_presets(preset_names, preset_manager)
          valid = []
          missing = []

          preset_names.each do |name|
            if preset_exists?(name, preset_manager)
              valid << name
            else
              missing << name
            end
          end

          {
            success: missing.empty?,
            valid: valid,
            missing: missing
          }
        end

        # Extract preset references from a preset's configuration
        # Returns array of preset names referenced in the 'presets:' key at root level
        def self.extract_preset_references(preset_data)
          return [] unless preset_data

          # Look for root-level 'presets' key (both string and symbol)
          presets = preset_data["presets"] || preset_data[:presets] || []

          # Ensure we return an array of strings
          Array(presets).map(&:to_s)
        end
      end
    end
  end
end
