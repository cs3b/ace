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
            auto_ids: true,         # Enable auto IDs by default
            entity_output: :as_char,
            toc_levels: "1..6",
            smart_quotes: ["rsquo", "rsquo", "rdquo", "rdquo"],
            gfm_quirks: [:paragraph_end],  # Preserve GFM paragraph handling
            syntax_highlighter: nil        # Disable syntax highlighting to preserve code blocks
          }.merge(options)
        end

        def format(content)
          doc = parse_markdown(content)
          formatted = convert_to_gfm(doc, content)

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

          begin
            content = File.read(file_path)
          rescue IOError, SystemCallError => e
            return {
              success: false,
              error: e.message
            }
          end

          result = format(content)

          if result[:success] && result[:changed] && !@options[:dry_run]
            begin
              File.write(file_path, result[:formatted])
              result[:file_updated] = true
            rescue IOError, SystemCallError => e
              return {
                success: false,
                error: e.message
              }
            end
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

        def convert_to_gfm(doc, original_content)
          kramdown_output = doc.to_kramdown

          # Convert Kramdown task list format back to GFM format
          kramdown_output = kramdown_output.gsub(/^\* \{: \.task-list-item\} <input type="checkbox" class="task-list-item-checkbox"\n  disabled="disabled" \/>(.+)$/m, '- [ ] \1')
          kramdown_output = kramdown_output.gsub(/^\* \{: \.task-list-item\} <input type="checkbox" class="task-list-item-checkbox"\n  disabled="disabled" checked="checked" \/>(.+)$/m, '- [x] \1')

          # Remove task-list class marker
          kramdown_output = kramdown_output.gsub(/^\{: \.task-list\}\n/m, "")

          # Convert indented code blocks back to fenced code blocks
          kramdown_output = kramdown_output.gsub(/^    (.+?)$\n^\{: \.language-(\w+)\}$/m) do |match|
            language = $2
            code_lines = match.split("\n")[0..-2].map { |line| line.sub(/^    /, "") }
            "```#{language}\n#{code_lines.join("\n")}\n```"
          end

          # Clean up remaining language markers
          kramdown_output = kramdown_output.gsub(/^\{: \.language-(\w+)\}$/m, "")

          # Clean up header ID attributes if auto_ids was disabled
          kramdown_output = kramdown_output.gsub(/ +\{#[\w-]+\}$/m, "")

          kramdown_output.strip
        end
      end
    end
  end
end
