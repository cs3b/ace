# frozen_string_literal: true

require "date"
require "yaml"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Loads a TS-format scenario directory into TestScenario + TestCase models
        #
        # Reads scenario.yml for metadata and setup steps, discovers TC-*.tc.md
        # files for independent test cases, and returns a fully populated
        # TestScenario model.
        #
        # Note: This is a Molecule (not an Atom) because it performs filesystem
        # I/O via File.read, File.exist?, and Dir.glob.
        class ScenarioLoader
          # Load a scenario directory
          #
          # @param scenario_dir [String] Path to the TS-* scenario directory
          # @return [Models::TestScenario] Populated test scenario
          # @raise [ArgumentError] If scenario.yml is missing, invalid, or has missing required fields
          def load(scenario_dir)
            yml_path = File.join(scenario_dir, "scenario.yml")
            raise ArgumentError, "scenario.yml not found: #{yml_path}" unless File.exist?(yml_path)

            frontmatter = parse_scenario_yml(yml_path)
            validate_scenario!(frontmatter, yml_path)

            test_cases = discover_test_cases(scenario_dir)
            fixture_path = detect_fixture_path(scenario_dir)

            Models::TestScenario.new(
              test_id: frontmatter["test-id"],
              title: frontmatter["title"],
              area: frontmatter["area"],
              package: frontmatter["package"] || infer_package(scenario_dir),
              priority: frontmatter["priority"] || "medium",
              duration: frontmatter["duration"] || "~5min",
              requires: frontmatter["requires"] || {},
              file_path: File.expand_path(yml_path),
              content: File.read(yml_path),
              setup_steps: frontmatter["setup"] || [],
              dir_path: File.expand_path(scenario_dir),
              fixture_path: fixture_path,
              test_cases: test_cases
            )
          end

          private

          # Parse scenario.yml with safe YAML loading
          #
          # @param path [String] Path to scenario.yml
          # @return [Hash] Parsed YAML frontmatter
          # @raise [ArgumentError] If YAML is invalid or empty
          def parse_scenario_yml(path)
            content = File.read(path)
            result = YAML.safe_load(content, permitted_classes: [Date])
            raise ArgumentError, "Empty or invalid YAML in #{path}" if result.nil?
            result
          rescue Psych::SyntaxError => e
            raise ArgumentError, "Invalid YAML in #{path}: #{e.message}"
          end

          # Validate required fields in scenario frontmatter
          #
          # @param frontmatter [Hash] Parsed scenario.yml
          # @param path [String] File path for error messages
          # @raise [ArgumentError] If required fields are missing
          def validate_scenario!(frontmatter, path)
            required = %w[test-id title area]
            missing = required.reject { |field| frontmatter&.key?(field) }
            unless missing.empty?
              raise ArgumentError, "Missing required fields in #{path}: #{missing.join(', ')}"
            end
          end

          # Discover and parse TC-*.tc.md files in the scenario directory
          #
          # @param scenario_dir [String] Path to the scenario directory
          # @return [Array<Models::TestCase>] Parsed test case models, sorted by filename
          def discover_test_cases(scenario_dir)
            tc_files = Dir.glob(File.join(scenario_dir, "TC-*.tc.md")).sort
            tc_files.map { |file| parse_test_case(file) }
          end

          # Parse a single TC-*.tc.md file
          #
          # @param file_path [String] Path to the .tc.md file
          # @return [Models::TestCase] Parsed test case
          # @raise [ArgumentError] If frontmatter is missing or invalid
          def parse_test_case(file_path)
            content = File.read(file_path)
            match = content.match(/\A---\s*\r?\n(.*?)\r?\n---\s*\r?\n(.*)\z/m)
            raise ArgumentError, "No frontmatter found in: #{file_path}" unless match

            frontmatter = YAML.safe_load(match[1], permitted_classes: [Date])
            body = match[2]

            unless frontmatter&.key?("tc-id") && frontmatter&.key?("title")
              raise ArgumentError, "Missing tc-id or title in: #{file_path}"
            end

            Models::TestCase.new(
              tc_id: frontmatter["tc-id"],
              title: frontmatter["title"],
              content: body,
              file_path: File.expand_path(file_path),
              pending: frontmatter["pending"]
            )
          end

          # Detect fixtures directory if it exists
          #
          # @param scenario_dir [String] Path to the scenario directory
          # @return [String, nil] Absolute path to fixtures/ or nil
          def detect_fixture_path(scenario_dir)
            path = File.join(scenario_dir, "fixtures")
            Dir.exist?(path) ? File.expand_path(path) : nil
          end

          # Infer package name from scenario directory path
          #
          # @param scenario_dir [String] Path to scenario directory
          # @return [String] Inferred package name
          def infer_package(scenario_dir)
            # Expected path: {package}/test/e2e/TS-{AREA}-{NNN}-{slug}/
            parts = File.expand_path(scenario_dir).split("/")
            parts.each_with_index do |part, idx|
              next unless part == "test" && idx > 0 && parts[idx + 1] == "e2e"

              return parts[idx - 1]
            end

            "unknown"
          end
        end
      end
    end
  end
end
