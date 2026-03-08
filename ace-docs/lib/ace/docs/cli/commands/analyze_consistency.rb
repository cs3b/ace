# frozen_string_literal: true

require "dry/cli"
require "ace/core"
require "colorize"
require_relative "../../organisms/cross_document_analyzer"
require_relative "../../models/consistency_report"
require_relative "scope_options"

module Ace
  module Docs
    module CLI
      module Commands
        # dry-cli Command class for the analyze-consistency command
        #
        # This command handles cross-document consistency analysis.
        class AnalyzeConsistency < Dry::CLI::Command
          include Ace::Core::CLI::DryCli::Base
          include ScopeOptions

          # Exit codes
          EXIT_SUCCESS = 0
          EXIT_ERROR = 1

          desc <<~DESC.strip
            Analyze cross-document consistency

            Analyze multiple documents for consistency issues including terminology
            conflicts, duplicate content, and version inconsistencies.

            Configuration:
              LLM model configured via ace-llm
              Global config:  ~/.ace/docs/config.yml
              Project config: .ace/docs/config.yml

            Output:
              Consistency report in markdown format (default)
              Exit codes: 0 (success), 1 (issues found with --strict), 2 (error)
          DESC

          example [
            "                             # Analyze all documents",
            "docs/handbook/               # Analyze specific directory",
            "--terminology                # Check terminology conflicts only",
            "--duplicates --threshold 80  # Check duplicates with threshold",
            "--save                       # Save report to file",
            "--model gpt-4               # Use specific LLM model",
            "--package ace-docs          # Scope to one package",
            "--glob 'ace-docs/**/*.md'   # Scope by glob"
          ]

          argument :pattern, required: false, desc: "Pattern to analyze"

          option :terminology, type: :boolean, desc: "Check terminology conflicts only"
          option :duplicates, type: :boolean, desc: "Find duplicate content only"
          option :versions, type: :boolean, desc: "Check version consistency only"
          option :all, type: :boolean, desc: "All analysis types (default)"
          option :threshold, type: :integer, desc: "Similarity threshold for duplicates (default: 70)"
          option :output, type: :string, desc: "Output format (markdown|json|text)", default: "markdown"
          option :save, type: :boolean, desc: "Save report to cache directory"
          option :model, type: :string, desc: "LLM model to use (default: gflash)"
          option :timeout, type: :integer, desc: "LLM timeout in seconds"
          option :strict, type: :boolean, desc: "Exit with code 1 if issues found"
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

            # Type-convert numeric options (dry-cli returns strings, Thor converted to integers)
            numeric_options = %i[threshold timeout]
            numeric_options.each do |key|
              options[key] = options[key].to_i if options[key]
            end

            execute_consistency_analysis(pattern, options)
          end

          private

          def execute_consistency_analysis(pattern, options)
            normalized_options = parse_options(options)
            analyzer = Ace::Docs::Organisms::CrossDocumentAnalyzer.new(normalized_options)

            # Show what we're analyzing
            if pattern
              puts "Analyzing documents matching: #{pattern}".cyan
            else
              puts "Analyzing all managed documents".cyan
            end

            # Determine focus areas
            focus_areas = determine_focus_areas(normalized_options)
            puts "Focus areas: #{focus_areas.join(', ')}".cyan

            # Run analysis
            report = analyzer.analyze(pattern)

            # The report is now a path to the saved file
            # Check if it's nil or file doesn't exist
            if report.nil? || !File.exist?(report)
              $stderr.puts "No analysis results returned."
              return EXIT_ERROR
            end

            # Display where the report was saved
            puts "Report saved to: #{report}".cyan

            # Simple completion message
            puts "\n✅ Analysis complete"
            EXIT_SUCCESS
          rescue StandardError => e
            $stderr.puts "Error: #{e.message}"
            $stderr.puts e.backtrace.join("\n") if normalized_options[:debug]
            EXIT_ERROR
          end

          # Parse and normalize options
          def parse_options(options)
            normalized = {}

            # Output format
            normalized[:output] = options[:output] || 'markdown'

            # Analysis focus
            normalized[:all] = options[:all] ||
                              (!options[:terminology] && !options[:duplicates] && !options[:versions])
            normalized[:terminology] = options[:terminology] || false
            normalized[:duplicates] = options[:duplicates] || false
            normalized[:versions] = options[:versions] || false

            # Threshold for duplicate detection
            normalized[:threshold] = options[:threshold] || 70

            # Save to cache
            normalized[:save] = options[:save] || false

            # Verbose mode
            normalized[:verbose] = options[:verbose] || false

            # Debug mode
            normalized[:debug] = options[:debug] || false

            # Strict mode (exit 1 if issues found)
            normalized[:strict] = options[:strict] || false

            # LLM model
            normalized[:model] = options[:model]

            # Timeout
            normalized[:timeout] = options[:timeout]
            normalized[:project_root] = options[:project_root]
            normalized[:scope_globs] = normalized_scope_globs(options, project_root: options[:project_root])

            normalized
          end

          # Determine which analysis areas to focus on
          def determine_focus_areas(options)
            areas = []

            if options[:all]
              areas = ['terminology', 'duplicates', 'versions', 'consolidation']
            else
              areas << 'terminology' if options[:terminology]
              areas << 'duplicates' if options[:duplicates]
              areas << 'versions' if options[:versions]
            end

            areas.empty? ? ['all types'] : areas
          end
        end
      end
    end
  end
end
