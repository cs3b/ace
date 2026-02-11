# frozen_string_literal: true

require "date"
require "yaml"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Parses .mt.md test scenario files into TestScenario models
        #
        # Extracts YAML frontmatter and markdown content from test scenario files.
        #
        # Note: This is a Molecule (not an Atom) because it performs filesystem
        # I/O via File.read and File.exist?.
        class ScenarioParser
          # Parse a test scenario file
          #
          # @param file_path [String] Path to the .mt.md file
          # @return [Models::TestScenario] Parsed test scenario
          # @raise [ArgumentError] If file does not exist or has invalid frontmatter
          def parse(file_path)
            raise ArgumentError, "File not found: #{file_path}" unless File.exist?(file_path)

            # TS-format: scenario.yml files delegate to ScenarioLoader
            if File.basename(file_path) == "scenario.yml"
              return ScenarioLoader.new.load(File.dirname(file_path))
            end

            content = File.read(file_path)
            frontmatter, body = extract_frontmatter(content)

            raise ArgumentError, "No frontmatter found in: #{file_path}" if frontmatter.nil?

            validate_frontmatter!(frontmatter, file_path)

            Models::TestScenario.new(
              test_id: frontmatter["test-id"],
              title: frontmatter["title"],
              area: frontmatter["area"],
              package: frontmatter["package"] || infer_package(file_path),
              priority: frontmatter["priority"] || "medium",
              duration: frontmatter["duration"] || "~5min",
              requires: frontmatter["requires"] || {},
              file_path: File.expand_path(file_path),
              content: body
            )
          end

          private

          # Extract YAML frontmatter and body from markdown content
          #
          # @param content [String] File content
          # @return [Array<Hash, String>] Frontmatter hash and body string
          def extract_frontmatter(content)
            match = content.match(/\A---\s*\n(.*?)\n---\s*\n(.*)\z/m)
            return [nil, content] unless match

            frontmatter = YAML.safe_load(match[1], permitted_classes: [Date])
            [frontmatter, match[2]]
          end

          # Validate required frontmatter fields
          #
          # @param frontmatter [Hash] Parsed frontmatter
          # @param file_path [String] File path for error messages
          # @raise [ArgumentError] If required fields are missing
          def validate_frontmatter!(frontmatter, file_path)
            required = %w[test-id title area]
            missing = required.reject { |field| frontmatter.key?(field) }
            unless missing.empty?
              raise ArgumentError, "Missing required frontmatter in #{file_path}: #{missing.join(', ')}"
            end
          end

          # Infer package name from file path
          #
          # @param file_path [String] Path to test file
          # @return [String] Inferred package name
          def infer_package(file_path)
            # Expected path: {package}/test/e2e/{file}.mt.md
            parts = file_path.split("/")
            test_idx = parts.index("test")
            return "unknown" unless test_idx && test_idx > 0

            parts[test_idx - 1]
          end
        end
      end
    end
  end
end
