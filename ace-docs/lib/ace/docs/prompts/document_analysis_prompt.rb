# frozen_string_literal: true

module Ace
  module Docs
    module Prompts
      # Builds prompts for analyzing changes relevant to a specific document
      class DocumentAnalysisPrompt
        # Build a prompt for analyzing changes for a specific document
        # @param document [Document] The document to analyze changes for
        # @param diff [String] The filtered git diff (already filtered by subject.diff.filters)
        # @param since [String] Time period for the diff
        # @return [String] Complete prompt for LLM
        def self.build(document, diff, since: nil)
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
            # Task: Analyze Code Changes for Documentation Update

            You are analyzing code changes to determine what needs to be updated in a specific documentation file.

            ## Document Information

            **Path**: #{doc_path}
            **Type**: #{doc_type}
            **Purpose**: #{purpose}

            #{context_desc}

            ## Subject (What Changed)

            The following git diff shows changes #{time_desc}.

            #{filters_desc}

            ```diff
            #{diff}
            ```

            ## Your Task

            Analyze these changes and provide a detailed report that answers:

            1. **What changed?**
               - List the key changes in the codebase
               - Focus on changes relevant to this document's purpose

            2. **What needs updating?**
               - Identify specific sections/content that should be updated
               - Explain why each update is needed
               - Consider the document type and purpose

            3. **Priority assessment:**
               - HIGH: Breaking changes, new features, removed functionality
               - MEDIUM: Behavioral changes, new options, interface modifications
               - LOW: Performance improvements, minor enhancements

            ## Output Format

            Provide a markdown report with these sections:

            ### Summary
            Brief overview of the changes (2-3 sentences)

            ### Changes Detected
            List changes organized by priority (HIGH/MEDIUM/LOW):
            - Component/file changed
            - What changed
            - Impact on documentation

            ### Recommended Updates
            For each section of the document that needs updating:
            - Section name
            - What to update
            - Why (what changed that necessitates this update)

            ### Additional Notes
            Any other observations or recommendations for this document

            ## Response

            Please provide the analysis in markdown format following the structure above.
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
