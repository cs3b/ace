# frozen_string_literal: true

require "json"

module Ace
  module Search
    module Atoms
      # ResultParser provides parsing of ripgrep and fd output into structured format
      # This is an atom - pure function for parsing search output
      module ResultParser
        module_function

        # Parse ripgrep output into structured results
        def parse_ripgrep_output(output, format = :text)
          return [] if output.nil? || output.empty?

          case format
          when :json
            parse_ripgrep_json(output)
          when :files_only
            parse_ripgrep_files_only(output)
          else
            parse_ripgrep_text(output)
          end
        end

        # Parse fd output into structured results
        def parse_fd_output(output, options = {})
          return [] if output.nil? || output.empty?

          lines = output.lines.map(&:strip).reject(&:empty?)

          lines.map do |line|
            {
              type: :file,
              path: line,
              absolute_path: options[:absolute_path] ? line : File.expand_path(line),
              basename: File.basename(line),
              dirname: File.dirname(line),
              extension: File.extname(line)[1..] || ""
            }
          end
        end

        # Parse ripgrep JSON output
        def parse_ripgrep_json(output)
          results = []

          output.lines.each do |line|
            line = line.strip
            next if line.empty?

            begin
              json_obj = JSON.parse(line)

              case json_obj["type"]
              when "match"
                data = json_obj["data"]
                results << {
                  type: :match,
                  path: data["path"]["text"],
                  line: data["line_number"],
                  column: data["submatches"]&.first&.dig("start") || 0,
                  text: data["lines"]["text"]&.strip || ""
                }
              end
            rescue JSON::ParserError
              next
            end
          end

          results
        end

        # Parse ripgrep text output (default format)
        def parse_ripgrep_text(output)
          results = []

          output.lines.each do |line|
            line = line.chomp
            next if line.empty?

            # Format: file:line:content or file:line:column:content
            if line.match?(/^([^:]+):(\d+):(\d+)?:?(.*)$/)
              match = line.match(/^([^:]+):(\d+):(\d+)?:?(.*)$/)
              results << {
                type: :match,
                path: match[1],
                line: match[2].to_i,
                column: match[3] ? match[3].to_i : 0,
                text: (match[4] || "").strip
              }
            end
          end

          results
        end

        # Parse files-only output (just file paths)
        def parse_ripgrep_files_only(output)
          output.lines.map(&:strip).reject(&:empty?).map do |file_path|
            {
              type: :file,
              path: file_path
            }
          end
        end
      end
    end
  end
end
