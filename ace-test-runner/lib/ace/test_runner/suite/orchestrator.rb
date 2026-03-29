# frozen_string_literal: true

require "open3"
require "pathname"

module Ace
  module TestRunner
    module Suite
      class Orchestrator
        attr_reader :config, :packages, :results, :running_processes

        def initialize(config)
          @config = config
          @packages = config.dig("test_suite", "packages") || []
          @results = {}
          @running_processes = {}
          @completed_packages = []
          @waiting_packages = []
          @failed_packages = []

          # Use ace-config's project root detection
          require "ace/support/config"
          @project_root = Ace::Support::Config.find_project_root

          # Resolve package paths relative to project root
          resolve_package_paths! if @project_root
        end

        def run
          validate_packages!
          test_options = (@config.dig("test_suite", "test_options") || {}).dup
          report_root = normalize_report_root(test_options["report_dir"])
          test_options["report_dir"] = report_root if report_root

          display_manager = create_display_manager
          process_monitor = ProcessMonitor.new(
            @config.dig("test_suite", "max_parallel") || 10,
            package_timeout: @config.dig("test_suite", "timeout")
          )

          # Enrich packages with historical duration data for scheduling
          estimator = DurationEstimator.new(report_root: report_root)
          estimator.enrich_packages(@packages)

          # Sort by expected duration (descending), then priority (ascending)
          # This ensures slowest packages start first, preventing end-of-run bottlenecks
          sorted_packages = @packages.sort_by { |p| [-(p["expected_duration"] || 0), p["priority"] || 999] }

          # Initialize display
          display_manager.initialize_display

          # Start processes
          sorted_packages.each do |package|
            process_monitor.start_package(package, test_options) do |pkg, status, output|
              display_manager.update_package(pkg, status, output)

              if status[:completed]
                @completed_packages << pkg
                @results[pkg["name"]] = status
              end
            end
          end

          # Wait for all processes to complete
          while process_monitor.running?
            process_monitor.check_processes
            display_manager.refresh
            sleep(@config.dig("test_suite", "display", "update_interval") || 0.1)
          end

          # Final display
          display_manager.show_final_results

          # Aggregate results
          aggregator = ResultAggregator.new(@packages, report_root: report_root, runtime_results: @results)
          summary = aggregator.aggregate

          display_manager.show_summary(summary)

          # Return exit code based on results
          (summary[:packages_failed] > 0) ? 1 : 0
        rescue Interrupt
          process_monitor&.stop_all(reason: :interrupt)
          raise
        rescue StandardError
          process_monitor&.stop_all(reason: :error)
          raise
        end

        private

        def validate_packages!
          @packages.each do |package|
            unless Dir.exist?(package["path"])
              raise "Package directory not found: #{package["path"]} for #{package["name"]}"
            end
          end
        end

        def resolve_package_paths!
          @packages.each do |package|
            # If path is relative (doesn't start with /), resolve it relative to project root
            if package["path"] && !package["path"].start_with?("/")
              package["path"] = File.join(@project_root, package["path"])
            end
          end
        end

        # Select display manager based on --progress flag.
        # Default: SimpleDisplayManager (line-by-line, pipe-friendly)
        # With --progress: DisplayManager (animated ANSI progress bars)
        def create_display_manager
          if @config.dig("test_suite", "progress")
            DisplayManager.new(@packages, @config)
          else
            SimpleDisplayManager.new(@packages, @config)
          end
        end

        def normalize_report_root(report_root)
          return nil if report_root.nil? || report_root.to_s.empty?
          return report_root if Pathname.new(report_root).absolute?

          File.expand_path(report_root, @project_root || Dir.pwd)
        end
      end
    end
  end
end
