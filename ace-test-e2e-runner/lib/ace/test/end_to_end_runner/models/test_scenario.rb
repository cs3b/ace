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
                      :requires, :file_path, :content

          # @param test_id [String] Test identifier (e.g., "MT-LINT-001")
          # @param title [String] Test title
          # @param area [String] Test area (e.g., "lint")
          # @param package [String] Package name (e.g., "ace-lint")
          # @param priority [String] Priority level (default: "medium")
          # @param duration [String] Expected duration (default: "~5min")
          # @param requires [Hash] Required tools and versions
          # @param file_path [String] Absolute path to the .mt.md file
          # @param content [String] Full markdown content of the test file
          def initialize(test_id:, title:, area:, package:, file_path:, content:,
                         priority: "medium", duration: "~5min", requires: {})
            @test_id = test_id
            @title = title
            @area = area
            @package = package
            @priority = priority
            @duration = duration
            @requires = requires
            @file_path = file_path
            @content = content
          end

          # Generate short package name (without ace- prefix)
          # @return [String] Short package name (e.g., "lint" from "ace-lint")
          def short_package
            package.sub(/\Aace-/, "")
          end

          # Generate short test ID for directory naming
          # @return [String] Short ID (e.g., "mt001" from "MT-LINT-001")
          def short_id
            match = test_id.match(/MT-[A-Z]+-(\d+)/)
            return "mt#{match[1]}" if match

            test_id.downcase.gsub(/[^a-z0-9]/, "")
          end

          # Build a directory name for sandbox/reports
          # @param timestamp [String] Timestamp ID (6-char Base36)
          # @return [String] Directory name (e.g., "8xyz12-lint-mt001")
          def dir_name(timestamp)
            "#{timestamp}-#{short_package}-#{short_id}"
          end
        end
      end
    end
  end
end
