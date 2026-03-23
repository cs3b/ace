# frozen_string_literal: true

require "open3"
require "tempfile"

module Ace
  module Git
    module Secrets
      module Molecules
        # Wrapper for git-filter-repo to remove tokens from Git history
        # Handles tool availability, filter building, and execution
        class GitRewriter
          FILTER_REPO_INSTALL_INSTRUCTIONS = <<~MSG
            git-filter-repo is required for history rewriting.
            Install with: brew install git-filter-repo
            See: https://github.com/newren/git-filter-repo
          MSG

          attr_reader :repository_path

          # @param repository_path [String] Path to git repository
          # @raise [ArgumentError] If repository_path is not a valid git repository
          def initialize(repository_path: ".")
            @repository_path = File.expand_path(repository_path)
            validate_repository_path!
          end

          # Check if git-filter-repo is available
          # @return [Boolean]
          def available?
            system("which git-filter-repo > /dev/null 2>&1")
          end

          # Check if working directory is clean
          # @return [Boolean]
          def clean_working_directory?
            output, status = Open3.capture2(
              "git", "-C", repository_path, "status", "--porcelain",
              err: File::NULL
            )
            status.success? && output.strip.empty?
          end

          # Rewrite history to remove specific tokens
          # @param tokens [Array<DetectedToken>] Tokens to remove
          # @param dry_run [Boolean] Whether to preview changes only
          # @return [Hash] Result with :success, :message, :changes keys
          def rewrite(tokens, dry_run: false)
            unless available?
              return {
                success: false,
                message: FILTER_REPO_INSTALL_INSTRUCTIONS,
                changes: []
              }
            end

            unless clean_working_directory?
              return {
                success: false,
                message: "Working directory has uncommitted changes. Commit or stash before rewriting history.",
                changes: []
              }
            end

            if tokens.empty?
              return {
                success: true,
                message: "No tokens to remove",
                changes: []
              }
            end

            # Build replacement expressions
            replacements = build_replacements(tokens)

            if dry_run
              {
                success: true,
                dry_run: true,
                message: "Dry run: Would remove #{tokens.size} token(s) from history",
                changes: replacements.map { |r| {original: r[:pattern], replacement: r[:replacement]} }
              }
            else
              execute_filter_repo(replacements)
            end
          end

          # Create a backup of the repository
          # @param backup_path [String] Path for backup
          # @return [Boolean] Success status
          def create_backup(backup_path)
            _, status = Open3.capture2(
              "git", "clone", "--mirror", repository_path, backup_path,
              err: File::NULL
            )
            status.success?
          rescue
            false
          end

          private

          # Validate that repository_path is a valid git repository
          # @raise [ArgumentError] If path doesn't exist or isn't a git repo
          def validate_repository_path!
            unless Dir.exist?(repository_path)
              raise ArgumentError, "Repository path does not exist: #{repository_path}"
            end

            git_dir = File.join(repository_path, ".git")
            unless Dir.exist?(git_dir) || File.exist?(git_dir)
              raise ArgumentError, "Not a git repository: #{repository_path}"
            end
          end

          # Build replacement expressions for git-filter-repo
          # @param tokens [Array<DetectedToken>]
          # @return [Array<Hash>]
          def build_replacements(tokens)
            tokens.map do |token|
              # Create a masked replacement value
              masked = "[REDACTED:#{token.token_type}]"

              {
                pattern: token.raw_value,
                replacement: masked,
                token_type: token.token_type
              }
            end.uniq { |r| r[:pattern] }
          end

          # Execute git-filter-repo with replacements
          # @param replacements [Array<Hash>]
          # @return [Hash]
          def execute_filter_repo(replacements)
            # Create replacement file for git-filter-repo with secure permissions
            # Mode 0600 ensures only the owner can read/write the file containing tokens
            #
            # Security: Use memory-backed tmpfs if available (Linux /dev/shm).
            # Tempfiles in memory are harder to recover than disk-based temps.
            # macOS doesn't have /dev/shm but has encrypted swap; this is defense in depth.
            temp_dir = Dir.exist?("/dev/shm") ? "/dev/shm" : Dir.tmpdir
            replacement_file = Tempfile.new(
              ["git-filter-repo-replacements", ".txt"],
              temp_dir,
              mode: File::RDWR | File::CREAT | File::EXCL,
              perm: 0o600
            )

            begin
              # Write replacements in git-filter-repo format
              # Format: literal:ORIGINAL==>literal:REPLACEMENT
              replacements.each do |r|
                replacement_file.puts("literal:#{r[:pattern]}==>literal:#{r[:replacement]}")
              end
              replacement_file.close

              cmd = [
                "git-filter-repo",
                "--replace-text", replacement_file.path,
                "--force"
              ]

              Dir.chdir(repository_path) do
                stdout, stderr, status = Open3.capture3(*cmd)

                if status.success?
                  {
                    success: true,
                    message: "Successfully removed #{replacements.size} token(s) from history",
                    changes: replacements.map { |r| {token_type: r[:token_type], status: "removed"} },
                    stdout: stdout,
                    stderr: stderr
                  }
                else
                  {
                    success: false,
                    message: "git-filter-repo failed: #{stderr}",
                    changes: [],
                    stdout: stdout,
                    stderr: stderr
                  }
                end
              end
            ensure
              replacement_file.unlink
            end
          rescue => e
            {
              success: false,
              message: "Error executing git-filter-repo: #{e.message}",
              changes: []
            }
          end
        end
      end
    end
  end
end
