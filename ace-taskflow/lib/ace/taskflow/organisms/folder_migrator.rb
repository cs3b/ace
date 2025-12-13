# frozen_string_literal: true

require "fileutils"

module Ace
  module Taskflow
    module Organisms
      # Migrates folder structure from old naming to new underscore-prefixed format
      class FolderMigrator
        FOLDER_MAPPINGS = {
          "done" => "_archive",
          "backlog" => "_backlog"
        }.freeze

        attr_reader :root_path, :dry_run, :use_git

        def initialize(root_path, dry_run: false, use_git: false)
          @root_path = root_path
          @dry_run = dry_run
          @use_git = use_git
        end

        # Migrate all folders in the taskflow structure
        # @return [Hash] Migration results with :migrated, :skipped, :errors, :total
        def migrate_all
          results = {
            migrated: [],
            skipped: [],
            errors: [],
            total: 0
          }

          # Find all folders that need migration
          folders_to_migrate = find_folders_to_migrate

          results[:total] = folders_to_migrate.count

          # Migrate each folder
          folders_to_migrate.each do |folder_info|
            migrate_folder(folder_info, results)
          end

          results
        end

        private

        # Find all folders that match old naming convention
        # @return [Array<Hash>] Array of folder info hashes with :old_path, :new_path
        def find_folders_to_migrate
          folders = []

          # Check top-level folders (done/ and backlog/)
          FOLDER_MAPPINGS.each do |old_name, new_name|
            old_path = File.join(@root_path, old_name)
            new_path = File.join(@root_path, new_name)

            if Dir.exist?(old_path)
              folders << {
                old_path: old_path,
                new_path: new_path,
                old_name: old_name,
                new_name: new_name,
                level: :top
              }
            end
          end

          # Check nested folders within releases (v.*/tasks/done/, v.*/ideas/done/)
          Dir.glob(File.join(@root_path, "v.*")).each do |release_path|
            next unless File.directory?(release_path)

            # Check tasks/done/ and ideas/done/
            %w[tasks ideas].each do |category|
              FOLDER_MAPPINGS.each do |old_name, new_name|
                old_path = File.join(release_path, category, old_name)
                new_path = File.join(release_path, category, new_name)

                if Dir.exist?(old_path)
                  folders << {
                    old_path: old_path,
                    new_path: new_path,
                    old_name: old_name,
                    new_name: new_name,
                    level: :nested,
                    release: File.basename(release_path),
                    category: category
                  }
                end
              end
            end
          end

          # Also check within backlog and done/archive if they exist
          # (to handle nested releases within those directories)
          [
            File.join(@root_path, "backlog"),
            File.join(@root_path, "_backlog"),
            File.join(@root_path, "done"),
            File.join(@root_path, "_archive")
          ].each do |parent_dir|
            next unless Dir.exist?(parent_dir)

            Dir.glob(File.join(parent_dir, "v.*")).each do |release_path|
              next unless File.directory?(release_path)

              %w[tasks ideas].each do |category|
                FOLDER_MAPPINGS.each do |old_name, new_name|
                  old_path = File.join(release_path, category, old_name)
                  new_path = File.join(release_path, category, new_name)

                  if Dir.exist?(old_path)
                    folders << {
                      old_path: old_path,
                      new_path: new_path,
                      old_name: old_name,
                      new_name: new_name,
                      level: :nested,
                      release: File.basename(release_path),
                      category: category
                    }
                  end
                end
              end
            end
          end

          folders
        end

        # Migrate a single folder
        # @param folder_info [Hash] Folder information
        # @param results [Hash] Results accumulator
        def migrate_folder(folder_info, results)
          old_path = folder_info[:old_path]
          new_path = folder_info[:new_path]

          # Check if target already exists
          if Dir.exist?(new_path)
            results[:skipped] << {
              path: old_path,
              reason: "Target already exists: #{new_path}"
            }
            return
          end

          # Perform migration
          if @dry_run
            puts "DRY RUN: Would migrate #{old_path} → #{new_path}"
            results[:migrated] << folder_info
          else
            begin
              if @use_git
                # Use git mv
                git_mv(old_path, new_path)
              else
                # Use FileUtils.mv
                FileUtils.mv(old_path, new_path)
              end

              results[:migrated] << folder_info
            rescue StandardError => e
              results[:errors] << {
                path: old_path,
                error: e.message
              }
            end
          end
        end

        # Execute git mv command
        # @param old_path [String] Source path
        # @param new_path [String] Destination path
        def git_mv(old_path, new_path)
          require "pathname"

          # Get relative paths from git root using Pathname for cross-platform robustness
          git_root = Pathname.new(`git rev-parse --show-toplevel`.strip)
          old_relative = Pathname.new(old_path).relative_path_from(git_root).to_s
          new_relative = Pathname.new(new_path).relative_path_from(git_root).to_s

          # Execute git mv
          result = system("git", "mv", old_relative, new_relative)

          unless result
            raise "git mv failed for #{old_path} → #{new_path}"
          end
        end
      end
    end
  end
end
