# frozen_string_literal: true

require_relative "../atoms/retro_file_pattern"
require_relative "../atoms/retro_id_formatter"

module Ace
  module Retro
    module Molecules
      # Validates the directory structure of a retros root directory.
      # Checks folder naming, file naming, and structural conventions.
      class RetroStructureValidator
        # @param root_dir [String] Root directory for retros (e.g., ".ace-retros")
        def initialize(root_dir)
          @root_dir = root_dir
        end

        # Validate the entire retros directory structure
        # @return [Array<Hash>] List of issues found
        def validate(root_dir = @root_dir)
          issues = []

          unless Dir.exist?(root_dir)
            issues << {type: :error, message: "Retros root directory does not exist", location: root_dir}
            return issues
          end

          check_folder_naming(root_dir, issues)
          check_retro_files(root_dir, issues)
          check_archive_partitions(root_dir, issues)
          check_stale_backups(root_dir, issues)
          check_empty_directories(root_dir, issues)

          issues
        end

        private

        # Check that retro folders follow {6-char-id}-{slug} naming
        def check_folder_naming(root_dir, issues)
          retro_dirs(root_dir).each do |dir|
            folder_name = File.basename(dir)
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

        # Check that each retro folder has exactly one .retro.md file
        def check_retro_files(root_dir, issues)
          retro_dirs(root_dir).each do |dir|
            folder_name = File.basename(dir)
            next if folder_name.start_with?("_")

            retro_files = Dir.glob(File.join(dir, Atoms::RetroFilePattern::FILE_GLOB))

            if retro_files.empty?
              issues << {
                type: :warning,
                message: "No .retro.md file in retro folder",
                location: dir
              }
            elsif retro_files.size > 1
              issues << {
                type: :warning,
                message: "Multiple .retro.md files in folder (#{retro_files.size} found)",
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

        # Check that _archive/ partition directories use valid b36ts names
        def check_archive_partitions(root_dir, issues)
          archive_dir = File.join(root_dir, "_archive")
          return unless Dir.exist?(archive_dir)

          Dir.glob(File.join(archive_dir, "*")).each do |path|
            next unless File.directory?(path)
            next unless category_folder?(path)

            partition_name = File.basename(path)
            unless valid_b36ts_partition?(partition_name)
              issues << {
                type: :error,
                message: "Invalid archive partition '#{partition_name}' (expected b36ts like '8o')",
                location: path
              }
            end
          end
        end

        # Valid b36ts month partitions are 1-3 char lowercase base36 strings
        def valid_b36ts_partition?(name)
          name.match?(/\A[0-9a-z]{1,3}\z/)
        end

        # Find all immediate subdirectories that look like retro folders
        # (excludes special folders which are containers, includes their children)
        # Also excludes category folders (folders containing only subdirectories)
        # For _archive/, recurses into partition dirs (category folders) to find retros inside them
        def retro_dirs(root_dir)
          dirs = []

          Dir.glob(File.join(root_dir, "*")).each do |path|
            next unless File.directory?(path)

            folder_name = File.basename(path)
            if folder_name == "_archive"
              Dir.glob(File.join(path, "*")).each do |subpath|
                next unless File.directory?(subpath)

                if category_folder?(subpath)
                  # Partition dir — recurse into it to find retro folders
                  Dir.glob(File.join(subpath, "*")).each do |retro_path|
                    dirs << retro_path if File.directory?(retro_path)
                  end
                else
                  dirs << subpath
                end
              end
            elsif folder_name.start_with?("_")
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
        # These are organizational folders and not individual retros
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
