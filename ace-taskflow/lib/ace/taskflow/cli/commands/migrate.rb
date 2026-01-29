# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require_relative "../../organisms/folder_migrator"
require_relative "../../molecules/command_option_parser"

module Ace
  module Taskflow
    module CLI
      module Commands
        # dry-cli Command class for the migrate command
        #
        # This command migrates folder structure to new naming convention.
        class Migrate < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base

          desc "Migrate folder structure to new naming convention"
          example [
            '             # Run migration',
            '--dry-run    # Preview changes',
            '--no-git     # Skip git mv'
          ]

          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Debug output"
          option :dry_run, type: :boolean, aliases: %w[-n], desc: "Preview changes"
          option :no_git, type: :boolean, desc: "Don't use git mv (copy/delete instead)"

          def call(**options)
            args = options[:args] || []
            clean_options = options.reject { |k, _| k == :args }
            execute_migrate(args, clean_options)
          end

          private

          def execute_migrate(args, thor_options = {})
            @root_path = find_taskflow_root
            @option_parser = build_option_parser

            parsed_options = {}  # Initialize for rescue block

            result = @option_parser.parse(args, thor_options: thor_options)
            return if result[:help_requested]

            parsed_options = result[:parsed]

            unless @root_path
              puts "Error: No .ace-taskflow directory found"
              puts "Please run this command from within an ace-taskflow project"
              raise Ace::Core::CLI::Error.new("No .ace-taskflow directory found")
            end

            in_git_repo = git_repository?

            if parsed_options[:dry_run]
              puts "DRY RUN MODE - No changes will be made"
              puts ""
            end

            puts "Migrating folder structure to new naming convention..."
            puts "Git repository detected - using git mv" if in_git_repo && !parsed_options[:no_git]
            puts ""

            migrator = Organisms::FolderMigrator.new(
              @root_path,
              dry_run: parsed_options[:dry_run],
              use_git: in_git_repo && !parsed_options[:no_git]
            )

            results = migrator.migrate_all

            display_results(results, parsed_options)

            raise Ace::Core::CLI::Error.new("Migration completed with errors") unless results[:errors].empty?
          rescue StandardError => e
            raise Ace::Core::CLI::Error.new(e.message)
          end

          def build_option_parser
            Molecules::CommandOptionParser.new(
              option_sets: [:display, :actions, :help],
              banner: "Usage: ace-taskflow migrate [options]"
            ) do |opts, parsed|
              opts.on("--no-git", "Don't use git mv (copy/delete instead)") { parsed[:no_git] = true }
            end
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
            return @git_repository unless @git_repository.nil?
            @git_repository = system("git rev-parse --git-dir > /dev/null 2>&1")
          end
        end
      end
    end
  end
end
