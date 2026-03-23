# frozen_string_literal: true

require "json"
require "yaml"

module Ace
  module LLM
    module Molecules
      # Format handlers for different output formats
      module FormatHandlers
        # Base format handler class
        class Base
          # Format response for output
          # @param response [Hash] Response with :text and normalized metadata
          # @param options [Hash] Additional formatting options
          # @return [String] Formatted output
          def format(response, **options)
            raise NotImplementedError, "Subclasses must implement #format"
          end

          # Generate summary for stdout when writing to file
          # @param response [Hash] Response with :text and normalized metadata
          # @param file_path [String] Output file path
          # @return [String] Summary text
          def generate_summary(response, file_path)
            metadata = response[:metadata] || {}

            summary_parts = []
            summary_parts << "Response saved to: #{file_path}"

            if metadata[:provider]
              summary_parts << if metadata[:model]
                "Provider: #{metadata[:provider]} (#{metadata[:model]})"
              else
                "Provider: #{metadata[:provider]}"
              end
            end

            summary_parts << "Execution time: #{metadata[:took]}s" if metadata[:took]

            if metadata[:input_tokens] && metadata[:output_tokens]
              tokens_info = "Tokens: #{metadata[:input_tokens]} input, #{metadata[:output_tokens]} output"
              if metadata[:cached_tokens] && metadata[:cached_tokens] > 0
                tokens_info += ", #{metadata[:cached_tokens]} cached"
              end
              summary_parts << tokens_info
            end

            # Add cost information if available
            if metadata[:cost]
              cost_info = build_cost_summary(metadata[:cost])
              summary_parts << cost_info if cost_info
            end

            summary_parts.join("\n")
          end

          # Build cost summary string from cost metadata
          # @param cost_data [Hash] Cost breakdown data
          # @return [String, nil] Formatted cost summary
          def build_cost_summary(cost_data)
            return nil unless cost_data && cost_data[:total]

            cost_parts = []
            cost_parts << "Cost: $#{format_cost(cost_data[:total])}"

            if cost_data[:input] || cost_data[:output]
              breakdown = []
              breakdown << "input: $#{format_cost(cost_data[:input])}" if cost_data[:input]
              breakdown << "output: $#{format_cost(cost_data[:output])}" if cost_data[:output]

              if cost_data[:cache_creation] && cost_data[:cache_creation] > 0
                breakdown << "cache creation: $#{format_cost(cost_data[:cache_creation])}"
              end

              if cost_data[:cache_read] && cost_data[:cache_read] > 0
                breakdown << "cache read: $#{format_cost(cost_data[:cache_read])}"
              end

              cost_parts << " (#{breakdown.join(", ")})" unless breakdown.empty?
            end

            cost_parts.join
          end

          # Format cost value for display
          # @param cost [Float, Numeric] Cost value
          # @return [String] Formatted cost string
          def format_cost(cost)
            return "0.000000" if cost.nil? || cost.zero?

            sprintf("%.6f", cost)
          end

          protected

          # Validate response structure
          # @param response [Hash] Response to validate
          # @raise [Error] If response is invalid
          def validate_response(response)
            return if response.is_a?(Hash) && response[:text]

            raise Ace::LLM::Error, "Invalid response format: missing :text field"
          end
        end

        # JSON format handler
        class JSON < Base
          # Format response as JSON with full metadata
          # @param response [Hash] Response with :text and normalized metadata
          # @param options [Hash] Additional formatting options
          # @return [String] JSON formatted output
          def format(response, **_options)
            validate_response(response)

            output = {
              text: response[:text],
              metadata: response[:metadata] || {}
            }

            ::JSON.pretty_generate(output)
          end
        end

        # Markdown format handler
        class Markdown < Base
          # Format response as Markdown with YAML front matter
          # @param response [Hash] Response with :text and normalized metadata
          # @param options [Hash] Additional formatting options
          # @return [String] Markdown formatted output
          def format(response, **_options)
            validate_response(response)

            metadata = response[:metadata] || {}
            content = response[:text]

            if metadata.empty?
              content
            else
              # Create YAML front matter
              yaml_front_matter = metadata.to_yaml.chomp
              "#{yaml_front_matter}\n---\n\n#{content}"
            end
          end
        end

        # Plain text format handler
        class Text < Base
          # Format response as plain text (content only)
          # @param response [Hash] Response with :text and normalized metadata
          # @param options [Hash] Additional formatting options
          # @return [String] Plain text output
          def format(response, **_options)
            validate_response(response)
            response[:text]
          end
        end

        # Factory method to get format handler
        # @param format [String] Format type (json, markdown, text)
        # @return [Base] Format handler instance
        def self.get_handler(format)
          case format.to_s.downcase
          when "json"
            JSON.new
          when "markdown", "md"
            Markdown.new
          when "text", "txt"
            Text.new
          else
            raise Ace::LLM::Error, "Unsupported format: #{format}"
          end
        end

        # Get list of supported formats
        # @return [Array<String>] List of supported formats
        def self.supported_formats
          ["json", "markdown", "text"]
        end
      end
    end
  end
end
