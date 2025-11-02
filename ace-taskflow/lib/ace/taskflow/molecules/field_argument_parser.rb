# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Parses command-line field arguments into typed hash values
      # Handles type inference and array parsing for CLI input
      class FieldArgumentParser
        class ParseError < StandardError; end

        # Parse field update arguments into structured format
        # @param field_args [Array<String>] Field arguments in "key=value" format
        # @return [Hash] Parsed field updates with keys and inferred values
        # @raise [ParseError] If field syntax is invalid
        def self.parse(field_args)
          updates = {}

          field_args.each do |arg|
            # Match key=value with optional quotes around value
            match = arg.match(/^([^=]+)=(.*)$/)
            raise ParseError, "Invalid field syntax. Use: --field key=value" unless match

            key = match[1].strip
            value_str = match[2].strip

            # Infer type from value string
            value = infer_type(value_str)

            # Store with key path for nested support
            updates[key] = value
          end

          updates
        end

        # Infer value type from string
        # @param value_str [String] String value from command line
        # @return [Object] Inferred value (Integer, Boolean, Array, or String)
        def self.infer_type(value_str)
          # Remove surrounding quotes if present (must match)
          if value_str.match?(/^"(.*)"$/) || value_str.match?(/^'(.*)'$/)
            # Quoted string - strip quotes and return as string
            return value_str[1..-2]
          end

          case value_str
          when "" then ""
          when "true" then true
          when "false" then false
          when /^-?\d+$/ then value_str.to_i
          when /^-?\d+\.\d+$/ then value_str.to_f
          when /^\[.*\]$/
            content = value_str[1..-2].strip
            return [] if content.empty?

            # Split by comma and trim each item
            items = content.split(",").map(&:strip)
            # Try to infer types for array items
            items.map { |item| infer_type(item) }
          else
            value_str
          end
        end

        private_class_method :infer_type
      end
    end
  end
end