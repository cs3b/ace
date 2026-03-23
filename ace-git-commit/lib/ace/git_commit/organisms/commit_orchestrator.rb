# frozen_string_literal: true

module Ace
  module GitCommit
    module Organisms
      # CommitOrchestrator coordinates the entire commit process
      class CommitOrchestrator
        # Reference the default scope name constant
        DEFAULT_SCOPE_NAME = Ace::Support::Config::Models::ConfigGroup::DEFAULT_SCOPE_NAME
        def initialize(config = nil)
          @config = config || load_config
          @git = Atoms::GitExecutor.new
          @diff_analyzer = Molecules::DiffAnalyzer.new(@git)
          @file_stager = Molecules::FileStager.new(@git)
          @path_resolver = Molecules::PathResolver.new(@git)
          @message_generator = Molecules::MessageGenerator.new(@config)
          @commit_grouper = Molecules::CommitGrouper.new
          @split_commit_executor = Molecules::SplitCommitExecutor.new(
            git_executor: @git,
            diff_analyzer: @diff_analyzer,
            file_stager: @file_stager,
            message_generator: @message_generator
          )
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
          has_staged_changes = @git.has_staged_changes?
          unless has_staged_changes
            puts "No changes to commit" unless options.quiet
            return true
          end
          puts "✓ Changes staged successfully" if options.stage_all? && !options.quiet

          staged_files = @file_stager.staged_files
          groups = @commit_grouper.group(staged_files, project_root: @git.repository_root)

          if options.no_split
            message = get_commit_message(options, config_override: @config)
            return handle_single_commit(message, options)
          end

          if groups.length > 1
            display_split_summary(groups) unless options.quiet
            result = @split_commit_executor.execute(groups, options)
            return result.success?
          end

          group_config = groups.first ? groups.first.config : @config
          message = get_commit_message(options, config_override: group_config)
          handle_single_commit(message, options)
        end

        private

        # Load configuration with gem defaults and user overrides
        # Follows ADR-022: Configuration Default and Override Pattern
        # Uses Ace::Support::Config.create() for configuration cascade resolution
        # @return [Hash] Configuration
        def load_config
          gem_root = Gem.loaded_specs["ace-git-commit"]&.gem_dir ||
            File.expand_path("../../../..", __dir__)

          resolver = Ace::Support::Config.create(
            config_dir: ".ace",
            defaults_dir: ".ace-defaults",
            gem_path: gem_root
          )

          # Resolve config for git/commit namespace
          config = resolver.resolve_namespace("git", filename: "commit")

          # Extract git section if present, otherwise use root
          config.data["git"] || config.data
        rescue => e
          warn "Error loading git commit config: #{e.message}" if Ace::GitCommit.debug?
          {}
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
              puts "\n✗ Invalid path(s): #{validation[:invalid].join(", ")}"
              if @path_resolver.last_error
                puts "Git error: #{@path_resolver.last_error}"
              else
                puts "These paths do not exist or have no git changes. Please check the paths and try again."
              end
              return false
            end
          end

          # Separate paths by type for different handling
          glob_patterns = options.files.select { |f| @path_resolver.glob_pattern?(f) }
          non_patterns = options.files - glob_patterns
          directories = non_patterns.select { |f| File.directory?(f) }
          single_files = non_patterns - directories

          # Build list of paths to stage
          # - Directories: pass through directly (git add handles gitignore)
          # - Globs: expand to tracked files (requires filesystem traversal)
          # - Single files: pass through
          paths_to_stage = directories + single_files

          # Expand glob patterns to committable files (tracked + untracked)
          unless glob_patterns.empty?
            resolved_globs = @path_resolver.resolve_paths(glob_patterns)
            if resolved_globs.empty?
              puts "\n✗ No files found matching the specified pattern(s)"

              # Collect suggestions for simple glob patterns
              suggestions = glob_patterns.filter_map do |pattern|
                suggested = @path_resolver.suggest_recursive_pattern(pattern)
                {original: pattern, suggested: suggested} if suggested
              end

              # Output consolidated hint if any suggestions exist
              unless suggestions.empty?
                puts "\nHint: The following pattern(s) only match files at the current directory level:"
                suggestions.each do |s|
                  puts "  '#{s[:original]}' → try '#{s[:suggested]}' for recursive matching"
                end
              end

              return false
            end
            paths_to_stage.concat(resolved_globs)
          end

          if paths_to_stage.empty?
            puts "\n✗ No files found matching the specified path(s)"
            return false
          end

          # Stage using path-restricted approach (reset + selective add)
          puts "Staging files from specified path(s)..." unless options.quiet
          result = @file_stager.stage_paths(paths_to_stage)

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
          result = @file_stager.stage_all

          if result
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
        def get_commit_message(options, config_override: nil)
          if options.use_llm?
            generate_message(options, config_override: config_override)
          else
            options.message
          end
        end

        # Generate commit message using LLM
        # @param options [Models::CommitOptions] Options
        # @return [String] Generated message
        def generate_message(options, config_override: nil)
          puts "Generating commit message..." unless options.quiet

          # Get the diff
          diff = @diff_analyzer.get_staged_diff
          files = @diff_analyzer.changed_files(staged_only: true)

          config = config_override || @config
          config = config.merge("model" => options.model) if options.model

          message = @message_generator.generate(
            diff,
            intention: options.intention,
            files: files,
            config: config
          )

          puts "✓ Message generated" unless options.quiet
          puts "\nMessage:\n#{message}" if options.debug

          message
        end

        def handle_single_commit(message, options)
          if options.dry_run
            show_dry_run(message, options)
            return true
          end

          perform_commit(message, options)
        end

        def display_split_summary(groups)
          puts "Detected #{groups.length} configuration scopes:"
          groups.each do |group|
            label = group.scope_name.to_s.empty? ? DEFAULT_SCOPE_NAME : group.scope_name
            source = group.source ? " (#{group.source})" : ""
            puts "  - #{label}#{source}: #{group.file_count} file(s)"
          end
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
