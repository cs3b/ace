# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Models
        # Data model representing a parsed E2E test scenario (.mt.md file)
        #
        # Contains all information extracted from a test scenario file including
        # frontmatter metadata and the full markdown content.
        class TestScenario
          attr_reader :test_id, :title, :area, :package, :priority, :duration,
                      :requires, :file_path, :content,
                      :setup_steps, :dir_path, :fixture_path, :test_cases

          # @param test_id [String] Test identifier (e.g., "MT-LINT-001" or "TS-LINT-001")
          # @param title [String] Test title
          # @param area [String] Test area (e.g., "lint")
          # @param package [String] Package name (e.g., "ace-lint")
          # @param priority [String] Priority level (default: "medium")
          # @param duration [String] Expected duration (default: "~5min")
          # @param requires [Hash] Required tools and versions
          # @param file_path [String] Absolute path to the .mt.md or scenario directory
          # @param content [String] Full markdown content of the test file
          # @param setup_steps [Array] Declarative setup steps from scenario.yml
          # @param dir_path [String, nil] Path to the scenario directory (TS- format)
          # @param fixture_path [String, nil] Path to the fixtures/ directory
          # @param test_cases [Array<Models::TestCase>] Independent test case files (TS- format)
          def initialize(test_id:, title:, area:, package:, file_path:, content:,
                         priority: "medium", duration: "~5min", requires: {},
                         setup_steps: [], dir_path: nil, fixture_path: nil, test_cases: [])
            @test_id = test_id
            @title = title
            @area = area
            @package = package
            @priority = priority
            @duration = duration
            @requires = requires
            @file_path = file_path
            @content = content
            @setup_steps = setup_steps
            @dir_path = dir_path
            @fixture_path = fixture_path
            @test_cases = test_cases
          end

          # Generate short package name (without ace- prefix)
          # @return [String] Short package name (e.g., "lint" from "ace-lint")
          def short_package
            package.sub(/\Aace-/, "")
          end

          # Generate short test ID for directory naming
          # @return [String] Short ID (e.g., "mt001" from "MT-LINT-001", "ts001" from "TS-LINT-001")
          def short_id
            match = test_id.match(/(MT|TS)-[A-Z]+-(\d+[a-z]*)/)
            if match
              prefix = match[1] == "TS" ? "ts" : "mt"
              return "#{prefix}#{match[2]}"
            end

            test_id.downcase.gsub(/[^a-z0-9]/, "")
          end

          # Extract test case IDs from the scenario content or test_cases array
          #
          # For TS- format scenarios, derives IDs from the test_cases array.
          # For MT- format scenarios, delegates to TestCaseParser to find TC-NNN headers.
          #
          # @return [Array<String>] List of test case IDs (e.g., ["TC-001", "TC-002"])
          def test_case_ids
            @test_case_ids ||= if test_cases.any?
                                 test_cases.map(&:tc_id)
                               else
                                 Atoms::TestCaseParser.extract_from_content(content)
                               end
          end

          # Determine the scenario format based on test ID prefix
          # @return [Symbol] :ts for TS- IDs, :mt for MT- IDs
          def scenario_format
            test_id.start_with?("TS-") ? :ts : :mt
          end

          # Build a directory name for sandbox/reports
          # @param timestamp [String] Timestamp ID (7-char Base36)
          # @return [String] Directory name (e.g., "8xyz12-lint-mt001")
          def dir_name(timestamp)
            "#{timestamp}-#{short_package}-#{short_id}"
          end
        end
      end
    end
  end
end
