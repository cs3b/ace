# frozen_string_literal: true

require "ace/support/markdown"
require_relative "../models/document"

module Ace
  module Docs
    module Molecules
      # Loads document files with frontmatter parsing
      class DocumentLoader
        # Load a single document from file
        # @param path [String] Path to the markdown file
        # @return [Document, nil] Document object or nil if loading fails
        def self.load_file(path)
          return nil unless File.exist?(path)
          return nil unless path.end_with?(".md")

          content = File.read(path)
          doc = Ace::Support::Markdown::Models::MarkdownDocument.parse(content, file_path: path)

          # Only create document if it has frontmatter
          return nil if doc.frontmatter.empty?

          Models::Document.new(
            path: path,
            frontmatter: doc.frontmatter,
            content: doc.raw_body
          )
        rescue StandardError => e
          return nil if e.message.include?("No frontmatter found")

          warn "Error loading document #{path}: #{e.message}"
          nil
        end

        # Load multiple documents from paths
        # @param paths [Array<String>] Array of file paths
        # @return [Array<Document>] Array of loaded documents
        def self.load_files(paths)
          paths.map { |path| load_file(path) }.compact
        end

        # Load all documents from a directory
        # @param directory [String] Directory path
        # @param recursive [Boolean] Whether to search recursively
        # @return [Array<Document>] Array of loaded documents
        def self.load_directory(directory, recursive: true)
          return [] unless File.directory?(directory)

          pattern = recursive ? "**/*.md" : "*.md"
          md_files = Dir.glob(File.join(directory, pattern))

          load_files(md_files)
        end

        # Load documents matching a glob pattern
        # @param pattern [String] Glob pattern
        # @param base_dir [String] Base directory for the pattern
        # @return [Array<Document>] Array of loaded documents
        def self.load_glob(pattern, base_dir: Dir.pwd)
          md_files = Dir.glob(File.join(base_dir, pattern))
          load_files(md_files)
        end

        # Check if a file has ace-docs frontmatter
        # @param path [String] File path
        # @return [Boolean] true if file has valid ace-docs frontmatter
        def self.managed_document?(path)
          return false unless File.exist?(path)
          return false unless path.end_with?(".md")

          content = File.read(path)
          doc = Ace::Support::Markdown::Models::MarkdownDocument.parse(content)

          # Check if has doc-type field (ace-docs requirement)
          !doc.frontmatter.empty? && doc.frontmatter["doc-type"]
        rescue StandardError
          false
        end

        # Load document or return error document
        # @param path [String] File path
        # @return [Document] Document object (may be empty with error metadata)
        def self.load_or_error(path)
          doc = load_file(path)
          return doc if doc

          # Return error document
          Models::Document.new(
            path: path,
            frontmatter: {
              "error" => "Failed to load document"
            }
          )
        end
      end
    end
  end
end
