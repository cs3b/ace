# frozen_string_literal: true

require "date"
require "yaml"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Loads a TS-format scenario directory into TestScenario + TestCase models.
        #
        # Supported test case format is standalone TC pairs only:
        # - `TC-*.runner.md`
        # - `TC-*.verify.md`
        class ScenarioLoader
          LEGACY_FIELDS = %w[mode execution-model].freeze

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
              timeout: parse_timeout(frontmatter["timeout"], yml_path),
              requires: frontmatter["requires"] || {},
              file_path: File.expand_path(yml_path),
              content: File.read(yml_path),
              setup_steps: frontmatter["setup"] || [],
              dir_path: File.expand_path(scenario_dir),
              fixture_path: fixture_path,
              test_cases: test_cases,
              tags: parse_tags(frontmatter["tags"]),
              tool_under_test: frontmatter["tool-under-test"],
              sandbox_layout: frontmatter["sandbox-layout"] || {}
            )
          end

          private

          # Parse an optional per-scenario timeout in seconds.
          #
          # @param raw_timeout [Object] Raw YAML timeout value
          # @param source_path [String] Source file path for errors
          # @return [Integer, nil] Timeout in seconds
          # @raise [ArgumentError] If timeout is present and invalid
          def parse_timeout(raw_timeout, source_path)
            return nil if raw_timeout.nil?

            value =
              case raw_timeout
              when Integer
                raw_timeout
              when Numeric
                raw_timeout.to_i
              when String
                stripped = raw_timeout.strip
                return nil if stripped.empty?
                raise ArgumentError, "Invalid timeout in #{source_path}: #{raw_timeout.inspect}" unless stripped.match?(/\\A\\d+\\z/)
                stripped.to_i
              else
                raise ArgumentError, "Invalid timeout in #{source_path}: #{raw_timeout.inspect}"
              end

            raise ArgumentError, "Invalid timeout in #{source_path}: must be greater than 0" if value <= 0
            value
          end

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
              raise ArgumentError, "Missing required fields in #{path}: #{missing.join(", ")}"
            end

            legacy = LEGACY_FIELDS.select { |field| frontmatter.key?(field) }
            return if legacy.empty?

            raise ArgumentError,
              "Legacy field(s) not supported in #{path}: #{legacy.join(", ")}. " \
              "Remove these fields; standalone runner/verify scenarios are the only supported format."
          end

          # Discover and parse standalone TC files in the scenario directory.
          #
          # @param scenario_dir [String] Path to the scenario directory
          # @return [Array<Models::TestCase>] Parsed test case models, sorted by TC ID
          def discover_test_cases(scenario_dir)
            runner_files = Dir.glob(File.join(scenario_dir, "TC-*.runner.md")).sort
            verify_files = Dir.glob(File.join(scenario_dir, "TC-*.verify.md")).sort

            if runner_files.empty? && verify_files.empty?
              reject_inline_tc_files!(scenario_dir)
              return []
            end

            validate_standalone_files!(scenario_dir, runner_files, verify_files)

            runner_by_id = runner_files.to_h { |f| [extract_tc_id_from_standalone_name(f), f] }
            verify_by_id = verify_files.to_h { |f| [extract_tc_id_from_standalone_name(f), f] }

            runner_by_id.keys.sort.map do |tc_id|
              runner_file = runner_by_id.fetch(tc_id)
              verify_file = verify_by_id.fetch(tc_id)
              parse_standalone_test_case(tc_id, runner_file, verify_file)
            end
          end

          def reject_inline_tc_files!(scenario_dir)
            inline_files = Dir.glob(File.join(scenario_dir, "TC-*.tc.md")).sort
            return if inline_files.empty?

            raise ArgumentError,
              "Inline TC files are no longer supported in #{scenario_dir}. " \
              "Replace #{inline_files.map { |f| File.basename(f) }.join(", ")} with standalone " \
              "TC-*.runner.md and TC-*.verify.md pairs."
          end

          def parse_standalone_test_case(tc_id, runner_file, verify_file)
            runner_content = File.read(runner_file)
            verify_content = File.read(verify_file)

            Models::TestCase.new(
              tc_id: tc_id,
              title: extract_title_from_markdown(runner_content) || tc_id,
              content: build_standalone_content(runner_content, verify_content),
              file_path: File.expand_path(runner_file),
              pending: nil,
              goal_format: "standalone"
            )
          end

          def extract_tc_id_from_standalone_name(file_path)
            basename = File.basename(file_path)
            match = basename.match(/\A(TC-\d+[a-z]*)(?:-[^.]+)?\.(?:runner|verify)\.md\z/i)
            return match[1].upcase if match

            raise ArgumentError, "Invalid standalone test case filename: #{basename}"
          end

          def extract_title_from_markdown(markdown)
            line = markdown.each_line.find { |l| l.strip.start_with?("#") }
            return nil unless line

            line.sub(/\A#+\s*/, "").strip
          end

          def build_standalone_content(runner_content, verify_content)
            <<~CONTENT
              ## Runner

              #{runner_content.rstrip}

              ## Verifier

              #{verify_content.rstrip}
            CONTENT
          end

          def validate_standalone_files!(scenario_dir, runner_files, verify_files)
            runner_ids = runner_files.map { |f| extract_tc_id_from_standalone_name(f) }.uniq
            verify_ids = verify_files.map { |f| extract_tc_id_from_standalone_name(f) }.uniq

            missing_runner_ids = verify_ids - runner_ids
            missing_verify_ids = runner_ids - verify_ids

            unless missing_runner_ids.empty?
              raise ArgumentError,
                "Missing standalone runner file(s) for: #{missing_runner_ids.join(", ")} in #{scenario_dir}"
            end

            unless missing_verify_ids.empty?
              raise ArgumentError,
                "Missing standalone verify file(s) for: #{missing_verify_ids.join(", ")} in #{scenario_dir}"
            end

            runner_yml = File.join(scenario_dir, "runner.yml.md")
            verifier_yml = File.join(scenario_dir, "verifier.yml.md")

            raise ArgumentError, "Missing standalone file: #{runner_yml}" unless File.exist?(runner_yml)
            raise ArgumentError, "Missing standalone file: #{verifier_yml}" unless File.exist?(verifier_yml)
          end

          def parse_tags(raw_tags)
            return [] unless raw_tags

            tags = raw_tags.is_a?(Array) ? raw_tags : [raw_tags]
            tags.map(&:to_s).map(&:strip).reject(&:empty?).map(&:downcase)
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
            # Expected path: {package}/test-e2e/scenarios/TS-{AREA}-{NNN}-{slug}/
            # Legacy path fallback: {package}/test/e2e/TS-{AREA}-{NNN}-{slug}/
            parts = File.expand_path(scenario_dir).split("/")
            parts.each_with_index do |part, idx|
              if part == "test-e2e" && idx > 0 && parts[idx + 1] == "scenarios"
                return parts[idx - 1]
              end
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
