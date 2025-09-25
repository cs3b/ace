# frozen_string_literal: true

require_relative "../organisms/task_migrator"

module Ace
  module Taskflow
    module Commands
      # CLI command for migrating task paths to new format
      class MigratePaths
        def self.run(args = [])
          dry_run = args.include?("--dry-run") || args.include?("-n")
          verbose = args.include?("--verbose") || args.include?("-v")

          migrator = Organisms::TaskMigrator.new(dry_run: dry_run)

          if dry_run
            puts "DRY RUN MODE - No changes will be made"
            puts ""
          end

          puts "Migrating task paths to new descriptive format..."
          results = migrator.migrate_all

          # Display results
          puts ""
          puts "Migration Summary:"
          puts "-" * 40
          puts "Total tasks found: #{results[:total]}"
          puts "Successfully migrated: #{results[:migrated].count}"
          puts "Skipped: #{results[:skipped].count}"
          puts "Errors: #{results[:errors].count}"

          if verbose || results[:migrated].any?
            puts ""
            puts "Migrated Tasks:"
            results[:migrated].each do |task|
              old_name = File.basename(task[:old_path])
              new_name = File.basename(task[:new_path])
              puts "  #{old_name} -> #{new_name}"
              puts "    #{task[:title]}" if verbose
            end
          end

          if verbose && results[:skipped].any?
            puts ""
            puts "Skipped Tasks:"
            results[:skipped].each do |skip|
              puts "  #{File.basename(skip[:path])}: #{skip[:reason]}"
            end
          end

          if results[:errors].any?
            puts ""
            puts "Errors:"
            results[:errors].each do |error|
              puts "  #{File.basename(error[:path])}: #{error[:error]}"
            end
          end

          # Exit code
          results[:errors].empty? ? 0 : 1
        end
      end
    end
  end
end