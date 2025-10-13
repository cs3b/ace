# frozen_string_literal: true

module Ace
  module Docs
    module Organisms
      # Validates documents against their declared rules
      class Validator
        def initialize(registry)
          @registry = registry
        end

        # Validate a document against rules
        # @param document [Document] Document to validate
        # @param syntax [Boolean] Run syntax validation
        # @param semantic [Boolean] Run semantic validation
        # @return [Hash] Validation results
        def validate_document(document, syntax: true, semantic: false)
          errors = []
          warnings = []

          # Check frontmatter validity
          if !document.managed?
            errors << "Missing required frontmatter fields"
          end

          # Check max lines rule
          if document.max_lines
            line_count = document.content.lines.count
            if line_count > document.max_lines
              errors << "Exceeds max lines: #{line_count}/#{document.max_lines}"
            end
          end

          # Check required sections
          if document.required_sections.any?
            missing_sections = check_sections(document)
            if missing_sections.any?
              errors << "Missing required sections: #{missing_sections.join(', ')}"
            end
          end

          # Syntax validation (would delegate to external linters)
          if syntax
            syntax_results = validate_syntax(document)
            errors.concat(syntax_results[:errors])
            warnings.concat(syntax_results[:warnings])
          end

          # Semantic validation (would use LLM)
          if semantic
            semantic_results = validate_semantic(document)
            errors.concat(semantic_results[:errors])
            warnings.concat(semantic_results[:warnings])
          end

          {
            valid: errors.empty?,
            errors: errors,
            warnings: warnings
          }
        end

        private

        def check_sections(document)
          required = document.required_sections
          content = document.content.downcase

          missing = []
          required.each do |section|
            # Check for section as a header
            unless content.include?("# #{section.downcase}") ||
                   content.include?("## #{section.downcase}")
              missing << section
            end
          end

          missing
        end

        def validate_syntax(document)
          # TODO: Integrate with markdownlint or similar
          { errors: [], warnings: [] }
        end

        def validate_semantic(document)
          # TODO: Integrate with ace-llm-query
          { errors: [], warnings: [] }
        end
      end
    end
  end
end