# frozen_string_literal: true

require_relative '../atoms/kramdown_parser'

module Ace
  module Lint
    module Molecules
      # Formats markdown with kramdown
      class KramdownFormatter
        # Format markdown file in place
        # @param file_path [String] Path to markdown file
        # @param options [Hash] Kramdown options
        # @return [Hash] Result with :success, :formatted, :errors
        def self.format_file(file_path, options: {})
          content = File.read(file_path)
          result = format_content(content, options: options)

          if result[:success] && result[:formatted_content]
            File.write(file_path, result[:formatted_content])
            { success: true, formatted: true, errors: [] }
          else
            { success: false, formatted: false, errors: result[:errors] }
          end
        rescue Errno::ENOENT
          { success: false, formatted: false, errors: ["File not found: #{file_path}"] }
        rescue StandardError => e
          { success: false, formatted: false, errors: ["Error formatting file: #{e.message}"] }
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
      end
    end
  end
end
