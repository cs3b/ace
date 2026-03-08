# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require "colorize"
require "open3"
require_relative "../../organisms/document_registry"
require_relative "../../organisms/validator"
require_relative "scope_options"

module Ace
  module Docs
    module CLI
      module Commands
        # dry-cli Command class for the validate command
        #
        # This command handles document validation.
        class Validate < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base
          include ScopeOptions

          # Exit codes
          EXIT_SUCCESS = 0
          EXIT_ERROR = 1

          desc <<~DESC.strip
            Validate documents against rules

            Validate documents against configured rules. Syntax validation uses linters,
            semantic validation uses LLM analysis.

            Configuration:
              Validation rules configured via ace-lint
              Global config:  ~/.ace/docs/config.yml
              Project config: .ace/docs/config.yml

            Output:
              Validation report printed to stdout
              Exit codes: 0 (pass), 1 (fail), 2 (error)
          DESC

          example [
            "                             # Validate all documents",
            "README.md                    # Validate specific file",
            "docs/**/*.md                 # Validate by pattern",
            "--syntax                     # Run syntax validation only",
            "--semantic                   # Run semantic validation only",
            "--all                        # Run all validation types",
            "--package ace-docs           # Scope validation to one package",
            "--glob 'ace-docs/**/*.md'    # Scope validation by glob"
          ]

          argument :pattern, required: false, desc: "File or pattern to validate"

          option :syntax, type: :boolean, desc: "Run syntax validation using linters"
          option :semantic, type: :boolean, desc: "Run semantic validation using LLM"
          option :all, type: :boolean, desc: "Run all validation types"
          option :package, type: :array, desc: "Scope to package(s), e.g. --package ace-docs"
          option :glob, type: :array, desc: "Scope by glob(s), e.g. --glob 'ace-docs/**/*.md'"

          # Standard options
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :debug, type: :boolean, aliases: %w[-d], desc: "Show debug output"

          def call(pattern: nil, **options)
            # Handle --help/-h passed as pattern argument
            if pattern == "--help" || pattern == "-h"
              # dry-cli will handle help automatically, so we just ignore
              return EXIT_SUCCESS
            end

            execute_validate(pattern, options)
          end

          private

          def execute_validate(pattern, options)
            scope_globs = normalized_scope_globs(options, project_root: options[:project_root])
            registry = Ace::Docs::Organisms::DocumentRegistry.new(
              project_root: options[:project_root],
              scope_globs: scope_globs
            )
            documents = select_documents(registry, pattern)

            if documents.empty?
              $stderr.puts "No documents to validate."
              return EXIT_SUCCESS
            end

            validator = Ace::Docs::Organisms::Validator.new(registry)
            has_errors = false

            documents.each do |doc|
              puts "Validating: #{doc.display_name}"
              results = validate_document(validator, doc, options)

              if results[:valid]
                puts "  ✓ Valid"
              else
                puts "  ✗ Invalid".red
                has_errors = true
                display_errors(results[:errors])
              end

              display_warnings(results[:warnings]) if results[:warnings]&.any?
            end

            has_errors ? EXIT_ERROR : EXIT_SUCCESS
          rescue StandardError => e
            $stderr.puts "Error validating documents: #{e.message}"
            $stderr.puts e.backtrace.join("\n") if debug?(options)
            EXIT_ERROR
          end

          def select_documents(registry, pattern)
            if pattern
              if File.exist?(pattern)
                doc = registry.find_by_path(pattern)
                doc ? [doc] : []
              else
                # Treat as glob pattern
                registry.all.select do |doc|
                  rel = doc.relative_path || doc.path
                  File.fnmatch?(pattern, rel, File::FNM_PATHNAME | File::FNM_EXTGLOB) ||
                    File.fnmatch?(pattern, doc.path, File::FNM_PATHNAME | File::FNM_EXTGLOB)
                end
              end
            else
              registry.all
            end
          end

          def validate_document(validator, doc, options)
            # Determine validation types
            run_syntax = options[:syntax] || options[:all]
            run_semantic = options[:semantic] || options[:all]
            run_all = !options[:syntax] && !options[:semantic]

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

            # Check if ace-lint is available (using argv-style to avoid shell injection)
            unless system("which", ace_lint_path, out: File::NULL, err: File::NULL)
              # Fall back to internal validation
              return {
                valid: false,
                errors: ["ace-lint not found. Install with: gem install ace-lint"],
                warnings: []
              }
            end

            # Run ace-lint on the document
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
              puts "    ⚠ #{warning}"
            end
          end
        end
      end
    end
  end
end
