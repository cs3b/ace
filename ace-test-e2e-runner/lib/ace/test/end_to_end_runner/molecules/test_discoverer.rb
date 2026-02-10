# frozen_string_literal: true

require "pathname"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Discovers E2E test scenario files (*.mt.md and TS-*/scenario.yml) in packages
        #
        # Supports dual-mode discovery:
        # - Legacy: {package}/test/e2e/*.mt.md (MT-format)
        # - New: {package}/test/e2e/TS-*/scenario.yml (TS-format)
        #
        # Note: This is a Molecule (not an Atom) because it performs filesystem
        # I/O via Dir.glob.
        class TestDiscoverer
          # Default pattern for test scenario files
          EXTENSION = ".mt.md"
          TEST_DIR = "test/e2e"
          SCENARIO_FILE = "scenario.yml"
          SCENARIO_DIR_PATTERN = "TS-*"

          # Find E2E test files matching criteria (both MT and TS formats)
          #
          # @param package [String] Package name (e.g., "ace-lint")
          # @param test_id [String, nil] Optional specific test ID (e.g., "MT-LINT-001")
          # @param base_dir [String] Base directory to search from (default: current dir)
          # @return [Array<String>] Sorted list of matching file paths
          def find_tests(package:, test_id: nil, base_dir: Dir.pwd)
            test_ids = test_id ? test_id.split(",").map(&:strip) : [nil]

            mt_files = test_ids
              .flat_map { |id| Dir.glob(build_pattern(package, id, base_dir)) }

            ts_files = test_ids
              .flat_map { |id| Dir.glob(build_scenario_pattern(package, id, base_dir)) }

            (mt_files + ts_files).uniq.sort
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

          # List all packages that have E2E tests (both MT and TS formats)
          #
          # @param base_dir [String] Base directory to search from
          # @return [Array<String>] Sorted list of package names
          def list_packages(base_dir: Dir.pwd)
            mt_pattern = File.join(base_dir, "*/#{TEST_DIR}/*#{EXTENSION}")
            ts_pattern = File.join(base_dir, "*/#{TEST_DIR}/#{SCENARIO_DIR_PATTERN}/#{SCENARIO_FILE}")

            mt_packages = Dir.glob(mt_pattern)
              .map { |f| Pathname.new(f).relative_path_from(base_dir).each_filename.first }

            ts_packages = Dir.glob(ts_pattern)
              .map { |f| Pathname.new(f).relative_path_from(base_dir).each_filename.first }

            (mt_packages + ts_packages).uniq.sort
          end

          private

          # Build glob pattern for finding MT-format test files
          def build_pattern(package, test_id, base_dir)
            test_dir = File.join(base_dir, package, TEST_DIR)

            if test_id
              File.join(test_dir, "*#{test_id}*#{EXTENSION}")
            else
              File.join(test_dir, "*#{EXTENSION}")
            end
          end

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
