# frozen_string_literal: true

require "ace/support/items"
require_relative "../atoms/idea_file_pattern"

module Ace
  module Idea
    module Molecules
      # Wraps DirectoryScanner for .idea.s.md files.
      # Returns scan results with raw b36ts IDs (no type markers).
      class IdeaScanner
        # @param root_dir [String] Root directory containing ideas (e.g., ".ace-ideas")
        def initialize(root_dir)
          @root_dir = root_dir
          @scanner = Ace::Support::Items::Molecules::DirectoryScanner.new(
            root_dir,
            file_pattern: Atoms::IdeaFilePattern::FILE_GLOB
          )
        end

        # Scan for all ideas
        # @return [Array<ScanResult>] Sorted scan results
        def scan
          @scanner.scan
        end

        # Scan and filter by special folder
        # @param folder [String, nil] Special folder name (e.g., "_maybe") or nil for all
        # @return [Array<ScanResult>] Filtered scan results
        def scan_in_folder(folder)
          results = scan
          return results if folder.nil?

          # Normalize the folder name
          normalized = Ace::Support::Items::Atoms::SpecialFolderDetector.normalize(folder)
          results.select { |r| r.special_folder == normalized }
        end

        # Check if root directory exists
        # @return [Boolean]
        def root_exists?
          Dir.exist?(@root_dir)
        end
      end
    end
  end
end
