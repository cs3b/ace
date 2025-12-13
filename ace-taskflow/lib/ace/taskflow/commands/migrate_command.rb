# frozen_string_literal: true

require_relative "../organisms/folder_migrator"

module Ace
  module Taskflow
    module Commands
      # Handle migrate subcommand for folder migration
      class MigrateCommand
        def initialize
          @root_path = find_taskflow_root
        end

        def execute(args)
          options = parse_options(args)

          # Handle help
          if options[:help]
            show_help
            return 0
          end

          # Check for taskflow directory
          unless @root_path
            puts "Error: No .ace-taskflow directory found"
            puts "Please run this command from within an ace-taskflow project"
            return 2
          end

          # Check if in git repo
          in_git_repo = git_repository?

          # Show mode
          if options[:dry_run]
            puts "DRY RUN MODE - No changes will be made"
            puts ""
          end

          puts "Migrating folder structure to new naming convention..."
          puts "Git repository detected - using git mv" if in_git_repo && !options[:no_git]
          puts ""

          # Run migration
          migrator = Organisms::FolderMigrator.new(
            @root_path,
            dry_run: options[:dry_run],
            use_git: in_git_repo && !options[:no_git]
          )

          results = migrator.migrate_all

          # Display results
          display_results(results, options)

          # Return appropriate exit code
          results[:errors].empty? ? 0 : 1
        rescue StandardError => e
          puts "Error: #{e.message}"
          puts e.backtrace if options[:verbose]
          2
        end

        private

        def parse_options(args)
          options = {
            dry_run: false,
            verbose: false,
            no_git: false,
            help: false
          }

          i = 0
          while i < args.length
            arg = args[i]

            case arg
            when "--help", "-h"
              options[:help] = true
            when "--dry-run", "-n"
              options[:dry_run] = true
            when "--verbose", "-v"
              options[:verbose] = true
            when "--no-git"
              options[:no_git] = true
            else
              puts "Unknown option: #{arg}"
            end

            i += 1
          end

          options
        end

        def display_results(results, options)
          puts "Migration Summary:"
          puts "-" * 60
          puts "Total folders found: #{results[:total]}"
          puts "Successfully migrated: #{results[:migrated].count}"
          puts "Skipped: #{results[:skipped].count}"
          puts "Errors: #{results[:errors].count}"

          if results[:migrated].any?
            puts ""
            puts "Migrated Folders:"
            results[:migrated].each do |migration|
              old_path = migration[:old_path].sub(@root_path + "/", "")
              new_path = migration[:new_path].sub(@root_path + "/", "")
              puts "  #{old_path} → #{new_path}"
            end
          end

          if options[:verbose] && results[:skipped].any?
            puts ""
            puts "Skipped Folders:"
            results[:skipped].each do |skip|
              path = skip[:path].sub(@root_path + "/", "")
              puts "  #{path}: #{skip[:reason]}"
            end
          end

          if results[:errors].any?
            puts ""
            puts "Errors:"
            results[:errors].each do |error|
              path = error[:path].sub(@root_path + "/", "")
              puts "  #{path}: #{error[:error]}"
            end
          end

          if results[:migrated].empty? && results[:errors].empty?
            puts ""
            puts "No folders need migration - structure is already up to date!"
          end
        end

        # Find taskflow root by walking up directory tree
        # @return [String, nil] Path to .ace-taskflow directory or nil if not found
        def find_taskflow_root
          current = Dir.pwd
          while current != "/"
            taskflow_dir = File.join(current, ".ace-taskflow")
            return taskflow_dir if Dir.exist?(taskflow_dir)
            current = File.dirname(current)
          end
          nil
        end

        def git_repository?
          # Check if we're in a git repository (cached)
          return @git_repository unless @git_repository.nil?
          @git_repository = system("git rev-parse --git-dir > /dev/null 2>&1")
        end

        def show_help
          help_text = <<~HELP
            Usage: ace-taskflow migrate [OPTIONS]

            Migrate folder structure from old naming convention to new underscore-prefixed format.

            This command renames:
              - done/         → _archive/       (published releases)
              - backlog/      → _backlog/       (future releases)
              - */tasks/done/ → */tasks/_archive/
              - */ideas/done/ → */ideas/_archive/

            OPTIONS:
              -h, --help       Show this help message
              -n, --dry-run    Preview changes without executing them
              -v, --verbose    Show detailed output including skipped folders
              --no-git         Don't use git mv even if in git repository

            BEHAVIOR:
              - When in a git repository, uses 'git mv' to preserve history
              - Falls back to FileUtils.mv when not in git or with --no-git
              - Idempotent: safe to run multiple times
              - Skips folders that already use new naming convention
              - Skips if target folder already exists

            EXAMPLES:
              # Preview what would be migrated
              ace-taskflow migrate --dry-run

              # Execute migration
              ace-taskflow migrate

              # Execute migration with detailed output
              ace-taskflow migrate --verbose

              # Execute migration without git (force FileUtils)
              ace-taskflow migrate --no-git

            EXIT CODES:
              0 - Migration successful (or dry-run completed)
              1 - Migration completed with errors
              2 - Command failed to execute

          HELP
          puts help_text
        end
      end
    end
  end
end
