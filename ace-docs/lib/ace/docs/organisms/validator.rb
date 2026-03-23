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
              errors << "Missing required sections: #{missing_sections.join(", ")}"
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
          {errors: [], warnings: []}
        end

        def validate_semantic(document)
          # Build semantic validation prompt
          keywords = document.context_keywords.any? ? document.context_keywords.join(", ") : "(none specified)"

          prompt = <<~PROMPT
            Validate this documentation for semantic accuracy and relevance.

            Document Type: #{document.doc_type}
            Purpose: #{document.purpose}
            Keywords: #{keywords}

            Content:
            #{document.content}

            Check for:
            - Content matches stated purpose
            - Information is accurate and up-to-date
            - No contradictions or inconsistencies
            - Appropriate depth for document type

            Respond with:
            VALID or INVALID on first line
            Then list any issues as bullet points starting with "-"
          PROMPT

          # Call LLM using Ruby API
          begin
            response = call_llm_for_validation(prompt)
            stdout = response[:text]
          rescue => e
            # Handle all errors (including when Ace::LLM is not loaded)
            error_msg = if e.message.include?("not found") || e.message.include?("No model specified") || e.message.include?("uninitialized constant")
              "Semantic validation unavailable (ace-llm configuration issue). Check ace-llm setup."
            else
              "Semantic validation error: #{e.message}"
            end
            return {errors: [error_msg], warnings: []}
          end

          # Parse LLM response
          errors = []
          warnings = []

          if stdout.match?(/INVALID/i)
            # Extract issues from response
            # Skip the first line (VALID/INVALID) and collect issue lines
            lines = stdout.strip.split("\n")
            lines.each_with_index do |line, idx|
              next if idx == 0 # Skip VALID/INVALID line
              next if line.strip.empty?

              if line.start_with?("-")
                errors << line.sub(/^-\s*/, "").strip
              end
            end

            # If no issues were extracted but marked INVALID, add generic error
            if errors.empty?
              errors << "Content validation failed - semantic issues detected"
            end
          end

          {errors: errors, warnings: warnings}
        end

        # Call LLM for validation (protected for testing)
        # @param prompt [String] The validation prompt
        # @return [Hash] Response with :text key
        def call_llm_for_validation(prompt)
          Ace::LLM::QueryInterface.query(
            "gflash",
            prompt,
            temperature: 0.3
          )
        end
      end
    end
  end
end
