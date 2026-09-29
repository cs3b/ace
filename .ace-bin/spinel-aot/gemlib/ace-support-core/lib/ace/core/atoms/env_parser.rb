# frozen_string_literal: true

module Ace
  module Core
    module Atoms
      # Pure .env file parsing functions
      module EnvParser
        module_function

        # Parse .env file content into hash
        # @param content [String] .env file content
        # @return [Hash] Parsed environment variables
        def parse(content)
          return {} if content.nil? || content.strip.empty?

          result = {}
          lines = content.lines.map(&:strip)

          lines.each do |line|
            # Skip empty lines and comments
            next if line.empty? || line.start_with?("#")

            # Parse KEY=VALUE format
            if (match = line.match(/\A([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)\z/))
              key = match[1]
              value = match[2]

              # Handle quoted values
              value = unquote(value)

              result[key] = value
            end
          end

          result
        end

        # Format hash as .env content
        # @param env_hash [Hash] Environment variables
        # @return [String] Formatted .env content
        def format(env_hash)
          return "" if env_hash.nil? || env_hash.empty?

          env_hash.map do |key, value|
            formatted_value = value.to_s.include?(" ") ? %("#{value}") : value.to_s
            "#{key}=#{formatted_value}"
          end.join("\n")
        end

        # Validate environment variable name
        # @param name [String] Variable name to validate
        # @return [Boolean] true if valid
        def valid_key?(name)
          !name.nil? && name.match?(/\A[A-Za-z_][A-Za-z0-9_]*\z/)
        end

        # Remove quotes from value if present
        # @param value [String] Value that may be quoted
        # @return [String] Unquoted value
        def unquote(value)
          return value unless value.is_a?(String)

          # Handle double quotes
          if value.start_with?('"') && value.end_with?('"')
            value[1..-2].gsub('\\"', '"').gsub("\\n", "\n").gsub("\\\\", "\\")
          # Handle single quotes
          elsif value.start_with?("'") && value.end_with?("'")
            value[1..-2]
          else
            value
          end
        end
      end
    end
  end
end
