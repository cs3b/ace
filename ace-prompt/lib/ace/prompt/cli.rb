# frozen_string_literal: true

require "thor"
require_relative "../prompt"
require_relative "organisms/prompt_processor"
require_relative "organisms/prompt_initializer"

module Ace
  module Prompt
    class CLI < Thor
      def self.exit_on_failure?
        true
      end

      default_task :process

      desc "process", "Process prompt (default command)"
      long_desc <<-LONGDESC
        Process the prompt file with optional context loading and enhancement.

        Default behavior:
        - Reads .cache/ace-prompt/prompts/the-prompt.md
        - Archives to archive/YYYYMMDD-HHMMSS.md
        - Updates _previous.md symlink
        - Outputs content to stdout

        Examples:
          $ ace-prompt                    # Basic processing
          $ ace-prompt --ace-context      # With context loading
          $ ace-prompt --enhance          # With LLM enhancement
          $ ace-prompt -ce                # Both context and enhancement
          $ ace-prompt --task 117         # Task-specific prompt
      LONGDESC
      option :ace_context, type: :boolean, aliases: "-c", desc: "Load context via ace-context"
      option :enhance, type: :boolean, aliases: "-e", desc: "Enhance prompt via LLM"
      option :raw, type: :boolean, desc: "Skip enhancement even if configured"
      option :no_context, type: :boolean, desc: "Skip context even if configured"
      option :task, type: :numeric, aliases: "-t", desc: "Use task-specific prompt"
      def process
        processor = Organisms::PromptProcessor.new
        content = processor.process(options.transform_keys(&:to_sym))
        puts content
        0
      rescue Ace::Prompt::Error => e
        warn "Error: #{e.message}"
        warn "Hint: Check your configuration and ensure required directories exist." if e.message.include?("not found")
        1
      rescue => e
        warn "Unexpected error: #{e.message}"
        warn "Hint: This may be a bug. Please report it with the command you were running."
        warn e.backtrace.join("\n") if ENV["DEBUG"]
        1
      end

      desc "setup", "Initialize prompt with base template"
      long_desc <<-LONGDESC
        Initialize a new prompt file using the base template.

        Creates .cache/ace-prompt/prompts/the-prompt.md with structured template
        including frontmatter for context specification.

        Examples:
          $ ace-prompt setup                                  # Use default template
          $ ace-prompt setup --template tmpl://custom/prompt  # Custom template
          $ ace-prompt setup --force                          # Overwrite existing
      LONGDESC
      option :template, type: :string, desc: "Template URI (default: tmpl://ace-prompt/base-prompt)"
      option :force, type: :boolean, desc: "Overwrite existing prompt"
      def setup
        initializer = Organisms::PromptInitializer.new
        path = initializer.setup(
          template_uri: options[:template],
          force: options[:force]
        )
        puts "Prompt initialized: #{path}"
        0
      rescue Ace::Prompt::Error => e
        warn "Error: #{e.message}"
        warn "Hint: Check your configuration and ensure required directories exist." if e.message.include?("not found")
        1
      rescue => e
        warn "Unexpected error: #{e.message}"
        warn "Hint: This may be a bug. Please report it with the command you were running."
        warn e.backtrace.join("\n") if ENV["DEBUG"]
        1
      end

      desc "reset", "Reset prompt to base template (archives current)"
      long_desc <<-LONGDESC
        Reset the prompt file to the base template, archiving the current version first.

        This is useful when you want to start fresh but preserve the current prompt
        in the archive.

        Examples:
          $ ace-prompt reset                                 # Reset to default template
          $ ace-prompt reset --template tmpl://custom/prompt # Reset to custom template
      LONGDESC
      option :template, type: :string, desc: "Template URI (default from config)"
      def reset
        initializer = Organisms::PromptInitializer.new
        path = initializer.reset(template_uri: options[:template])
        puts "Prompt reset: #{path}"
        puts "Previous prompt archived"
        0
      rescue Ace::Prompt::Error => e
        warn "Error: #{e.message}"
        warn "Hint: Check your configuration and ensure required directories exist." if e.message.include?("not found")
        1
      rescue => e
        warn "Unexpected error: #{e.message}"
        warn "Hint: This may be a bug. Please report it with the command you were running."
        warn e.backtrace.join("\n") if ENV["DEBUG"]
        1
      end

      desc "enhance", "Enhance prompt via LLM (standalone command)"
      long_desc <<-LONGDESC
        Enhance the prompt using LLM for clarity and specificity.

        This command:
        - Reads the current prompt
        - Archives original (if first enhancement)
        - Enhances via LLM
        - Archives enhanced version with _e001, _e002, etc. suffix
        - Writes enhanced content back to the-prompt.md
        - Outputs enhanced content to stdout

        Can be used standalone or combined with other commands via process -e flag.

        Examples:
          $ ace-prompt enhance                # Enhance current prompt
          $ ace-prompt enhance --task 117     # Enhance task-specific prompt
          $ ace-prompt enhance --ace-context  # Enhance with context loaded
      LONGDESC
      option :task, type: :numeric, aliases: "-t", desc: "Use task-specific prompt"
      option :ace_context, type: :boolean, aliases: "-c", desc: "Load context before enhancement"
      def enhance
        processor = Organisms::PromptProcessor.new
        # Force enhancement on
        opts = options.transform_keys(&:to_sym).merge(enhance: true)
        content = processor.process(opts)
        puts content
        0
      rescue Ace::Prompt::Error => e
        warn "Error: #{e.message}"
        warn "Hint: Check your configuration and ensure required directories exist." if e.message.include?("not found")
        1
      rescue => e
        warn "Unexpected error: #{e.message}"
        warn "Hint: This may be a bug. Please report it with the command you were running."
        warn e.backtrace.join("\n") if ENV["DEBUG"]
        1
      end
    end
  end
end
