# frozen_string_literal: true

require "json"
require "fileutils"

# Tracks test execution times and failure patterns
# to identify flaky tests and performance issues
module TestReliabilityTracker
  class << self
    TRACKING_DIR = "tmp/test_reliability"
    TRACKING_FILE = File.join(TRACKING_DIR, "test_metrics.json")
    FLAKY_THRESHOLD = 0.2 # 20% failure rate indicates flaky test
    SLOW_TEST_THRESHOLD = 1.0 # Tests taking longer than 1 second are considered slow

    def initialize!
      FileUtils.mkdir_p(TRACKING_DIR)
      @data = load_tracking_data
    end

    def track_test(example)
      test_key = generate_test_key(example)

      @data[test_key] ||= {
        "runs" => 0,
        "failures" => 0,
        "execution_times" => [],
        "last_run" => nil,
        "file_path" => example.metadata[:file_path],
        "line_number" => example.metadata[:line_number]
      }

      @data[test_key]["runs"] += 1
      @data[test_key]["failures"] += 1 if example.exception
      @data[test_key]["execution_times"] << example.execution_result.run_time
      @data[test_key]["last_run"] = Time.now.iso8601

      save_tracking_data
    end

    def flaky_tests
      @data.select do |_test_key, metrics|
        failure_rate = metrics["failures"].to_f / metrics["runs"]
        failure_rate > 0 && failure_rate < 1.0 && failure_rate >= FLAKY_THRESHOLD
      end
    end

    def slow_tests
      @data.select do |_test_key, metrics|
        times = metrics["execution_times"].compact
        next false if times.empty?

        avg_time = times.sum / times.size.to_f
        avg_time > SLOW_TEST_THRESHOLD
      end.sort_by { |_k, v|
        times = v["execution_times"].compact
        times.empty? ? 0 : -times.sum / times.size.to_f
      }
    end

    def test_statistics
      total_runs = @data.values.sum { |m| m["runs"] }
      total_failures = @data.values.sum { |m| m["failures"] }

      {
        "total_tests" => @data.size,
        "total_runs" => total_runs,
        "total_failures" => total_failures,
        "flaky_tests" => flaky_tests.size,
        "slow_tests" => slow_tests.size,
        "average_failure_rate" => (total_runs > 0) ? (total_failures.to_f / total_runs) : 0
      }
    end

    def generate_report
      stats = test_statistics

      report = []
      report << "=== Test Reliability Report ==="
      report << "Total Tests: #{stats["total_tests"]}"
      report << "Total Runs: #{stats["total_runs"]}"
      report << "Total Failures: #{stats["total_failures"]}"
      report << "Average Failure Rate: #{(stats["average_failure_rate"] * 100).round(2)}%"
      report << ""

      if flaky_tests.any?
        report << "=== Flaky Tests (#{stats["flaky_tests"]}) ==="
        flaky_tests.each do |test_key, metrics|
          failure_rate = (metrics["failures"].to_f / metrics["runs"] * 100).round(2)
          report << "- #{test_key}"
          report << "  Failure Rate: #{failure_rate}% (#{metrics["failures"]}/#{metrics["runs"]} runs)"
          report << "  Location: #{metrics["file_path"]}:#{metrics["line_number"]}"
        end
        report << ""
      end

      if slow_tests.any?
        report << "=== Slow Tests (#{stats["slow_tests"]}) ==="
        slow_tests.first(10).each do |test_key, metrics|
          times = metrics["execution_times"].compact
          next if times.empty?

          avg_time = times.sum / times.size.to_f
          report << "- #{test_key}"
          report << "  Average Time: #{avg_time.round(3)}s"
          report << "  Location: #{metrics["file_path"]}:#{metrics["line_number"]}"
        end
      end

      report.join("\n")
    end

    def clear_data!
      @data = {}
      save_tracking_data
    end

    private

    def generate_test_key(example)
      # Create a unique but readable key for the test
      group_description = example.example_group.description
      test_description = example.description
      "#{group_description} > #{test_description}"
    end

    def load_tracking_data
      return {} unless File.exist?(TRACKING_FILE)

      JSON.parse(File.read(TRACKING_FILE))
    rescue JSON::ParserError
      {}
    end

    def save_tracking_data
      File.write(TRACKING_FILE, JSON.pretty_generate(@data))
    rescue => e
      warn "Failed to save test tracking data: #{e.message}"
    end
  end
end

# RSpec configuration
if defined?(RSpec)
  RSpec.configure do |config|
    config.before(:suite) do
      TestReliabilityTracker.initialize!
    end

    config.after(:each) do |example|
      TestReliabilityTracker.track_test(example) unless ENV["DISABLE_TEST_TRACKING"]
    end

    config.after(:suite) do
      unless ENV["DISABLE_TEST_TRACKING"] || ENV["CI"]
        report = TestReliabilityTracker.generate_report
        puts "\n\n#{report}" if ENV["SHOW_RELIABILITY_REPORT"]

        # Save report to file
        report_file = File.join(TestReliabilityTracker::TRACKING_DIR, "last_run_report.txt")
        File.write(report_file, report)
      end
    end
  end
end
