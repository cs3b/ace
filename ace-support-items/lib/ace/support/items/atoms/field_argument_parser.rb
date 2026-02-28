# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Atoms
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

              # Parse array items handling quoted strings
              items = parse_array_items(content)

              # Try to infer types for array items
              items.map { |item| infer_type(item) }
            else
              value_str
            end
          end

          # Parse array items handling quoted strings with commas
          # @param content [String] Array content without brackets
          # @return [Array<String>] Parsed items
          def self.parse_array_items(content)
            items = []
            current_item = ""
            in_quotes = false
            quote_char = nil
            i = 0

            while i < content.length
              char = content[i]

              if !in_quotes && (char == '"' || char == "'")
                in_quotes = true
                quote_char = char
                current_item += char
              elsif in_quotes && char == quote_char
                in_quotes = false
                quote_char = nil
                current_item += char
              elsif !in_quotes && char == ","
                items << current_item.strip
                current_item = ""
              else
                current_item += char
              end

              i += 1
            end

            items << current_item.strip unless current_item.strip.empty?
            items.map { |item| item.empty? ? "" : item }
          end

          private_class_method :infer_type, :parse_array_items
        end
      end
    end
  end
end
