# frozen_string_literal: true

require_relative "../../atoms/code/file_content_reader"
require_relative "../../atoms/taskflow_management/file_system_scanner"
require "rexml/document"

module CodingAgentTools
  module Molecules
    module Code
      # Extracts file contents matching patterns
      # This is a molecule - it composes atoms to extract file content
      class FilePatternExtractor
        def initialize
          @file_reader = Atoms::Code::FileContentReader.new
          @file_scanner = Atoms::TaskflowManagement::FileSystemScanner
        end

        # Extract files matching a pattern
        # @param pattern [String] file pattern or path
        # @return [Hash] {xml_content: String, file_list: Array, success: Boolean, error: String}
        def extract_files(pattern)
          # Handle single file case
          if File.exist?(pattern) && !File.directory?(pattern)
            return extract_single_file(pattern)
          end

          # Find files matching pattern
          files = find_matching_files(pattern)

          if files.empty?
            return {
              xml_content: nil,
              file_list: [],
              success: false,
              error: "No files found matching pattern: #{pattern}"
            }
          end

          # Build XML content
          xml_content = build_xml_content(files)

          {
            xml_content: xml_content,
            file_list: files,
            success: true,
            error: nil
          }
        end

        # Save extracted files to XML with metadata
        # @param pattern [String] file pattern
        # @param session_dir [String] session directory path
        # @return [Hash] {xml_file: String, meta_file: String, success: Boolean, error: String}
        def extract_and_save(pattern, session_dir)
          # Extract files
          result = extract_files(pattern)
          return result unless result[:success]

          # Save XML file
          xml_file = File.join(session_dir, "input.xml")
          meta_file = File.join(session_dir, "input.meta")

          begin
            File.write(xml_file, result[:xml_content])

            # Determine type
            type = if File.exist?(pattern) && !File.directory?(pattern)
              "single_file"
            else
              "file_pattern"
            end

            # Write metadata
            meta_content = <<~META
              target: #{pattern}
              type: #{type}
              files: #{result[:file_list].count}
            META

            # Add size info for single file
            if type == "single_file" && result[:file_list].count == 1
              lines = File.readlines(result[:file_list].first).count
              meta_content += "size: #{lines} lines\n"
            end

            File.write(meta_file, meta_content)

            {
              xml_file: xml_file,
              meta_file: meta_file,
              success: true,
              error: nil
            }
          rescue => e
            {
              xml_file: nil,
              meta_file: nil,
              success: false,
              error: "Failed to save files: #{e.message}"
            }
          end
        end

        private

        # Extract single file
        # @param file_path [String] file path
        # @return [Hash] extraction result
        def extract_single_file(file_path)
          result = @file_reader.read(file_path)

          if result[:success]
            xml_content = build_xml_content([file_path])
            {
              xml_content: xml_content,
              file_list: [file_path],
              success: true,
              error: nil
            }
          else
            {
              xml_content: nil,
              file_list: [],
              success: false,
              error: result[:error]
            }
          end
        end

        # Find files matching pattern
        # @param pattern [String] file pattern
        # @return [Array<String>] matching file paths
        def find_matching_files(pattern)
          # Use glob for patterns with wildcards
          if pattern.include?("*") || pattern.include?("?") || pattern.include?("[")
            Dir.glob(pattern).select { |f| File.file?(f) }
          else
            # Use file system scanner for directory traversal
            result = @file_scanner.find_files_with_pattern(".", pattern)
            result[:files] || []
          end
        end

        # Build XML content from files
        # @param files [Array<String>] file paths
        # @return [String] XML content
        def build_xml_content(files)
          doc = REXML::Document.new
          doc.add_element("documents")
          root = doc.root

          files.each do |file_path|
            result = @file_reader.read(file_path)
            next unless result[:success]

            document = root.add_element("document")
            document.add_attribute("path", file_path)

            # Use CDATA for file content
            cdata = REXML::CData.new(result[:content])
            document.add_text(cdata)
          end

          # Format with proper XML declaration
          output = StringIO.new
          formatter = REXML::Formatters::Pretty.new(2)
          formatter.write(doc, output)

          "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n#{output.string}"
        end
      end
    end
  end
end
