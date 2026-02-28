# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Atoms
        # Parse `--filter key:value` syntax from command-line arguments.
        # Supports simple values, OR (`key:a|b`), and negation (`key:!value`).
        class FilterParser
          # Parse filter strings into filter specifications
          # @param filter_strings [Array<String>] Array of "key:value" filter strings
          # @return [Array<Hash>] Array of filter specifications
          # @raise [ArgumentError] If filter syntax is invalid
          #
          # Examples:
          #   parse(["status:pending"])
          #   # => [{key: "status", values: ["pending"], negated: false, or_mode: false}]
          #
          #   parse(["status:pending|in-progress"])
          #   # => [{key: "status", values: ["pending", "in-progress"], negated: false, or_mode: true}]
          #
          #   parse(["status:!done"])
          #   # => [{key: "status", values: ["done"], negated: true, or_mode: false}]
          def self.parse(filter_strings)
            return [] if filter_strings.nil? || filter_strings.empty?

            Array(filter_strings).map do |filter_string|
              parse_single_filter(filter_string)
            end
          end

          # Parse a single filter string
          # @param filter_string [String] Single "key:value" string
          # @return [Hash] Filter specification
          # @raise [ArgumentError] If syntax is invalid
          private_class_method def self.parse_single_filter(filter_string)
            unless filter_string.is_a?(String) && filter_string.include?(":")
              raise ArgumentError, "Invalid filter syntax: '#{filter_string}'. Use: --filter key:value"
            end

            parts = filter_string.split(":", 2)
            key = parts[0]&.strip
            value_part = parts[1]&.strip

            if key.nil? || key.empty?
              raise ArgumentError, "Invalid filter syntax: missing key in '#{filter_string}'. Use: --filter key:value"
            end

            if value_part.nil? || value_part.empty?
              raise ArgumentError, "Invalid filter syntax: missing value in '#{filter_string}'. Use: --filter key:value"
            end

            negated = value_part.start_with?("!")
            value_part = value_part[1..] if negated

            if value_part.nil? || value_part.empty?
              raise ArgumentError, "Invalid filter syntax: empty value after negation in '#{filter_string}'"
            end

            values = value_part.split("|").map(&:strip).reject(&:empty?)

            if values.empty?
              raise ArgumentError, "Invalid filter syntax: no valid values in '#{filter_string}'"
            end

            or_mode = values.length > 1

            {
              key: key,
              values: values,
              negated: negated,
              or_mode: or_mode
            }
          end
        end
      end
    end
  end
end
