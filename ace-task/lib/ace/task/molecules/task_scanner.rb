# frozen_string_literal: true

require "ace/support/items"

module Ace
  module Task
    module Molecules
      # Wraps DirectoryScanner for task-format directories.
      # Uses a custom id_extractor that matches xxx.t.yyy-slug folder names.
      # Excludes subtask folders from primary scan results.
      class TaskScanner
        attr_reader :last_scan_total, :last_folder_counts

        # ID extractor for task-format folders: "8pp.t.q7w-fix-login"
        TASK_ID_EXTRACTOR = ->(folder_name) {
          match = folder_name.match(/^([0-9a-z]{3}\.[a-z]\.[0-9a-z]{3})-(.+)$/)
          return nil unless match

          id = match[1]
          slug = match[2]
          [id, slug]
        }

        FILE_PATTERN = "*.s.md"

        # @param root_dir [String] Root directory containing tasks (e.g., ".ace-tasks")
        def initialize(root_dir)
          @root_dir = root_dir
          @scanner = Ace::Support::Items::Molecules::DirectoryScanner.new(
            root_dir,
            file_pattern: FILE_PATTERN,
            id_extractor: TASK_ID_EXTRACTOR
          )
        end

        # Scan for all primary tasks (excludes subtask folders).
        # @return [Array<ScanResult>] Sorted scan results
        def scan
          @scanner.scan.reject { |sr| subtask_folder?(sr.folder_name) }
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

        # Scan for all items including subtask folders.
        # @return [Array<ScanResult>] Sorted scan results
        def scan_all
          @scanner.scan
        end

        # Scan for subtask directories within a parent task directory.
        # Subtask folders follow the pattern: {parent_id}.{char}-{slug}
        #
        # @param parent_dir [String] Path to the parent task directory
        # @param parent_id [String] Formatted parent task ID (e.g., "8pp.t.q7w")
        # @return [Array<ScanResult>] Subtask scan results, sorted by ID
        def scan_subtasks(parent_dir, parent_id:)
          return [] unless Dir.exist?(parent_dir)

          results = []
          Dir.entries(parent_dir).sort.each do |entry|
            next if entry.start_with?(".")

            full_path = File.join(parent_dir, entry)
            next unless File.directory?(full_path)

            subtask_id = nil
            slug = nil

            # Short format: "0-slug" or "a-slug"
            if (short_match = entry.match(/^([a-z0-9])-(.+)$/))
              subtask_id = "#{parent_id}.#{short_match[1]}"
              slug = short_match[2]
            else
              next
            end

            spec_files = Dir.glob(File.join(full_path, FILE_PATTERN))
            next if spec_files.empty?

            special_folder = Ace::Support::Items::Atoms::SpecialFolderDetector.detect_in_path(
              full_path, root: @root_dir
            )

            results << Ace::Support::Items::Models::ScanResult.new(
              id: subtask_id,
              slug: slug,
              folder_name: entry,
              dir_path: full_path,
              file_path: spec_files.first,
              special_folder: special_folder
            )
          end

          results.sort_by(&:id)
        end

        # Check if root directory exists
        # @return [Boolean]
        def root_exists?
          Dir.exist?(@root_dir)
        end

        private

        # Check if a folder name matches the subtask pattern
        def subtask_folder?(folder_name)
          folder_name.match?(/\A[a-z0-9]-/)
        end
      end
    end
  end
end
