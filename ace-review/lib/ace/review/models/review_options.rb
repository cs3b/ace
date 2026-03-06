# frozen_string_literal: true

module Ace
  module Review
    module Models
      # Options for code review execution
      class ReviewOptions
        attr_accessor :preset, :output_dir, :output, :context, :subject,
                      :model, :models, :reviewers, :dry_run, :verbose,
                      :auto_execute, :save_session, :session_dir,
                      :task, :pr, :post_comment, :pr_metadata, :gh_timeout,
                      :pr_comments, :pr_comment_data, :no_auto_save,
                      :no_feedback, :feedback_model, :provider_overrides,
                      :providers_llm, :providers_tools_lint,
                      :partition,
                      :require_all_reports,
                      :list_presets, :list_prompts, :help

        def initialize(hash = {})
          @model_explicit = hash.key?(:model) && !hash[:model].nil?
          @models_explicit = hash.key?(:models) && hash[:models].is_a?(Array) && hash[:models].any?

          # Core options
          @preset = hash[:preset] || Ace::Review.get("defaults", "preset")
          @output_dir = hash[:output_dir]
          @output = hash[:output]

          # Context and subject
          @context = hash[:context]
          @subject = hash[:subject]

          # Execution options
          @model = hash[:model]
          @models = hash[:models]
          @reviewers = hash[:reviewers]
          @provider_overrides = hash[:provider_overrides]
          @providers_llm = hash[:providers_llm]
          @providers_tools_lint = hash[:providers_tools_lint]
          @partition = hash[:partition]
          @require_all_reports = hash.key?(:require_all_reports) ? hash[:require_all_reports] : true
          @dry_run = hash[:dry_run] || false
          @verbose = hash[:verbose] || false
          @auto_execute = hash.key?(:auto_execute) ? hash[:auto_execute] : (Ace::Review.get("defaults", "auto_execute") || false)

          # Session options
          @save_session = hash.fetch(:save_session, true)
          @session_dir = hash[:session_dir]

          # Task integration
          @task = hash[:task]

          # PR review options
          @pr = hash[:pr]
          @post_comment = hash[:post_comment] || false
          @pr_metadata = hash[:pr_metadata]
          @gh_timeout = hash[:gh_timeout]

          # PR comment options
          @pr_comments = hash[:pr_comments]  # nil = use default, true/false = explicit
          @pr_comment_data = nil  # Populated during execution

          # Auto-save options
          @no_auto_save = hash[:no_auto_save] || false

          # Feedback extraction options
          @no_feedback = hash[:no_feedback] || false
          @feedback_model = hash[:feedback_model]

          # List commands
          @list_presets = hash[:list_presets] || false
          @list_prompts = hash[:list_prompts] || false
          @help = hash[:help] || false
        end

        # Convert back to hash for compatibility
        def to_h
          internal_keys = %i[model_explicit models_explicit]
          instance_variables.each_with_object({}) do |var, hash|
            key = var.to_s.delete_prefix('@').to_sym
            next if internal_keys.include?(key)
            value = instance_variable_get(var)
            hash[key] = value unless value.nil?
          end
        end

        # Check if this is a list command
        def list_command?
          list_presets || list_prompts || help
        end

        # Check if this is a PR review
        def pr_review?
          !pr.nil? && !pr.to_s.strip.empty?
        end

        # Check if comment posting should be triggered (includes dry-run preview)
        def should_post_comment?
          pr_review? && post_comment
        end

        # Check if PR comments should be included as feedback source
        # Enabled by default for PR reviews, can be disabled with --no-pr-comments
        def include_pr_comments?
          return false unless pr_review?

          # Explicit flag overrides everything
          return pr_comments unless pr_comments.nil?

          # Check config default (defaults to true for PR reviews)
          config_default = Ace::Review.get("defaults", "pr_comments")
          config_default.nil? ? true : config_default
        end

        # Check if output should be saved
        def save_output?
          !dry_run && save_session
        end

        # Check if feedback extraction is enabled
        def feedback_enabled?
          !@no_feedback
        end

        # Get effective model from explicit CLI selection only.
        def effective_model(_config_model = nil)
          return model if model
          return models.first if models&.any?

          nil
        end

        # Get effective models array from explicit CLI selection only.
        def effective_models(_config_models = nil)
          return models if models&.any?
          return [model] if model

          []
        end

        # Merge with config values
        def merge_config(config)
          return if config.nil?

          # Merge other config values
          @context ||= config[:context] || config["context"]
          @subject ||= config[:subject] || config["subject"]

          # Merge reviewer objects from preset config (only if not already set and
          # no explicit CLI model overrides — explicit --models take full precedence)
          cli_models_explicit = @models_explicit || @model_explicit
          unless @reviewers&.any? || cli_models_explicit
            raw = config[:reviewers] || config["reviewers"]
            if raw.is_a?(Array) && raw.first.is_a?(Models::Reviewer)
              @reviewers = raw
            else
              resolved = Models::Reviewer.from_preset_config(config)
              @reviewers = resolved unless resolved.empty?
            end
          end

          @gh_timeout ||= config["gh_timeout"]

          self
        end
      end
    end
  end
end
