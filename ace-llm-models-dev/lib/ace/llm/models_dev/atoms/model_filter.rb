# frozen_string_literal: true

module Ace
  module LLM
    module ModelsDev
      module Atoms
        # Filters models based on various criteria
        class ModelFilter
          # Supported filter predicates
          FILTERS = {
            # Provider filter
            provider: ->(model, value) { model.provider_id == value },

            # Capability filters (boolean)
            reasoning: ->(model, value) { model.capabilities[:reasoning] == parse_boolean(value) },
            tool_call: ->(model, value) { model.capabilities[:tool_call] == parse_boolean(value) },
            attachment: ->(model, value) { model.capabilities[:attachment] == parse_boolean(value) },
            structured_output: ->(model, value) { model.capabilities[:structured_output] == parse_boolean(value) },
            temperature: ->(model, value) { model.capabilities[:temperature] == parse_boolean(value) },

            # Open weights filter
            open_weights: ->(model, value) { model.open_weights == parse_boolean(value) },

            # Modality filter (checks input modalities)
            modality: ->(model, value) { model.modalities[:input]&.include?(value) },

            # Numeric filters
            min_context: ->(model, value) { (model.context_limit || 0) >= value.to_i },
            max_input_cost: lambda { |model, value|
              pricing_input = model.pricing&.input
              return false unless pricing_input

              pricing_input <= value.to_f
            }
          }.freeze

          class << self
            # Apply filters to a list of models
            # @param models [Array<Models::ModelInfo>] Models to filter
            # @param filters [Hash] Filter key-value pairs
            # @return [Array<Models::ModelInfo>] Filtered models
            def apply(models, filters)
              return models if filters.nil? || filters.empty?

              models.select do |model|
                filters.all? do |key, value|
                  filter = FILTERS[key.to_sym]
                  # Unknown filters are ignored (forward compatibility)
                  filter.nil? || filter.call(model, value)
                end
              end
            end

            # Parse a filter string into key-value pair
            # @param filter_string [String] Filter in "key:value" format
            # @return [Array<Symbol, String>, nil] [key, value] or nil if invalid
            def parse(filter_string)
              return nil unless filter_string.is_a?(String)

              parts = filter_string.split(":", 2)
              return nil if parts.size != 2 || parts.any?(&:empty?)

              [parts[0].to_sym, parts[1]]
            end

            # Parse multiple filter strings into a hash
            # @param filter_strings [Array<String>] Array of "key:value" strings
            # @return [Hash] Parsed filters
            def parse_all(filter_strings)
              return {} if filter_strings.nil? || filter_strings.empty?

              filter_strings.each_with_object({}) do |filter_string, hash|
                parsed = parse(filter_string)
                hash[parsed[0]] = parsed[1] if parsed
              end
            end

            private

            # Parse boolean string value
            # @param value [String, Boolean] Value to parse
            # @return [Boolean]
            def parse_boolean(value)
              return value if value.is_a?(TrueClass) || value.is_a?(FalseClass)

              %w[true 1 yes].include?(value.to_s.downcase)
            end
          end
        end
      end
    end
  end
end
