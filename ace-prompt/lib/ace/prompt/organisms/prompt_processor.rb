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

          # Determine processing flags
          should_load_context = should_load_context?(prompt_data, options)
          should_enhance = should_enhance?(options)

          # Always archive before processing (with appropriate suffix if enhanced)
          archive_original(prompt_path)

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
          # Read current content to check enhancement state
          prompt_data = Molecules::PromptReader.read(prompt_path)

          archive_dir = File.join(File.dirname(prompt_path), @config["archive_subdir"])

          # Determine archive filename based on enhancement state
          if prompt_data[:frontmatter]&.key?("enhancement_of")
            # Already enhanced - use _eXXX suffix
            iteration = prompt_data[:frontmatter]["enhancement_iteration"] || 1
            archived_path = Molecules::PromptArchiver.archive(
              prompt_path,
              archive_dir,
              enhancement_iteration: iteration
            )
          else
            # Original content - no suffix
            archived_path = Molecules::PromptArchiver.archive(prompt_path, archive_dir)
          end

          # Update symlink
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
          @config.dig("context", "enabled") || false
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
          # Read original to get current state
          prompt_data = Molecules::PromptReader.read(prompt_path)

          # Enhance only the content part (not frontmatter)
          enhancer = PromptEnhancer.new(@config)
          enhanced_content_only = enhancer.enhance(prompt_data[:content])

          # Determine enhancement tracking fields
          if prompt_data[:frontmatter]&.key?("enhancement_of")
            # Continuing enhancement chain
            base = prompt_data[:frontmatter]["enhancement_of"]
            iteration = (prompt_data[:frontmatter]["enhancement_iteration"] || 0) + 1
          else
            # First enhancement - find the archived original
            archive_dir = File.join(File.dirname(prompt_path), @config["archive_subdir"])
            archives = Dir.glob(File.join(archive_dir, "*.md")).sort
            latest = archives.last
            base = latest ? "archive/#{File.basename(latest)}" : "archive/unknown.md"
            iteration = 1
          end

          # Merge original context with enhancement tracking
          merged_frontmatter = (prompt_data[:frontmatter] || {}).merge({
            "enhancement_of" => base,
            "enhancement_iteration" => iteration,
            "context_used" => false  # TODO: detect if context was actually used
          })

          # Reconstruct with merged frontmatter
          require 'yaml'
          frontmatter_yaml = YAML.dump(merged_frontmatter)
          full_enhanced_content = "#{frontmatter_yaml}---\n\n#{enhanced_content_only}"

          # Write back to the-prompt.md (WITH enhancement tracking)
          File.write(prompt_path, full_enhanced_content)

          full_enhanced_content
        end
      end
    end
  end
end
