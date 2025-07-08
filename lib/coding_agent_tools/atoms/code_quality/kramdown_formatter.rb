# frozen_string_literal: true

require "kramdown"
require "kramdown-parser-gfm"

module CodingAgentTools
  module Atoms
    module CodeQuality
      # Atom for formatting markdown using Kramdown
      # Replaces Node.js-based markdown formatters
      class KramdownFormatter
        attr_reader :options

        def initialize(options = {})
          @options = {
            input: "GFM",           # GitHub Flavored Markdown
            hard_wrap: false,
            auto_ids: true,
            entity_output: :as_char,
            toc_levels: "1..6",
            smart_quotes: ["rsquo", "rsquo", "rdquo", "rdquo"]
          }.merge(options)
        end

        def format(content)
          doc = parse_markdown(content)
          formatted = doc.to_kramdown

          {
            success: true,
            formatted: formatted,
            changed: content != formatted
          }
        rescue => e
          {
            success: false,
            error: e.message,
            formatted: content
          }
        end

        def format_file(file_path)
          unless File.exist?(file_path)
            return {
              success: false,
              error: "File not found: #{file_path}"
            }
          end

          content = File.read(file_path)
          result = format(content)

          if result[:success] && result[:changed] && !@options[:dry_run]
            File.write(file_path, result[:formatted])
            result[:file_updated] = true
          end

          result
        end

        def validate_syntax(content)
          doc = parse_markdown(content)
          warnings = doc.warnings

          {
            valid: warnings.empty?,
            warnings: warnings
          }
        rescue => e
          {
            valid: false,
            error: e.message
          }
        end

        private

        def parse_markdown(content)
          Kramdown::Document.new(content, @options)
        end
      end
    end
  end
end
