# frozen_string_literal: true

require "fileutils"
require_relative "../molecules/task_loader"
require_relative "../molecules/task_slug_generator"
require_relative "../atoms/path_builder"

module Ace
  module Taskflow
    module Organisms
      # Migrates task directories from old format to new descriptive format
      class TaskMigrator
        attr_reader :root_path, :dry_run

        def initialize(root_path = nil, dry_run: false)
          @root_path = root_path || File.join(Dir.pwd, ".ace-taskflow")
          @dry_run = dry_run
          @task_loader = Molecules::TaskLoader.new(@root_path)
        end

        # Migrate all tasks to new format
        # @return [Hash] Migration results
        def migrate_all
          results = {
            migrated: [],
            skipped: [],
            errors: [],
            total: 0
          }

          contexts_to_migrate.each do |context_path|
            migrate_context(context_path, results)
          end

          results
        end

        # Migrate tasks in a specific context
        # @param context [String] Context name (e.g., "v.0.9.0", "backlog")
        # @return [Hash] Migration results
        def migrate_context(context_path, results = nil)
          results ||= { migrated: [], skipped: [], errors: [], total: 0 }

          task_dir = File.join(context_path, "t")
          return results unless File.directory?(task_dir)

          # Find all task directories
          Dir.glob(File.join(task_dir, "*")).select { |d| File.directory?(d) }.each do |task_path|
            results[:total] += 1

            dir_name = File.basename(task_path)

            # Skip if already in new format
            if dir_name =~ /^\d{3}-/
              results[:skipped] << {
                path: task_path,
                reason: "Already in new format"
              }
              next
            end

            # Only process numeric directories
            unless dir_name =~ /^\d+$/
              results[:skipped] << {
                path: task_path,
                reason: "Not a task directory"
              }
              next
            end

            migrate_task_directory(task_path, results)
          end

          results
        end

        private

        def contexts_to_migrate
          contexts = []

          # Active releases
          Dir.glob(File.join(@root_path, "v.*")).each do |release_path|
            contexts << release_path if File.directory?(release_path)
          end

          # Backlog
          backlog_path = File.join(@root_path, "backlog")
          if File.directory?(backlog_path)
            contexts << backlog_path

            # Backlog releases
            Dir.glob(File.join(backlog_path, "v.*")).each do |release_path|
              contexts << release_path if File.directory?(release_path)
            end
          end

          # Done releases
          done_path = File.join(@root_path, "done")
          if File.directory?(done_path)
            Dir.glob(File.join(done_path, "v.*")).each do |release_path|
              contexts << release_path if File.directory?(release_path)
            end
          end

          contexts
        end

        def migrate_task_directory(old_path, results)
          # Extract task number
          task_number = File.basename(old_path)
          padded_number = task_number.rjust(3, '0')

          # Find and load the task file to get title
          task_file = find_task_file(old_path)
          unless task_file
            results[:errors] << {
              path: old_path,
              error: "No task file found"
            }
            return
          end

          # Load task to get title and metadata
          task = @task_loader.load_task(task_file)
          unless task
            results[:errors] << {
              path: old_path,
              error: "Failed to load task"
            }
            return
          end

          # Generate new directory name with slug
          title = task[:title] || "Untitled Task"
          metadata = task[:metadata] || {}
          slug_part = Molecules::TaskSlugGenerator.generate_descriptive_part(title, metadata)
          new_dir_name = "#{padded_number}-#{slug_part}"

          # Build new path
          parent_dir = File.dirname(old_path)
          new_path = File.join(parent_dir, new_dir_name)

          # Check if new path already exists
          if File.exist?(new_path)
            results[:skipped] << {
              path: old_path,
              reason: "Target path already exists: #{new_path}"
            }
            return
          end

          # Perform migration (or dry run)
          if @dry_run
            puts "DRY RUN: Would migrate #{old_path} -> #{new_path}"

            # Also rename the task file if needed
            old_task_file = File.basename(task_file)
            new_task_file = "task.#{padded_number}.md"
            if old_task_file != new_task_file
              puts "         Would rename #{old_task_file} -> #{new_task_file}"
            end
          else
            begin
              # Move directory
              FileUtils.mv(old_path, new_path)

              # Rename task file if needed
              old_task_file = File.basename(task_file)
              new_task_file = "task.#{padded_number}.md"
              if old_task_file != new_task_file
                old_file_path = File.join(new_path, old_task_file)
                new_file_path = File.join(new_path, new_task_file)
                FileUtils.mv(old_file_path, new_file_path) if File.exist?(old_file_path)
              end

              results[:migrated] << {
                old_path: old_path,
                new_path: new_path,
                task_id: task[:id],
                title: title
              }
            rescue StandardError => e
              results[:errors] << {
                path: old_path,
                error: e.message
              }
            end
          end
        end

        def find_task_file(task_dir)
          # Look for .md files with task frontmatter
          Dir.glob(File.join(task_dir, "*.md")).find do |file|
            has_task_frontmatter?(file)
          end
        end

        def has_task_frontmatter?(file_path)
          return false unless File.exist?(file_path)

          begin
            content = File.read(file_path, encoding: "utf-8")

            # Quick check for YAML frontmatter
            return false unless content.start_with?("---\n")

            # Parse frontmatter
            if content =~ /\A---\s*\n(.*?)\n---\s*\n/m
              yaml_content = $1
              frontmatter = YAML.safe_load(yaml_content)

              # Check for task metadata
              !!(frontmatter["id"] && frontmatter["status"])
            else
              false
            end
          rescue StandardError
            false
          end
        end
      end
    end
  end
end