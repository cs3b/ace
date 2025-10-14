# frozen_string_literal: true

require_relative "../organisms/document_registry"
require_relative "../molecules/change_detector"
require_relative "../molecules/time_range_finder"
require_relative "../molecules/diff_analyzer"
require_relative "../molecules/report_formatter"
require_relative "../atoms/diff_filterer"
require "colorize"

module Ace
  module Docs
    module Commands
      # Command for batch document analysis with LLM
      class AnalyzeCommand
        def initialize(options = {})
          @options = options
          @registry = Organisms::DocumentRegistry.new
          @time_finder = Molecules::TimeRangeFinder.new
          @analyzer = Molecules::DiffAnalyzer.new
          @formatter = Molecules::ReportFormatter.new
        end

        # Execute the analyze command
        # @param files [Array<String>] Specific files to analyze
        # @return [Integer] Exit code (0 success, 1 no docs, 2 no changes, 3 LLM error, 4 git error)
        def execute(*files)
          documents = select_documents(files)

          if documents.empty?
            puts "No documents match the specified criteria.".yellow
            puts "Try: --needs-update, --type guide, or specify files directly"
            return 1
          end

          puts "Analyzing changes for #{documents.size} document(s)..."

          # Determine time range
          time_range = @time_finder.determine_range(documents, @options[:since])
          puts "Analyzing changes since: #{time_range}"

          # Generate diff
          diff = generate_diff(documents, time_range)

          if diff.nil? || diff.strip.empty?
            puts "No changes detected in the specified period.".green
            return 2
          end

          # Check diff size
          if Atoms::DiffFilterer.exceeds_limit?(diff, Ace::Docs.config["max_diff_lines_warning"])
            diff_stats = Atoms::DiffFilterer.count_changes(diff)
            puts "Warning: Large diff (#{diff_stats[:total_changes]} changes in #{diff_stats[:files]} files)".yellow
            puts "Consider using --exclude-renames, --exclude-moves, or --since to reduce scope"
          end

          # Analyze with LLM
          puts "Compacting changes with LLM analysis..."
          analysis_result = @analyzer.analyze(diff, documents, @options)

          unless analysis_result[:success]
            puts "Error: #{analysis_result[:error]}".red
            return 3
          end

          # Format and save report
          report = @formatter.format(
            analysis_result,
            documents,
            since: time_range,
            diff_stats: Atoms::DiffFilterer.count_changes(diff)
          )

          report_path = report.save_to_cache
          puts "Analysis report saved to: #{report_path}".green

          display_summary(report)
          0
        rescue StandardError => e
          puts "Error during analysis: #{e.message}".red
          puts e.backtrace.join("\n") if ENV["DEBUG"]
          4
        end

        private

        def select_documents(files)
          if files && !files.empty?
            # Specific files provided
            files.map { |f| @registry.find_by_path(f) }.compact
          elsif @options[:needs_update]
            @registry.needing_update
          elsif @options[:type]
            @registry.all.select { |d| d.doc_type == @options[:type] }
          elsif @options[:freshness]
            @registry.all.select { |d| d.freshness_status == @options[:freshness].to_sym }
          else
            # Default to documents needing updates
            @registry.needing_update
          end
        end

        def generate_diff(documents, time_range)
          diff_options = {
            include_renames: !@options[:exclude_renames],
            include_moves: !@options[:exclude_moves]
          }

          begin
            Molecules::ChangeDetector.generate_batch_diff(documents, time_range, diff_options)
          rescue StandardError => e
            raise "Failed to generate git diff: #{e.message}"
          end
        end

        def display_summary(report)
          puts "\n" + "="*60
          puts "Analysis Summary".bold
          puts "="*60
          puts "Documents analyzed: #{report.documents.size}"
          puts "Period: #{report.since}"
          puts "Generated: #{report.generated}"

          if report.statistics && report.statistics.any?
            puts "\nChange Statistics:"
            report.statistics.each do |key, value|
              next if key == "analysis_timestamp"
              puts "  #{key.capitalize.gsub('_', ' ')}: #{value}"
            end
          end

          puts "\nRun 'cat #{Ace::Docs.config["cache_dir"]}/analysis-*.md' to view the full report"
        end
      end
    end
  end
end