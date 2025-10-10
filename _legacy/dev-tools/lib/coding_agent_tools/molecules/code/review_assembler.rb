# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    module Code
      # Assembles the final review prompt from enhanced system prompt and subject
      class ReviewAssembler
        SEPARATOR = "\n---\n\n"

        # Assemble the final prompt for LLM review
        def assemble(enhanced_prompt, subject_content)
          # Validate inputs
          raise ArgumentError, "Enhanced prompt cannot be nil" if enhanced_prompt.nil?
          raise ArgumentError, "Subject content cannot be nil" if subject_content.nil?

          # Build the final prompt structure
          final_prompt = []

          # Add the enhanced system prompt (with context)
          final_prompt << enhanced_prompt.strip

          # Add separator
          final_prompt << SEPARATOR.strip

          # Add subject header and content
          final_prompt << "# Content for Review\n"
          final_prompt << subject_content.strip

          # Join everything with proper spacing
          final_prompt.join("\n\n")
        end

        # Disassemble a prompt into its components
        def disassemble(full_prompt)
          return {enhanced_prompt: nil, subject: nil} unless full_prompt

          # Split on the separator
          parts = full_prompt.split(SEPARATOR, 2)

          if parts.length == 2
            # Extract subject content (remove the "# Content for Review" header if present)
            subject = parts[1].sub(/^# Content for Review\n+/, "")

            {
              enhanced_prompt: parts[0].strip,
              subject: subject.strip
            }
          else
            # No clear separator, treat entire content as enhanced prompt
            {
              enhanced_prompt: full_prompt.strip,
              subject: nil
            }
          end
        end

        # Validate that a prompt is properly assembled
        def valid_assembly?(full_prompt)
          return false unless full_prompt

          # Check for required components
          has_separator = full_prompt.include?(SEPARATOR.strip)
          has_content_header = full_prompt.include?("# Content for Review")

          has_separator && has_content_header
        end

        # Get statistics about the assembled prompt
        def prompt_stats(full_prompt)
          return nil unless full_prompt

          components = disassemble(full_prompt)

          {
            total_length: full_prompt.length,
            total_lines: full_prompt.lines.count,
            enhanced_prompt_length: components[:enhanced_prompt]&.length || 0,
            enhanced_prompt_lines: components[:enhanced_prompt]&.lines&.count || 0,
            subject_length: components[:subject]&.length || 0,
            subject_lines: components[:subject]&.lines&.count || 0,
            has_context: components[:enhanced_prompt]&.include?("## Project Context") || false
          }
        end
      end
    end
  end
end
