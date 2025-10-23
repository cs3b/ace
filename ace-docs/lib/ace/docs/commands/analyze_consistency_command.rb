# frozen_string_literal: true

require_relative "../organisms/cross_document_analyzer"
require_relative "../models/consistency_report"
require "colorize"

module Ace
  module Docs
    module Commands
      # Command for analyzing cross-document consistency
      class AnalyzeConsistencyCommand
        def initialize(options = {})
          @options = parse_options(options)
        end

        # Execute the analyze-consistency command
        # @param pattern [String, nil] optional pattern to filter documents
        # @return [Integer] Exit code (0 success, 1 error)
        def execute(pattern = nil)
          begin
            # Create analyzer
            analyzer = Organisms::CrossDocumentAnalyzer.new(@options)

            # Show what we're analyzing
            if pattern
              puts "Analyzing documents matching: #{pattern}".cyan
            else
              puts "Analyzing all managed documents".cyan
            end

            # Determine focus areas
            focus_areas = determine_focus_areas
            puts "Focus areas: #{focus_areas.join(', ')}".cyan

            # Run analysis
            report = analyzer.analyze(pattern)

            # The report is now a path to the saved file
            # Check if it's nil or file doesn't exist
            if report.nil? || !File.exist?(report)
              puts "No analysis results returned.".yellow
              return 1
            end

            # Display where the report was saved
            puts "Report saved to: #{report}".cyan

            # Simple completion message
            puts "\n✅ Analysis complete".green
            0
          rescue StandardError => e
            puts "Error: #{e.message}".red
            puts e.backtrace.join("\n") if @options[:debug]
            1
          end
        end

        private

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

          normalized
        end

        # Determine which analysis areas to focus on
        def determine_focus_areas
          areas = []

          if @options[:all]
            areas = ['terminology', 'duplicates', 'versions', 'consolidation']
          else
            areas << 'terminology' if @options[:terminology]
            areas << 'duplicates' if @options[:duplicates]
            areas << 'versions' if @options[:versions]
          end

          areas.empty? ? ['all types'] : areas
        end

        # Removed handle_output and display_markdown_report methods
        # The report is now just a string from LLM that we display directly
      end
    end
  end
end