# frozen_string_literal: true

require_relative "../atoms/task_file_pattern"

module Ace
  module Task
    module Molecules
      # Validates the directory structure of a tasks root directory.
      # Checks folder naming, file naming, and structural conventions.
      class TaskStructureValidator
        # Task folder naming pattern: {xxx.t.yyy}-{slug}
        FOLDER_PATTERN = /^[0-9a-z]{3}\.[a-z]\.[0-9a-z]{3}-.+$/

        # @param root_dir [String] Root directory for tasks (e.g., ".ace-tasks")
        def initialize(root_dir)
          @root_dir = root_dir
        end

        # Validate the entire tasks directory structure
        # @return [Array<Hash>] List of issues found
        def validate(root_dir = @root_dir)
          issues = []

          unless Dir.exist?(root_dir)
            issues << {type: :error, message: "Tasks root directory does not exist", location: root_dir}
            return issues
          end

          check_folder_naming(root_dir, issues)
          check_spec_files(root_dir, issues)
          check_stale_backups(root_dir, issues)
          check_empty_directories(root_dir, issues)

          issues
        end

        private

        # Check that task folders follow {xxx.t.yyy}-{slug} naming
        def check_folder_naming(root_dir, issues)
          task_dirs(root_dir).each do |dir|
            folder_name = File.basename(dir)

            next if folder_name.start_with?("_")

            unless folder_name.match?(FOLDER_PATTERN)
              issues << {
                type: :error,
                message: "Folder name does not match '{id}-{slug}' convention: '#{folder_name}'",
                location: dir
              }
            end
          end
        end

        # Check that each task folder has exactly one .s.md spec file (excluding .idea.s.md)
        def check_spec_files(root_dir, issues)
          task_dirs(root_dir).each do |dir|
            folder_name = File.basename(dir)
            next if folder_name.start_with?("_")

            spec_files = Dir.glob(File.join(dir, Atoms::TaskFilePattern::SPEC_PATTERN))
              .reject { |f| f.end_with?(".idea.s.md") }

            if spec_files.empty?
              issues << {
                type: :warning,
                message: "No .s.md spec file in task folder",
                location: dir
              }
            elsif spec_files.size > 1
              issues << {
                type: :warning,
                message: "Multiple .s.md spec files in folder (#{spec_files.size} found)",
                location: dir
              }
            end
          end
        end

        # Check for stale backup/tmp files
        def check_stale_backups(root_dir, issues)
          backup_patterns = [
            File.join(root_dir, "**", "*.backup.*"),
            File.join(root_dir, "**", "*.tmp"),
            File.join(root_dir, "**", "*~")
          ]

          backup_patterns.each do |pattern|
            Dir.glob(pattern).each do |file|
              next if file.include?("/.git/")

              issues << {
                type: :warning,
                message: "Stale backup file (safe to delete)",
                location: file
              }
            end
          end
        end

        # Check for empty directories
        def check_empty_directories(root_dir, issues)
          Dir.glob(File.join(root_dir, "**", "*")).each do |path|
            next unless File.directory?(path)
            next if path.include?("/.git/")

            files = Dir.glob(File.join(path, "**", "*")).select { |f| File.file?(f) }
            if files.empty?
              issues << {
                type: :warning,
                message: "Empty directory (safe to delete)",
                location: path
              }
            end
          end
        end

        # Find all immediate subdirectories that look like task folders
        # (excludes special folders which are containers, includes their children)
        def task_dirs(root_dir)
          dirs = []

          Dir.glob(File.join(root_dir, "*")).each do |path|
            next unless File.directory?(path)

            folder_name = File.basename(path)
            if folder_name.start_with?("_")
              # Recurse into special folders
              Dir.glob(File.join(path, "*")).each do |subpath|
                dirs << subpath if File.directory?(subpath) && !category_folder?(subpath)
              end
            else
              dirs << path unless category_folder?(path)
            end
          end

          dirs
        end

        # Check if a folder is a category folder (only contains subdirectories, no files)
        def category_folder?(dir_path)
          return false unless Dir.exist?(dir_path)

          files = Dir.glob(File.join(dir_path, "*")).select { |f| File.file?(f) }
          return false if files.any?

          subdirs = Dir.glob(File.join(dir_path, "*")).select { |f| File.directory?(f) }
          subdirs.any?
        end
      end
    end
  end
end
