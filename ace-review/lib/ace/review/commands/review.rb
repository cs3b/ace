# frozen_string_literal: true

require_relative "review_command"

module Ace
  module Review
    module Commands
      # dry-cli Command class for the review command
      #
      # This wraps the existing ReviewCommand logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class Review < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Execute code review using presets or custom configuration

          Presets provide pre-configured review types with focused prompts:
            code         → General code review
            code-pr      → PR-focused code review
            security     → Security-focused review
            performance  → Performance-focused review
            docs         → Documentation review

          Configuration:
            Global config:  ~/.ace/review/config.yml
            Project config: .ace/review/config.yml
            Example:        ace-review/.ace-defaults/review/config.yml

          Presets configured via review.presets
        DESC

        example [
          '--preset code-pr             # PR code review',
          '--preset security --auto-execute',
          '--preset code-pr --task 114',
          '--pr 123                      # Review by PR number',
          '--preset code --subject diff:HEAD~3 --subject files:docs/**/*.md',
          '--preset code-pr --model gemini --model gpt-4 --auto-execute',
          '--preset security --dry-run'
        ]

        # Review configuration options
        option :preset, type: :string, desc: "Review preset from configuration"
        option :output_dir, type: :string, desc: "Custom output directory for review"
        option :output, type: :string, desc: "Specific output file path"
        option :context, type: :string, desc: "Context configuration (preset name or YAML)"
        option :subject, type: :array, desc: "Subject configuration (can be specified multiple times)"
        option :prompt_base, type: :string, desc: "Base prompt module"
        option :prompt_format, type: :string, desc: "Format module"
        option :prompt_focus, type: :string, desc: "Focus modules (comma-separated)"
        option :add_focus, type: :string, desc: "Add focus modules to preset"
        option :prompt_guidelines, type: :string, desc: "Guideline modules (comma-separated)"
        option :model, type: :array, desc: "LLM model(s) to use (can be specified multiple times)"
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
        option :gh_timeout, type: :integer, desc: "Timeout for gh CLI operations in seconds (default: 30)"

        # Standard options
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress config summary output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

        def call(**options)
          # Remove dry-cli specific keys (args is leftover arguments)
          clean_options = options.reject { |k, _| k == :args }

          # Type-convert numeric options (dry-cli returns strings, Thor converted to integers)
          clean_options[:gh_timeout] = clean_options[:gh_timeout]&.to_i if clean_options[:gh_timeout]

          # Use the existing ReviewCommand logic
          ReviewCommand.new([], clean_options).execute
        end
      end
    end
  end
end
