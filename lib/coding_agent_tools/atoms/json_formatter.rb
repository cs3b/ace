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
            # If parsing fails, it might be invalid JSON containing sensitive data
            # Use regex to sanitize common sensitive key patterns as a fallback
            # If parsing fails, it might be an invalid JSON string containing sensitive data.
            # Use targeted regexes for common sensitive key patterns as a fallback.
            current_data = data.dup # Operate on a copy of the original string input

            # Performance optimization: skip regex processing for large strings without sensitive keys
            # This avoids expensive regex operations on large blobs that don't contain sensitive data
            # Use case-insensitive check to match the regex behavior
            unless sensitive_keys.any? { |key| current_data.downcase.include?(key.to_s.downcase) }
              return current_data
            end

            sensitive_keys.each do |key_sym_or_str|
              key_str = key_sym_or_str.to_s
              escaped_key = Regexp.escape(key_str)

              # Regex for quoted values (e.g., key:"value", 'key':'value', key="value")
              # Captures: 1=key_part_and_separator, 2=opening_quote, 3=value_content. \2 ensures matching closing quote.
              # Replaces only the value content, preserving original quoting and key form.
              # The 'x' flag allows for comments and insignificant whitespace. The 'i' flag makes key matching case-insensitive.
              quoted_value_regex = %r{
                (                                      # Start of Capture Group $1 (key part and separator)
                  (?:["']?)#{escaped_key}(?:["']?)     # Optional quotes around the key, then the key, then optional quotes
                  \s*[:=]\s*                           # Separator (colon or equals) surrounded by optional whitespace
                )                                      # End of Capture Group $1
                (["'])                                 # Capture Group $2: The opening quote of the value
                (.*?)                                  # Capture Group $3: The actual value content (non-greedy)
                \2                                     # Backreference to Group $2, ensuring matching closing quote
              }xi
              current_data.gsub!(quoted_value_regex) { "#{$1}#{$2}#{redact_value}#{$2}" }

              # Regex for unquoted values (e.g., key:value, key=value)
              # Value is a sequence of characters not including spaces, quotes, commas, or common structure/query delimiters.
              # Captures: 1=key_part_and_separator, 2=unquoted_value_content.
              # Replaces value content with redact_value (unquoted), preserving key form.
              unquoted_value_regex = %r{
                (                                      # Start of Capture Group $1 (key part and separator)
                  (?:["']?)#{escaped_key}(?:["']?)     # Optional quotes around the key, then the key, then optional quotes
                  \s*[:=]\s*                           # Separator (colon or equals) surrounded by optional whitespace
                )                                      # End of Capture Group $1
                (                                      # Start of Capture Group $2 (the unquoted value itself)
                  [^\s,"'\[\]{}&;]+                    # Match one or more characters that are not whitespace or common delimiters
                )                                      # End of Capture Group $2
              }xi
              current_data.gsub!(unquoted_value_regex) { "#{$1}#{redact_value}" }
            end
            # current_data is now the regex-sanitized string.
            # It will fall through to the 'case' statement. If it's still a string (which it is),
            # it will be returned by the 'else' branch of the case statement.
          end
        end

        case current_data
        when Hash
          current_data.each_with_object({}) do |(key, value), result|
            result[key] = if sensitive_keys.any? { |sensitive| key.to_s == sensitive.to_s }
              redact_value
            else
              sanitize(value, sensitive_keys: sensitive_keys, redact_value: redact_value)
            end
          end
        when Array
          current_data.map { |item| sanitize(item, sensitive_keys: sensitive_keys, redact_value: redact_value) }
        else
          current_data # This will return primitives or sanitized strings.
        end
      end
    end
  end
end
