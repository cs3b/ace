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

          # Archive original ONLY if not enhancing or if first enhancement
          if !should_enhance || should_archive_for_enhancement?(prompt_path)
            archive_original(prompt_path)
          end

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

        def should_archive_for_enhancement?(prompt_path)
          # Check if this is the first enhancement or if we need a new base
          archive_dir = File.join(File.dirname(prompt_path), @config["archive_subdir"])

          # Get all archives
          all_archives = Dir.glob(File.join(archive_dir, "*.md")).sort

          # If no archives exist, this is first time - archive it
          return true if all_archives.empty?

          # Find latest base (without _e suffix)
          base_archives = all_archives.reject { |path| path.match?(/_e\d+\.md$/) }

          # If no base exists, we need to create one
          return true if base_archives.empty?

          # Check if enhancement chain exists for the latest base
          latest_base = base_archives.last
          require_relative "../molecules/enhancement_tracker"
          iteration = Molecules::EnhancementTracker.next_iteration(latest_base, archive_dir)

          # If iteration is 1, no enhancements exist yet, so archive
          # If iteration > 1, enhancement chain exists, don't re-archive
          iteration == 1
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
          # Read original prompt data to preserve frontmatter
          prompt_data = Molecules::PromptReader.read(prompt_path)

          # Enhance only the content part (not frontmatter)
          enhancer = PromptEnhancer.new(@config)
          enhanced_content_only = enhancer.enhance(prompt_data[:content])

          # Reconstruct full content with original frontmatter + enhanced content
          full_enhanced_content = if prompt_data[:frontmatter] && !prompt_data[:frontmatter].empty?
            require 'yaml'
            frontmatter_yaml = YAML.dump(prompt_data[:frontmatter])
            "---\n#{frontmatter_yaml}---\n\n#{enhanced_content_only}"
          else
            enhanced_content_only
          end

          # Archive the enhanced version with tracking
          archive_enhanced_version(full_enhanced_content, prompt_path)

          # Write enhanced content back to the-prompt.md (WITH frontmatter preserved)
          File.write(prompt_path, full_enhanced_content)

          full_enhanced_content
        end

        def archive_enhanced_version(enhanced_content, prompt_path)
          archive_dir = File.join(File.dirname(prompt_path), @config["archive_subdir"])

          # Find the base/original archived file (most recent without _e suffix)
          all_archives = Dir.glob(File.join(archive_dir, "*.md")).sort
          base_archive = all_archives.reverse.find { |path| !path.match?(/_e\d+\.md$/) }

          return unless base_archive  # No base archive yet, skip enhancement tracking

          # Determine next iteration using EnhancementTracker
          require_relative "../molecules/enhancement_tracker"
          iteration = Molecules::EnhancementTracker.next_iteration(base_archive, archive_dir)

          # Generate enhancement frontmatter
          frontmatter = Molecules::EnhancementTracker.generate_frontmatter(
            base_archive,
            iteration,
            context_used: false  # TODO: track if context was used
          )

          # Add frontmatter to enhanced content
          content_with_frontmatter = Molecules::EnhancementTracker.add_frontmatter(
            enhanced_content,
            frontmatter
          )

          # Create temporary file with enhanced content + frontmatter
          temp_file = File.join(archive_dir, ".tmp_enhanced.md")
          File.write(temp_file, content_with_frontmatter)

          # Archive with current timestamp and enhancement iteration suffix
          require_relative "../atoms/timestamp_generator"
          current_timestamp = Atoms::TimestampGenerator.generate
          enhanced_filename = "#{current_timestamp}_e#{format('%03d', iteration)}.md"
          enhanced_archive_path = File.join(archive_dir, enhanced_filename)

          FileUtils.cp(temp_file, enhanced_archive_path)
          FileUtils.rm(temp_file)

          # Update symlink to point to enhanced version
          symlink_path = File.join(File.dirname(prompt_path), "_previous.md")
          Molecules::PromptArchiver.update_symlink(enhanced_archive_path, symlink_path)

          enhanced_archive_path
        rescue => e
          warn "Warning: Failed to archive enhanced version: #{e.message}"
          nil
        end
      end
    end
  end
end
