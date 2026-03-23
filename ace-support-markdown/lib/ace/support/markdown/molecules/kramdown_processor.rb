# frozen_string_literal: true

require "kramdown"
require "kramdown-parser-gfm"

module Ace
  module Support
    module Markdown
      module Molecules
        # Parse and serialize markdown using Kramdown
        # Provides GFM-compatible markdown processing
        class KramdownProcessor
          # Parse markdown content to AST
          # @param content [String] The markdown content
          # @param options [Hash] Kramdown options
          # @return [Hash] Result with :document, :success, :errors
          def self.parse(content, options: {})
            default_options = {
              input: "GFM", # GitHub Flavored Markdown
              hard_wrap: false,
              auto_ids: true,
              parse_block_html: true
            }

            merged_options = default_options.merge(options)

            begin
              document = Kramdown::Document.new(content, merged_options)

              {
                document: document,
                success: true,
                warnings: document.warnings || [],
                errors: []
              }
            rescue => e
              {
                document: nil,
                success: false,
                warnings: [],
                errors: ["Kramdown parsing error: #{e.message}"]
              }
            end
          end

          # Convert markdown AST back to markdown string
          # @param document [Kramdown::Document] The kramdown document
          # @return [Hash] Result with :markdown, :success, :errors
          def self.to_markdown(document)
            raise ArgumentError, "Document must be a Kramdown::Document" unless document.is_a?(Kramdown::Document)

            begin
              markdown = document.to_kramdown

              {
                markdown: markdown,
                success: true,
                errors: []
              }
            rescue => e
              {
                markdown: nil,
                success: false,
                errors: ["Kramdown serialization error: #{e.message}"]
              }
            end
          end

          # Round-trip: parse and convert back to markdown
          # @param content [String] The markdown content
          # @param options [Hash] Kramdown options
          # @return [Hash] Result with :markdown, :success, :errors
          def self.round_trip(content, options: {})
            parse_result = parse(content, options: options)
            return parse_result unless parse_result[:success]

            to_markdown(parse_result[:document])
          end

          # Validate markdown can be parsed without errors
          # @param content [String] The markdown content
          # @return [Boolean] true if valid
          def self.valid?(content)
            result = parse(content)
            result[:success] && result[:errors].empty?
          end

          # Extract headings from markdown
          # @param content [String] The markdown content
          # @return [Array<Hash>] Array of {:text, :level}
          def self.extract_headings(content)
            result = parse(content)
            return [] unless result[:success]

            find_headings(result[:document].root)
          end

          private

          # Recursively find all headings in AST
          def self.find_headings(element, headings = [])
            if element.type == :header
              text = element.children
                .select { |c| c.type == :text }
                .map(&:value)
                .join

              headings << {
                text: text,
                level: element.options[:level]
              }
            end

            element.children.each do |child|
              find_headings(child, headings)
            end

            headings
          end
        end
      end
    end
  end
end
