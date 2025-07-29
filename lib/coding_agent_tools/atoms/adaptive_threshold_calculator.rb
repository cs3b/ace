# frozen_string_literal: true

module CodingAgentTools
  module Atoms
    # Calculates optimal coverage threshold automatically using progressive algorithm
    # This atom implements a simple yet effective strategy to find actionable thresholds
    # by progressively testing from 10% to 90% in 10% increments.
    class AdaptiveThresholdCalculator
      DEFAULT_MIN_THRESHOLD = 10.0
      DEFAULT_MAX_THRESHOLD = 90.0
      DEFAULT_INCREMENT = 10.0
      MINIMUM_ACTIONABLE_FILES = 1
      PREFERRED_MINIMUM_FILES = 6
      MAXIMUM_ACTIONABLE_FILES = 15

      def initialize(
        min_threshold: DEFAULT_MIN_THRESHOLD,
        max_threshold: DEFAULT_MAX_THRESHOLD,
        increment: DEFAULT_INCREMENT
      )
        @min_threshold = min_threshold.to_f
        @max_threshold = max_threshold.to_f
        @increment = increment.to_f

        validate_parameters
      end

      # Calculates the optimal threshold for a given set of coverage data
      # @param coverage_data [Array<Hash>] Array of file coverage data with :coverage_percentage keys
      # @return [Hash] Result containing optimal threshold, reasoning, and statistics
      def calculate_optimal_threshold(coverage_data)
        return build_no_files_result if coverage_data.empty?

        # Test thresholds progressively from min to max
        threshold_results = test_thresholds(coverage_data)

        # Find optimal threshold based on actionable file count
        optimal_result = find_optimal_threshold(threshold_results)

        build_result(optimal_result, threshold_results, coverage_data)
      end

      # Quick validation to check if adaptive calculation is worthwhile
      # @param coverage_data [Array<Hash>] Array of file coverage data
      # @return [Boolean] True if adaptive calculation would be beneficial
      def should_use_adaptive?(coverage_data)
        return false if coverage_data.empty?

        # Calculate spread in coverage percentages
        percentages = coverage_data.map { |file| file[:coverage_percentage] || 0 }
        spread = percentages.max - percentages.min

        # Use adaptive if there's significant spread (>30%) or many files
        spread > 30.0 || coverage_data.length > 20
      end

      private

      def validate_parameters
        unless @min_threshold >= 0 && @min_threshold <= 100
          raise ArgumentError, "min_threshold must be between 0 and 100"
        end

        unless @max_threshold >= 0 && @max_threshold <= 100
          raise ArgumentError, "max_threshold must be between 0 and 100"
        end

        unless @min_threshold < @max_threshold
          raise ArgumentError, "min_threshold must be less than max_threshold"
        end

        unless @increment > 0
          raise ArgumentError, "increment must be positive"
        end
      end

      def test_thresholds(coverage_data)
        results = []
        current_threshold = @min_threshold

        while current_threshold <= @max_threshold
          files_under_threshold = count_files_under_threshold(coverage_data, current_threshold)

          results << {
            threshold: current_threshold,
            files_under_threshold: files_under_threshold,
            actionable: actionable_file_count?(files_under_threshold),
            preferred: preferred_file_count?(files_under_threshold)
          }

          current_threshold += @increment
        end

        results
      end

      def count_files_under_threshold(coverage_data, threshold)
        coverage_data.count do |file|
          file_coverage = file[:coverage_percentage] || 0
          file_coverage < threshold
        end
      end

      def actionable_file_count?(count)
        count >= MINIMUM_ACTIONABLE_FILES && count <= MAXIMUM_ACTIONABLE_FILES
      end

      def preferred_file_count?(count)
        count >= PREFERRED_MINIMUM_FILES && count <= MAXIMUM_ACTIONABLE_FILES
      end

      def find_optimal_threshold(threshold_results)
        # First priority: Find threshold with preferred file count (6-15 files)
        preferred_results = threshold_results.select { |result| result[:preferred] }

        if preferred_results.any?
          # Choose the highest threshold that still produces preferred results
          return preferred_results.max_by { |result| result[:threshold] }
        end

        # Second priority: Find threshold with actionable file count (1-15 files)
        actionable_results = threshold_results.select { |result| result[:actionable] }

        if actionable_results.any?
          # Choose the highest threshold that still produces actionable results
          return actionable_results.max_by { |result| result[:threshold] }
        end

        # Third priority: Find threshold closest to actionable range
        threshold_results.min_by do |result|
          files_count = result[:files_under_threshold]
          if files_count < MINIMUM_ACTIONABLE_FILES
            MINIMUM_ACTIONABLE_FILES - files_count
          else
            files_count - MAXIMUM_ACTIONABLE_FILES
          end
        end
      end

      def build_result(optimal_result, all_results, coverage_data)
        files_count = optimal_result[:files_under_threshold]
        reasoning = generate_reasoning(optimal_result, files_count, coverage_data.length)

        {
          optimal_threshold: optimal_result[:threshold],
          files_under_threshold: files_count,
          total_files: coverage_data.length,
          actionable: optimal_result[:actionable],
          reasoning: reasoning,
          threshold_testing_results: all_results.map do |result|
            {
              threshold: result[:threshold],
              files_under_threshold: result[:files_under_threshold],
              actionable: result[:actionable],
              preferred: result[:preferred]
            }
          end,
          calculation_metadata: {
            min_threshold_tested: @min_threshold,
            max_threshold_tested: @max_threshold,
            increment_used: @increment,
            calculation_timestamp: Time.now.iso8601
          }
        }
      end

      def generate_reasoning(optimal_result, files_count, total_files)
        threshold = optimal_result[:threshold]

        if optimal_result[:preferred]
          "Threshold #{threshold}% selected: produces #{files_count} files in preferred range " \
          "(#{PREFERRED_MINIMUM_FILES}-#{MAXIMUM_ACTIONABLE_FILES}). This provides an optimal " \
          "balance of meaningful work without overwhelming the developer."
        elsif optimal_result[:actionable]
          "Threshold #{threshold}% selected: produces #{files_count} actionable files " \
          "(within fallback range of #{MINIMUM_ACTIONABLE_FILES}-#{MAXIMUM_ACTIONABLE_FILES}). " \
          "While below the preferred minimum of #{PREFERRED_MINIMUM_FILES} files, this still " \
          "provides focused work that won't overwhelm."
        elsif files_count == 0
          "Threshold #{threshold}% selected: no files need attention at this level. " \
          "Consider this excellent coverage! You might want to increase your standards."
        elsif files_count < MINIMUM_ACTIONABLE_FILES
          "Threshold #{threshold}% selected: only #{files_count} files under threshold. " \
          "This represents the highest standard where files still need attention."
        else
          "Threshold #{threshold}% selected: #{files_count} files under threshold. " \
          "While above the ideal range (#{MAXIMUM_ACTIONABLE_FILES}), this represents " \
          "the most focused view possible given current coverage distribution."
        end
      end

      def build_no_files_result
        {
          optimal_threshold: @min_threshold,
          files_under_threshold: 0,
          total_files: 0,
          actionable: false,
          reasoning: "No files provided for analysis. Using minimum threshold (#{@min_threshold}%) as default.",
          threshold_testing_results: [],
          calculation_metadata: {
            min_threshold_tested: @min_threshold,
            max_threshold_tested: @max_threshold,
            increment_used: @increment,
            calculation_timestamp: Time.now.iso8601
          }
        }
      end
    end
  end
end
