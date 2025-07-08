# frozen_string_literal: true

require "fileutils"
require "pathname"

module CodingAgentTools
  module Organisms
    module TaskManagement
      # TemplateSynchronizer is an organism that orchestrates the complete
      # template synchronization workflow, coordinating XML parsing, file
      # synchronization, and optional git commit operations.
      class TemplateSynchronizer
        # Synchronization result for the entire operation
        SyncOperationResult = Struct.new(:success?, :stats, :errors, :warnings, :files_changed) do
          def failure?
            !success?
          end

          def has_errors?
            !errors.empty?
          end

          def has_warnings?
            !warnings.empty?
          end

          def changes_made?
            files_changed.any?
          end
        end

        # Configuration options for the synchronizer
        SyncConfig = Struct.new(:path, :dry_run, :verbose, :commit, :file_patterns) do
          def initialize(
            path: "dev-handbook/workflow-instructions",
            dry_run: false,
            verbose: false,
            commit: false,
            file_patterns: ["**/*.wf.md"]
          )
            super(path, dry_run, verbose, commit, file_patterns)
          end
        end

        # @param xml_parser [XmlTemplateParser] XML template parser molecule
        # @param file_synchronizer [FileSynchronizer] File synchronizer molecule
        # @param config [SyncConfig] Configuration options
        def initialize(xml_parser: nil, file_synchronizer: nil, config: SyncConfig.new)
          @xml_parser = xml_parser || create_xml_parser
          @file_synchronizer = file_synchronizer || create_file_synchronizer(config)
          @config = config
          @errors = []
          @warnings = []
          @files_changed = []
        end

        # Execute the complete synchronization workflow
        # @return [SyncOperationResult] Results of the synchronization operation
        def synchronize
          reset_state
          log_operation_start

          workflow_files = find_workflow_files
          return empty_result("No workflow files found in #{@config.path}") if workflow_files.empty?

          log("Found #{workflow_files.length} workflow files to process")

          workflow_files.each do |file_path|
            process_workflow_file(file_path)
          end

          result = create_operation_result
          
          if @config.commit && result.success? && result.changes_made? && !@config.dry_run
            commit_changes(result.stats)
            # Recreate result to include any commit errors
            result = create_operation_result
          end

          log_operation_summary(result)
          result
        end

        # Get current synchronization statistics
        # @return [FileSynchronizer::SyncStats] Current synchronization statistics
        def stats
          @file_synchronizer.stats
        end

        # Reset internal state and statistics
        def reset_state
          @errors.clear
          @warnings.clear
          @files_changed.clear
          @file_synchronizer.reset_stats
        end

        private

        attr_reader :xml_parser, :file_synchronizer, :config

        def find_workflow_files
          files = []
          config.file_patterns.each do |pattern|
            search_pattern = File.join(config.path, pattern)
            files.concat(Dir.glob(search_pattern))
          end
          files.uniq.sort
        end

        def process_workflow_file(file_path)
          log("Processing: #{File.basename(file_path)}")

          begin
            content = File.read(file_path)
            parse_result = xml_parser.parse(content, source_file: file_path)

            # Collect warnings from parser
            @warnings.concat(parse_result.warnings)

            if parse_result.documents.empty?
              log("  No documents found")
              return
            end

            log("  Found #{parse_result.documents.length} document(s)") if config.verbose

            updated_content = content
            file_changed = false

            parse_result.documents.each do |document|
              sync_result = file_synchronizer.synchronize_document(updated_content, document, file_path)
              
              case sync_result.status
              when :updated
                updated_content = sync_result.updated_content if sync_result.updated_content
                file_changed = true
                log("  ✅ Document synchronized: #{document.path}")
                
                if config.dry_run && sync_result.diff_preview
                  log(sync_result.diff_preview)
                end
              when :up_to_date
                log("  ℹ️  Document up-to-date: #{document.path}")
              when :error
                log("  ❌ Error: #{sync_result.error_message}")
                @errors << "#{file_path}: #{sync_result.error_message}"
              end
            end

            # Write updated file if changes were made and not in dry-run mode
            if file_changed && !config.dry_run
              File.write(file_path, updated_content)
              @files_changed << file_path
              log("  Wrote updated content to #{file_path}") if config.verbose
            elsif file_changed && config.dry_run
              @files_changed << file_path
            end

          rescue => e
            error_message = "Error processing file #{file_path}: #{e.message}"
            log("  ❌ #{error_message}")
            @errors << error_message
            log("  Stack trace: #{e.backtrace.join("\n")}") if config.verbose
          end
        end

        def commit_changes(stats)
          log("Committing changes...")

          # Check if we're in a git repository
          unless git_repository?
            log("  ❌ Error: Not in a git repository")
            @errors << "Not in a git repository"
            return
          end

          # Add changed files
          system("git add -A")

          # Create commit message
          commit_message = create_commit_message(stats)

          # Commit changes
          if system("git", "commit", "-m", commit_message)
            log("  ✅ Changes committed successfully")
          else
            error_message = "Error committing changes"
            log("  ❌ #{error_message}")
            @errors << error_message
          end
        end

        def create_commit_message(stats)
          message = "chore: sync embedded templates\n\n"
          
          if stats.documents_synchronized > 0
            message += "- Synchronized #{stats.documents_synchronized} document#{stats.documents_synchronized == 1 ? "" : "s"}"
            if stats.documents_up_to_date > 0
              message += ", #{stats.documents_up_to_date} up-to-date"
            end
            message += "\n\n"
          end
          
          message += "🤖 Generated with [Claude Code](https://claude.ai/code)\n\n"
          message += "Co-Authored-By: Claude <noreply@anthropic.com>"
          
          message
        end

        def git_repository?
          system("git rev-parse --git-dir > /dev/null 2>&1")
        end

        def create_operation_result
          stats = file_synchronizer.stats
          success = @errors.empty?

          SyncOperationResult.new(
            success,
            stats,
            @errors.dup,
            @warnings.dup,
            @files_changed.dup
          )
        end

        def empty_result(message)
          @warnings << message
          create_operation_result
        end

        def log_operation_start
          if config.dry_run
            log("DRY RUN MODE - No files will be modified")
          else
            log("Synchronizing templates")
          end
          log("Scanning workflow files in: #{config.path}")
          log("")
        end

        def log_operation_summary(result)
          log("")
          log("Summary:")
          log("  Files processed: #{result.stats.files_processed}")

          if config.dry_run
            log("  Would synchronize: #{result.stats.documents_synchronized} document#{result.stats.documents_synchronized == 1 ? "" : "s"}")
            log("  Would skip: #{result.stats.documents_up_to_date} document#{result.stats.documents_up_to_date == 1 ? "" : "s"} (up-to-date)")
          else
            log("  Documents synchronized: #{result.stats.documents_synchronized}")
            log("  Documents up-to-date: #{result.stats.documents_up_to_date}")
          end

          if result.has_errors?
            log("  Errors: #{result.errors.size}")
          end

          if result.has_warnings?
            log("  Warnings: #{result.warnings.size}")
          end

          log("")
        end

        def log(message)
          # Always show errors and summary
          if message.include?("❌") || message.start_with?("Summary:") || message.start_with?("  Files processed:") || 
             message.start_with?("  Documents synchronized:") || message.start_with?("  Documents up-to-date:") ||
             message.start_with?("  Would synchronize:") || message.start_with?("  Would skip:") ||
             message.start_with?("  Errors:") || message.start_with?("  Warnings:") || message.empty?
            puts message
          # Show all messages in verbose mode
          elsif config.verbose
            puts message
          end
        end

        def create_xml_parser
          CodingAgentTools::Molecules::TaskManagement::XmlTemplateParser.new
        end

        def create_file_synchronizer(config)
          CodingAgentTools::Molecules::TaskManagement::FileSynchronizer.new(
            dry_run: config.dry_run
          )
        end
      end
    end
  end
end