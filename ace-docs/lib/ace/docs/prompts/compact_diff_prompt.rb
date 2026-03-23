# frozen_string_literal: true

module Ace
  module Docs
    module Prompts
      # Builds prompts for LLM diff compaction
      class CompactDiffPrompt
        # Build a prompt for compacting a diff
        # @param diff [String] The git diff to compact
        # @param documents [Array<Document>] Documents being analyzed
        # @return [String] Complete prompt for LLM
        def self.build(diff, documents = [])
          document_list = format_document_list(documents)

          <<~PROMPT
            # Task: Compact Git Diff for Documentation Updates

            You are analyzing code changes to help update documentation. Your task is to compact the following git diff by removing noise while preserving all relevant details that might affect documentation.

            ## Documents Being Updated
            #{document_list}

            ## Instructions

            1. **REMOVE** (noise that doesn't affect documentation):
               - Test file changes (test/, spec/, *_test.rb, *.test.*)
               - Formatting-only changes (whitespace, indentation)
               - Comment-only changes that don't alter functionality
               - Version bumps in lock files (Gemfile.lock, package-lock.json)
               - Generated files and build artifacts
               - Minor refactors that don't change behavior

            2. **KEEP** (relevant changes that affect documentation):
               - New features, classes, methods, or commands
               - Changed interfaces, parameters, or return values
               - New or modified configuration options
               - Architecture or structural changes
               - Behavioral changes
               - New dependencies or tools
               - Error handling changes
               - Performance improvements worth documenting
               - Deprecations or removals

            3. **ORGANIZE** the output by impact level:
               - HIGH: New features, removed features, breaking changes
               - MEDIUM: Interface changes, new options, behavioral changes
               - LOW: Performance improvements, minor enhancements

            ## Output Format

            Provide a markdown report with:
            - Summary section with key changes
            - Sections organized by impact (HIGH/MEDIUM/LOW)
            - For each change, include:
              * Component/gem name
              * Brief description
              * Relevant files
              * Which documents might need updates

            ## Git Diff to Analyze

            ```diff
            #{diff}
            ```

            ## Response

            Please provide the compacted analysis in markdown format.
          PROMPT
        end

        # Build a prompt for analyzing changes without documents
        # @param diff [String] The git diff to analyze
        # @param since [String] Time period for the diff
        # @return [String] Complete prompt for LLM
        def self.build_general(diff, since: "recent changes")
          <<~PROMPT
            # Task: Analyze and Compact Git Diff

            Analyze the following git diff from #{since} and provide a compacted summary suitable for documentation updates.

            ## Instructions

            1. Remove noise (tests, formatting, lock files)
            2. Focus on changes that affect documentation
            3. Organize by impact level (HIGH/MEDIUM/LOW)
            4. Provide actionable insights for documentation updates

            ## Git Diff

            ```diff
            #{diff}
            ```

            ## Response

            Provide a structured markdown analysis with:
            - Executive summary
            - Significant changes by impact level
            - Files and components affected
            - Suggested documentation updates
          PROMPT
        end

        private_class_method def self.format_document_list(documents)
          return "No specific documents targeted" if documents.empty?

          list = documents.map do |doc|
            path = doc.respond_to?(:relative_path) ? doc.relative_path : doc.path
            type = doc.respond_to?(:doc_type) ? " (#{doc.doc_type})" : ""
            "- #{path}#{type}"
          end

          list.join("\n")
        end
      end
    end
  end
end
