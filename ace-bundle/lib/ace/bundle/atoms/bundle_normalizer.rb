# frozen_string_literal: true

module Ace
  module Bundle
    module Atoms
      # Normalizes bundle configuration into ace-bundle compatible structure
      #
      # Handles various input formats and ensures proper structure for ace-bundle:
      # - String inputs (preset names) wrapped in bundle.presets array
      # - Hashes with top-level base: key moved to bundle.base
      # - Hashes with both base: and bundle: keys properly merged
      # - Properly structured configs passed through unchanged
      # - Normalizes all input to bundle: key structure for ace-bundle compatibility
      #
      class BundleNormalizer
        # Normalize various input types to proper ace-bundle structure
        #
        # @param input [String, Hash, nil] Bundle configuration input
        # @return [Hash] Normalized bundle configuration
        #
        # @example String input (preset name)
        #   normalize_config("project")
        #   #=> { "bundle" => { "presets" => ["project"] } }
        #
        # @example Hash with top-level base key
        #   normalize_config({ "base" => "custom content", "files" => ["README.md"] })
        #   #=> { "bundle" => { "base" => "custom content", "files" => ["README.md"] } }
        #
        # @example Hash with both base and bundle keys
        #   normalize_config({ "base" => "content", "bundle" => { "presets" => ["project"] } })
        #   #=> { "bundle" => { "base" => "content", "presets" => ["project"] } }
        #
        # @example Properly structured config (unchanged)
        #   normalize_config({ "bundle" => { "base" => "content" } })
        #   #=> { "bundle" => { "base" => "content" } }
        def self.normalize_config(input)
          case input
          when String
            # String input (e.g., "project", "staged") -> wrap as preset
            {"bundle" => {"presets" => [input]}}
          when Hash
            normalize_hash_config(input)
          when NilClass
            # Return empty config for nil
            {}
          else
            # Fallback for unexpected types
            {}
          end
        end

        # Normalize hash-based bundle configuration
        #
        # @param input [Hash] Bundle configuration hash
        # @return [Hash] Normalized configuration
        # @api private
        def self.normalize_hash_config(input)
          # Check if this config has a top-level "base" key that needs to be moved
          has_base = input.key?("base") || input.key?(:base)
          # Check for bundle: configuration key
          has_bundle_config = input.key?("bundle") || input.key?(:bundle)

          if has_base && !has_bundle_config
            # Case 1: Config has base: at top level but no bundle: key
            # Need to move base under bundle.base and wrap other keys
            wrap_base_in_bundle(input)
          elsif has_base && has_bundle_config
            # Case 2: Config has both base: and bundle: at top level
            # Move base under bundle.base
            merge_base_into_bundle(input)
          else
            # Case 3: Config already properly structured or doesn't need normalization
            input
          end
        end

        # Wrap top-level base and other keys under bundle
        #
        # @param input [Hash] Configuration with top-level base
        # @return [Hash] Configuration with base under bundle.base
        # @api private
        def self.wrap_base_in_bundle(input)
          normalized = {"bundle" => {}}

          input.each do |key, value|
            key_str = key.to_s
            if key_str == "base"
              # Move top-level base to bundle.base
              normalized["bundle"]["base"] = value
            else
              # Other top-level keys go under bundle
              normalized["bundle"][key_str] = value
            end
          end

          normalized
        end

        # Merge top-level base into existing bundle.base
        #
        # @param input [Hash] Configuration with both base and bundle keys
        # @return [Hash] Configuration with base merged into bundle
        # @api private
        def self.merge_base_into_bundle(input)
          normalized = {}
          base_value = input["base"] || input[:base]

          input.each do |key, value|
            key_str = key.to_s
            if key_str == "base"
              # Skip - will add under bundle.base below
              next
            elsif key_str == "bundle"
              # Merge base value into existing bundle
              bundle_hash = value.is_a?(Hash) ? value.dup : {}
              bundle_hash["base"] = base_value
              normalized["bundle"] = bundle_hash
            else
              normalized[key_str] = value
            end
          end

          normalized
        end
      end
    end
  end
end
