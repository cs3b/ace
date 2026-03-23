# frozen_string_literal: true

require_relative "../../organisms/prompt_processor"

module Ace
  module PromptPrep
    module CLI
      module Commands
        # ace-support-cli Command class for the process command
        #
        # This wraps the existing PromptProcessor logic in a ace-support-cli compatible
        # interface, maintaining complete parity with the Thor implementation.
        class Process < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base

          desc <<~DESC.strip
            Read prompt file, archive it with Base36 ID, update symlink, and output content

            By default:
            - Reads from .ace-local/prompt-prep/prompts/the-prompt.md
            - Archives to .ace-local/prompt-prep/prompts/archive/{base36-id}.md
            - Updates _previous.md symlink
            - Outputs to stdout
          DESC

          example [
            "                             # Process prompt from default location",
            "--output /tmp/prompt.md      # Write to file instead of stdout",
            "--output -                   # Explicit stdout (default)",
            "--bundle                     # Process via ace-bundle SDK (short: -b)",
            "--no-bundle                  # Explicitly disable ace-bundle processing",
            "--enhance --model gpt-4     # Enhance via LLM",
            "--task 121                   # Use task-specific prompts"
          ]

          option :output, type: :string, aliases: %w[-o],
            desc: "Write content to file instead of stdout (use '-' for explicit stdout)"
          option :bundle, type: :boolean, aliases: %w[-b],
            desc: "Process via ace-bundle SDK"
          option :context, type: :boolean, aliases: %w[-c],
            desc: "Deprecated alias for --bundle"
          option :no_bundle, type: :boolean,
            desc: "Explicitly disable ace-bundle processing"
          option :no_context, type: :boolean,
            desc: "Deprecated alias for --no-bundle"
          option :enhance, type: :boolean, aliases: %w[-e],
            desc: "Enhance prompt via LLM"
          option :no_enhance, type: :boolean,
            desc: "Explicitly disable LLM enhancement (override config)"
          option :model, type: :string,
            desc: "LLM model (default from config: defaults.model)"
          option :system_prompt, type: :string,
            desc: "Custom system prompt path"
          option :task, type: :string,
            desc: "Use task's prompts directory (e.g., '117' or '121.01')"
          # Note: ace-support-cli handles --help/-h automatically, no need to define it

          # Standard options (inherited from Base but need explicit definition for ace-support-cli)
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(**options)
            # Determine bundle flag
            bundle_enabled = determine_bundle_enabled(options)

            # Determine enhance flag
            enhance_enabled = determine_enhance_enabled(options)

            # Resolve task prompt path (handles both explicit --task and auto-detection)
            task_prompt_path = resolve_task_prompt_path(options[:task])

            # Process prompt
            result = Organisms::PromptProcessor.call(
              input_path: task_prompt_path,
              bundle: bundle_enabled,
              enhance: enhance_enabled,
              model: options[:model],
              system_prompt: options[:system_prompt]
            )

            unless result[:success]
              raise Ace::Support::Cli::Error.new(result[:error])
            end

            # Handle output
            output_mode = options[:output] || "-"

            if output_mode == "-"
              # Output to stdout
              puts result[:content]
            else
              # Write to file
              require "fileutils"
              FileUtils.mkdir_p(File.dirname(output_mode))

              begin
                File.write(output_mode, result[:content], encoding: "utf-8")
                # Output summary to stdout
                $stdout.puts "Prompt archived and saved:"
                $stdout.puts "  Archive: #{result[:archive_path]}"
                $stdout.puts "  Output:  #{File.expand_path(output_mode)}"
              rescue => e
                raise Ace::Support::Cli::Error.new("Failed to write output file: #{e.message}")
              end
            end
          rescue Ace::PromptPrep::Error => e
            raise Ace::Support::Cli::Error.new(e.message)
          end

          private

          # Determine if bundle processing should be enabled
          # Priority: CLI flags > config file
          def determine_bundle_enabled(options)
            # Explicit --no-bundle disables
            return false if options[:no_bundle] || options[:no_context]

            # Explicit --bundle enables
            return true if options[:bundle] || options[:context]

            # Fall back to config (check both legacy "context" key and new "bundle" key)
            Ace::PromptPrep.config.dig("bundle", "enabled") || Ace::PromptPrep.config.dig("context", "enabled") || false
          end

          # Determine if enhancement should be enabled
          # Priority: CLI flags > config file
          def determine_enhance_enabled(options)
            # Explicit --no-enhance disables
            return false if options[:no_enhance]

            # Explicit --enhance enables
            return true if options[:enhance]

            # Fall back to config
            Ace::PromptPrep.config.dig("enhance", "enabled") || false
          end

          # Resolve task prompt path using shared helper
          def resolve_task_prompt_path(task_option)
            Ace::PromptPrep::CLI::Helpers.resolve_task_prompt_path(task_option)
          end
        end
      end
    end
  end
end
