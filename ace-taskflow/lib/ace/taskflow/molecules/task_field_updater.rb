# frozen_string_literal: true

require_relative "field_argument_parser"

module Ace
  module Taskflow
    module Molecules
      # Updates task frontmatter fields with support for nested structures
      # Now acts as a facade for backward compatibility
      class TaskFieldUpdater
        class FieldUpdateError < StandardError; end

        # Parse field update arguments into structured format
        # Delegates to FieldArgumentParser for CLI parsing
        # @param field_args [Array<String>] Field arguments in "key=value" format
        # @return [Hash] Parsed field updates with keys and inferred values
        # @raise [FieldUpdateError] If field syntax is invalid
        def self.parse_field_updates(field_args)
          FieldArgumentParser.parse(field_args)
        rescue FieldArgumentParser::ParseError => e
          raise FieldUpdateError, e.message
        end

        # Apply field updates to YAML hash structure
        # @param yaml_hash [Hash] The frontmatter hash to update
        # @param updates [Hash] Field updates with keys and values
        # @return [Hash] Updated YAML hash
        def self.apply_updates(yaml_hash, updates)
          result = Marshal.load(Marshal.dump(yaml_hash))

          updates.each do |key_path, value|
            if key_path.include?(".")
              # Handle nested fields with dot notation
              apply_nested_update(result, key_path, value)
            else
              # Simple field update
              result[key_path] = value
            end
          end

          result
        end

        # Validate field types against existing schema (basic validation)
        # @param yaml_hash [Hash] The original YAML hash
        # @param updates [Hash] Field updates to validate
        # @return [Array<String>] Array of validation errors (empty if valid)
        def self.validate_types(yaml_hash, updates)
          errors = []

          updates.each do |key_path, new_value|
            # Get existing value if it exists
            existing_value = get_nested_value(yaml_hash, key_path)

            # Only validate if field already exists and has a value
            next if existing_value.nil?

            # Check type compatibility
            existing_type = existing_value.class
            new_type = new_value.class

            # Allow flexibility: strings can become any type, nil can become anything
            next if existing_type == String
            next if existing_value == ""

            # Strict type matching for non-strings
            if existing_type != new_type
              errors << "Field '#{key_path}' expects #{existing_type}, got #{new_type}"
            end
          end

          errors
        end


        # Apply nested update using dot notation
        # @param hash [Hash] The hash to update
        # @param key_path [String] Dot-separated key path (e.g., "worktree.branch")
        # @param value [Object] Value to set
        # @return [void]
        def self.apply_nested_update(hash, key_path, value)
          keys = key_path.split(".")
          final_key = keys.pop

          # Navigate to or create nested hash structure
          current = hash
          keys.each do |key|
            current[key] ||= {}
            unless current[key].is_a?(Hash)
              raise FieldUpdateError,
                    "Cannot update nested field '#{key_path}' - '#{key}' is not a hash"
            end
            current = current[key]
          end

          # Set the final value
          current[final_key] = value
        end

        # Get nested value from hash using dot notation
        # @param hash [Hash] The hash to search
        # @param key_path [String] Dot-separated key path
        # @return [Object, nil] The value or nil if not found
        def self.get_nested_value(hash, key_path)
          keys = key_path.split(".")
          current = hash

          keys.each do |key|
            return nil unless current.is_a?(Hash)
            current = current[key]
            return nil if current.nil?
          end

          current
        end

        private_class_method :apply_nested_update
      end
    end
  end
end
