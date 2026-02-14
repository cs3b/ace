# frozen_string_literal: true

require "pathname"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Discovers E2E test scenario directories (TS-*/scenario.yml) in packages
        #
        # Finds test scenarios in the TS-format directory structure:
        #   {package}/test/e2e/TS-*/scenario.yml
        #
        # Note: This is a Molecule (not an Atom) because it performs filesystem
        # I/O via Dir.glob.
        class TestDiscoverer
          TEST_DIR = "test/e2e"
          SCENARIO_FILE = "scenario.yml"
          SCENARIO_DIR_PATTERN = "TS-*"

          # Find E2E test scenario files matching criteria
          #
          # @param package [String] Package name (e.g., "ace-lint")
          # @param test_id [String, nil] Optional specific test ID (e.g., "TS-LINT-001")
          # @param base_dir [String] Base directory to search from (default: current dir)
          # @return [Array<String>] Sorted list of matching scenario.yml file paths
          def find_tests(package:, test_id: nil, base_dir: Dir.pwd)
            test_ids = test_id ? test_id.split(",").map(&:strip) : [nil]

            test_ids
              .flat_map { |id| Dir.glob(build_scenario_pattern(package, id, base_dir)) }
              .uniq
              .sort
          end

          # Find TS-format scenario directories and load them as TestScenario models
          #
          # @param package [String] Package name
          # @param test_id [String, nil] Optional test ID to filter
          # @param base_dir [String] Base directory to search from
          # @return [Array<Models::TestScenario>] Loaded scenario models with test_cases
          def find_scenarios(package:, test_id: nil, base_dir: Dir.pwd)
            test_dir = File.join(base_dir, package, TEST_DIR)
            pattern = File.join(test_dir, SCENARIO_DIR_PATTERN, SCENARIO_FILE)
            scenario_files = Dir.glob(pattern).sort

            loader = ScenarioLoader.new
            scenarios = scenario_files.map do |yml_path|
              scenario_dir = File.dirname(yml_path)
              loader.load(scenario_dir)
            end

            if test_id
              scenarios.select { |s| s.test_id == test_id }
            else
              scenarios
            end
          end

          # List all packages that have E2E tests
          #
          # @param base_dir [String] Base directory to search from
          # @return [Array<String>] Sorted list of package names
          def list_packages(base_dir: Dir.pwd)
            pattern = File.join(base_dir, "*/#{TEST_DIR}/#{SCENARIO_DIR_PATTERN}/#{SCENARIO_FILE}")

            base = Pathname.new(base_dir)

            Dir.glob(pattern)
              .map { |f| Pathname.new(f).relative_path_from(base).each_filename.first }
              .uniq
              .sort
          end

          private

          # Build glob pattern for finding TS-format scenario.yml files
          def build_scenario_pattern(package, test_id, base_dir)
            test_dir = File.join(base_dir, package, TEST_DIR)

            if test_id
              File.join(test_dir, "*#{test_id}*", SCENARIO_FILE)
            else
              File.join(test_dir, SCENARIO_DIR_PATTERN, SCENARIO_FILE)
            end
          end
        end
      end
    end
  end
end
