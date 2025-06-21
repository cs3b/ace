# frozen_string_literal: true

require "yaml"

module CodingAgentTools
  module Molecules
    # Format handlers for different output formats
    # This is a molecule - it handles specific formatting operations
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

          if metadata[:took]
            summary_parts << "Execution time: #{metadata[:took]}s"
          end

          if metadata[:input_tokens] && metadata[:output_tokens]
            summary_parts << "Tokens: #{metadata[:input_tokens]} input, #{metadata[:output_tokens]} output"
          end

          summary_parts.join("\n")
        end

        protected

        # Validate response structure
        # @param response [Hash] Response to validate
        # @raise [Error] If response is invalid
        def validate_response(response)
          unless response.is_a?(Hash) && response[:text]
            raise Error, "Invalid response format: missing :text field"
          end
        end
      end

      # JSON format handler
      class JSON < Base
        # Format response as JSON with full metadata
        # @param response [Hash] Response with :text and normalized metadata
        # @param options [Hash] Additional formatting options
        # @return [String] JSON formatted output
        def format(response, **options)
          validate_response(response)

          output = {
            text: response[:text],
            metadata: response[:metadata] || {}
          }

          Atoms::JSONFormatter.pretty_format(output)
        end
      end

      # Markdown format handler
      class Markdown < Base
        # Format response as Markdown with YAML front matter
        # @param response [Hash] Response with :text and normalized metadata
        # @param options [Hash] Additional formatting options
        # @return [String] Markdown formatted output
        def format(response, **options)
          validate_response(response)

          metadata = response[:metadata] || {}
          content = response[:text]

          if metadata.empty?
            content
          else
            yaml_front_matter = metadata.to_yaml
            "---\n#{yaml_front_matter}---\n\n#{content}"
          end
        end
      end

      # Plain text format handler
      class Text < Base
        # Format response as plain text (content only)
        # @param response [Hash] Response with :text and normalized metadata
        # @param options [Hash] Additional formatting options
        # @return [String] Plain text output
        def format(response, **options)
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
          raise Error, "Unsupported format: #{format}"
        end
      end

      # Get list of supported formats
      # @return [Array<String>] List of supported formats
      def self.supported_formats
        %w[json markdown text]
      end
    end
  end
end
