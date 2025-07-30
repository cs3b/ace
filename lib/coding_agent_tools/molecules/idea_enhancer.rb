# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    # IdeaEnhancer handles the enhancement of raw ideas using templates and context
    # This is a molecule - it provides behavior-oriented idea enhancement functionality
    class IdeaEnhancer
      def initialize
        # This molecule focuses on template and enhancement logic
        # LLM interaction is handled by LLMClient molecule
      end

      # Validate idea content before enhancement
      # @param idea_content [String] Raw idea text
      # @return [Hash] Validation result
      def validate_idea_content(idea_content)
        return {valid: false, error: "Idea content cannot be nil"} if idea_content.nil?
        
        cleaned = idea_content.strip
        return {valid: false, error: "Idea content cannot be empty"} if cleaned.empty?
        return {valid: false, error: "Idea content too short (minimum 5 characters)"} if cleaned.length < 5

        {valid: true, content: cleaned}
      end

      # Extract title from raw idea content
      # @param idea_content [String] Raw idea text
      # @return [String] Generated title
      def extract_title(idea_content)
        # Take first sentence or first line, clean it up
        first_line = idea_content.strip.lines.first&.strip || ""
        
        # Remove common prefixes
        cleaned = first_line.gsub(/^(idea:|thought:|suggestion:)\s*/i, "")
        
        # Truncate at reasonable length
        if cleaned.length > 80
          # Try to break at word boundary
          truncated = cleaned[0, 77]
          if truncated.include?(" ")
            truncated = truncated.rpartition(" ").first
          end
          truncated + "..."
        else
          cleaned
        end
      end

      # Generate structured questions based on idea content
      # @param idea_content [String] Raw idea text
      # @param project_context [String, nil] Project context for relevant questions
      # @return [Array<String>] Generated questions
      def generate_questions(idea_content, project_context = nil)
        questions = []
        
        # Basic validation questions
        questions << "What specific problem does this solve?"
        questions << "Who would benefit from this implementation?"
        questions << "What are the success criteria?"

        # Technical questions based on common patterns
        if idea_content.downcase.include?("feature") || idea_content.downcase.include?("add")
          questions << "How does this integrate with existing components?"
          questions << "What are the technical dependencies?"
        end

        if idea_content.downcase.include?("improve") || idea_content.downcase.include?("better")
          questions << "What metrics will measure the improvement?"
          questions << "What are the current pain points?"
        end

        if idea_content.downcase.include?("tool") || idea_context.downcase.include?("command")
          questions << "What CLI interface would be most intuitive?"
          questions << "How should this integrate with existing tools?"
        end

        questions.take(6) # Limit to reasonable number
      end

      private

      def idea_context
        @idea_context ||= ""
      end
    end
  end
end