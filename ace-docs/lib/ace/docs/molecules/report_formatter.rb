# frozen_string_literal: true

require_relative "../models/analysis_report"
require_relative "../atoms/diff_filterer"

module Ace
  module Docs
    module Molecules
      # Formats analysis results into structured reports
      class ReportFormatter
        # Format analysis results into a report
        # @param analysis_result [Hash] Result from DiffAnalyzer
        # @param documents [Array] Documents that were analyzed
        # @param options [Hash] Formatting options
        # @return [AnalysisReport] Formatted report
        def format(analysis_result, documents, options = {})
          report = Models::AnalysisReport.new(
            generated: Time.now.utc.iso8601,
            since: options[:since] || "recent changes",
            documents: documents,
            statistics: extract_statistics(analysis_result, options),
            analysis: format_analysis(analysis_result)
          )

          report
        end

        # Create a summary report from multiple analyses
        # @param analyses [Array<Hash>] Multiple analysis results
        # @return [String] Summary markdown
        def create_summary(analyses)
          return "No analyses to summarize" if analyses.empty?

          summary_parts = ["# Analysis Summary\n"]
          summary_parts << "Generated: #{Time.now.utc.iso8601}\n"
          summary_parts << "Analyses performed: #{analyses.size}\n\n"

          analyses.each_with_index do |analysis, index|
            summary_parts << format_analysis_summary(analysis, index + 1)
          end

          summary_parts.join("\n")
        end

        private

        def format_analysis(analysis_result)
          return "No analysis available" unless analysis_result[:success]

          analysis = analysis_result[:analysis]

          # If analysis is already well-formatted markdown, return as-is
          if analysis.include?("##") || analysis.include?("###")
            return analysis
          end

          # Otherwise, apply basic formatting
          <<~MARKDOWN
            # Codebase Changes Analysis

            #{analysis}
          MARKDOWN
        end

        def extract_statistics(analysis_result, options)
          stats = {
            "analysis_timestamp" => analysis_result[:timestamp],
            "documents_analyzed" => analysis_result[:documents_analyzed]
          }

          # Add diff statistics if available
          if options[:diff_stats]
            stats.merge!(options[:diff_stats])
          end

          stats
        end

        def format_analysis_summary(analysis, number)
          <<~SUMMARY
            ## Analysis ##{number}

            - Timestamp: #{analysis[:timestamp]}
            - Documents analyzed: #{analysis[:documents_analyzed]}
            - Success: #{analysis[:success] ? "✓" : "✗"}

            #{analysis[:success] ? extract_key_findings(analysis[:analysis]) : "Error: #{analysis[:error]}"}

            ---
          SUMMARY
        end

        def extract_key_findings(analysis_text)
          return "No findings available" if analysis_text.nil? || analysis_text.empty?

          # Try to extract summary or high-impact sections
          lines = analysis_text.split("\n")
          summary_lines = []
          in_summary = false
          in_high_impact = false

          lines.each do |line|
            if line =~ /summary|executive summary|key changes/i
              in_summary = true
              next
            elsif line =~ /^#+\s+HIGH|high.impact|significant.changes/i
              in_high_impact = true
              next
            elsif line =~ /^#+\s+/ && (in_summary || in_high_impact)
              # New section started, stop collecting
              break
            elsif (in_summary || in_high_impact) && !line.strip.empty?
              summary_lines << line
            end
          end

          if summary_lines.any?
            "### Key Findings\n" + summary_lines.take(5).join("\n")
          else
            # Fall back to first few lines
            "### Summary\n" + lines.take(3).join("\n")
          end
        end
      end
    end
  end
end