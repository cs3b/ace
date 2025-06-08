# frozen_string_literal: true

require "json"

module CodingAgentTools
  module Atoms
    # JSONFormatter provides JSON formatting utilities
    # This is an atom - it has no dependencies on other parts of this gem
    class JSONFormatter
      # Pretty print JSON data
      # @param data [Hash, Array, String] Data to format (String will be parsed first)
      # @param indent [String] Indentation string (default: "  ")
      # @return [String] Pretty-formatted JSON string
      # @raise [JSON::ParserError] If string input cannot be parsed as JSON
      def self.pretty_print(data, indent: "  ")
        data = JSON.parse(data) if data.is_a?(String)
        JSON.pretty_generate(data, indent: indent)
      end

      # Alias for pretty_print for convenience
      # @param data [Hash, Array, String] Data to format (String will be parsed first)
      # @param indent [String] Indentation string (default: "  ")
      # @return [String] Pretty-formatted JSON string
      def self.pretty_format(data, indent: "  ")
        pretty_print(data, indent: indent)
      end

      # Convert data to compact JSON string
      # @param data [Hash, Array, String] Data to format (String will be parsed first)
      # @return [String] Compact JSON string
      # @raise [JSON::ParserError] If string input cannot be parsed as JSON
      def self.compact(data)
        data = JSON.parse(data) if data.is_a?(String)
        JSON.generate(data)
      end

      # Parse JSON string safely
      # @param json_string [String] JSON string to parse
      # @param symbolize_names [Boolean] Whether to symbolize hash keys
      # @return [Hash, Array, nil] Parsed data or nil if parsing fails
      def self.safe_parse(json_string, symbolize_names: false)
        return nil unless json_string.is_a?(String)

        JSON.parse(json_string, symbolize_names: symbolize_names)
      rescue JSON::ParserError
        nil
      end

      # Check if a string is valid JSON
      # @param string [String] String to check
      # @return [Boolean] True if valid JSON, false otherwise
      def self.valid_json?(string)
        return false unless string.is_a?(String)

        JSON.parse(string)
        true
      rescue JSON::ParserError
        false
      end

      # Extract nested value from JSON data using dot notation
      # @param data [Hash, Array] Parsed JSON data
      # @param path [String] Dot-separated path (e.g., "user.name.first")
      # @return [Object, nil] The value at the path or nil if not found
      def self.extract_path(data, path)
        return nil if data.nil? || path.nil?

        path.split(".").reduce(data) do |current, key|
          case current
          when Hash
            current[key] || current[key.to_sym]
          when Array
            index = key.to_i
            current[index] if key =~ /^\d+$/ && index < current.length
          else
            nil
          end
        end
      end

      # Sanitize JSON for logging (remove sensitive keys)
      # @param data [Hash, Array, String] Data to sanitize
      # @param sensitive_keys [Array<String, Symbol>] Keys to redact
      # @param redact_value [String] Value to replace sensitive data with
      # @return [Hash, Array] Sanitized data
      def self.sanitize(data, sensitive_keys: %w[api_key token password secret], redact_value: "[REDACTED]")
        current_data = data
        if data.is_a?(String)
          begin
            # Attempt to parse the string as JSON. If it's a primitive string that isn't
            # a valid JSON document (e.g., "hello" vs "\"hello\""), JSON.parse will raise an error.
            current_data = JSON.parse(data)
          rescue JSON::ParserError
            # If parsing fails, it means the string is not a JSON structure or JSON primitive.
            # In this case, we treat it as a literal string and it will be returned as is by the 'else' clause.
            # current_data remains the original 'data' string.
          end
        end

        case current_data
        when Hash
          current_data.each_with_object({}) do |(key, value), result|
            if sensitive_keys.any? { |sensitive| key.to_s == sensitive.to_s }
              result[key] = redact_value
            else
              result[key] = sanitize(value, sensitive_keys: sensitive_keys, redact_value: redact_value)
            end
          end
        when Array
          current_data.map { |item| sanitize(item, sensitive_keys: sensitive_keys, redact_value: redact_value) }
        else
          current_data # This will return primitives or original strings that were not valid JSON.
        end
      end
    end
  end
end
