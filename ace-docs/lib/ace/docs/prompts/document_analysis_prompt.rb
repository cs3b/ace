# frozen_string_literal: true

require "open3"
require "yaml"

module Ace
  module Docs
    module Prompts
      # Builds prompts for analyzing changes relevant to a specific document
      class DocumentAnalysisPrompt
        # Build prompts for analyzing changes for a specific document
        # @param document [Document] The document to analyze changes for
        # @param diff [String] The filtered git diff (already filtered by subject.diff.filters)
        # @param since [String] Time period for the diff
        # @param cache_dir [String, nil] Optional cache directory (unused but kept for compatibility)
        # @return [Hash] Hash with :system, :user prompts, :diff_stats
        def self.build(document, diff, since: nil, cache_dir: nil)
          # Load base instructions
          base_instructions = load_user_prompt_template

          # Build document-specific sections to append
          diff_stats = calculate_diff_stats(diff)
          doc_section = build_document_section(document, since, diff_stats)
          diff_section = build_diff_section(diff, document)

          # Final prompt = base instructions + document metadata + diff
          final_user_prompt = [base_instructions, doc_section, diff_section].join("\n\n")

          {
            system: load_system_prompt,
            user: final_user_prompt,
            diff_stats: diff_stats
          }
        end

        # Load user prompt template via ace-nav protocol
        # @return [String] User prompt template content
        def self.load_user_prompt_template
          stdout, stderr, status = Open3.capture3("ace-nav", "prompt://document-analysis", "--content")

          if status.success?
            stdout.strip
          else
            # Fallback to reading file directly
            template_path = File.join(Ace::Docs.root, "handbook/prompts/document-analysis.md")
            File.exist?(template_path) ? File.read(template_path) : fallback_user_template
          end
        rescue StandardError
          fallback_user_template
        end

        # Fallback user template if ace-nav unavailable
        # @return [String] Minimal user template
        def self.fallback_user_template
          <<~TEMPLATE
            # Document Analysis

            ## Document Information
            **Path**: {document_path}
            **Type**: {document_type}
            **Purpose**: {document_purpose}

            ## Changes to Analyze
            {diff_content}
          TEMPLATE
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
        # @param context [String, nil] Optional embedded context from ace-context
        # @return [String] User prompt
        def self.build_user_prompt(document, diff, since, context: nil)
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

          # Build context section if provided
          context_section = if context && !context.strip.empty?
                              "\n## Context\n\n#{context}\n"
                            else
                              ""
                            end

          <<~PROMPT
            ## Document Information

            **Path**: #{doc_path}
            **Type**: #{doc_type}
            **Purpose**: #{purpose}

            #{context_desc}
            #{context_section}
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


        # Calculate diff statistics
        # @param diff [String] The git diff content
        # @return [Hash] Statistics with hunks_total, files_changed, insertions, deletions
        def self.calculate_diff_stats(diff)
          {
            hunks_total: diff.scan(/^@@ .+ @@/).size,
            files_changed: diff.scan(/^diff --git/).size,
            insertions: diff.scan(/^\+[^+]/).size,
            deletions: diff.scan(/^-[^-]/).size
          }
        end



        # Build document-specific section to append
        # @param document [Document] The document configuration (defines filters)
        # @param since [String] Time period for analysis
        # @param diff_stats [Hash] Diff statistics
        # @return [String] Document section content
        def self.build_document_section(document, since, diff_stats)
          filters = document.subject_diff_filters || []
          filters_list = filters.empty? ? "No filters (all changes)" : filters.map { |f| "- `#{f}`" }.join("\n")

          <<~SECTION
            ## Analysis Context

            **Analyzing changes**: since #{since || 'recent'}
            **Filters applied**:
            #{filters_list}

            ## Diff Statistics

            - Total hunks: #{diff_stats[:hunks_total]}
            - Files changed: #{diff_stats[:files_changed]}
            - Insertions: +#{diff_stats[:insertions]}
            - Deletions: -#{diff_stats[:deletions]}
          SECTION
        end

        # Build diff section to append
        # @param diff [String] The git diff content
        # @param document [Document] The document being analyzed
        # @return [String] Diff section content
        def self.build_diff_section(diff, document)
          filters = document.subject_diff_filters
          filters_note = if filters && !filters.empty?
                           "\n**Filtered to show only:**\n" + filters.map { |f| "- `#{f}`" }.join("\n") + "\n"
                         else
                           ""
                         end

          <<~SECTION
            ## Git Diff to Analyze
            #{filters_note}
            ```diff
            #{diff}
            ```
          SECTION
        end

        # Make helper methods accessible
        private_class_method :load_user_prompt_template
        private_class_method :fallback_user_template
        private_class_method :calculate_diff_stats
        private_class_method :build_document_section
        private_class_method :build_diff_section
      end
    end
  end
end
