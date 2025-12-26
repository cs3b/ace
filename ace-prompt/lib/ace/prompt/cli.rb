# frozen_string_literal: true

require "fileutils"
require "thor"
require_relative "organisms/prompt_processor"
require_relative "organisms/prompt_initializer"

module Ace
  module Prompt
    # Thor CLI for ace-prompt
    class CLI < Thor
      def self.exit_on_failure?
        false
      end

      desc "process", "Read prompt, archive it, and output to stdout or file (default command)"
      long_desc <<~DESC
        Read prompt file, archive it with timestamp, update symlink, and output content.

        By default:
        - Reads from .cache/ace-prompt/prompts/the-prompt.md
        - Archives to .cache/ace-prompt/prompts/archive/YYYYMMDD-HHMMSS.md
        - Updates _previous.md symlink
        - Outputs to stdout

        EXAMPLES:

          # Basic usage (stdout)
          $ ace-prompt

          # Output to file
          $ ace-prompt --output /tmp/prompt.md

          # Explicit stdout
          $ ace-prompt --output -

          # Load context from frontmatter
          $ ace-prompt --context

          # Short flag for context
          $ ace-prompt -c

          # Explicitly disable context
          $ ace-prompt --no-context

        OUTPUT:

          By default, content is printed to stdout.
          Use --output to save to a file instead.
      DESC
      option :output, type: :string, aliases: "-o",
                      desc: "Write content to file instead of stdout (use '-' for explicit stdout)"
      option :context, type: :boolean, aliases: "-c",
                       desc: "Load context via ace-context (from frontmatter)"
      option :no_context, type: :boolean,
                          desc: "Explicitly disable context loading (override config)"
      option :enhance, type: :boolean, aliases: "-e",
                       desc: "Enhance prompt via LLM"
      option :no_enhance, type: :boolean,
                          desc: "Explicitly disable LLM enhancement (override config)"
      option :model, type: :string,
                     desc: "LLM model (default: #{Ace::Prompt::DEFAULT_MODEL})"
      option :system_prompt, type: :string,
                             desc: "Custom system prompt path"
      option :task, type: :string,
                    desc: "Use task's prompts directory (e.g., '117' or '121.01')"
      def process
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
          warn "Error: #{result[:error]}"
          return 1
        end

        # Handle output
        output_mode = options[:output] || "-"

        if output_mode == "-"
          # Output to stdout
          puts result[:content]
          return 0
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
            return 0
          rescue StandardError => e
            warn "Error: Failed to write output file: #{e.message}"
            return 1
          end
        end
      rescue Ace::Prompt::Error => e
        warn "Error: #{e.message}"
        return 1
      end

      default_task :process

      desc "setup", "Initialize prompt workspace with template"
      long_desc <<~DESC
        Create prompt workspace and initialize with template.

        By default:
        - Creates {project_root}/.cache/ace-prompt/prompts/ directory
        - Archives existing the-prompt.md if present
        - Copies template to the-prompt.md
        - Uses tmpl://the-prompt-base template

        EXAMPLES:

          # Basic setup (archives existing prompt)
          $ ace-prompt setup

          # Custom template (short form)
          $ ace-prompt setup --template bug

          # Custom template (full URI)
          $ ace-prompt setup --template tmpl://custom/template

          # Skip archiving existing prompt
          $ ace-prompt setup --no-archive

          # Force overwrite (alias for --no-archive)
          $ ace-prompt setup --force

        BEHAVIOR:

          - Always archives existing prompt unless --no-archive or --force
          - Creates directory structure if needed
          - Resolves template via ace-nav tmpl:// protocol
          - Short form templates expand to tmpl://the-prompt-{name}
      DESC
      option :template, type: :string, aliases: "-t",
                        desc: "Template name or URI (e.g., 'bug' or 'tmpl://the-prompt-bug')"
      option :no_archive, type: :boolean,
                          desc: "Skip archiving existing prompt file"
      option :force, type: :boolean, aliases: "-f",
                     desc: "Skip archiving (alias for --no-archive)"
      option :task, type: :string,
                    desc: "Use task's prompts directory (e.g., '117' or '121.01')"
      def setup
        template_uri = options[:template] || Organisms::PromptInitializer::DEFAULT_TEMPLATE_URI
        force = options[:force] || options[:no_archive] || false

        # Resolve task prompt path (handles both explicit --task and auto-detection)
        task_prompt_path = resolve_task_prompt_path(options[:task])
        # Extract target directory from resolved path
        target_dir = task_prompt_path ? File.dirname(task_prompt_path) : nil

        result = Organisms::PromptInitializer.setup(
          template_uri: template_uri,
          force: force,
          target_dir: target_dir
        )

        unless result[:success]
          warn "Error: Setup failed: #{result[:error]}"
          return 1
        end

        $stdout.puts "Prompt initialized:"
        $stdout.puts "  Path: #{result[:path]}"
        if result[:archive_path]
          $stdout.puts "  Archive: #{result[:archive_path]}"
        end
        0
      rescue StandardError => e
        warn "Error: Setup failed: #{e.message}"
        1
      end

      desc "version", "Show version"
      def version
        puts Ace::Prompt::VERSION
      end

      map %w[-v --version] => :version

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
        require_relative "atoms/task_path_resolver"
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
