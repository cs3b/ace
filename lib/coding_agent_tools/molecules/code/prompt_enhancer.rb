# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    module Code
      # Enhances system prompts by appending context information
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
      end
    end
  end
end