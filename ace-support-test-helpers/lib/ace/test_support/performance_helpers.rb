# frozen_string_literal: true

require "benchmark"

module Ace
  module TestSupport
    # Performance testing helpers for ACE gems
    #
    # Provides utilities for:
    # - Performance assertions (max duration checks)
    # - Benchmarking helpers
    # - Performance regression detection
    #
    # Usage:
    #   include Ace::TestSupport::PerformanceHelpers
    #
    #   def test_performance
    #     assert_performance(0.1) do
    #       # Code that should complete in < 0.1 seconds
    #     end
    #   end
    module PerformanceHelpers
      # Assert that a block completes within the specified duration
      #
      # @param max_duration [Float] Maximum allowed duration in seconds
      # @param message [String] Optional custom failure message
      # @yield Block to measure
      # @return [Float] Actual duration
      #
      # @example
      #   assert_performance(0.5, "Search should complete quickly") do
      #     MySearch.new.execute("pattern")
      #   end
      def assert_performance(max_duration, message = nil)
        raise ArgumentError, "Block required for performance assertion" unless block_given?

        result = Benchmark.measure { yield }
        actual_duration = result.real

        message ||= "Expected block to complete in under #{max_duration}s, but took #{format("%.3f", actual_duration)}s"

        assert actual_duration <= max_duration, message

        actual_duration
      end

      # Benchmark a block and return detailed timing information
      #
      # @yield Block to benchmark
      # @return [Hash] Timing information with :real, :user, :system, :total keys
      #
      # @example
      #   timing = benchmark_block do
      #     expensive_operation
      #   end
      #   puts "Real time: #{timing[:real]}s"
      def benchmark_block
        raise ArgumentError, "Block required for benchmarking" unless block_given?

        result = Benchmark.measure { yield }

        {
          real: result.real,
          user: result.utime,
          system: result.stime,
          total: result.total
        }
      end

      # Compare performance of two blocks
      #
      # @param label_a [String] Label for first block
      # @param label_b [String] Label for second block
      # @yield_a First block to benchmark
      # @yield_b Second block to benchmark
      # @return [Hash] Comparison results with :faster, :slower, :speedup keys
      #
      # @example
      #   compare_performance("old", "new") do |compare|
      #     compare.baseline { old_implementation }
      #     compare.candidate { new_implementation }
      #   end
      def compare_performance(label_a, label_b)
        raise ArgumentError, "Block required for performance comparison" unless block_given?

        comparison = PerformanceComparison.new(label_a, label_b)
        yield comparison

        comparison.execute
      end

      # Check if performance has regressed compared to baseline
      #
      # @param baseline_duration [Float] Expected baseline duration in seconds
      # @param tolerance [Float] Acceptable tolerance factor (default: 1.5 = 50% slower allowed)
      # @yield Block to measure
      # @return [Boolean] True if within tolerance, false if regressed
      #
      # @example
      #   # Allow up to 50% slower than baseline
      #   assert check_performance_regression(0.1) do
      #     my_operation
      #   end
      def check_performance_regression(baseline_duration, tolerance: 1.5)
        raise ArgumentError, "Block required for regression check" unless block_given?

        actual = benchmark_block { yield }[:real]
        max_allowed = baseline_duration * tolerance

        actual <= max_allowed
      end

      # Assert that performance hasn't regressed beyond tolerance
      #
      # @param baseline_duration [Float] Expected baseline duration in seconds
      # @param tolerance [Float] Acceptable tolerance factor (default: 1.5)
      # @param message [String] Optional custom failure message
      # @yield Block to measure
      #
      # @example
      #   # Baseline is 0.1s, allow up to 0.15s (1.5x)
      #   assert_no_performance_regression(0.1, tolerance: 1.5) do
      #     search_operation
      #   end
      def assert_no_performance_regression(baseline_duration, tolerance: 1.5, message: nil)
        raise ArgumentError, "Block required for regression assertion" unless block_given?

        actual = benchmark_block { yield }[:real]
        max_allowed = baseline_duration * tolerance

        message ||= "Performance regression detected: expected ≤ #{format("%.3f", max_allowed)}s " \
                    "(baseline #{format("%.3f", baseline_duration)}s × #{tolerance}), " \
                    "but took #{format("%.3f", actual)}s (#{format("%.1f", actual / baseline_duration)}x baseline)"

        assert actual <= max_allowed, message
      end

      # Performance comparison helper class
      class PerformanceComparison
        attr_reader :label_a, :label_b

        def initialize(label_a, label_b)
          @label_a = label_a
          @label_b = label_b
          @block_a = nil
          @block_b = nil
        end

        def baseline(&block)
          @block_a = block
        end

        def candidate(&block)
          @block_b = block
        end

        def execute
          raise "Both baseline and candidate blocks required" unless @block_a && @block_b

          result_a = Benchmark.measure { @block_a.call }
          result_b = Benchmark.measure { @block_b.call }

          faster_label = (result_a.real < result_b.real) ? label_a : label_b
          slower_label = (result_a.real < result_b.real) ? label_b : label_a
          speedup = [result_a.real, result_b.real].max / [result_a.real, result_b.real].min

          {
            faster: faster_label,
            slower: slower_label,
            speedup: speedup,
            baseline_time: result_a.real,
            candidate_time: result_b.real
          }
        end
      end
    end
  end
end
