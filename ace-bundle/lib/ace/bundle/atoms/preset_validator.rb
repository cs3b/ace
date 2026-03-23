# frozen_string_literal: true

module Ace
  module Bundle
    module Atoms
      # Validates preset references and detects circular dependencies
      class PresetValidator
        MAX_DEPTH = 10  # Maximum recursion depth for preset composition

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
        # Returns array of preset names referenced in the 'presets:' key
        def self.extract_preset_references(preset_data)
          return [] unless preset_data

          bundle_config = preset_data[:bundle] || preset_data["bundle"] || {}
          presets = bundle_config["presets"] || bundle_config[:presets] || []

          # Ensure we return an array of strings
          Array(presets).map(&:to_s)
        end
      end
    end
  end
end
