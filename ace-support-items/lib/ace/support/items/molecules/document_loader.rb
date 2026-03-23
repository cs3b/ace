# frozen_string_literal: true

require_relative "../atoms/frontmatter_parser"
require_relative "../atoms/title_extractor"
require_relative "../models/loaded_document"

module Ace
  module Support
    module Items
      module Molecules
        # Loads a document from an item directory: finds the spec file,
        # parses frontmatter/body, extracts title, and enumerates attachments.
        class DocumentLoader
          # Load a document from a directory path
          # @param dir_path [String] Path to item directory
          # @param file_pattern [String] Glob pattern for spec files (e.g., "*.idea.s.md")
          # @param spec_extension [String] Extension to exclude from attachments (e.g., ".idea.s.md")
          # @return [LoadedDocument, nil] Loaded document or nil if not found
          def self.load(dir_path, file_pattern:, spec_extension:)
            return nil unless Dir.exist?(dir_path)

            spec_file = Dir.glob(File.join(dir_path, file_pattern)).first
            return nil unless spec_file

            build_document(dir_path, spec_file, spec_extension)
          end

          # Load a document from a ScanResult
          # @param scan_result [ScanResult] Scan result with dir_path and file_path
          # @param file_pattern [String] Glob pattern (unused when file_path present, kept for API consistency)
          # @param spec_extension [String] Extension to exclude from attachments
          # @return [LoadedDocument, nil] Loaded document or nil
          def self.from_scan_result(scan_result, spec_extension:, file_pattern: nil)
            return nil unless scan_result&.dir_path && Dir.exist?(scan_result.dir_path)

            spec_file = scan_result.file_path || Dir.glob(File.join(scan_result.dir_path, file_pattern)).first
            return nil unless spec_file

            build_document(scan_result.dir_path, spec_file, spec_extension)
          end

          # Build a LoadedDocument from directory and spec file
          private_class_method def self.build_document(dir_path, spec_file, spec_extension)
            content = File.read(spec_file)
            frontmatter, body = Atoms::FrontmatterParser.parse(content)

            folder_name = File.basename(dir_path)
            title = frontmatter["title"] ||
              Atoms::TitleExtractor.extract(body) ||
              folder_name

            attachments = enumerate_attachments(dir_path, spec_extension)

            Models::LoadedDocument.new(
              frontmatter: frontmatter,
              body: body,
              title: title,
              file_path: spec_file,
              dir_path: dir_path,
              attachments: attachments
            )
          end

          # List non-spec files in directory (excluding hidden files)
          private_class_method def self.enumerate_attachments(dir_path, spec_extension)
            Dir.glob(File.join(dir_path, "*"))
              .select { |f| File.file?(f) }
              .reject { |f| f.end_with?(spec_extension) }
              .map { |f| File.basename(f) }
              .reject { |name| name.start_with?(".") }
              .sort
          end
        end
      end
    end
  end
end
