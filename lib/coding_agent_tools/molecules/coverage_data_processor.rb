# frozen_string_literal: true

module CodingAgentTools
  module Molecules
    # Processes SimpleCov JSON data into internal format
    # Handles multiple test frameworks and combines coverage data
    class CoverageDataProcessor
      def initialize(file_reader: nil, calculator: nil, threshold_validator: nil)
        @file_reader = file_reader || Atoms::CoverageFileReader.new
        @calculator = calculator || Atoms::CoverageCalculator.new
        @threshold_validator = threshold_validator || Atoms::ThresholdValidator.new
      end

      # Processes a SimpleCov resultset file into structured coverage data
      # @param file_path [String] Path to .resultset.json file
      # @param options [Hash] Processing options
      # @option options [Array<String>] :include_patterns File patterns to include
      # @option options [Array<String>] :exclude_patterns File patterns to exclude
      # @return [Hash] Processed coverage data with file paths and coverage info
      def process_file(file_path, options = {})
        raw_data = @file_reader.read(file_path)
        @file_reader.validate_structure(raw_data)

        process_coverage_data(raw_data, options)
      end

      # Processes raw SimpleCov data into structured format
      # @param raw_data [Hash] Raw SimpleCov JSON data
      # @param options [Hash] Processing options
      # @return [Hash] Processed coverage data
      def process_coverage_data(raw_data, options = {})
        include_patterns = normalize_patterns(options[:include_patterns] || ["**/lib/**/*.rb"])
        exclude_patterns = normalize_patterns(options[:exclude_patterns] || ["**/spec/**", "**/test/**"])

        # Extract all file paths across frameworks
        all_file_paths = @file_reader.extract_file_paths(raw_data)
        filtered_files = filter_file_paths(all_file_paths, include_patterns, exclude_patterns)

        # Process each file's coverage data
        file_coverage_data = {}
        filtered_files.each do |file_path|
          coverage_arrays = extract_coverage_arrays_for_file(raw_data, file_path)

          unless coverage_arrays.empty?
            combined_lines = combine_lines_data(coverage_arrays)
            combined_coverage = @calculator.calculate_combined_coverage(coverage_arrays)
            uncovered_details = @calculator.extract_uncovered_lines(combined_lines)
            line_details = @calculator.extract_detailed_line_info(combined_lines)

            file_coverage_data[file_path] = {
              coverage_data: combined_coverage,
              uncovered_details: uncovered_details,
              line_details: line_details,
              lines_data: combined_lines,
              frameworks: extract_frameworks_for_file(raw_data, file_path)
            }
          end
        end

        {
          total_files: filtered_files.length,
          processed_files: file_coverage_data.length,
          skipped_files: filtered_files.length - file_coverage_data.length,
          file_coverage: file_coverage_data,
          frameworks: @file_reader.extract_frameworks(raw_data),
          timestamp: extract_latest_timestamp(raw_data)
        }
      end

      # Filters files based on threshold to prioritize under-covered files
      # @param processed_data [Hash] Processed coverage data
      # @param threshold [Float] Coverage threshold percentage
      # @return [Hash] Filtered data with under-covered files prioritized
      def prioritize_under_covered_files(processed_data, threshold)
        validated_threshold = @threshold_validator.validate_threshold(threshold)

        under_covered = {}
        well_covered = {}

        processed_data[:file_coverage].each do |file_path, file_data|
          coverage_percentage = file_data[:coverage_data][:coverage_percentage]

          if coverage_percentage < validated_threshold
            under_covered[file_path] = file_data
          else
            well_covered[file_path] = file_data
          end
        end

        {
          **processed_data,
          under_covered_files: under_covered,
          well_covered_files: well_covered,
          under_covered_count: under_covered.length,
          threshold_used: validated_threshold
        }
      end

      private

      def normalize_patterns(patterns)
        return [] if patterns.nil?

        Array(patterns).map do |pattern|
          @threshold_validator.validate_file_pattern(pattern)
        end.compact
      end

      def filter_file_paths(file_paths, include_patterns, exclude_patterns)
        filtered = file_paths.select do |file_path|
          # Check include patterns (default to lib/**)
          included = include_patterns.any? { |pattern| File.fnmatch(pattern, file_path, File::FNM_PATHNAME) }

          # Check exclude patterns
          excluded = exclude_patterns.any? { |pattern| File.fnmatch(pattern, file_path, File::FNM_PATHNAME) }

          included && !excluded
        end

        # Sort to prioritize lib files first
        filtered.sort_by { |path| path.include?("/lib/") ? 0 : 1 }
      end

      def extract_coverage_arrays_for_file(raw_data, file_path)
        coverage_arrays = []

        raw_data.each do |_framework_name, framework_data|
          next unless framework_data.is_a?(Hash) && framework_data["coverage"]

          file_coverage = framework_data["coverage"][file_path]
          if file_coverage && file_coverage["lines"]
            coverage_arrays << file_coverage["lines"]
          end
        end

        coverage_arrays
      end

      def combine_lines_data(coverage_arrays)
        return [] if coverage_arrays.empty?

        max_length = coverage_arrays.map(&:length).max
        combined_lines = Array.new(max_length)

        (0...max_length).each do |index|
          values = coverage_arrays.map { |arr| arr[index] if index < arr.length }.compact

          combined_lines[index] = if values.empty? || values.all?(&:nil?)
            nil
          else
            # Sum non-nil values for combined execution count
            values.map { |v| v || 0 }.sum
          end
        end

        combined_lines
      end

      def extract_frameworks_for_file(raw_data, file_path)
        frameworks = []

        raw_data.each do |framework_name, framework_data|
          next unless framework_data.is_a?(Hash) && framework_data["coverage"]

          if framework_data["coverage"][file_path]
            frameworks << framework_name
          end
        end

        frameworks
      end

      def extract_latest_timestamp(raw_data)
        timestamps = raw_data.values
          .select { |data| data.is_a?(Hash) && data["timestamp"] }
          .map { |data| data["timestamp"] }
          .compact

        timestamps.empty? ? Time.now.to_i : timestamps.max
      end
    end
  end
end
