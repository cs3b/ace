# frozen_string_literal: true

module Ace
  module Review
    module Models
      # Options for code review execution
      class ReviewOptions
        attr_accessor :preset, :output_dir, :output, :context, :subject,
          :prompt_base, :prompt_format, :prompt_focus, :add_focus,
          :prompt_guidelines, :model, :models, :dry_run, :verbose,
          :auto_execute, :save_session, :session_dir,
          :pr, :post_comment, :pr_metadata, :gh_timeout,
          :pr_comments, :pr_comment_data,
          :no_feedback, :feedback_model,
          :list_presets, :list_prompts, :help

        def initialize(hash = {})
          # Core options
          @preset = hash[:preset] || Ace::Review.get("defaults", "preset")
          @output_dir = hash[:output_dir]
          @output = hash[:output]

          # Context and subject
          @context = hash[:context]
          @subject = hash[:subject]

          # Prompt composition overrides
          @prompt_base = hash[:prompt_base]
          @prompt_format = hash[:prompt_format]
          @prompt_focus = hash[:prompt_focus]
          @add_focus = hash[:add_focus]
          @prompt_guidelines = hash[:prompt_guidelines]

          # Execution options
          @model = hash[:model]
          @models = hash[:models]
          @dry_run = hash[:dry_run] || false
          @verbose = hash[:verbose] || false
          @auto_execute = if @dry_run
            false
          elsif hash[:auto_execute].nil?
            Ace::Review.get("defaults", "auto_execute") || false
          else
            hash[:auto_execute]
          end

          # Session options
          @save_session = hash.fetch(:save_session, true)
          @session_dir = hash[:session_dir]

          # PR review options
          @pr = hash[:pr]
          @post_comment = hash[:post_comment] || false
          @pr_metadata = hash[:pr_metadata]
          @gh_timeout = hash[:gh_timeout]

          # PR comment options
          @pr_comments = hash[:pr_comments]  # nil = use default, true/false = explicit
          @pr_comment_data = nil  # Populated during execution

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
          instance_variables.each_with_object({}) do |var, hash|
            key = var.to_s.delete_prefix("@").to_sym
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
          config_default.nil? || config_default
        end

        # Check if output should be saved
        def save_output?
          !dry_run && save_session
        end

        # Check if feedback extraction is enabled
        def feedback_enabled?
          !@no_feedback
        end

        # Get effective model (single model)
        # Priority: model scalar > first model in models array > config_model > default
        def effective_model(config_model = nil)
          return model if model
          return models.first if models&.any?
          config_model || "google:gemini-2.5-flash"
        end

        # Get effective models array
        # Returns array of models, handling both single model and multi-model cases
        # Priority: models array > model scalar > config_models > default
        def effective_models(config_models = nil)
          # If models array is set (from CLI), use it
          return models if models&.any?

          # If model scalar is set, wrap in array
          return [model] if model

          # If config provides models array, use it
          if config_models.is_a?(Array) && config_models.any?
            return config_models
          end

          # If config provides single model, wrap in array
          if config_models.is_a?(String) && !config_models.empty?
            return [config_models]
          end

          # Default to single model
          ["google:gemini-2.5-flash"]
        end

        # Merge with config values
        def merge_config(config)
          return if config.nil?

          # Merge system prompt configuration if not overridden
          @prompt_base ||= config.dig("system_prompt", "base")
          @prompt_format ||= config.dig("system_prompt", "format")

          # Handle focus modules
          if @add_focus && config.dig("system_prompt", "focus")
            existing_focus = config.dig("system_prompt", "focus") || []
            additional_focus = @add_focus.split(",").map(&:strip)
            @prompt_focus = (existing_focus + additional_focus).uniq.join(",")
          elsif !@prompt_focus && config.dig("system_prompt", "focus")
            @prompt_focus = Array(config.dig("system_prompt", "focus")).join(",")
          end

          @prompt_guidelines ||= Array(config.dig("system_prompt", "guidelines")).join(",") if config.dig("system_prompt", "guidelines")

          # Merge other config values
          @context ||= config["context"]
          @subject ||= config["subject"]

          # Handle models from config
          # CLI models override preset models
          unless @models&.any?
            if config["models"].is_a?(Array) && config["models"].any?
              @models = config["models"]
            elsif config["model"]
              @model ||= config["model"]
            end
          end

          @gh_timeout ||= config["gh_timeout"]

          self
        end

        # Build system prompt composition hash
        def system_prompt_composition
          composition = {}

          composition["base"] = prompt_base if prompt_base
          composition["format"] = prompt_format if prompt_format

          if prompt_focus
            composition["focus"] = prompt_focus.split(",").map(&:strip)
          end

          if prompt_guidelines
            composition["guidelines"] = prompt_guidelines.split(",").map(&:strip)
          end

          composition.empty? ? nil : composition
        end
      end
    end
  end
end
