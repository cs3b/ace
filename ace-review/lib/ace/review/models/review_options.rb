# frozen_string_literal: true

module Ace
  module Review
    module Models
      # Options for code review execution
      class ReviewOptions
        attr_accessor :preset, :output_dir, :output, :context, :subject,
                      :prompt_base, :prompt_format, :prompt_focus, :add_focus,
                      :prompt_guidelines, :model, :dry_run, :verbose,
                      :auto_execute, :save_session, :session_dir,
                      :list_presets, :list_prompts, :help

        def initialize(hash = {})
          # Core options
          @preset = hash[:preset] || "pr"
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
          @dry_run = hash[:dry_run] || false
          @verbose = hash[:verbose] || false
          @auto_execute = hash[:auto_execute] || false

          # Session options
          @save_session = hash.fetch(:save_session, true)
          @session_dir = hash[:session_dir]

          # List commands
          @list_presets = hash[:list_presets] || false
          @list_prompts = hash[:list_prompts] || false
          @help = hash[:help] || false
        end

        # Convert back to hash for compatibility
        def to_h
          instance_variables.each_with_object({}) do |var, hash|
            key = var.to_s.delete_prefix('@').to_sym
            value = instance_variable_get(var)
            hash[key] = value unless value.nil?
          end
        end

        # Check if this is a list command
        def list_command?
          list_presets || list_prompts || help
        end

        # Check if output should be saved
        def save_output?
          !dry_run && save_session
        end

        # Get effective model
        def effective_model(config_model = nil)
          model || config_model || "google:gemini-2.5-flash"
        end

        # Merge with config values
        def merge_config(config)
          # Merge prompt composition if not overridden
          @prompt_base ||= config.dig("prompt_composition", "base")
          @prompt_format ||= config.dig("prompt_composition", "format")

          # Handle focus modules
          if @add_focus && config.dig("prompt_composition", "focus")
            existing_focus = config.dig("prompt_composition", "focus") || []
            additional_focus = @add_focus.split(",").map(&:strip)
            @prompt_focus = (existing_focus + additional_focus).uniq.join(",")
          elsif !@prompt_focus && config.dig("prompt_composition", "focus")
            @prompt_focus = Array(config.dig("prompt_composition", "focus")).join(",")
          end

          @prompt_guidelines ||= Array(config.dig("prompt_composition", "guidelines")).join(",") if config.dig("prompt_composition", "guidelines")

          # Merge other config values
          @context ||= config["context"]
          @subject ||= config["subject"]
          @model ||= config["model"]

          self
        end

        # Build prompt composition hash
        def prompt_composition
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