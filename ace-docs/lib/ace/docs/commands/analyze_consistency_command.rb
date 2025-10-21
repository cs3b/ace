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

            # Check if we have documents
            if report.document_count == 0
              puts "No documents found to analyze.".yellow
              puts "Ensure documents have ace-docs frontmatter." if pattern
              return 1
            end

            # Display or save report
            handle_output(report)

            # Return success/failure based on issues found
            if @options[:strict] && report.has_issues?
              puts "\n⚠️  Consistency issues found (strict mode)".yellow
              return 1
            end

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

        # Handle output of the report
        def handle_output(report)
          # Format based on output option
          case @options[:output]
          when 'json'
            puts report.to_json
          when 'text', 'markdown'
            display_markdown_report(report)
          else
            puts "Unknown output format: #{@options[:output]}".red
            display_markdown_report(report)
          end
        end

        # Display markdown report with colors
        def display_markdown_report(report)
          lines = report.to_markdown.split("\n")

          lines.each do |line|
            case line
            when /^#\s+/
              puts line.cyan.bold
            when /^##\s+/
              puts line.yellow.bold
            when /^###\s+/
              puts line.white.bold
            when /^\*\*Recommendation\*\*:/
              puts line.green
            when /^Generated:|^Documents analyzed:|^Issues found:/
              puts line.light_black
            when /^✅/
              puts line.green
            when /^⚠️/
              puts line.yellow
            when /^```/
              puts line.light_black
            else
              puts line
            end
          end

          # Show summary
          puts "\n" + "="*60
          puts "Summary:".cyan.bold
          puts "  Documents analyzed: #{report.document_count}"
          puts "  Total issues found: #{report.total_issues}"

          if report.total_issues > 0
            puts "  Issue breakdown:".yellow
            puts "    - Terminology conflicts: #{report.terminology_conflicts.size}" if report.terminology_conflicts.any?
            puts "    - Duplicate content: #{report.duplicate_content.size}" if report.duplicate_content.any?
            puts "    - Version inconsistencies: #{report.version_inconsistencies.size}" if report.version_inconsistencies.any?
            puts "    - Consolidation opportunities: #{report.consolidation_opportunities.size}" if report.consolidation_opportunities.any?
          end
        end
      end
    end
  end
end