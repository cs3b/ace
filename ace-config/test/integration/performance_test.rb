# frozen_string_literal: true

require "test_helper"
require "benchmark"

module Ace
  module Config
    class PerformanceTest < TestCase
      # Performance threshold in seconds
      # Configuration resolution should complete well under 1 second
      RESOLUTION_THRESHOLD = 0.5

      def test_cascade_resolution_performance
        with_deep_cascade(depth: 5) do |_tmpdir|
          elapsed = Benchmark.realtime do
            100.times do
              resolver = Organisms::ConfigResolver.new
              resolver.resolve
              resolver.reset!
            end
          end

          avg_time = elapsed / 100
          assert avg_time < RESOLUTION_THRESHOLD,
                 "Average resolution time #{avg_time}s exceeded threshold #{RESOLUTION_THRESHOLD}s"
        end
      end

      def test_virtual_resolver_glob_performance
        with_many_files(count: 50) do |_tmpdir|
          resolver = Organisms::VirtualConfigResolver.new

          elapsed = Benchmark.realtime do
            100.times do
              resolver.glob("**/*.yml")
              resolver.reload!
            end
          end

          avg_time = elapsed / 100
          assert avg_time < RESOLUTION_THRESHOLD,
                 "Average glob time #{avg_time}s exceeded threshold #{RESOLUTION_THRESHOLD}s"
        end
      end

      def test_project_root_finder_cached_performance
        with_temp_config(".git" => "") do |tmpdir|
          finder = Ace::Support::Fs::Molecules::ProjectRootFinder.new(start_path: tmpdir)

          # First call populates cache
          finder.stub(:env_project_root, nil) do
            finder.find
          end

          elapsed = Benchmark.realtime do
            1000.times do
              finder.stub(:env_project_root, nil) do
                finder.find
              end
            end
          end

          avg_time = elapsed / 1000
          assert avg_time < 0.001,
                 "Cached lookup time #{avg_time}s too slow (should be <1ms)"
        end
      end

      def test_deep_merge_performance
        large_hash1 = build_nested_hash(depth: 5, breadth: 10)
        large_hash2 = build_nested_hash(depth: 5, breadth: 10)

        elapsed = Benchmark.realtime do
          100.times do
            Atoms::DeepMerger.merge(large_hash1, large_hash2)
          end
        end

        avg_time = elapsed / 100
        assert avg_time < 0.1,
               "Average merge time #{avg_time}s exceeded threshold 0.1s"
      end

      # Test mode performance tests

      def test_test_mode_resolution_is_fast
        # Test mode should be extremely fast since it skips filesystem
        elapsed = Benchmark.realtime do
          1000.times do
            resolver = Organisms::ConfigResolver.new(test_mode: true)
            resolver.resolve
            resolver.resolve_namespace("git")
            resolver.resolve_file("some/path.yml")
          end
        end

        avg_time = elapsed / 1000
        # Should be < 5ms per iteration - relaxed threshold for CI stability
        assert avg_time < 0.005,
               "Test mode average time #{avg_time}s too slow (should be <5ms)"
      end

      def test_test_mode_with_mock_config_performance
        mock_config = build_nested_hash(depth: 3, breadth: 5)

        elapsed = Benchmark.realtime do
          1000.times do
            resolver = Organisms::ConfigResolver.new(
              test_mode: true,
              mock_config: mock_config
            )
            resolver.resolve
            resolver.get("key0", "key0", "key0")
          end
        end

        avg_time = elapsed / 1000
        # Relaxed threshold for CI stability
        assert avg_time < 0.005,
               "Test mode with mock config too slow: #{avg_time}s (should be <5ms)"
      end

      def test_class_level_test_mode_performance
        original_test_mode = Ace::Config.test_mode
        original_mock = Ace::Config.default_mock

        begin
          Ace::Config.test_mode = true
          Ace::Config.default_mock = { "key" => "value" }

          elapsed = Benchmark.realtime do
            1000.times do
              resolver = Ace::Config.create
              resolver.resolve
            end
          end

          avg_time = elapsed / 1000
          # Relaxed threshold for CI stability
          assert avg_time < 0.005,
                 "Class-level test mode too slow: #{avg_time}s (should be <5ms)"
        ensure
          Ace::Config.test_mode = original_test_mode
          Ace::Config.default_mock = original_mock
        end
      end

      private

      def with_deep_cascade(depth:)
        structure = { ".git" => "" }
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
        return { "leaf" => "value" } if depth <= 0

        result = {}
        breadth.times do |i|
          result["key#{i}"] = build_nested_hash(depth: depth - 1, breadth: breadth)
        end
        result
      end
    end
  end
end
