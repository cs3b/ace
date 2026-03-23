# frozen_string_literal: true

require "ace/b36ts"

module Ace
  module Git
    module Secrets
      module Organisms
        # Orchestrates the history cleaning workflow
        # Combines scanning, confirmation, backup, and rewriting
        #
        # Requires gitleaks to be installed: brew install gitleaks
        class HistoryCleaner
          CONFIRMATION_TEXT = "REWRITE HISTORY"

          attr_reader :rewriter, :scanner, :repository_path

          # @param repository_path [String] Path to git repository
          # @param gitleaks_config [String, nil] Path to gitleaks config file
          # @param exclusions [Array<String>, nil] Glob patterns for files to exclude
          def initialize(repository_path: ".", gitleaks_config: nil, exclusions: nil)
            @repository_path = File.expand_path(repository_path)
            @rewriter = Molecules::GitRewriter.new(repository_path: @repository_path)
            @scanner = Molecules::HistoryScanner.new(
              repository_path: @repository_path,
              gitleaks_config: gitleaks_config,
              exclusions: exclusions
            )
          end

          # Clean tokens from history
          # @param tokens [Array<DetectedToken>, nil] Tokens to remove (scans if nil)
          # @param dry_run [Boolean] Preview only
          # @param force [Boolean] Skip confirmation
          # @param create_backup [Boolean] Create backup before rewriting
          # @param backup_path [String, nil] Custom backup path
          # @return [Hash] Result with :success, :message, :report keys
          def clean(tokens: nil, dry_run: false, force: false, create_backup: true, backup_path: nil)
            # Scan if tokens not provided (needed for both dry-run and actual run)
            if tokens.nil?
              report = scanner.scan
              tokens = report.tokens
            end

            if tokens.empty?
              return {
                success: true,
                message: "No tokens found to remove. Repository is clean.",
                tokens_removed: 0
              }
            end

            # Dry run - just show what would be removed (no rewriter needed)
            if dry_run
              return dry_run_result(tokens)
            end

            # Check prerequisites (only needed for actual rewrite)
            unless rewriter.available?
              return {
                success: false,
                message: Molecules::GitRewriter::FILTER_REPO_INSTALL_INSTRUCTIONS
              }
            end

            unless rewriter.clean_working_directory?
              return {
                success: false,
                message: "Working directory has uncommitted changes. Commit or stash first."
              }
            end

            # Require confirmation unless forced
            unless force
              return {
                success: false,
                requires_confirmation: true,
                message: confirmation_warning(tokens),
                confirmation_text: CONFIRMATION_TEXT
              }
            end

            # Create backup if requested
            if create_backup
              backup_result = create_repository_backup(backup_path)
              unless backup_result[:success]
                return {
                  success: false,
                  message: "Failed to create backup: #{backup_result[:message]}"
                }
              end
              puts "Backup created at: #{backup_result[:path]}"
            end

            # Execute rewrite
            result = rewriter.rewrite(tokens)

            if result[:success]
              {
                success: true,
                message: result[:message],
                tokens_removed: tokens.size,
                next_steps: post_rewrite_instructions
              }
            else
              {
                success: false,
                message: result[:message]
              }
            end
          end

          # Validate confirmation text
          # @param input [String] User input
          # @return [Boolean]
          def valid_confirmation?(input)
            input.strip == CONFIRMATION_TEXT
          end

          private

          # Generate dry run result
          def dry_run_result(tokens)
            {
              success: true,
              dry_run: true,
              message: "Dry run: Would remove #{tokens.size} token(s) from history",
              tokens: tokens.map do |t|
                {
                  type: t.token_type,
                  masked_value: t.masked_value,
                  file: t.file_path,
                  commit: t.short_commit
                }
              end
            }
          end

          # Generate confirmation warning
          def confirmation_warning(tokens)
            <<~WARNING
              WARNING: This operation will rewrite Git history.

              This action:
              - Is IRREVERSIBLE (without backup)
              - Will change commit SHAs
              - Requires all collaborators to re-clone after completion
              - Should only be done after revoking the tokens

              Tokens to be removed: #{tokens.size}

              To proceed, type exactly: #{CONFIRMATION_TEXT}
            WARNING
          end

          # Create repository backup
          def create_repository_backup(custom_path)
            backup_path = custom_path || generate_backup_path

            if rewriter.create_backup(backup_path)
              {success: true, path: backup_path}
            else
              {success: false, message: "Could not create mirror clone"}
            end
          end

          # Generate default backup path
          def generate_backup_path
            session_id = Ace::B36ts.encode(Time.now)
            repo_name = File.basename(repository_path)
            File.join(File.dirname(repository_path), "#{repo_name}-backup-#{session_id}.git")
          end

          # Instructions after successful rewrite
          def post_rewrite_instructions
            <<~INSTRUCTIONS

              History has been rewritten successfully.

              IMPORTANT: Complete these steps:

              1. Verify the changes:
                 git log --oneline -20

              2. Force push to remote:
                 git push --force-with-lease origin <branch>

              3. Notify all collaborators to:
                 - Delete their local clones
                 - Re-clone the repository

              4. If you created a backup, you can safely delete it after
                 confirming everything works correctly.

            INSTRUCTIONS
          end
        end
      end
    end
  end
end
