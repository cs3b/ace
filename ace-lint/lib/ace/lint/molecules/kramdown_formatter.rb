# frozen_string_literal: true

require_relative "../atoms/kramdown_parser"
require_relative "../atoms/frontmatter_extractor"
require_relative "markdown_linter"

module Ace
  module Lint
    module Molecules
      # Formats markdown with kramdown
      class KramdownFormatter
        # Format markdown file in place
        # @param file_path [String] Path to markdown file
        # @param options [Hash] Kramdown options
        # @param guardrails [Boolean] Enable structural safety checks before write
        # @return [Hash] Result with :success, :formatted, :errors, :warnings
        def self.format_file(file_path, options: {}, guardrails: false)
          content = File.read(file_path)
          result = format_content(content, options: options)

          return {success: false, formatted: false, errors: result[:errors], warnings: []} unless result[:success]

          formatted_content = result[:formatted_content]
          return {success: true, formatted: false, errors: [], warnings: []} if formatted_content == content

          if guardrails
            structural_changes = detect_structural_changes(content, formatted_content)
            if structural_changes.any?
              return {
                success: true,
                formatted: false,
                errors: [],
                warnings: ["Skipped formatting due to structural change risk: #{structural_changes.join(", ")}"]
              }
            end
          end

          File.write(file_path, formatted_content)
          {success: true, formatted: true, errors: [], warnings: []}
        rescue Errno::ENOENT
          {success: false, formatted: false, errors: ["File not found: #{file_path}"], warnings: []}
        rescue => e
          {success: false, formatted: false, errors: ["Error formatting file: #{e.message}"], warnings: []}
        end

        # Format markdown content
        # @param content [String] Markdown content
        # @param options [Hash] Kramdown options
        # @return [Hash] Result with :success, :formatted_content, :errors
        def self.format_content(content, options: {})
          # Load kramdown configuration from ace-core config cascade
          # Config location: .ace/lint/kramdown.yml
          kramdown_config = Ace::Lint.kramdown_config

          # Convert string keys to symbols (kramdown expects symbols)
          kramdown_opts = kramdown_config.transform_keys(&:to_sym)

          # Merge: config file < formatting defaults < CLI options
          default_options = {
            line_width: kramdown_opts[:line_width] || 120,
            remove_block_html_tags: false,
            remove_span_html_tags: false
          }

          merged_options = kramdown_opts.merge(default_options).merge(options)
          Atoms::KramdownParser.format(content, options: merged_options)
        end

        # Check if content would change after formatting
        # @param content [String] Markdown content
        # @param options [Hash] Kramdown options
        # @return [Boolean] True if formatting would change content
        def self.needs_formatting?(content, options: {})
          result = format_content(content, options: options)
          return false unless result[:success]

          result[:formatted_content] != content
        end

        def self.detect_structural_changes(original, formatted)
          changes = []
          changes << "frontmatter" if frontmatter_changed?(original, formatted)
          changes << "code blocks" if fence_count_changed?(original, formatted)
          changes << "tables" if table_row_count_changed?(original, formatted)
          changes << "html attributes" if html_attributes_changed?(original, formatted)
          changes
        end

        def self.frontmatter_changed?(original, formatted)
          original_frontmatter = Atoms::FrontmatterExtractor.extract(original)
          formatted_frontmatter = Atoms::FrontmatterExtractor.extract(formatted)

          original_frontmatter[:has_frontmatter] != formatted_frontmatter[:has_frontmatter] ||
            original_frontmatter[:frontmatter].to_s != formatted_frontmatter[:frontmatter].to_s
        end

        def self.fence_count_changed?(original, formatted)
          fence_count(original) != fence_count(formatted)
        end

        def self.fence_count(content)
          content.lines.count { |line| line.match?(MarkdownLinter::FENCE_PATTERN) }
        end

        def self.table_row_count_changed?(original, formatted)
          table_row_count(original) != table_row_count(formatted)
        end

        def self.table_row_count(content)
          content.lines.count { |line| line.match?(/^\s*\|.*\|\s*$/) }
        end

        def self.html_attributes_changed?(original, formatted)
          html_attribute_count(formatted) != html_attribute_count(original)
        end

        def self.html_attribute_count(content)
          content.scan(/<([A-Za-z][A-Za-z0-9:-]*)([^>]*)>/).sum do |_tag_name, attributes|
            attributes.scan(/\s+[A-Za-z_:][\w:.-]*(?:\s*=\s*(?:"[^"]*"|'[^']*'|[^\s"'=<>`]+))?/).size
          end
        end

        private_class_method :frontmatter_changed?,
          :fence_count_changed?,
          :fence_count,
          :table_row_count_changed?,
          :table_row_count,
          :html_attributes_changed?,
          :html_attribute_count
      end
    end
  end
end
