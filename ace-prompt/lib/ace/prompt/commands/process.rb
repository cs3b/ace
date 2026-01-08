# frozen_string_literal: true

require_relative "../organisms/prompt_processor"

module Ace
  module Prompt
    module Commands
      # dry-cli Command class for the process command
      #
      # This wraps the existing PromptProcessor logic in a dry-cli compatible
      # interface, maintaining complete parity with the Thor implementation.
      class Process < Dry::CLI::Command
        include Ace::Core::CLI::DryCli::Base

        desc <<~DESC.strip
          Read prompt file, archive it with timestamp, update symlink, and output content

          By default:
            - Reads from .cache/ace-prompt/prompts/the-prompt.md
            - Archives to .cache/ace-prompt/prompts/archive/YYYYMMDD-HHMMSS.md
            - Updates _previous.md symlink
            - Outputs to stdout
        DESC

        example [
          'ace-prompt                    # Process prompt from default location',
          '--output /tmp/prompt.md       # Write to file instead of stdout',
          '--output -                    # Explicit stdout (default)',
          '--context                    # Load context via ace-context (short: -c)',
          '--no-context                 # Explicitly disable context loading',
          '--enhance --model gpt-4      # Enhance via LLM',
          '--task 121                   # Use task-specific prompts'
        ]

        option :output, type: :string, aliases: %w[-o],
                        desc: "Write content to file instead of stdout (use '-' for explicit stdout)"
        option :context, type: :boolean, aliases: %w[-c],
                         desc: "Load context via ace-context (from frontmatter)"
        option :no_context, type: :boolean,
                          desc: "Explicitly disable context loading (override config)"
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
        option :help, type: :boolean, aliases: %w[-h], desc: "Show this help message"

        # Standard options (inherited from Base but need explicit definition for dry-cli)
        option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"
        option :verbose, type: :boolean, aliases: %w[-v], desc: "Enable verbose output"
        option :debug, type: :boolean, aliases: %w[-d], desc: "Enable debug output"

        def call(**options)
          # Handle --help/-h option
          if help?(options)
            # dry-cli will handle help automatically via the desc and example attributes
            # We just need to return success
            return exit_success
          end

          # Determine context flag
          context_enabled = determine_context_enabled(options)

          # Determine enhance flag
          enhance_enabled = determine_enhance_enabled(options)

          # Resolve task prompt path (handles both explicit --task and auto-detection)
          task_prompt_path = resolve_task_prompt_path(options[:task])

          # Process prompt
          result = Organisms::PromptProcessor.call(
            input_path: task_prompt_path,
            context: context_enabled,
            enhance: enhance_enabled,
            model: options[:model],
            system_prompt: options[:system_prompt]
          )

          unless result[:success]
            return exit_failure(result[:error])
          end

          # Handle output
          output_mode = options[:output] || "-"

          if output_mode == "-"
            # Output to stdout
            puts result[:content]
            return exit_success
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
              return exit_success
            rescue StandardError => e
              return exit_failure("Failed to write output file: #{e.message}")
            end
          end
        rescue Ace::Prompt::Error => e
          exit_failure(e.message)
        end

        private

        # Determine if context loading should be enabled
        # Priority: CLI flags > config file
        def determine_context_enabled(options)
          # Explicit --no-context disables
          return false if options[:no_context]

          # Explicit --context enables
          return true if options[:context]

          # Fall back to config
          Ace::Prompt.config.dig("context", "enabled") || false
        end

        # Determine if enhancement should be enabled
        # Priority: CLI flags > config file
        def determine_enhance_enabled(options)
          # Explicit --no-enhance disables
          return false if options[:no_enhance]

          # Explicit --enhance enables
          return true if options[:enhance]

          # Fall back to config
          Ace::Prompt.config.dig("enhance", "enabled") || false
        end

        # Resolve task prompt path from explicit task ID or auto-detection
        # This is the global task resolution used by ALL commands
        #
        # @param task_option [String, nil] Explicit task ID from --task flag
        # @return [String, nil] Path to the-prompt.md in task's prompts directory, or nil for default
        def resolve_task_prompt_path(task_option)
          require_relative "../atoms/task_path_resolver"
          require "ace/git"

          # If task ID is explicitly provided, use it
          if task_option
            result = Atoms::TaskPathResolver.resolve(task_option)
            raise Error, result[:error] unless result[:found]

            prompts_dir = result[:prompts_path]
            FileUtils.mkdir_p(prompts_dir)
            return File.join(prompts_dir, "the-prompt.md")
          end

          # Check if auto-detection is enabled in config
          return nil unless Ace::Prompt.config.dig("task", "detection")

          # Try to extract task ID from current branch (via ace-git for I/O)
          branch = Ace::Git::Molecules::BranchReader.current_branch
          return nil unless branch

          extracted_task_id = Atoms::TaskPathResolver.extract_from_branch(branch)
          return nil unless extracted_task_id

          # Resolve task path
          result = Atoms::TaskPathResolver.resolve(extracted_task_id)
          return nil unless result[:found]

          prompts_dir = result[:prompts_path]
          FileUtils.mkdir_p(prompts_dir)
          File.join(prompts_dir, "the-prompt.md")
        rescue StandardError => e
          # For explicit --task, re-raise the error
          raise if task_option

          # For auto-detection, notify user and continue without task context
          warn "[ace-prompt] Task auto-detection skipped: #{e.message}"
          nil
        end
      end
    end
  end
end
