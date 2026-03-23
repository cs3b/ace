# frozen_string_literal: true

require_relative "../atoms/idea_file_pattern"
require_relative "../atoms/idea_id_formatter"

module Ace
  module Idea
    module Molecules
      # Validates the directory structure of an ideas root directory.
      # Checks folder naming, file naming, and structural conventions.
      class IdeaStructureValidator
        # @param root_dir [String] Root directory for ideas (e.g., ".ace-ideas")
        def initialize(root_dir)
          @root_dir = root_dir
        end

        # Validate the entire ideas directory structure
        # @return [Array<Hash>] List of issues found
        def validate(root_dir = @root_dir)
          issues = []

          unless Dir.exist?(root_dir)
            issues << {type: :error, message: "Ideas root directory does not exist", location: root_dir}
            return issues
          end

          check_folder_naming(root_dir, issues)
          check_spec_files(root_dir, issues)
          check_stale_backups(root_dir, issues)
          check_empty_directories(root_dir, issues)

          issues
        end

        private

        # Check that idea folders follow {6-char-id}-{slug} naming
        def check_folder_naming(root_dir, issues)
          idea_dirs(root_dir).each do |dir|
            folder_name = File.basename(dir)

            # Skip special folders
            next if folder_name.start_with?("_")

            unless folder_name.match?(/^[0-9a-z]{6}-.+$/)
              issues << {
                type: :error,
                message: "Folder name does not match '{id}-{slug}' convention: '#{folder_name}'",
                location: dir
              }
            end
          end
        end

        # Check that each idea folder has exactly one .idea.s.md spec file
        def check_spec_files(root_dir, issues)
          idea_dirs(root_dir).each do |dir|
            folder_name = File.basename(dir)
            next if folder_name.start_with?("_")

            spec_files = Dir.glob(File.join(dir, Atoms::IdeaFilePattern::FILE_GLOB))

            if spec_files.empty?
              issues << {
                type: :warning,
                message: "No .idea.s.md spec file in idea folder",
                location: dir
              }
            elsif spec_files.size > 1
              issues << {
                type: :warning,
                message: "Multiple .idea.s.md spec files in folder (#{spec_files.size} found)",
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

        # Find all immediate subdirectories that look like idea folders
        # (excludes special folders which are containers, includes their children)
        # Also excludes category folders (folders containing only subdirectories)
        def idea_dirs(root_dir)
          dirs = []

          # Direct children of root
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
        # These are organizational folders and not individual ideas
        def category_folder?(dir_path)
          return false unless Dir.exist?(dir_path)

          # Check if folder has any files
          files = Dir.glob(File.join(dir_path, "*")).select { |f| File.file?(f) }
          return false if files.any?

          # Check if folder has any subdirectories
          subdirs = Dir.glob(File.join(dir_path, "*")).select { |f| File.directory?(f) }
          subdirs.any?
        end
      end
    end
  end
end
