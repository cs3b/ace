# frozen_string_literal: true

require_relative "../organisms/document_registry"
require_relative "../organisms/validator"
require "colorize"

module Ace
  module Docs
    module Commands
      # Command for validating documents
      class ValidateCommand
        def initialize(options = {})
          @options = options
          @registry = Organisms::DocumentRegistry.new
        end

        # Execute the validate command
        # @return [Integer] Exit code (0 for success, 1 for validation errors)
        def execute(pattern = nil)
          documents = select_documents(pattern)

          if documents.empty?
            puts "No documents to validate."
            return 0
          end

          validator = Organisms::Validator.new(@registry)
          has_errors = false

          documents.each do |doc|
            puts "Validating: #{doc.display_name}"
            results = validate_document(validator, doc)

            if results[:valid]
              puts "  ✓ Valid".green
            else
              puts "  ✗ Invalid".red
              has_errors = true
              display_errors(results[:errors])
            end

            display_warnings(results[:warnings]) if results[:warnings]&.any?
          end

          has_errors ? 1 : 0
        rescue StandardError => e
          puts "Error validating documents: #{e.message}"
          puts e.backtrace.join("\n") if ENV["DEBUG"]
          1
        end

        private

        def select_documents(pattern)
          if pattern
            if File.exist?(pattern)
              doc = @registry.find_by_path(pattern)
              doc ? [doc] : []
            else
              # Treat as glob pattern
              @registry.all.select { |d| File.fnmatch(pattern, d.path) }
            end
          else
            @registry.all
          end
        end

        def validate_document(validator, doc)
          # Determine validation types
          run_syntax = @options[:syntax] || @options[:all]
          run_semantic = @options[:semantic] || @options[:all]
          run_all = !@options[:syntax] && !@options[:semantic]

          # If syntax validation is requested and ace-lint is configured, use it
          if (run_syntax || run_all) && Ace::Docs.config["validation_enabled"]
            validate_with_ace_lint(doc)
          else
            # Fall back to internal validation
            validator.validate_document(
              doc,
              syntax: run_syntax || run_all,
              semantic: run_semantic || run_all
            )
          end
        end

        def validate_with_ace_lint(doc)
          ace_lint_path = Ace::Docs.config["ace_lint_path"] || "ace-lint"

          # Check if ace-lint is available
          unless system("which #{ace_lint_path} > /dev/null 2>&1")
            # Fall back to internal validation
            return {
              valid: false,
              errors: ["ace-lint not found. Install with: gem install ace-lint"],
              warnings: []
            }
          end

          # Run ace-lint on the document
          require "open3"
          stdout, stderr, status = Open3.capture3(ace_lint_path, doc.path)

          if status.success?
            { valid: true, errors: [], warnings: parse_lint_warnings(stdout) }
          else
            { valid: false, errors: parse_lint_errors(stdout, stderr), warnings: [] }
          end
        rescue StandardError => e
          {
            valid: false,
            errors: ["Lint validation failed: #{e.message}"],
            warnings: []
          }
        end

        def parse_lint_errors(stdout, stderr)
          errors = []

          # Parse stdout for errors
          stdout.lines.each do |line|
            if line.include?("error") || line.include?("ERROR")
              errors << line.strip
            end
          end

          # Add stderr if present
          errors << stderr.strip unless stderr.strip.empty?

          errors.empty? ? ["Validation failed"] : errors
        end

        def parse_lint_warnings(stdout)
          warnings = []

          stdout.lines.each do |line|
            if line.include?("warning") || line.include?("WARNING")
              warnings << line.strip
            end
          end

          warnings
        end

        def display_errors(errors)
          errors.each do |error|
            puts "    - #{error}".red
          end
        end

        def display_warnings(warnings)
          warnings.each do |warning|
            puts "    ⚠ #{warning}".yellow
          end
        end
      end
    end
  end
end