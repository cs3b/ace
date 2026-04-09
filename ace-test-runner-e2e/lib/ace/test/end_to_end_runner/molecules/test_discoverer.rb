# frozen_string_literal: true

require "pathname"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Discovers E2E test scenario directories (TS-*/scenario.yml) in packages
        class TestDiscoverer
          SCENARIO_FILE = "scenario.yml"
          SCENARIO_DIR_PATTERN = "TS-*"

          def initialize(config: ConfigLoader.load)
            @config = config || {}
            @scenario_dir = @config.dig("paths", "scenarios") || "test-e2e/scenarios"
            @integration_dir = @config.dig("paths", "integration") || "test-e2e/integration"
            @scenario_pattern = @config.dig("patterns", "discovery") || File.join(@scenario_dir, SCENARIO_DIR_PATTERN, SCENARIO_FILE)
            @integration_pattern = @config.dig("patterns", "integration") || File.join(@integration_dir, "**/*_test.rb")
          end

          # Find E2E test scenario files matching criteria
          #
          # @param package [String] Package name (e.g., "ace-lint")
          # @param test_id [String, nil] Optional specific test ID (e.g., "TS-LINT-001")
          # @param tags [Array<String>, String, nil] Scenario tags to include (OR semantics)
          # @param exclude_tags [Array<String>, String, nil] Scenario tags to exclude (OR semantics)
          # @param base_dir [String] Base directory to search from (default: current dir)
          # @return [Array<String>] Sorted list of matching scenario.yml file paths
          def find_tests(package:, test_id: nil, tags: nil, exclude_tags: nil, base_dir: Dir.pwd)
            test_ids = test_id ? test_id.split(",").map(&:strip) : [nil]
            scenario_files = test_ids
              .flat_map { |id| Dir.glob(build_scenario_pattern(package, id, base_dir)) }
              .uniq
              .sort

            return scenario_files if no_filters?(tags, exclude_tags)

            loader = ScenarioLoader.new
            scenarios = scenario_files.map do |yml_path|
              loader.load(File.dirname(yml_path))
            end

            filter_scenarios(
              scenarios,
              tags: normalize_tags(tags),
              exclude_tags: normalize_tags(exclude_tags)
            ).map(&:file_path).sort
          end

          # Find TS-format scenario directories and load them as TestScenario models
          #
          # @param package [String] Package name
          # @param test_id [String, nil] Optional test ID to filter
          # @param tags [Array<String>, String, nil] Scenario tags to include (OR semantics)
          # @param exclude_tags [Array<String>, String, nil] Scenario tags to exclude (OR semantics)
          # @param base_dir [String] Base directory to search from
          # @return [Array<Models::TestScenario>] Loaded scenario models with test_cases
          def find_scenarios(package:, test_id: nil, tags: nil, exclude_tags: nil, base_dir: Dir.pwd)
            test_dir = File.join(base_dir, package, @scenario_dir)
            pattern = File.join(test_dir, SCENARIO_DIR_PATTERN, SCENARIO_FILE)
            scenario_files = Dir.glob(pattern).sort

            loader = ScenarioLoader.new
            scenarios = scenario_files.map do |yml_path|
              scenario_dir = File.dirname(yml_path)
              loader.load(scenario_dir)
            end

            if test_id
              scenarios = scenarios.select { |s| s.test_id == test_id }
            end

            filter_scenarios(
              scenarios,
              tags: normalize_tags(tags),
              exclude_tags: normalize_tags(exclude_tags)
            )
          end

          # Find sandboxed deterministic integration test files in a package.
          #
          # @param package [String] Package name
          # @param base_dir [String] Base directory to search from
          # @return [Array<String>] Sorted list of matching *_test.rb files
          def find_integration_tests(package:, base_dir: Dir.pwd)
            Dir.glob(File.join(base_dir, package, @integration_pattern))
              .select { |path| File.file?(path) }
              .sort
          end

          # List all packages that have E2E tests
          #
          # @param base_dir [String] Base directory to search from
          # @return [Array<String>] Sorted list of package names
          def list_packages(base_dir: Dir.pwd)
            base = Pathname.new(base_dir)
            scenario_pattern = File.join(base_dir, "*/#{@scenario_pattern}")
            integration_pattern = File.join(base_dir, "*/#{@integration_pattern}")

            Dir.glob(scenario_pattern)
              .concat(Dir.glob(integration_pattern))
              .select { |f| File.file?(f) }
              .map { |f| Pathname.new(f).relative_path_from(base).each_filename.first }
              .uniq
              .sort
          end

          private

          # Build glob pattern for finding TS-format scenario.yml files
          def build_scenario_pattern(package, test_id, base_dir)
            test_dir = File.join(base_dir, package, @scenario_dir)

            if test_id
              File.join(test_dir, "*#{test_id}*", SCENARIO_FILE)
            else
              File.join(test_dir, SCENARIO_DIR_PATTERN, SCENARIO_FILE)
            end
          end

          def no_filters?(tags, exclude_tags)
            normalize_tags(tags).empty? && normalize_tags(exclude_tags).empty?
          end

          def normalize_tags(raw)
            return [] if raw.nil?

            values = raw.is_a?(Array) ? raw : raw.to_s.split(",")
            values.map(&:to_s).map(&:strip).reject(&:empty?).map(&:downcase)
          end

          def filter_scenarios(scenarios, tags:, exclude_tags:)
            filtered = scenarios

            unless tags.empty?
              filtered = filtered.select { |scenario| !(scenario.tags & tags).empty? }
            end

            unless exclude_tags.empty?
              filtered = filtered.reject { |scenario| !(scenario.tags & exclude_tags).empty? }
            end

            filtered
          end
        end
      end
    end
  end
end
