# frozen_string_literal: true

require 'kramdown'
require 'kramdown-parser-gfm'

module Ace
  module Lint
    module Atoms
      # Pure function to parse markdown with kramdown
      class KramdownParser
        # Parse markdown content with kramdown
        # @param content [String] Markdown content
        # @param options [Hash] Kramdown options
        # @return [Hash] Result with :success, :document, :errors, :warnings
        def self.parse(content, options: {})
          default_options = {
            input: 'GFM', # Use GitHub Flavored Markdown
            hard_wrap: false,
            auto_ids: false, # Don't generate anchor IDs
            parse_block_html: true,
            parse_span_html: true
          }

          merged_options = default_options.merge(options)

          begin
            document = Kramdown::Document.new(content, merged_options)

            # Kramdown collects warnings during parsing (as strings)
            # All warnings are informational, not errors
            warnings = document.warnings || []

            {
              success: true, # Kramdown warnings don't indicate parsing failure
              document: document,
              errors: [],
              warnings: warnings
            }
          rescue StandardError => e
            {
              success: false,
              document: nil,
              errors: ["Kramdown parsing error: #{e.message}"],
              warnings: []
            }
          end
        end

        # Format markdown content with kramdown
        # @param content [String] Markdown content
        # @param options [Hash] Kramdown options
        # @return [Hash] Result with :success, :formatted_content, :errors
        def self.format(content, options: {})
          parse_result = parse(content, options: options)

          return { success: false, formatted_content: nil, errors: parse_result[:errors] } unless parse_result[:success]

          begin
            # Convert back to markdown
            formatted = parse_result[:document].to_kramdown

            {
              success: true,
              formatted_content: formatted,
              errors: []
            }
          rescue StandardError => e
            {
              success: false,
              formatted_content: nil,
              errors: ["Kramdown formatting error: #{e.message}"]
            }
          end
        end

        # Kramdown warnings are already formatted strings
        def self.format_kramdown_message(warning)
          warning.to_s
        end
      end
    end
  end
end
