# frozen_string_literal: true

require "pathname"
require_relative "../models/scan_result"
require_relative "../atoms/special_folder_detector"

module Ace
  module Support
    module Items
      module Molecules
        # Recursively scans an item root directory for item spec files.
        # Returns ScanResult objects with folder and ID metadata.
        #
        # Item directories follow the convention: {id}-{slug}/
        # Item spec files match a configurable glob pattern within those directories.
        #
        # The id_extractor proc allows customizing how IDs are extracted from folder names.
        # Default: matches 6-char b36ts IDs (e.g., "8ppq7w-dark-mode")
        # Custom: can match type-marked IDs (e.g., "8pp.t.q7w-fix-login")
        class DirectoryScanner
          # Default extractor for 6-char raw b36ts IDs
          DEFAULT_ID_EXTRACTOR = ->(folder_name) {
            match = folder_name.match(/^([0-9a-z]{6})-?(.*)$/)
            return nil unless match

            id = match[1]
            slug = match[2].empty? ? folder_name : match[2]
            [id, slug]
          }

          # @param root_dir [String] Root directory to scan
          # @param file_pattern [String] Glob pattern for spec files (e.g., "*.idea.s.md")
          # @param id_extractor [Proc, nil] Custom proc to extract [id, slug] from folder name.
          #   Receives folder_name string, returns [id, slug] array or nil if no match.
          def initialize(root_dir, file_pattern:, id_extractor: nil)
            @root_dir = root_dir
            @file_pattern = file_pattern
            @id_extractor = id_extractor || DEFAULT_ID_EXTRACTOR
          end

          # Scan root directory recursively for items
          # @return [Array<ScanResult>] List of scan results, sorted by ID (chronological)
          def scan
            return [] unless Dir.exist?(@root_dir)

            results = []
            scan_directory(@root_dir, results)
            results.sort_by(&:id)
          end

          private

          def scan_directory(dir, results)
            Dir.entries(dir).sort.each do |entry|
              next if entry.start_with?(".")

              full_path = File.join(dir, entry)
              next unless File.directory?(full_path)

              # Check if this directory contains spec files
              spec_files = Dir.glob(File.join(full_path, @file_pattern))
              if spec_files.any?
                result = build_result(full_path, spec_files.first)
                results << result if result
              else
                # Recurse into subdirectory (for special folders like _maybe/)
                scan_directory(full_path, results)
              end
            end
          end

          def build_result(dir_path, file_path)
            folder_name = File.basename(dir_path)

            # Extract ID from folder name: "8ppq7w-dark-mode" => id="8ppq7w", slug="dark-mode"
            id, slug = extract_id_and_slug(folder_name)
            return nil unless id

            # Detect special folder (e.g., _maybe, _archive)
            special_folder = Atoms::SpecialFolderDetector.detect_in_path(dir_path, root: @root_dir)

            Models::ScanResult.new(
              id: id,
              slug: slug,
              folder_name: folder_name,
              dir_path: dir_path,
              file_path: file_path,
              special_folder: special_folder
            )
          end

          # Extract ID and slug from folder name using the configured extractor
          # @return [Array<String, String>, nil] [id, slug] or nil if pattern doesn't match
          def extract_id_and_slug(folder_name)
            @id_extractor.call(folder_name)
          end
        end
      end
    end
  end
end
