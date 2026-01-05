# frozen_string_literal: true

require "ace/core/cli/base"

module Ace
  module Review
    class CLI < Ace::Core::CLI::Base
      # class_options :quiet, :verbose, :debug inherited from Base

      default_task :review

      # Override help to add preset system section
      def self.help(shell, subcommand = false)
        super
        shell.say ""
        shell.say "Preset System:"
        shell.say "  Presets provide pre-configured review types with focused prompts:"
        shell.say "    code         → General code review"
        shell.say "    code-pr      → PR-focused code review"
        shell.say "    security     → Security-focused review"
        shell.say "    performance  → Performance-focused review"
        shell.say "    docs         → Documentation review"
        shell.say "  Use --list-presets to see all available presets"
        shell.say ""
        shell.say "Examples:"
        shell.say "  ace-review --preset code-pr             # PR code review"
        shell.say "  ace-review --preset security --auto-execute"
        shell.say "  ace-review --pr 123                      # Review by PR number"
      end

      desc "review [OPTIONS]", "Execute code review using presets or custom configuration"
      long_desc <<~DESC
        Execute code review using presets or custom configuration.

        SYNTAX:
          ace-review [OPTIONS]

        EXAMPLES:

          # Use preset for code review
          $ ace-review --preset code-pr

          # Security review with auto-execute
          $ ace-review --preset security --auto-execute

          # Save review to task directory
          $ ace-review --preset code-pr --task 114

          # Review GitHub PR
          $ ace-review --pr 123 --auto-execute

          # Multi-subject review
          $ ace-review --preset code --subject diff:HEAD~3 --subject files:docs/**/*.md

          # Multi-model review with synthesis
          $ ace-review --preset code-pr --model gemini --model gpt-4 --auto-execute

          # Dry run to preview
          $ ace-review --preset security --dry-run

        CONFIGURATION:

          Global config:  ~/.ace/review/config.yml
          Project config: .ace/review/config.yml
          Example:        ace-review/.ace-defaults/review/config.yml

          Presets configured via review.presets

        OUTPUT:

          Review report saved to file or task directory
          Exit codes: 0 (success), 1 (error)

        PRESET SYSTEM:

          code         → General code review
          code-pr      → PR-focused code review
          security     → Security-focused review
          performance  → Performance-focused review
          docs         → Documentation review

          Use --list-presets to see all available presets
      DESC
      option :preset, type: :string, desc: "Review preset from configuration"
      option :output_dir, type: :string, desc: "Custom output directory for review"
      option :output, type: :string, desc: "Specific output file path"
      option :context, type: :string, desc: "Context configuration (preset name or YAML)"
      option :subject, type: :string, repeatable: true, desc: "Subject configuration (can be specified multiple times)"
      option :prompt_base, type: :string, desc: "Base prompt module"
      option :prompt_format, type: :string, desc: "Format module"
      option :prompt_focus, type: :string, desc: "Focus modules (comma-separated)"
      option :add_focus, type: :string, desc: "Add focus modules to preset"
      option :prompt_guidelines, type: :string, desc: "Guideline modules (comma-separated)"
      option :model, type: :string, repeatable: true, desc: "LLM model(s) to use (can be specified multiple times)"
      option :no_synthesize, type: :boolean, desc: "Skip synthesis for multi-model reviews"
      option :synthesis_model, type: :string, desc: "Model to use for synthesis (default: gemini-2.5-flash)"
      option :dry_run, type: :boolean, desc: "Prepare review without executing"
      option :auto_execute, type: :boolean, desc: "Execute LLM query automatically"
      option :save_session, type: :boolean, desc: "Save session files (default: true)"
      option :session_dir, type: :string, desc: "Custom session directory"
      option :task, type: :string, desc: "Save review report to task directory (task number, task.NNN, or v.X.Y.Z+NNN)"
      option :no_auto_save, type: :boolean, desc: "Disable auto-save even if enabled in config"
      option :pr, type: :string, desc: "Review GitHub PR (number, URL, or owner/repo#number)"
      option :pr_comments, type: :boolean, desc: "Include PR comments as feedback source (default: true for --pr)"
      option :post_comment, type: :boolean, desc: "Post review as PR comment (requires --pr)"
      option :gh_timeout, type: :numeric, desc: "Timeout for gh CLI operations in seconds (default: 30)"
      def review(*args)
        # Handle --help/-h passed as first argument
        if args.first == "--help" || args.first == "-h"
          invoke :help, ["review"]
          return 0
        end
        require_relative "commands/review_command"
        Commands::ReviewCommand.new(args, options).execute
      end

      desc "synthesize [OPTIONS]", "Synthesize multiple review reports into a consolidated report"
      long_desc <<~DESC
        Synthesize multiple review reports into a consolidated report.

        SYNTAX:
          ace-review synthesize [OPTIONS]

        EXAMPLES:

          # Synthesize from session directory
          $ ace-review synthesize --session .cache/ace-review/sessions/review-20251201-143022/

          # Synthesize specific reports
          $ ace-review synthesize --reports report1.md,report2.md --output synthesis.md

        CONFIGURATION:

          Global config:  ~/.ace/review/config.yml
          Project config: .ace/review/config.yml
          Example:        ace-review/.ace-defaults/review/config.yml

        OUTPUT:

          Consolidated synthesis report saved to file
          Exit codes: 0 (success), 1 (error)
      DESC
      option :session, type: :string, desc: "Session directory containing review reports"
      option :reports, type: :string, desc: "Explicit report files to synthesize (comma-separated)"
      option :synthesis_model, type: :string, desc: "Model to use for synthesis"
      option :output, type: :string, desc: "Output file path (default: synthesis-report.md)"
      option :verbose, type: :boolean, aliases: "-v", desc: "Verbose output"
      def synthesize(*args)
        require_relative "commands/synthesize_command"
        Commands::SynthesizeCommand.new(args, options).execute
      end

      desc "list-presets", "List available review presets"
      long_desc <<~DESC
        List all available review presets with descriptions and sources.

        EXAMPLES:

          # List all presets
          $ ace-review list-presets

        CONFIGURATION:

          Global config:  ~/.ace/review/config.yml
          Project config: .ace/review/config.yml
          Example:        ace-review/.ace-defaults/review/config.yml

        OUTPUT:

          Table format with columns: name, description, source
          Exit codes: 0 (success), 1 (error)
      DESC
      def list_presets
        require_relative "commands/list_presets_command"
        Commands::ListPresetsCommand.new.execute
      end

      desc "list-prompts", "List available prompt modules"
      long_desc <<~DESC
        List all available prompt modules by category.

        EXAMPLES:

          # List all prompt modules
          $ ace-review list-prompts

        CONFIGURATION:

          Global config:  ~/.ace/review/config.yml
          Project config: .ace/review/config.yml
          Example:        ace-review/.ace-defaults/review/config.yml

        OUTPUT:

          Grouped by category: base, format, focus, guidelines
          Exit codes: 0 (success), 1 (error)
      DESC
      def list_prompts
        require_relative "commands/list_prompts_command"
        Commands::ListPromptsCommand.new.execute
      end

      desc "version", "Show version"
      long_desc <<~DESC
        Display the current version of ace-review.

        EXAMPLES:

          $ ace-review version
          $ ace-review --version
      DESC
      def version
        puts "ace-review #{Ace::Review::VERSION}"
        0
      end
      map "--version" => :version

      # Handle unknown commands as arguments to the default 'review' command
      def method_missing(command, *args)
        invoke :review, [command.to_s] + args
      end
      # respond_to_missing? inherited from Ace::Core::CLI::Base
    end
  end
end
