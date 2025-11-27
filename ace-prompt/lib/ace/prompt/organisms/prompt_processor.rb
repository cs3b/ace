# frozen_string_literal: true

require_relative "../molecules/prompt_reader"
require_relative "../molecules/prompt_archiver"
require_relative "../molecules/context_loader"
require_relative "../molecules/config_loader"
require_relative "../molecules/enhancement_tracker"
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

          # Read prompt and capture original frontmatter immediately
          warn "[DEBUG] Reading prompt from: #{prompt_path}"

          # Read the raw file content first
          raw_content = File.read(prompt_path) if File.exist?(prompt_path)

          # Extract frontmatter immediately using our own method to avoid race conditions
          frontmatter, content = extract_frontmatter_safely(raw_content)
          warn "[DEBUG] Captured frontmatter: #{frontmatter.inspect}"

          # Create prompt_data with captured frontmatter
          prompt_data = {
            frontmatter: frontmatter,
            content: content,
            full_text: raw_content
          }

          warn "[DEBUG] Enhancement context in captured frontmatter: #{frontmatter.dig('enhancement', 'context')&.inspect || 'nil'}"

          # Determine processing flags
          should_load_context = should_load_context?(prompt_data, options)
          should_enhance = should_enhance?(options)

          # Always archive before processing (with appropriate suffix if enhanced)
          archive_original(prompt_path)

          # Process content using the captured full_text (not re-reading the file)
          content = prompt_data[:full_text]

          # Phase 1: Context loading (if needed)
          if should_load_context
            content = load_context(prompt_path)
          end

          # Phase 2: Enhancement (if needed)
          if should_enhance
            warn "[DEBUG] About to enhance with captured frontmatter: #{prompt_data[:frontmatter]&.dig('enhancement', 'context')&.inspect || 'nil'}"
            content = enhance_content(content, prompt_path, prompt_data[:frontmatter])
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

        def enhance_content(content, prompt_path, frontmatter)
          warn "[DEBUG] enhance_content called with passed frontmatter"
          warn "[DEBUG] passed frontmatter: #{frontmatter&.inspect || 'nil'}"
          warn "[DEBUG] enhancement.context in frontmatter: #{frontmatter&.dig('enhancement', 'context')&.inspect || 'nil'}"

          # Enhance only the content part (not frontmatter)
          # Pass frontmatter for context-based enhancement
          enhancer = PromptEnhancer.new(@config)
          enhanced_content_only = enhancer.enhance(
            content,
            frontmatter: frontmatter
          )

          # Track enhancement using molecule (cleaner separation of concerns)
          tracking_result = Molecules::EnhancementTracker.track_enhancement(
            prompt_path,
            enhanced_content_only,
            frontmatter,
            @config["archive_subdir"]
          )

          # Format with frontmatter
          require 'yaml'
          frontmatter_yaml = YAML.dump(tracking_result[:frontmatter])
          full_enhanced_content = "#{frontmatter_yaml}---\n\n#{tracking_result[:content]}"

          # Write back to the-prompt.md (WITH enhancement tracking)
          File.write(prompt_path, full_enhanced_content)

          # Archive the enhanced version immediately with proper _eXXX suffix
          archive_dir = File.join(File.dirname(prompt_path), @config["archive_subdir"])
          archived_path = Molecules::PromptArchiver.archive(
            prompt_path,
            archive_dir,
            enhancement_iteration: tracking_result[:iteration]
          )

          # Update symlink to point to the enhanced version
          if archived_path
            symlink_path = File.join(File.dirname(prompt_path), "_previous.md")
            Molecules::PromptArchiver.update_symlink(archived_path, symlink_path)
          end

          full_enhanced_content
        end

        # Extract frontmatter safely using our own logic to avoid race conditions
        # @param raw_content [String] Raw file content
        # @return [Array] Tuple of [frontmatter_hash, content_without_frontmatter]
        def extract_frontmatter_safely(raw_content)
          # Handle nil content
          return [{}, ""] if raw_content.nil?

          # Look for the pattern: ---\n...content...\n---\n
          if raw_content.match?(/\A---\s*\n(.*?)\n---\s*\n(.*)\z/m)
            yaml_content = $1
            content_part = $2

            warn "[DEBUG] Raw YAML content: #{yaml_content.inspect}"
            warn "[DEBUG] Content part: #{content_part[0, 50].inspect}"

            begin
              # Parse YAML safely
              require "yaml"
              frontmatter = YAML.safe_load(yaml_content) || {}
              warn "[DEBUG] Successfully parsed frontmatter: #{frontmatter.inspect}"
              [frontmatter, content_part]
            rescue => e
              warn "[DEBUG] YAML parsing failed: #{e.message}, using empty frontmatter"
              [{}, raw_content]
            end
          else
            # No frontmatter found
            warn "[DEBUG] No frontmatter pattern found in content"
            [{}, raw_content]
          end
        end

        # Read a prompt file using the PromptReader molecule
        # @param path [String] Path to the prompt file
        # @return [String] The prompt content
        def read_prompt_file(path)
          prompt_data = Molecules::PromptReader.read(path)
          prompt_data[:full_text]
        end

        # Enhance prompt content using EnhancementSessionManager
        # @param content [String] Original content
        # @param frontmatter [Hash] Frontmatter for context
        # @return [String] Enhanced content or original on failure
        def enhance_prompt(content, frontmatter = {})
          manager = create_enhancement_session_manager(@config)
          manager.enhance_with_context(content, frontmatter)
        rescue => e
          warn "Enhancement failed: #{e.message}, using original content"
          content
        end

        # Create an EnhancementSessionManager instance
        # @param config [Hash] Configuration
        # @return [EnhancementSessionManager] Manager instance
        def create_enhancement_session_manager(config)
          EnhancementSessionManager.new(config)
        end
      end
    end
  end
end
