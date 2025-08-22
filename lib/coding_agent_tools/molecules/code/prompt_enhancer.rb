# frozen_string_literal: true

require "yaml"
require_relative "../../atoms/project_root_detector"

module CodingAgentTools
  module Molecules
    module Code
      # Enhances system prompts by appending context information and composing modular prompts
      class PromptEnhancer
        DEFAULT_SYSTEM_PROMPT = <<~PROMPT
          # Code Review

          You are a senior software engineer conducting a thorough code review. Your goal is to provide constructive feedback that improves code quality, maintainability, and alignment with project standards.

          ## Review Guidelines

          1. **Be Specific**: Reference specific lines, files, and code blocks
          2. **Be Constructive**: Provide actionable suggestions with examples
          3. **Be Balanced**: Acknowledge good practices alongside areas for improvement
          4. **Be Thorough**: Consider functionality, performance, security, and maintainability

          ## Output Format

          Structure your review with clear sections:
          - Summary of changes
          - Strengths and good practices
          - Issues and concerns (prioritized by severity)
          - Suggestions for improvement
          - Questions or areas needing clarification
        PROMPT

        # Enhance a system prompt by appending context information
        def enhance_prompt(system_prompt, context_content)
          # Use default prompt if none provided
          base_prompt = system_prompt || DEFAULT_SYSTEM_PROMPT

          # Return base prompt if no context
          return base_prompt if context_content.nil? || context_content.empty?

          # Append context to the system prompt
          enhanced = base_prompt.dup

          # Add separator if prompt doesn't end with newlines
          enhanced << "\n\n" unless enhanced.end_with?("\n\n")

          # Add context section
          enhanced << "## Project Context\n\n"
          enhanced << "The following project-specific information provides background context for this review:\n\n"
          enhanced << context_content

          # Ensure proper ending
          enhanced << "\n" unless enhanced.end_with?("\n")

          enhanced
        end

        # Extract just the context portion from an enhanced prompt
        def extract_context(enhanced_prompt)
          return nil unless enhanced_prompt

          # Look for the context section
          context_match = enhanced_prompt.match(/## Project Context\n\n(.+)\z/m)
          context_match ? context_match[1] : nil
        end

        # Check if a prompt has already been enhanced
        def enhanced?(prompt)
          return false unless prompt
          prompt.include?("## Project Context")
        end

        # Get the default system prompt
        def default_prompt
          DEFAULT_SYSTEM_PROMPT
        end

        # Compose a prompt from modular components
        # @param composition_config [Hash] Configuration for prompt composition
        #   - base: Base module path or name
        #   - format: Format module (standard, detailed, compact)
        #   - focus: Array of focus module paths
        #   - guidelines: Array of guideline module paths
        # @return [String] The composed prompt
        def compose_prompt(composition_config)
          return DEFAULT_SYSTEM_PROMPT if composition_config.nil? || composition_config.empty?

          modules_dir = find_modules_directory
          return DEFAULT_SYSTEM_PROMPT unless modules_dir

          composed_parts = []

          # Load base module
          if composition_config["base"]
            base_content = load_module(modules_dir, "base", composition_config["base"])
            composed_parts << base_content if base_content
          end

          # Load sections (always include if base is specified)
          if composition_config["base"]
            sections_content = load_module(modules_dir, "base", "sections")
            composed_parts << sections_content if sections_content
          end

          # Load format module
          if composition_config["format"]
            format_content = load_module(modules_dir, "format", composition_config["format"])
            composed_parts << format_content if format_content
          end

          # Load focus modules
          if composition_config["focus"]
            focus_modules = Array(composition_config["focus"])
            focus_modules.each do |focus_module|
              focus_content = load_focus_module(modules_dir, focus_module)
              composed_parts << focus_content if focus_content
            end
          end

          # Load guideline modules
          if composition_config["guidelines"]
            guideline_modules = Array(composition_config["guidelines"])
            guideline_modules.each do |guideline_module|
              guideline_content = load_module(modules_dir, "guidelines", guideline_module)
              composed_parts << guideline_content if guideline_content
            end
          end

          # Join all parts with proper spacing
          composed_parts.empty? ? DEFAULT_SYSTEM_PROMPT : composed_parts.join("\n\n")
        end

        # Cache for loaded modules (15-minute TTL)
        def module_cache
          @module_cache ||= {}
          @cache_timestamp ||= Time.now

          # Clear cache if older than 15 minutes
          if Time.now - @cache_timestamp > 900
            @module_cache = {}
            @cache_timestamp = Time.now
          end

          @module_cache
        end

        private

        def find_modules_directory
          project_root = CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
          return nil unless project_root

          modules_dir = File.join(project_root, "dev-handbook", "templates", "review-modules")
          File.directory?(modules_dir) ? modules_dir : nil
        end

        def load_module(modules_dir, category, module_name)
          # Support both simple names and paths
          if module_name.include?("/")
          end
          module_file = File.join(modules_dir, category, "#{module_name}.md")

          cache_key = module_file
          return module_cache[cache_key] if module_cache.key?(cache_key)

          if File.exist?(module_file)
            content = File.read(module_file).strip
            module_cache[cache_key] = content
            content
          end
        end

        def load_focus_module(modules_dir, focus_path)
          # Focus modules can be in subdirectories
          # e.g., "architecture/atom", "languages/ruby", "quality/security"
          module_file = File.join(modules_dir, "focus", "#{focus_path}.md")

          cache_key = module_file
          return module_cache[cache_key] if module_cache.key?(cache_key)

          if File.exist?(module_file)
            content = File.read(module_file).strip
            module_cache[cache_key] = content
            content
          end
        end
      end
    end
  end
end
