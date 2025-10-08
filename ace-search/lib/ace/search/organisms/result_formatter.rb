# frozen_string_literal: true

require "json"
require "yaml"

module Ace
  module Search
    module Organisms
      # Formats search results for various output formats
      # This is an organism - business logic for result formatting
      class ResultFormatter
        # Format results based on output format
        # @param results [Array<Hash>] Search results
        # @param format [Symbol] Output format (:text, :json, :yaml)
        # @param options [Hash] Formatting options
        # @return [String] Formatted output
        def self.format(results, format: :text, options: {})
          case format
          when :json
            format_json(results)
          when :yaml
            format_yaml(results)
          else
            format_text(results, options)
          end
        end

        # Format results as text with clickable terminal links
        def self.format_text(results, options = {})
          return "No results found" if results.empty?

          lines = []

          results.each do |result|
            case result[:type]
            when :file
              lines << format_file_result(result)
            when :match
              lines << format_match_result(result, options)
            end
          end

          lines.join("\n")
        end

        # Format file result
        def self.format_file_result(result)
          "  #{result[:path]}"
        end

        # Format match result with clickable link
        def self.format_match_result(result, options = {})
          # Create clickable terminal link: file:line:column
          path = result[:path]
          line = result[:line] || result[:line_number] || 1
          column = result[:column] || 0
          text = result[:text] || result[:content] || ""

          "  #{path}:#{line}:#{column}: #{text}"
        end

        # Format results as JSON
        def self.format_json(results)
          JSON.pretty_generate({
            count: results.size,
            results: results
          })
        end

        # Format results as YAML
        def self.format_yaml(results)
          YAML.dump({
            "count" => results.size,
            "results" => results
          })
        end

        # Format summary header
        def self.format_summary(results, options = {})
          count = results.size
          mode = options[:mode] || "search"
          pattern = options[:pattern] || ""

          filters = []
          filters << "mode: #{mode}" if mode
          filters << "pattern: \"#{pattern}\"" if pattern && !pattern.empty?
          filters << "glob: #{options[:glob]}" if options[:glob]
          filters << "scope: #{options[:scope]}" if options[:scope]

          filter_str = filters.empty? ? "" : " | #{filters.join(" | ")}"

          "Search context:#{filter_str}\nFound #{count} results\n"
        end
      end
    end
  end
end
