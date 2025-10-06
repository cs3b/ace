# frozen_string_literal: true

require 'yaml'

module Ace
  module Core
    module Molecules
      # Formats aggregated content into various output formats
      class OutputFormatter
        # Supported output formats
        FORMATS = %w[markdown yaml xml markdown-xml json].freeze

        def initialize(format = 'markdown')
          @format = validate_format(format)
        end

        # Format aggregated content
        # @param data [Hash] Aggregated data with files and commands
        # @return [String] Formatted output
        def format(data)
          case @format
          when 'markdown'
            format_markdown(data)
          when 'yaml'
            format_yaml(data)
          when 'xml'
            format_xml(data)
          when 'markdown-xml'
            format_markdown_xml(data)
          when 'json'
            format_json(data)
          else
            format_markdown(data)
          end
        end

        # Format as pure markdown
        # @param data [Hash] Data to format
        # @return [String] Markdown formatted output
        def format_markdown(data)
          output = []

          # Add header
          output << "# Context"
          output << ""

          # Add metadata if present
          if data[:metadata]
            output << "## Metadata"
            output << ""
            data[:metadata].each do |key, value|
              output << "- **#{key}**: #{value}"
            end
            output << ""
          end

          # Add files section
          if data[:files] && !data[:files].empty?
            output << "## Files"
            output << ""

            data[:files].each do |file|
              output << "### #{file[:path]}"
              output << ""
              output << "```"
              output << file[:content]
              output << "```"
              output << ""
            end
          end

          # Add commands section
          if data[:commands] && !data[:commands].empty?
            output << "## Commands"
            output << ""

            data[:commands].each do |cmd|
              output << "### Command: `#{cmd[:command]}`"
              output << ""

              if cmd[:success]
                output << "**Output:**"
                output << "```"
                output << cmd[:output]
                output << "```"
              else
                output << "**Error:** #{cmd[:error]}"
              end
              output << ""
            end
          end

          # Add diffs section
          if data[:diffs] && !data[:diffs].empty?
            output << "## Git Diffs"
            output << ""

            data[:diffs].each do |diff|
              output << "### Diff: `#{diff[:range]}`"
              output << ""

              if diff[:success]
                output << "```diff"
                output << diff[:output]
                output << "```"
              else
                output << "**Error:** #{diff[:error]}"
              end
              output << ""
            end
          end

          # Add errors section
          if data[:errors] && !data[:errors].empty?
            output << "## Errors"
            output << ""
            data[:errors].each do |error|
              output << "- #{error}"
            end
            output << ""
          end

          output.join("\n").strip
        end

        # Format as YAML
        # @param data [Hash] Data to format
        # @return [String] YAML formatted output
        def format_yaml(data)
          clean_data = prepare_for_serialization(data)
          YAML.dump(clean_data)
        end

        # Format as JSON
        # @param data [Hash] Data to format
        # @return [String] JSON formatted output
        def format_json(data)
          require 'json'
          clean_data = prepare_for_serialization(data)
          JSON.pretty_generate(clean_data)
        end

        # Format as XML
        # @param data [Hash] Data to format
        # @return [String] XML formatted output
        def format_xml(data)
          output = []
          output << '<?xml version="1.0" encoding="UTF-8"?>'
          output << '<context>'

          # Add metadata
          if data[:metadata]
            output << '  <metadata>'
            data[:metadata].each do |key, value|
              output << "    <#{key}>#{escape_xml(value.to_s)}</#{key}>"
            end
            output << '  </metadata>'
          end

          # Add files
          if data[:files] && !data[:files].empty?
            output << '  <files>'
            data[:files].each do |file|
              output << "    <file path=\"#{escape_xml(file[:path])}\" size=\"#{file[:size]}\">"
              output << "      <content><![CDATA[#{file[:content]}]]></content>"
              output << '    </file>'
            end
            output << '  </files>'
          end

          # Add commands
          if data[:commands] && !data[:commands].empty?
            output << '  <commands>'
            data[:commands].each do |cmd|
              output << "    <command name=\"#{escape_xml(cmd[:command])}\" success=\"#{cmd[:success]}\">"
              if cmd[:output]
                output << "      <output><![CDATA[#{cmd[:output]}]]></output>"
              end
              if cmd[:error]
                output << "      <error>#{escape_xml(cmd[:error])}</error>"
              end
              output << '    </command>'
            end
            output << '  </commands>'
          end

          # Add diffs
          if data[:diffs] && !data[:diffs].empty?
            output << '  <diffs>'
            data[:diffs].each do |diff|
              output << "    <diff range=\"#{escape_xml(diff[:range])}\" success=\"#{diff[:success]}\">"
              if diff[:output]
                output << "      <output><![CDATA[#{diff[:output]}]]></output>"
              end
              if diff[:error]
                output << "      <error>#{escape_xml(diff[:error])}</error>"
              end
              output << '    </diff>'
            end
            output << '  </diffs>'
          end

          # Add errors
          if data[:errors] && !data[:errors].empty?
            output << '  <errors>'
            data[:errors].each do |error|
              output << "    <error>#{escape_xml(error)}</error>"
            end
            output << '  </errors>'
          end

          output << '</context>'
          output.join("\n")
        end

        # Format as markdown with embedded XML (hybrid format)
        # @param data [Hash] Data to format
        # @return [String] Markdown-XML formatted output
        def format_markdown_xml(data)
          output = []

          output << "# Context"
          output << ""

          # Add metadata
          if data[:metadata]
            output << "## Metadata"
            output << ""
            data[:metadata].each do |key, value|
              output << "- **#{key}**: #{value}"
            end
            output << ""
          end

          # Add files as XML blocks
          if data[:files] && !data[:files].empty?
            output << "## Files"
            output << ""

            data[:files].each do |file|
              size_info = file[:size] ? " size=\"#{file[:size]}\"" : ""
              output << "<file path=\"#{escape_xml(file[:path])}\"#{size_info}>"
              output << file[:content]
              output << "</file>"
              output << ""
            end
          end

          # Add commands
          if data[:commands] && !data[:commands].empty?
            output << "## Commands"
            output << ""

            data[:commands].each do |cmd|
              success_attr = cmd[:success] ? 'true' : 'false'
              error_attr = cmd[:error] ? " error=\"#{escape_xml(cmd[:error])}\"" : ""

              output << "<output command=\"#{escape_xml(cmd[:command])}\" success=\"#{success_attr}\"#{error_attr}>"
              output << ""
              output << cmd[:output] if cmd[:output]
              output << "</output>"
              output << ""
            end
          end

          # Add diffs
          if data[:diffs] && !data[:diffs].empty?
            output << "## Git Diffs"
            output << ""

            data[:diffs].each do |diff|
              success_attr = diff[:success] ? 'true' : 'false'
              error_attr = diff[:error] ? " error=\"#{escape_xml(diff[:error])}\"" : ""

              output << "<diff range=\"#{escape_xml(diff[:range])}\" success=\"#{success_attr}\"#{error_attr}>"
              output << ""
              output << diff[:output] if diff[:output]
              output << "</diff>"
              output << ""
            end
          end

          # Add errors
          if data[:errors] && !data[:errors].empty?
            output << "## Errors"
            output << ""
            data[:errors].each do |error|
              output << "- #{error}"
            end
          end

          output.join("\n").strip
        end

        private

        # Validate and normalize format
        # @param format [String] Format to validate
        # @return [String] Valid format
        def validate_format(format)
          normalized = format.to_s.downcase
          FORMATS.include?(normalized) ? normalized : 'markdown'
        end

        # Prepare data for serialization (YAML/JSON)
        # @param data [Hash] Data to prepare
        # @return [Hash] Clean data for serialization
        def prepare_for_serialization(data)
          {
            'metadata' => data[:metadata],
            'files' => data[:files]&.map do |f|
              {
                'path' => f[:path],
                'content' => f[:content],
                'size' => f[:size]
              }.compact
            end,
            'commands' => data[:commands]&.map do |c|
              {
                'command' => c[:command],
                'output' => c[:output],
                'success' => c[:success],
                'error' => c[:error]
              }.compact
            end,
            'errors' => data[:errors],
            'stats' => data[:stats]
          }.compact
        end

        # Escape XML special characters
        # @param text [String] Text to escape
        # @return [String] Escaped text
        def escape_xml(text)
          text.to_s
            .gsub('&', '&amp;')
            .gsub('<', '&lt;')
            .gsub('>', '&gt;')
            .gsub('"', '&quot;')
            .gsub("'", '&apos;')
        end
      end
    end
  end
end