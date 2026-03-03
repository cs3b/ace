# frozen_string_literal: true

require "ace/support/items"
require_relative "../atoms/retro_file_pattern"

module Ace
  module Retro
    module Molecules
      # Wraps DirectoryScanner for .retro.md files.
      # Returns scan results with raw b36ts IDs (no type markers).
      class RetroScanner
        attr_reader :last_scan_total, :last_folder_counts

        # @param root_dir [String] Root directory containing retros (e.g., ".ace-retros")
        def initialize(root_dir)
          @root_dir = root_dir
          @scanner = Ace::Support::Items::Molecules::DirectoryScanner.new(
            root_dir,
            file_pattern: Atoms::RetroFilePattern::FILE_GLOB
          )
        end

        # Scan for all retros
        # @return [Array<ScanResult>] Sorted scan results
        def scan
          @scanner.scan
        end

        # Scan and filter by special folder or virtual filter
        # @param folder [String, nil] Folder name, virtual filter ("next", "all"), or nil for all
        # @return [Array<ScanResult>] Filtered scan results
        def scan_in_folder(folder)
          results = scan
          @last_scan_total = results.size
          @last_folder_counts = results.group_by(&:special_folder).transform_values(&:size)
          return results if folder.nil?

          virtual = Ace::Support::Items::Atoms::SpecialFolderDetector.virtual_filter?(folder)
          case virtual
          when :all  then results
          when :next then results.select { |r| r.special_folder.nil? }
          else
            normalized = Ace::Support::Items::Atoms::SpecialFolderDetector.normalize(folder)
            results.select { |r| r.special_folder == normalized }
          end
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
