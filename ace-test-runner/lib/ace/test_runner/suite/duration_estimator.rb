# frozen_string_literal: true

require "json"

module Ace
  module TestRunner
    module Suite
      # Estimates expected test duration for packages based on historical data.
      # Used by Orchestrator to schedule slowest packages first, preventing
      # them from becoming bottlenecks at the end of parallel test runs.
      class DurationEstimator
        def initialize(report_root: nil)
          @report_root = report_root
        end

        # Read historical duration from package's latest summary.json
        #
        # @param package [Hash] Package config with "path" key
        # @return [Float, nil] Duration in seconds, or nil if unavailable
        def estimate(package)
          reports_dir = Atoms::ReportPathResolver.report_directory(
            package["path"],
            report_root: @report_root,
            package_name: package["name"]
          )
          return nil unless reports_dir

          summary_file = File.join(reports_dir, "summary.json")
          return nil unless File.exist?(summary_file)

          data = JSON.parse(File.read(summary_file))
          data["duration"]
        rescue JSON::ParserError, Errno::ENOENT, Errno::EACCES
          nil
        end

        # Enrich packages with expected_duration from historical data
        #
        # @param packages [Array<Hash>] Package configs
        # @return [Array<Hash>] Same packages with expected_duration added
        def enrich_packages(packages)
          packages.each do |pkg|
            pkg["expected_duration"] = estimate(pkg) || 0
          end
          packages
        end
      end
    end
  end
end
