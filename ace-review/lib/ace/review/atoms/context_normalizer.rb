# frozen_string_literal: true

module Ace
  module Review
    module Atoms
      # Normalizes context configuration into ace-context compatible structure
      #
      # Handles various input formats and ensures proper structure for ace-context:
      # - String inputs (preset names) wrapped in context.presets array
      # - Hashes with top-level base: key moved to context.base
      # - Hashes with both base: and context: keys properly merged
      # - Properly structured configs passed through unchanged
      class ContextNormalizer
        # Normalize various input types to proper ace-context structure
        #
        # @param input [String, Hash, nil] Context configuration input
        # @return [Hash] Normalized context configuration
        #
        # @example String input (preset name)
        #   normalize_context_config("project")
        #   #=> { "context" => { "presets" => ["project"] } }
        #
        # @example Hash with top-level base key
        #   normalize_context_config({ "base" => "custom content", "files" => ["README.md"] })
        #   #=> { "context" => { "base" => "custom content", "files" => ["README.md"] } }
        #
        # @example Hash with both base and context keys
        #   normalize_context_config({ "base" => "content", "context" => { "presets" => ["project"] } })
        #   #=> { "context" => { "base" => "content", "presets" => ["project"] } }
        #
        # @example Properly structured config (unchanged)
        #   normalize_context_config({ "context" => { "base" => "content" } })
        #   #=> { "context" => { "base" => "content" } }
        def self.normalize_context_config(input)
          case input
          when String
            # String input (e.g., "project", "staged") -> wrap as preset
            { "context" => { "presets" => [input] } }
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

        # Normalize hash-based context configuration
        #
        # @param input [Hash] Context configuration hash
        # @return [Hash] Normalized configuration
        # @api private
        def self.normalize_hash_config(input)
          # Check if this config has a top-level "base" key that needs to be moved
          has_base = input.key?("base") || input.key?(:base)
          has_context = input.key?("context") || input.key?(:context)

          if has_base && !has_context
            # Case 1: Config has base: at top level but no context: key
            # Need to move base under context.base and wrap other keys
            wrap_base_in_context(input)
          elsif has_base && has_context
            # Case 2: Config has both base: and context: at top level
            # Move base under context.base
            merge_base_into_context(input)
          else
            # Case 3: Config already properly structured or doesn't need normalization
            input
          end
        end

        # Wrap top-level base and other keys under context
        #
        # @param input [Hash] Configuration with top-level base
        # @return [Hash] Configuration with base under context.base
        # @api private
        def self.wrap_base_in_context(input)
          normalized = { "context" => {} }

          input.each do |key, value|
            key_str = key.to_s
            if key_str == "base"
              # Move top-level base to context.base
              normalized["context"]["base"] = value
            else
              # Other top-level keys go under context
              normalized["context"][key_str] = value
            end
          end

          normalized
        end

        # Merge top-level base into existing context.base
        #
        # @param input [Hash] Configuration with both base and context keys
        # @return [Hash] Configuration with base merged into context
        # @api private
        def self.merge_base_into_context(input)
          normalized = {}
          base_value = input["base"] || input[:base]

          input.each do |key, value|
            key_str = key.to_s
            if key_str == "base"
              # Skip - will add under context.base below
              next
            elsif key_str == "context"
              # Merge context and add base under it
              context_hash = value.is_a?(Hash) ? value.dup : {}
              context_hash["base"] = base_value
              normalized["context"] = context_hash
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
