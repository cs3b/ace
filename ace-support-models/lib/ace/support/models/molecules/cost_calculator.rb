# frozen_string_literal: true

module Ace
  module Support
    module Models
      module Molecules
        # Calculates query costs based on token usage
        class CostCalculator
          # Initialize calculator
          # @param validator [ModelValidator, nil] Validator instance
          def initialize(validator: nil)
            @validator = validator || ModelValidator.new
          end

          # Calculate cost for a query
          # @param model_id [String] Model ID
          # @param input_tokens [Integer] Input token count
          # @param output_tokens [Integer] Output token count
          # @param reasoning_tokens [Integer] Reasoning token count
          # @return [Hash] Cost breakdown
          def calculate(model_id, input_tokens:, output_tokens:, reasoning_tokens: 0)
            model = @validator.validate(model_id)
            pricing = model.pricing

            unless pricing.available?
              return {
                model_id: model.full_id,
                model_name: model.name,
                error: "No pricing data available for this model",
                available: false
              }
            end

            input_cost = calculate_component(input_tokens, pricing.input)
            output_cost = calculate_component(output_tokens, pricing.output)
            reasoning_cost = calculate_component(reasoning_tokens, pricing.reasoning)

            total = input_cost + output_cost + reasoning_cost

            {
              model_id: model.full_id,
              model_name: model.name,
              available: true,
              tokens: {
                input: input_tokens,
                output: output_tokens,
                reasoning: reasoning_tokens,
                total: input_tokens + output_tokens + reasoning_tokens
              },
              rates: {
                input: pricing.input,
                output: pricing.output,
                reasoning: pricing.reasoning
              },
              costs: {
                input: input_cost,
                output: output_cost,
                reasoning: reasoning_cost,
                total: total
              },
              formatted: {
                input: format_cost(input_cost),
                output: format_cost(output_cost),
                reasoning: format_cost(reasoning_cost),
                total: format_cost(total)
              }
            }
          end

          # Format a cost breakdown as human-readable string
          # @param result [Hash] Result from calculate
          # @return [String] Formatted string
          def format(result)
            return result[:error] unless result[:available]

            lines = []
            lines << "Model: #{result[:model_name]} (#{result[:model_id]})"
            lines << ""

            tokens = result[:tokens]
            result[:costs]
            rates = result[:rates]

            if tokens[:input] > 0
              lines << "Input:     #{format_tokens(tokens[:input])} tokens × $#{rates[:input]}/M = #{result[:formatted][:input]}"
            end

            if tokens[:output] > 0
              lines << "Output:    #{format_tokens(tokens[:output])} tokens × $#{rates[:output]}/M = #{result[:formatted][:output]}"
            end

            if tokens[:reasoning] > 0 && rates[:reasoning]
              lines << "Reasoning: #{format_tokens(tokens[:reasoning])} tokens × $#{rates[:reasoning]}/M = #{result[:formatted][:reasoning]}"
            end

            lines << ""
            lines << "Total: #{result[:formatted][:total]}"

            lines.join("\n")
          end

          private

          def calculate_component(tokens, rate)
            return 0.0 unless rate && tokens > 0

            (tokens / 1_000_000.0) * rate
          end

          def format_cost(cost)
            return "$0.00" if cost.zero?

            if cost < 0.01
              "$#{sprintf("%.4f", cost)}"
            elsif cost < 1
              "$#{sprintf("%.3f", cost)}"
            else
              "$#{sprintf("%.2f", cost)}"
            end
          end

          def format_tokens(count)
            if count >= 1_000_000
              "#{sprintf("%.1f", count / 1_000_000.0)}M"
            elsif count >= 1_000
              "#{sprintf("%.1f", count / 1_000.0)}K"
            else
              count.to_s
            end
          end
        end
      end
    end
  end
end
