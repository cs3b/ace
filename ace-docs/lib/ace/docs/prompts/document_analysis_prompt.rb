# frozen_string_literal: true

require "open3"

module Ace
  module Docs
    module Prompts
      # Builds prompts for analyzing changes relevant to a specific document
      class DocumentAnalysisPrompt
        # Build prompts for analyzing changes for a specific document
        # @param document [Document] The document to analyze changes for
        # @param diff [String] The filtered git diff (already filtered by subject.diff.filters)
        # @param since [String] Time period for the diff
        # @return [Hash] Hash with :system and :user prompts
        def self.build(document, diff, since: nil)
          {
            system: load_system_prompt,
            user: build_user_prompt(document, diff, since)
          }
        end

        # Load system prompt via ace-nav protocol
        # @return [String] System prompt content
        def self.load_system_prompt
          stdout, stderr, status = Open3.capture3("ace-nav", "prompt://document-analysis.system", "--content")

          if status.success?
            stdout.strip
          else
            # Fallback to embedded prompt if ace-nav fails
            fallback_system_prompt
          end
        rescue StandardError
          fallback_system_prompt
        end

        # Build user prompt with document context and diff
        # @param document [Document] The document to analyze
        # @param diff [String] The git diff content
        # @param since [String] Time period
        # @return [String] User prompt
        def self.build_user_prompt(document, diff, since)
          # Extract document metadata
          doc_type = document.doc_type || "document"
          purpose = document.purpose || "(not specified)"
          doc_path = document.respond_to?(:relative_path) ? document.relative_path : document.path

          # Extract context information
          context_keywords = document.context_keywords
          context_preset = document.context_preset

          # Extract subject filters (to show what was filtered)
          subject_filters = document.subject_diff_filters

          # Build context description
          context_desc = build_context_description(context_keywords, context_preset)

          # Build filters description
          filters_desc = build_filters_description(subject_filters)

          # Build time description
          time_desc = since ? "since #{since}" : "recent changes"

          <<~PROMPT
            ## Document Information

            **Path**: #{doc_path}
            **Type**: #{doc_type}
            **Purpose**: #{purpose}

            #{context_desc}

            ## Changes to Analyze

            The following git diff shows changes #{time_desc}.

            #{filters_desc}

            ```diff
            #{diff}
            ```
          PROMPT
        end

        # Fallback system prompt if ace-nav unavailable
        # @return [String] Embedded system prompt
        def self.fallback_system_prompt
          <<~PROMPT
            You are analyzing code changes to determine what needs to be updated in documentation.

            Provide a markdown report with:
            - Summary (2-3 sentences)
            - Changes Detected (organized by HIGH/MEDIUM/LOW priority)
            - Recommended Updates (specific sections with reasoning)
            - Additional Notes

            Focus on relevance to the document's purpose and be specific about what needs updating and why.
          PROMPT
        end

        private_class_method def self.build_context_description(keywords, preset)
          parts = []

          if keywords && !keywords.empty?
            parts << "**Context Keywords**: #{keywords.join(', ')}"
          end

          if preset && !preset.empty?
            parts << "**Context Preset**: #{preset}"
          end

          return "" if parts.empty?

          "\n## Document Context\n\n#{parts.join("\n")}\n"
        end

        private_class_method def self.build_filters_description(filters)
          return "" if filters.nil? || filters.empty?

          "\n**Note**: This diff has been filtered to show only changes in:\n" +
          filters.map { |f| "- `#{f}`" }.join("\n") + "\n"
        end
      end
    end
  end
end
