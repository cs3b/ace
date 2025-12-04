# frozen_string_literal: true

require "json"

module Ace
  module LLM
    module ModelsDev
      module Atoms
        # Parses JSON responses from the API
        class JsonParser
          class << self
            # Parse JSON string
            # @param json_string [String] JSON to parse
            # @return [Hash] Parsed data
            # @raise [ApiError] on parse errors
            def parse(json_string)
              JSON.parse(json_string)
            rescue JSON::ParserError => e
              raise ApiError, "Failed to parse JSON: #{e.message}"
            end

            # Convert hash to JSON string
            # @param data [Hash] Data to convert
            # @param pretty [Boolean] Pretty print output
            # @return [String] JSON string
            def to_json(data, pretty: false)
              if pretty
                JSON.pretty_generate(data)
              else
                JSON.generate(data)
              end
            end
          end
        end
      end
    end
  end
end
