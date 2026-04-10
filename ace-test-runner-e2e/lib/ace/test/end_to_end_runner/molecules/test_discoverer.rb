# frozen_string_literal: true

require "pathname"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Discovers E2E test scenario directories (TS-*/scenario.yml) in packages
        #
        # Finds test scenarios in the TS-format directory structure:
        #   {package}/test-e2e/scenarios/TS-*/scenario.yml
        # Falls back to legacy:
        #   {package}/test/e2e/TS-*/scenario.yml
        #
        # Note: This is a Molecule (not an Atom) because it performs filesystem
        # I/O via Dir.glob.
        class TestDiscoverer
          TEST_DIR = "test-e2e/scenarios"
          LEGACY_TEST_DIR = "test/e2e"
          SCENARIO_FILE = "scenario.yml"
          SCENARIO_DIR_PATTERN = "TS-*"

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
            test_roots = test_dirs(package, base_dir)
            scenario_files = test_ids
              .flat_map { |id| test_roots.flat_map { |root| Dir.glob(build_scenario_pattern(root, id)) } }
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
            scenario_files = test_dirs(package, base_dir)
              .flat_map { |test_dir| Dir.glob(File.join(test_dir, SCENARIO_DIR_PATTERN, SCENARIO_FILE)) }
              .uniq
              .sort

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

          # List all packages that have E2E tests
          #
          # @param base_dir [String] Base directory to search from
          # @return [Array<String>] Sorted list of package names
          def list_packages(base_dir: Dir.pwd)
            base = Pathname.new(base_dir)
            patterns = [TEST_DIR, LEGACY_TEST_DIR].map do |dir|
              File.join(base_dir, "*/#{dir}/#{SCENARIO_DIR_PATTERN}/#{SCENARIO_FILE}")
            end

            patterns.flat_map { |pattern| Dir.glob(pattern) }
              .map { |f| Pathname.new(f).relative_path_from(base).each_filename.first }
              .uniq
              .sort
          end

          private

          # Build glob pattern for finding TS-format scenario.yml files
          def build_scenario_pattern(test_dir, test_id)
            if test_id
              File.join(test_dir, "*#{test_id}*", SCENARIO_FILE)
            else
              File.join(test_dir, SCENARIO_DIR_PATTERN, SCENARIO_FILE)
            end
          end

          def test_dirs(package, base_dir)
            [TEST_DIR, LEGACY_TEST_DIR].map { |dir| File.join(base_dir, package, dir) }
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
