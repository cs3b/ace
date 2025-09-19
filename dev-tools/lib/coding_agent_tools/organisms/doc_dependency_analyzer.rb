# frozen_string_literal: true

require "set"
require "json"
require_relative "../molecules/doc_link_parser"
require_relative "../molecules/circular_dependency_detector"
require_relative "../molecules/statistics_calculator"
require_relative "../atoms/dot_graph_writer"
require_relative "../atoms/json_exporter"

module CodingAgentTools::Organisms
  # Organism for complete documentation dependency analysis
  # Orchestrates the full analysis workflow with reporting
  class DocDependencyAnalyzer
    def initialize(config_path = nil)
      @parser = CodingAgentTools::Molecules::DocLinkParser.new(config_path)
      @cycle_detector = CodingAgentTools::Molecules::CircularDependencyDetector.new
      @stats_calculator = CodingAgentTools::Molecules::StatisticsCalculator.new
      @dot_writer = CodingAgentTools::Atoms::DotGraphWriter.new
      @json_exporter = CodingAgentTools::Atoms::JsonExporter.new
      @dependencies = Hash.new { |h, k| h[k] = {refs_to: Set.new, refs_from: Set.new} }
    end

    # Run complete dependency analysis
    def analyze(output_format: :text, export_dot: true, export_json: true)
      # Step 1: Collect all documentation files
      all_files = @parser.collect_documentation_files

      # Step 2: Analyze dependencies for each file
      all_files.each do |file|
        analyze_file_dependencies(file, all_files)
      end

      # Step 3: Generate analysis results
      results = generate_analysis_results

      # Step 4: Export files if requested
      if export_dot
        results[:dot_file] = @dot_writer.write_dot_file(@dependencies)
        results[:png_command] = @dot_writer.png_generation_instructions(results[:dot_file])
      end

      results[:json_file] = @json_exporter.export_to_file(@dependencies) if export_json

      # Step 5: Format output
      case output_format
      when :json
        # For JSON output, we need to serialize the results properly
        JSON.pretty_generate(serialize_results_for_json(results))
      when :text
        format_text_output(results)
      else
        results
      end
    end

    # Analyze dependencies without file exports (for testing)
    def analyze_dependencies_only
      all_files = @parser.collect_documentation_files

      all_files.each do |file|
        analyze_file_dependencies(file, all_files)
      end

      @dependencies
    end

    # Get specific analysis components
    def get_statistics
      @stats_calculator.calculate_basic_stats(@dependencies)
    end

    def get_circular_dependencies
      @cycle_detector.find_cycles(@dependencies)
    end

    def get_orphaned_files
      @stats_calculator.find_orphaned_files(@dependencies)
    end

    def get_most_referenced_files(limit = 10)
      @stats_calculator.most_referenced_files(@dependencies, limit)
    end

    private

    def analyze_file_dependencies(file, all_files)
      references = @parser.parse_file_references(file, all_files)

      references.each do |target|
        @dependencies[file][:refs_to] << target
        @dependencies[target][:refs_from] << file
      end

      # Ensure file exists in dependencies even if it has no references
      @dependencies[file] unless @dependencies.key?(file)
    end

    def generate_analysis_results
      {
        timestamp: Time.now,
        statistics: @stats_calculator.calculate_basic_stats(@dependencies),
        most_referenced: @stats_calculator.most_referenced_files(@dependencies, 10),
        most_referencing: @stats_calculator.most_referencing_files(@dependencies, 10),
        orphaned_files: @stats_calculator.find_orphaned_files(@dependencies),
        circular_dependencies: @cycle_detector.find_cycles(@dependencies),
        hub_files: @stats_calculator.find_hub_files(@dependencies),
        file_type_distribution: @stats_calculator.calculate_file_type_distribution(@dependencies),
        reference_patterns: @stats_calculator.analyze_reference_patterns(@dependencies)
      }
    end

    def format_text_output(results)
      output = []
      output << "# Document Dependency Analysis"
      output << "Generated: #{results[:timestamp]}"
      output << ""

      # Summary statistics
      stats = results[:statistics]
      output << "## Summary"
      output << "- Total files analyzed: #{stats[:total_files]}"
      output << "- Files with outgoing references: #{stats[:files_with_outgoing_refs]}"
      output << "- Files with incoming references: #{stats[:files_with_incoming_refs]}"
      output << "- Total references: #{stats[:total_references]}"
      output << "- Average outgoing references per file: #{stats[:average_outgoing_refs]}"
      output << "- Average incoming references per file: #{stats[:average_incoming_refs]}"
      output << ""

      # Most referenced files
      if results[:most_referenced].any?
        output << "## Most Referenced Files (Top 10)"
        results[:most_referenced].each do |item|
          output << "- **#{item[:file]}** - Referenced by #{item[:reference_count]} files"
        end
        output << ""
      end

      # Most referencing files
      if results[:most_referencing].any?
        output << "## Most Referencing Files (Top 10)"
        results[:most_referencing].each do |item|
          output << "- **#{item[:file]}** - References #{item[:reference_count]} other files"
        end
        output << ""
      end

      # Hub files
      if results[:hub_files].any?
        output << "## Hub Files (High Connectivity)"
        results[:hub_files].each do |hub|
          output << "- **#{hub[:file]}** - #{hub[:incoming_count]} incoming, #{hub[:outgoing_count]} outgoing (#{hub[:total_connections]} total)"
        end
        output << ""
      end

      # Orphaned files
      if results[:orphaned_files].any?
        output << "## Orphaned Files (No References)"
        results[:orphaned_files].each { |f| output << "- #{f}" }
        output << ""
      end

      # Circular dependencies
      if results[:circular_dependencies].any?
        output << "## Circular Dependencies"
        results[:circular_dependencies].each do |cycle|
          output << "- #{cycle.join(" → ")} → #{cycle.first}"
        end
        output << ""
      end

      # File type distribution
      if results[:file_type_distribution].any?
        output << "## File Type Distribution"
        results[:file_type_distribution].each do |type, count|
          output << "- #{type.to_s.capitalize}: #{count} files"
        end
        output << ""
      end

      # Visualization info
      if results[:dot_file]
        output << "## Visualization"
        output << "Dependency graph saved to: #{results[:dot_file]}"
        output << "To generate an image: #{results[:png_command]}"
        output << ""
      end

      # JSON export info
      if results[:json_file]
        output << "Detailed dependency data saved to: #{results[:json_file]}"
        output << ""
      end

      output.join("\n")
    end

    def serialize_results_for_json(results)
      # Convert all non-serializable objects to serializable format
      serialized = {}

      results.each do |key, value|
        serialized[key] = case key
        when :timestamp
          value.iso8601
        when :dependencies
          @json_exporter.format_dependencies(value)
        else
          value
        end
      end

      serialized
    end
  end
end
