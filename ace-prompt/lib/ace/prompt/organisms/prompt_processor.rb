# frozen_string_literal: true

require_relative "../molecules/prompt_reader"
require_relative "../molecules/prompt_archiver"
require_relative "../molecules/context_loader"
require_relative "../molecules/config_loader"
require_relative "../atoms/task_path_resolver"
require_relative "prompt_enhancer"

module Ace
  module Prompt
    module Organisms
      # Main workflow orchestration for prompt processing
      class PromptProcessor
        def initialize(config = nil)
          @config = config || Molecules::ConfigLoader.load
        end

        # Process prompt with all phases
        # @param options [Hash] Processing options
        # @option options [Boolean] :ace_context Load context via ace-context
        # @option options [Boolean] :enhance Enhance via LLM
        # @option options [Boolean] :raw Skip enhancement
        # @option options [Boolean] :no_context Skip context
        # @option options [Integer, nil] :task Task ID for task-specific prompt
        # @return [String] Final processed content
        def process(options = {})
          # Determine prompt path
          prompt_path = determine_prompt_path(options[:task])

          # Read prompt
          prompt_data = Molecules::PromptReader.read(prompt_path)

          # Archive original
          archive_original(prompt_path)

          # Determine processing flags
          should_load_context = should_load_context?(prompt_data, options)
          should_enhance = should_enhance?(options)

          # Process content
          content = prompt_data[:full_text]

          # Phase 1: Context loading (if needed)
          if should_load_context
            content = load_context(prompt_path)
          end

          # Phase 2: Enhancement (if needed)
          if should_enhance
            content = enhance_content(content, prompt_path)
          end

          content
        end

        private

        def determine_prompt_path(task_id)
          if task_id
            task_prompts_dir = Atoms::TaskPathResolver.resolve(task_id)
            unless task_prompts_dir
              raise Ace::Prompt::Error, "Task #{task_id} not found"
            end
            File.join(task_prompts_dir, @config["default_file"])
          else
            File.join(@config["default_dir"], @config["default_file"])
          end
        end

        def archive_original(prompt_path)
          archive_dir = File.join(File.dirname(prompt_path), @config["archive_subdir"])
          archived_path = Molecules::PromptArchiver.archive(prompt_path, archive_dir)

          if archived_path
            symlink_path = File.join(File.dirname(prompt_path), "_previous.md")
            Molecules::PromptArchiver.update_symlink(archived_path, symlink_path)
          end

          archived_path
        end

        def should_load_context?(prompt_data, options)
          return false if options[:no_context]
          return true if options[:ace_context]

          # Check config default
          config_enabled = @config.dig("context", "enabled")
          return true if config_enabled

          # Check if frontmatter has context key with actual content
          context = prompt_data[:frontmatter]["context"]
          return false unless context.is_a?(Hash)

          # Only load context if there's actual content (non-empty arrays/values)
          has_files = context["files"]&.is_a?(Array) && !context["files"].empty?
          has_commands = context["commands"]&.is_a?(Array) && !context["commands"].empty?
          has_presets = context["presets"]&.is_a?(Array) && !context["presets"].empty?

          has_files || has_commands || has_presets
        end

        def should_enhance?(options)
          return false if options[:raw]
          return true if options[:enhance]

          # Check config default
          @config.dig("enhancement", "enabled") || false
        end

        def load_context(prompt_path)
          Molecules::ContextLoader.load(prompt_path)
        rescue => e
          warn "Warning: Context loading failed: #{e.message}"
          File.read(prompt_path)
        end

        def enhance_content(content, prompt_path)
          enhancer = PromptEnhancer.new(@config)
          enhanced = enhancer.enhance(content)

          # Archive enhanced version
          archive_dir = File.join(File.dirname(prompt_path), @config["archive_subdir"])

          # Find latest archived file to determine iteration
          archives = Dir.glob(File.join(archive_dir, "*.md")).sort
          if archives.any?
            latest = archives.last
            iteration = 1  # For now, simple increment

            # Archive with enhancement suffix
            Molecules::PromptArchiver.archive(
              prompt_path,
              archive_dir,
              enhancement_iteration: iteration
            )
          end

          enhanced
        end
      end
    end
  end
end
