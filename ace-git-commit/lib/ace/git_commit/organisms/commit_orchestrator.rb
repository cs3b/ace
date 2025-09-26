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
          stage_changes(options)

          # Ensure we have changes to commit
          unless @git.has_staged_changes?
            puts "No changes to commit" if options.debug
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
          # Try to load from ace-core config resolver
          if defined?(Ace::Core::ConfigResolver)
            Ace::Core::ConfigResolver.load("git")
          else
            # Fallback to default config
            default_config
          end
        rescue StandardError
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
        def stage_changes(options)
          if options.specific_files?
            puts "Staging specific files: #{options.files.join(', ')}" if options.debug
            @file_stager.stage_files(options.files)
          elsif options.stage_all?
            puts "Staging all changes" if options.debug
            @file_stager.stage_all
          else
            puts "Using currently staged changes" if options.debug
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
          puts "Generating commit message..." if options.debug

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

          puts "Generated message:\n#{message}" if options.debug

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
          puts "Committing..." if options.debug

          # Execute commit
          @git.execute("commit", "-m", message)

          puts "Commit successful!" if options.debug
          true
        rescue GitError => e
          puts "Commit failed: #{e.message}"
          false
        end
      end
    end
  end
end