# frozen_string_literal: true

module Ace
  module GitCommit
    module Organisms
      # CommitOrchestrator coordinates the entire commit process
      class CommitOrchestrator
        def initialize(config = nil)
          @config = config || load_config
          @git = Atoms::GitExecutor.new
          @diff_analyzer = Molecules::DiffAnalyzer.new(@git)
          @file_stager = Molecules::FileStager.new(@git)
          @path_resolver = Molecules::PathResolver.new(@git)
          @message_generator = Molecules::MessageGenerator.new(@config)
        end

        # Execute the commit process
        # @param options [Models::CommitOptions] Commit options
        # @return [Boolean] True if successful
        def execute(options)
          validate_repository!

          if options.debug
            puts "Debug: Commit options:"
            options.to_h.each { |k, v| puts "  #{k}: #{v.inspect}" }
          end

          # Stage files if needed
          staging_result = stage_changes(options)

          # Stop if staging failed
          unless staging_result
            puts "\nCannot proceed with commit due to staging failure" unless options.quiet
            return false
          end

          # Ensure we have changes to commit
          unless @git.has_staged_changes?
            puts "No changes to commit" unless options.quiet
            return false
          end

          # Get or generate commit message
          message = get_commit_message(options)

          if options.dry_run
            show_dry_run(message, options)
            return true
          end

          # Execute the commit
          perform_commit(message, options)
        end

        private

        # Load configuration
        # @return [Hash] Configuration
        def load_config
          # Load git/commit.yml configuration using ace-core
          require 'ace/core/organisms/config_resolver'

          resolver = Ace::Core::Organisms::ConfigResolver.new(
            file_patterns: ["git/commit.yml", "git/commit.yaml"]
          )

          config = resolver.resolve

          if config && config.data && !config.data.empty?
            # Extract git section if present, otherwise use root
            config.data["git"] || config.data
          else
            default_config
          end
        rescue StandardError => e
          warn "Error loading git commit config: #{e.message}" if ENV["DEBUG"]
          default_config
        end

        # Default configuration
        # @return [Hash] Default config
        def default_config
          {
            "model" => "glite",
            "conventions" => {
              "format" => "conventional",
              "scopes" => {
                "enabled" => true,
                "detect_from_paths" => true
              }
            }
          }
        end

        # Validate we're in a git repository
        # @raise [GitError] If not in a repository
        def validate_repository!
          unless @git.in_repository?
            raise GitError, "Not in a git repository"
          end
        end

        # Stage changes based on options
        # @param options [Models::CommitOptions] Options
        # @return [Boolean] True if staging successful
        def stage_changes(options)
          if options.specific_files?
            stage_specific_files(options)
          elsif options.stage_all?
            stage_all_changes(options)
          else
            # Using currently staged changes
            puts "Using currently staged changes" if options.verbose && !options.quiet
            true
          end
        end

        # Stage specific files with progress feedback
        # @param options [Models::CommitOptions] Options
        # @return [Boolean] True if successful
        def stage_specific_files(options)
          # Early validation: check for non-existent paths (exclude glob patterns)
          non_glob_paths = options.files.reject { |f| @path_resolver.glob_pattern?(f) }
          unless non_glob_paths.empty?
            validation = @path_resolver.validate_paths(non_glob_paths)
            if validation[:invalid].any?
              puts "\n✗ Invalid path(s): #{validation[:invalid].join(', ')}"
              puts "These paths do not exist. Please check the paths and try again."
              return false
            end
          end

          # Check if any paths are directories, glob patterns, or multiple files
          has_directories = options.files.any? { |f| File.directory?(f) }
          has_glob_patterns = options.files.any? { |f| @path_resolver.glob_pattern?(f) }

          if has_directories || has_glob_patterns || options.files.length > 1
            # Use path-restricted staging (reset + selective add)
            # Resolve paths/patterns to actual file lists first
            resolved_files = @path_resolver.resolve_paths(options.files)

            if resolved_files.empty?
              puts "\n✗ No files found matching the specified path(s) or pattern(s)"
              puts "Glob patterns expand only to git-tracked files."
              return false
            end

            puts "Staging files from specified path(s)..." unless options.quiet
            result = @file_stager.stage_paths(resolved_files)
          else
            # Single file - use simple staging
            puts "Staging specific files..." unless options.quiet
            result = @file_stager.stage_files(options.files)
          end

          if result
            staged_count = @file_stager.staged_files.length
            puts "✓ Successfully staged #{staged_count} file(s)" unless options.quiet
            true
          else
            # Always show errors, even in quiet mode
            puts "\n✗ Failed to stage files"
            puts "Error: #{@file_stager.last_error}" if @file_stager.last_error
            # Suggestions only in verbose mode
            unless options.quiet
              puts "\nSuggestion: Check file permissions and paths"
            end
            false
          end
        end

        # Stage all changes with progress feedback
        # @param options [Models::CommitOptions] Options
        # @return [Boolean] True if successful
        def stage_all_changes(options)
          puts "Staging all changes..." unless options.quiet

          result = @file_stager.stage_all

          if result
            puts "✓ Changes staged successfully" unless options.quiet
            true
          else
            # Always show errors, even in quiet mode
            puts "\n✗ Failed to stage changes"
            puts "Error: #{@file_stager.last_error}" if @file_stager.last_error

            # Suggestions only in verbose mode
            unless options.quiet
              puts "\nSuggestions:"
              puts "  1. Check file permissions"
              puts "  2. Run 'git status' to see unstaged files"
              puts "  3. Use --only-staged to commit existing staged files"
            end
            false
          end
        end

        # Get or generate commit message
        # @param options [Models::CommitOptions] Options
        # @return [String] Commit message
        def get_commit_message(options)
          if options.use_llm?
            generate_message(options)
          else
            options.message
          end
        end

        # Generate commit message using LLM
        # @param options [Models::CommitOptions] Options
        # @return [String] Generated message
        def generate_message(options)
          puts "Generating commit message..." unless options.quiet

          # Get the diff
          diff = @diff_analyzer.get_staged_diff
          files = @diff_analyzer.changed_files(staged_only: true)

          # Override model if specified
          if options.model
            generator = Molecules::MessageGenerator.new(@config.merge("model" => options.model))
          else
            generator = @message_generator
          end

          message = generator.generate(
            diff,
            intention: options.intention,
            files: files
          )

          puts "✓ Message generated" unless options.quiet
          puts "\nMessage:\n#{message}" if options.debug

          message
        end

        # Show dry run information
        # @param message [String] Commit message
        # @param options [Models::CommitOptions] Options
        def show_dry_run(message, options)
          puts "=== DRY RUN ==="
          puts "Would commit with message:"
          puts "-" * 40
          puts message
          puts "-" * 40

          staged_files = @file_stager.staged_files
          puts "\nFiles to be committed:"
          staged_files.each { |f| puts "  #{f}" }

          if options.debug
            diff_summary = @diff_analyzer.analyze_diff(@diff_analyzer.get_staged_diff)
            puts "\nChanges:"
            puts "  Insertions: +#{diff_summary[:insertions]}"
            puts "  Deletions: -#{diff_summary[:deletions]}"
          end
        end

        # Perform the actual commit
        # @param message [String] Commit message
        # @param options [Models::CommitOptions] Options
        # @return [Boolean] True if successful
        def perform_commit(message, options)
          puts "Committing..." unless options.quiet

          # Execute commit
          @git.execute("commit", "-m", message)

          # Get the commit SHA
          commit_sha = @git.execute("rev-parse", "HEAD").strip

          # Display commit summary
          unless options.quiet
            summarizer = Molecules::CommitSummarizer.new(@git)
            summary = summarizer.summarize(commit_sha)
            puts summary
          end

          true
        rescue GitError => e
          puts "\n✗ Commit failed: #{e.message}"
          false
        end
      end
    end
  end
end