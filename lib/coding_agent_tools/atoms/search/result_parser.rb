# frozen_string_literal: true

require 'json'

module CodingAgentTools
  module Atoms
    module Search
      # ResultParser provides parsing of ripgrep and fd output into structured format
      # This is an atom - it has no internal dependencies and provides basic parsing functionality
      class ResultParser
        # Parse ripgrep output into structured results
        # @param output [String] Raw ripgrep output
        # @param format [Symbol] Output format (:text, :json, :files_only)
        # @return [Array<Hash>] Parsed results
        def self.parse_ripgrep_output(output, format = :text)
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
        # @param output [String] Raw fd output
        # @param options [Hash] Parse options
        # @return [Array<Hash>] Parsed results
        def self.parse_fd_output(output, options = {})
          return [] if output.nil? || output.empty?

          lines = output.lines.map(&:strip).reject(&:empty?)
          
          lines.map do |line|
            {
              type: :file,
              path: line,
              absolute_path: options[:absolute_path] ? line : File.expand_path(line),
              basename: File.basename(line),
              dirname: File.dirname(line),
              extension: File.extname(line)[1..-1] || '', # Remove the leading dot
              size: nil, # fd doesn't provide size by default
              modified_time: nil
            }
          end
        end

        # Parse ripgrep JSON output
        # @param output [String] Raw JSON output from ripgrep
        # @return [Array<Hash>] Parsed results
        def self.parse_ripgrep_json(output)
          results = []
          
          output.lines.each do |line|
            line = line.strip
            next if line.empty?
            
            begin
              json_obj = JSON.parse(line)
              
              case json_obj['type']
              when 'match'
                results << parse_ripgrep_match(json_obj)
              when 'summary'
                # Summary object contains stats about the search
                # We can add this information to metadata if needed
                next
              end
            rescue JSON::ParserError => e
              # Skip invalid JSON lines
              warn "Failed to parse ripgrep JSON line: #{e.message}"
              next
            end
          end
          
          results
        end

        # Parse ripgrep text output (default format)
        # @param output [String] Raw text output from ripgrep
        # @return [Array<Hash>] Parsed results
        def self.parse_ripgrep_text(output)
          results = []
          current_file = nil
          
          output.lines.each do |line|
            line = line.chomp
            next if line.empty?
            
            # Check if this is a file path line (when using --with-filename)
            if line.match?(/^[^:]+:\d+:/)
              # Format: file:line:content or file:line:column:content
              parts = line.split(':', 3)
              if parts.length >= 3
                file_path = parts[0]
                line_number = parts[1].to_i
                content = parts[2]
                
                results << {
                  type: :match,
                  path: file_path,
                  line_number: line_number,
                  content: content,
                  column: nil,
                  match_start: nil,
                  match_end: nil
                }
              end
            elsif line.match?(/^[^:]+:\d+:\d+:/)
              # Format with column: file:line:column:content
              parts = line.split(':', 4)
              if parts.length >= 4
                file_path = parts[0]
                line_number = parts[1].to_i
                column = parts[2].to_i
                content = parts[3]
                
                results << {
                  type: :match,
                  path: file_path,
                  line_number: line_number,
                  content: content,
                  column: column,
                  match_start: nil,
                  match_end: nil
                }
              end
            else
              # Might be a file path only (files-with-matches mode)
              results << {
                type: :file,
                path: line,
                matches: nil
              }
            end
          end
          
          results
        end

        # Parse files-only output (from --files-with-matches)
        # @param output [String] Raw output
        # @return [Array<Hash>] Parsed results
        def self.parse_ripgrep_files_only(output)
          output.lines.map(&:strip).reject(&:empty?).map do |file_path|
            {
              type: :file,
              path: file_path,
              matches: nil
            }
          end
        end

        # Group results by file path
        # @param results [Array<Hash>] Search results
        # @return [Hash] Results grouped by file path
        def self.group_by_file(results)
          results.group_by { |result| result[:path] }
        end

        # Filter results by file extension
        # @param results [Array<Hash>] Search results
        # @param extensions [Array<String>] File extensions to include
        # @return [Array<Hash>] Filtered results
        def self.filter_by_extension(results, extensions)
          return results if extensions.empty?
          
          results.select do |result|
            file_ext = File.extname(result[:path])[1..-1] || ''
            extensions.include?(file_ext)
          end
        end

        # Add metadata to results (file size, modified time, etc.)
        # @param results [Array<Hash>] Search results
        # @return [Array<Hash>] Results with metadata
        def self.add_file_metadata(results)
          results.map do |result|
            path = result[:path]
            
            if File.exist?(path)
              stat = File.stat(path)
              result.merge(
                size: stat.size,
                modified_time: stat.mtime,
                readable: File.readable?(path),
                writable: File.writable?(path)
              )
            else
              result.merge(
                size: nil,
                modified_time: nil,
                readable: false,
                writable: false
              )
            end
          end
        end

        private_class_method def self.parse_ripgrep_match(json_obj)
          data = json_obj['data']
          path = data['path']['text']
          lines = data['lines']
          
          # Handle potential multiple lines in the match
          line_text = lines['text']
          line_number = lines['line_number']
          
          # Extract submatch information if available
          submatches = data['submatches'] || []
          
          {
            type: :match,
            path: path,
            line_number: line_number,
            content: line_text,
            submatches: submatches.map do |submatch|
              {
                match_text: submatch['match']['text'],
                start: submatch['start'],
                end: submatch['end']
              }
            end
          }
        end
      end
    end
  end
end