# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Models
        # Data model representing a parsed E2E test scenario (TS-*/scenario.yml directory)
        #
        # Contains all information extracted from a test scenario including
        # scenario.yml metadata, test cases, and setup steps.
        class TestScenario
          attr_reader :test_id, :title, :area, :package, :priority, :duration,
                      :requires, :file_path, :content, :timeout,
                      :setup_steps, :dir_path, :fixture_path, :test_cases,
                      :tags, :tool_under_test, :sandbox_layout

          # @param test_id [String] Test identifier (e.g., "TS-LINT-001")
          # @param title [String] Test title
          # @param area [String] Test area (e.g., "lint")
          # @param package [String] Package name (e.g., "ace-lint")
          # @param priority [String] Priority level (default: "medium")
          # @param duration [String] Expected duration (default: "~5min")
          # @param requires [Hash] Required tools and versions
          # @param file_path [String] Absolute path to the scenario directory
          # @param content [String] Full markdown content of the scenario
          # @param timeout [Integer, nil] Optional per-scenario timeout in seconds
          # @param setup_steps [Array] Declarative setup steps from scenario.yml
          # @param dir_path [String, nil] Path to the scenario directory
          # @param fixture_path [String, nil] Path to the fixtures/ directory
          # @param test_cases [Array<Models::TestCase>] Independent test case files
          # @param tags [Array<String>] Scenario-level tags for discovery-time filtering
          # @param tool_under_test [String, nil] Primary tool under test
          # @param sandbox_layout [Hash] Declared sandbox artifact layout
          def initialize(test_id:, title:, area:, package:, file_path:, content:,
                         priority: "medium", duration: "~5min", requires: {},
                         setup_steps: [], dir_path: nil, fixture_path: nil, test_cases: [],
                         timeout: nil, tags: [], tool_under_test: nil,
                         sandbox_layout: {})
            @test_id = test_id
            @title = title
            @area = area
            @package = package
            @priority = priority
            @duration = duration
            @requires = requires
            @file_path = file_path
            @content = content
            @timeout = timeout
            @setup_steps = setup_steps
            @dir_path = dir_path
            @fixture_path = fixture_path
            @test_cases = test_cases
            @tags = tags
            @tool_under_test = tool_under_test
            @sandbox_layout = sandbox_layout
          end

          # Generate short package name (without ace- prefix)
          # @return [String] Short package name (e.g., "lint" from "ace-lint")
          def short_package
            package.sub(/\Aace-/, "")
          end

          # Generate short test ID for directory naming
          # @return [String] Short ID (e.g., "ts001" from "TS-LINT-001")
          def short_id
            match = test_id.match(/TS-[A-Z0-9]+-(\d+[a-z]*)/)
            return "ts#{match[1]}" if match

            test_id.downcase.gsub(/[^a-z0-9]/, "")
          end

          # Extract test case IDs from the test_cases array
          #
          # @return [Array<String>] List of test case IDs (e.g., ["TC-001", "TC-002"])
          def test_case_ids
            @test_case_ids ||= test_cases.map(&:tc_id)
          end

          # Build a directory name for sandbox/reports
          # @param timestamp [String] Timestamp ID (7-char Base36)
          # @return [String] Directory name (e.g., "8xyz12-lint-ts001")
          def dir_name(timestamp)
            "#{timestamp}-#{short_package}-#{short_id}"
          end
        end
      end
    end
  end
end
