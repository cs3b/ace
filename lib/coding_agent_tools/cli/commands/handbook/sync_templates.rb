# frozen_string_literal: true

require "dry/cli"

module CodingAgentTools
  module Cli
    module Commands
      module Handbook
        # CLI command for synchronizing embedded templates in workflow documents
        # Provides modern interface to template synchronization functionality
        class SyncTemplates < Dry::CLI::Command
          desc "Synchronize XML-embedded template content with their corresponding template files"

          option :path, type: :string, default: "dev-handbook/workflow-instructions",
            desc: "Directory to scan for workflow files"
          option :dry_run, type: :boolean, default: false,
            desc: "Show what would be changed without modifying files"
          option :verbose, type: :boolean, default: false,
            desc: "Show detailed processing information"
          option :commit, type: :boolean, default: false,
            desc: "Automatically commit changes after synchronization"
          option :help, type: :boolean, default: false,
            aliases: ["-h"], desc: "Show this help message"

          example [
            "                                    # Sync all templates in default directory",
            "--dry-run                          # Preview changes without modifying files",
            "--path custom/path --verbose       # Sync templates in custom directory with detailed output",
            "--commit                           # Sync and automatically commit changes",
            "--path dev-handbook --dry-run --verbose  # Preview with full details for dev-handbook"
          ]

          # Execute the template synchronization command
          # @param options [Hash] Command-line options
          def call(**options)
            if options[:help]
              puts help_message
              return 0
            end

            begin
              config = create_sync_config(options)
              synchronizer = create_synchronizer(config)

              result = synchronizer.synchronize

              result.success? ? 0 : 1
            rescue => e
              handle_error(e, options[:verbose])
              1
            end
          end

          private

          def create_sync_config(options)
            CodingAgentTools::Organisms::TaskflowManagement::TemplateSynchronizer::SyncConfig.new(
              path: options[:path],
              dry_run: options[:dry_run],
              verbose: options[:verbose],
              commit: options[:commit]
            )
          end

          def create_synchronizer(config)
            CodingAgentTools::Organisms::TaskflowManagement::TemplateSynchronizer.new(config: config)
          end

          def handle_error(error, verbose)
            puts "❌ Error: #{error.message}"
            return unless verbose

            puts "\nStack trace:"
            puts error.backtrace.join("\n")
          end

          def help_message
            <<~HELP
              handbook sync-templates - Synchronize XML-embedded template content

              DESCRIPTION:
                Scans workflow instruction files for XML <templates> and <documents> sections
                and synchronizes embedded template content with their corresponding template files.

                Supports both modern <documents> format with <template> and <guide> tags,
                and legacy <templates> format for backward compatibility.

              USAGE:
                handbook sync-templates [options]

              OPTIONS:
                --path PATH        Directory to scan for workflow files#{" "}
                                  (default: dev-handbook/workflow-instructions)
                --dry-run          Show what would be changed without modifying files
                --verbose          Show detailed processing information
                --commit           Automatically commit changes after synchronization
                -h, --help         Show this help message

              EXAMPLES:
                handbook sync-templates
                  Sync all templates in default directory

                handbook sync-templates --dry-run
                  Preview changes without modifying files

                handbook sync-templates --path custom/path --verbose
                  Sync templates in custom directory with detailed output

                handbook sync-templates --commit
                  Sync and automatically commit changes

                handbook sync-templates --path dev-handbook --dry-run --verbose
                  Preview with full details for dev-handbook

              EXIT CODES:
                0  Success (no errors, changes may or may not have been made)
                1  Error occurred during processing

              XML FORMATS SUPPORTED:
                Modern format:
                  <documents>
                  <template path="dev-handbook/templates/example.template.md">
                  Template content here
                  </template>
                  <guide path="dev-handbook/guides/example.g.md">
                  Guide content here
                  </guide>
                  </documents>

                Legacy format:
                  <templates>
                  <template path="dev-handbook/templates/example.template.md">
                  Template content here
                  </template>
                  </templates>
            HELP
          end
        end
      end
    end
  end
end
