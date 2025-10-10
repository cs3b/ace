# frozen_string_literal: true

require "yaml"
require "cgi"

module CodingAgentTools
  module Molecules
    module Context
      # OutputFormatter - Molecule for formatting context in multiple output formats
      #
      # Responsibilities:
      # - Format aggregated context as XML
      # - Format aggregated context as YAML
      # - Format aggregated context as Markdown with embedded XML
      # - Handle truncation for large outputs
      class OutputFormatter
        TRUNCATION_LIMIT = 100000  # 100KB per file/command output

        def initialize(format = "markdown-xml")
          @format = format
        end

        # Format aggregated context according to specified format
        #
        # @param context [Hash] Aggregated context with :files, :commands, :errors
        # @return [String] Formatted output
        def format(context)
          case @format
          when "xml"
            format_as_xml(context)
          when "yaml"
            format_as_yaml(context)
          when "markdown-xml"
            format_as_markdown_xml(context)
          else
            raise ArgumentError, "Unsupported format: #{@format}"
          end
        end

        private

        # Format as pure XML
        #
        # @param context [Hash] Context data
        # @return [String] XML formatted output
        def format_as_xml(context)
          lines = ['<?xml version="1.0" encoding="UTF-8"?>', "<context>"]

          # Files section
          if context[:files].any?
            lines << "  <files>"
            context[:files].each do |file|
              content = truncate_content(file[:content])
              escaped_content = CGI.escapeHTML(content)
              lines << "    <file path=\"#{CGI.escapeHTML(file[:path])}\" size=\"#{file[:size]}\">"
              lines << escaped_content
              lines << "    </file>"
            end
            lines << "  </files>"
          end

          # Commands section
          if context[:commands].any?
            lines << "  <commands>"
            context[:commands].each do |cmd|
              output = truncate_content(cmd[:output] || "")
              escaped_output = CGI.escapeHTML(output)
              cmd_attrs = "command=\"#{CGI.escapeHTML(cmd[:command])}\" success=\"#{cmd[:success]}\""
              cmd_attrs += " error=\"#{CGI.escapeHTML(cmd[:error])}\"" if cmd[:error]

              lines << "    <output #{cmd_attrs}>"
              lines << escaped_output
              lines << "    </output>"
            end
            lines << "  </commands>"
          end

          # Errors section
          if context[:errors].any?
            lines << "  <errors>"
            context[:errors].each do |error|
              lines << "    <error>#{CGI.escapeHTML(error)}</error>"
            end
            lines << "  </errors>"
          end

          lines << "</context>"
          lines.join("\n")
        end

        # Format as YAML
        #
        # @param context [Hash] Context data
        # @return [String] YAML formatted output
        def format_as_yaml(context)
          formatted_context = {
            "context" => {}
          }

          # Files section
          if context[:files].any?
            formatted_context["context"]["files"] = context[:files].map do |file|
              {
                "path" => file[:path],
                "size" => file[:size],
                "content" => truncate_content(file[:content])
              }
            end
          end

          # Commands section
          if context[:commands].any?
            formatted_context["context"]["commands"] = context[:commands].map do |cmd|
              cmd_entry = {
                "command" => cmd[:command],
                "success" => cmd[:success],
                "output" => truncate_content(cmd[:output] || "")
              }
              cmd_entry["error"] = cmd[:error] if cmd[:error]
              cmd_entry
            end
          end

          # Errors section
          if context[:errors].any?
            formatted_context["context"]["errors"] = context[:errors]
          end

          YAML.dump(formatted_context)
        end

        # Format as Markdown with embedded XML
        #
        # @param context [Hash] Context data
        # @return [String] Markdown+XML formatted output
        def format_as_markdown_xml(context)
          lines = ["# Context"]
          lines << ""

          # Files section
          if context[:files].any?
            lines << "## Files"
            lines << ""
            context[:files].each do |file|
              content = truncate_content(file[:content])
              lines << "<file path=\"#{CGI.escapeHTML(file[:path])}\" size=\"#{file[:size]}\">"
              lines << content
              lines << "</file>"
              lines << ""
            end
          end

          # Commands section
          if context[:commands].any?
            lines << "## Commands"
            lines << ""
            context[:commands].each do |cmd|
              output = truncate_content(cmd[:output] || "")
              cmd_attrs = "command=\"#{CGI.escapeHTML(cmd[:command])}\" success=\"#{cmd[:success]}\""
              cmd_attrs += " error=\"#{CGI.escapeHTML(cmd[:error])}\"" if cmd[:error]

              lines << "<output #{cmd_attrs}>"
              lines << output
              lines << "</output>"
              lines << ""
            end
          end

          # Errors section
          if context[:errors].any?
            lines << "## Errors"
            lines << ""
            context[:errors].each do |error|
              lines << "- #{error}"
            end
            lines << ""
          end

          lines.join("\n").strip
        end

        # Truncate content if it exceeds limit
        #
        # @param content [String] Content to potentially truncate
        # @return [String] Original or truncated content
        def truncate_content(content)
          return "" if content.nil?
          return content if content.bytesize <= TRUNCATION_LIMIT

          truncated = content.byteslice(0, TRUNCATION_LIMIT)
          # Try to end at a line boundary if possible
          last_newline = truncated.rindex("\n")
          if last_newline && last_newline > TRUNCATION_LIMIT * 0.8
            truncated = truncated[0..last_newline]
          end

          truncated + "\n\n[... content truncated at #{TRUNCATION_LIMIT} bytes ...]"
        end
      end
    end
  end
end
