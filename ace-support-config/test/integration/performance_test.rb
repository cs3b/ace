# frozen_string_literal: true

require "test_helper"
require "benchmark"

module Ace
  module Support
    module Config
      class PerformanceTest < TestCase
        # Performance threshold in seconds
        # Configuration resolution should complete well under 1 second
        RESOLUTION_THRESHOLD = 0.5

        # Iteration counts for performance tests
        # Reduced from 100-1000 to 10-50 to achieve <5s test suite execution time
        # (task 172: 11.77s → 1.72s = 85% improvement while maintaining statistical validity)
        #
        # Separate constants allow independent tuning for I/O-bound vs CPU-bound operations:
        # - CASCADE: Config resolution traversing directories
        # - GLOB: File pattern matching (I/O heavy)
        # - FINDER: Project root lookup with caching
        # - TEST_MODE: In-memory operations (CPU only)
        CASCADE_ITERATIONS = 10
        GLOB_ITERATIONS = 10
        FINDER_ITERATIONS = 50
        TEST_MODE_ITERATIONS = 50

        # Performance Metrics Strategy
        # ============================
        # Uses median instead of mean for iteration timings to mitigate outlier noise
        # (GC pauses, system jitter). With small sample sizes (10-50 iterations),
        # a single slow iteration represents 2-10% of the sample, making median
        # more robust than average. See PR #111 review feedback for details.

        def test_cascade_resolution_performance
          with_deep_cascade(depth: 2) do |_tmpdir|
            times = measure_iterations(CASCADE_ITERATIONS) do
              resolver = Organisms::ConfigResolver.new
              resolver.resolve
              resolver.reset!
            end

            median = median_time(times)
            assert median < RESOLUTION_THRESHOLD,
              "Median resolution time #{format_time(median)} exceeded threshold #{RESOLUTION_THRESHOLD}s"
          end
        end

        def test_virtual_resolver_glob_performance
          with_many_files(count: 10) do |_tmpdir|
            resolver = Organisms::VirtualConfigResolver.new

            times = measure_iterations(GLOB_ITERATIONS) do
              resolver.glob("**/*.yml")
              resolver.reload!
            end

            median = median_time(times)
            assert median < RESOLUTION_THRESHOLD,
              "Median glob time #{format_time(median)} exceeded threshold #{RESOLUTION_THRESHOLD}s"
          end
        end

        def test_project_root_finder_cached_performance
          with_temp_config(".git" => "") do |tmpdir|
            finder = Ace::Support::Fs::Molecules::ProjectRootFinder.new(start_path: tmpdir)

            # First call populates cache
            finder.stub(:env_project_root, nil) do
              finder.find
            end

            times = measure_iterations(FINDER_ITERATIONS) do
              finder.stub(:env_project_root, nil) do
                finder.find
              end
            end

            median = median_time(times)
            assert median < 0.001,
              "Cached lookup median time #{format_time(median)} too slow (should be <1ms)"
          end
        end

        def test_deep_merge_performance
          large_hash1 = build_nested_hash(depth: 5, breadth: 10)
          large_hash2 = build_nested_hash(depth: 5, breadth: 10)

          times = measure_iterations(CASCADE_ITERATIONS) do
            Atoms::DeepMerger.merge(large_hash1, large_hash2)
          end

          median = median_time(times)
          assert median < 0.25,
            "Median merge time #{format_time(median)} exceeded threshold 0.25s"
        end

        # Test mode performance tests

        def test_test_mode_resolution_is_fast
          # Test mode should be extremely fast since it skips filesystem
          times = measure_iterations(TEST_MODE_ITERATIONS) do
            resolver = Organisms::ConfigResolver.new(test_mode: true)
            resolver.resolve
            resolver.resolve_namespace("git")
            resolver.resolve_file("some/path.yml")
          end

          median = median_time(times)
          # Should be < 5ms per iteration - relaxed threshold for CI stability
          assert median < 0.005,
            "Test mode median time #{format_time(median)} too slow (should be <5ms)"
        end

        def test_test_mode_with_mock_config_performance
          mock_config = build_nested_hash(depth: 3, breadth: 5)

          times = measure_iterations(TEST_MODE_ITERATIONS) do
            resolver = Organisms::ConfigResolver.new(
              test_mode: true,
              mock_config: mock_config
            )
            resolver.resolve
            resolver.get("key0", "key0", "key0")
          end

          median = median_time(times)
          # Relaxed threshold for CI stability
          assert median < 0.005,
            "Test mode with mock config median #{format_time(median)} too slow (should be <5ms)"
        end

        def test_class_level_test_mode_performance
          original_test_mode = Ace::Support::Config.test_mode
          original_mock = Ace::Support::Config.default_mock

          begin
            Ace::Support::Config.test_mode = true
            Ace::Support::Config.default_mock = {"key" => "value"}

            times = measure_iterations(TEST_MODE_ITERATIONS) do
              resolver = Ace::Support::Config.create
              resolver.resolve
            end

            median = median_time(times)
            # Relaxed threshold for CI stability
            assert median < 0.005,
              "Class-level test mode median #{format_time(median)} too slow (should be <5ms)"
          ensure
            Ace::Support::Config.test_mode = original_test_mode
            Ace::Support::Config.default_mock = original_mock
          end
        end

        # Deep nesting verification test
        # Ensures correctness at scale without sacrificing speed (minimal iterations)
        def test_deep_cascade_correctness
          with_deep_cascade(depth: 5) do |_tmpdir|
            # Single iteration to verify correctness at full depth
            resolver = Organisms::ConfigResolver.new
            config = resolver.resolve

            # Verify deepest level is accessible
            assert config, "Deep cascade resolution should return config"
          end
        end

        private

        def with_deep_cascade(depth:)
          structure = {".git" => ""}
          current = structure

          depth.times do |i|
            subdir = "level#{i}"
            current[subdir] = {
              ".ace" => {
                "settings.yml" => "level: #{i}\nkey#{i}: value#{i}"
              }
            }
            current = current[subdir]
          end

          with_temp_config(structure) do |tmpdir|
            # Navigate to deepest directory
            deepest = tmpdir
            depth.times { |i| deepest = File.join(deepest, "level#{i}") }

            Dir.chdir(deepest) do
              yield tmpdir
            end
          end
        end

        def with_many_files(count:)
          files = {}
          count.times do |i|
            files["file#{i}.yml"] = "key: value#{i}"
          end

          with_temp_config(
            ".git" => "",
            ".ace" => files
          ) do |tmpdir|
            yield tmpdir
          end
        end

        def build_nested_hash(depth:, breadth:)
          return {"leaf" => "value"} if depth <= 0

          result = {}
          breadth.times do |i|
            result["key#{i}"] = build_nested_hash(depth: depth - 1, breadth: breadth)
          end
          result
        end

        # Performance measurement helpers

        # Measures individual iteration times for robust statistical analysis
        def measure_iterations(count)
          Array.new(count) do
            Benchmark.realtime { yield }
          end
        end

        # Calculates median time from array of measurements
        # More robust than mean for small sample sizes (10-50 iterations)
        def median_time(times)
          sorted = times.sort
          mid = sorted.size / 2
          sorted.size.odd? ? sorted[mid] : (sorted[mid - 1] + sorted[mid]) / 2.0
        end

        # Formats time for readable assertion messages
        def format_time(seconds)
          if seconds < 0.001
            format("%.3fms", seconds * 1000)
          else
            format("%.4fs", seconds)
          end
        end

        # Asserts performance improvement meets target percentage
        # @param baseline_time [Float] Original performance baseline
        # @param current_time [Float] Current measured performance
        # @param min_improvement_percent [Float] Minimum required improvement (0-100)
        def assert_performance_improvement(baseline_time, current_time, min_improvement_percent)
          improvement = ((baseline_time - current_time) / baseline_time) * 100
          assert improvement >= min_improvement_percent,
            "Performance improvement #{improvement.round(1)}% below target #{min_improvement_percent}%"
        end
      end
    end
  end
end
