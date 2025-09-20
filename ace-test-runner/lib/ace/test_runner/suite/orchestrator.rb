# frozen_string_literal: true

require "yaml"
require "open3"

module Ace
  module TestRunner
    module Suite
      class Orchestrator
        attr_reader :config, :packages, :results, :running_processes

        def initialize(config_path = ".ace/test-suite.yml")
          @config_path = config_path
          @config = load_config
          @packages = config.dig("test_suite", "packages") || []
          @results = {}
          @running_processes = {}
          @completed_packages = []
          @waiting_packages = []
          @failed_packages = []
        end

        def run
          validate_packages!

          display_manager = DisplayManager.new(@packages, @config)
          process_monitor = ProcessMonitor.new(@config.dig("test_suite", "max_parallel") || 10)

          # Sort packages by priority
          sorted_packages = @packages.sort_by { |p| p["priority"] || 999 }

          # Initialize display
          display_manager.initialize_display

          # Start processes
          sorted_packages.each do |package|
            process_monitor.start_package(package, @config.dig("test_suite", "test_options") || {}) do |pkg, status, output|
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
          aggregator = ResultAggregator.new(@packages)
          summary = aggregator.aggregate

          display_manager.show_summary(summary)

          # Return exit code based on results
          summary[:packages_failed] > 0 ? 1 : 0
        end

        private

        def load_config
          unless File.exist?(@config_path)
            raise "Configuration file not found: #{@config_path}"
          end

          YAML.load_file(@config_path)
        end

        def validate_packages!
          @packages.each do |package|
            unless Dir.exist?(package["path"])
              raise "Package directory not found: #{package['path']} for #{package['name']}"
            end
          end
        end
      end
    end
  end
end