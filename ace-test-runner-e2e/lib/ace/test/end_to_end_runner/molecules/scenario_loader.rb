# frozen_string_literal: true

require "date"
require "yaml"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Loads a TS-format scenario directory into TestScenario + TestCase models
        #
        # Reads scenario.yml for metadata and setup steps, discovers test case
        # files (`TC-*.tc.md` for procedural/inline goal mode or standalone
        # `TC-*.runner.md` + `TC-*.verify.md` for goal mode), and returns a fully populated
        # TestScenario model.
        #
        # Note: This is a Molecule (not an Atom) because it performs filesystem
        # I/O via File.read, File.exist?, and Dir.glob.
        class ScenarioLoader
          VALID_MODES = %w[procedural goal].freeze
          VALID_EXECUTION_MODELS = %w[isolated sequential].freeze
          VALID_TC_MODES = %w[procedural goal].freeze

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

            mode = parse_mode(frontmatter["mode"])
            test_cases = discover_test_cases(scenario_dir, mode: mode)
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
              test_cases: test_cases,
              tags: parse_tags(frontmatter["tags"]),
              mode: mode,
              execution_model: parse_execution_model(frontmatter["execution-model"]),
              tool_under_test: frontmatter["tool-under-test"],
              sandbox_layout: frontmatter["sandbox-layout"] || {}
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

            mode = frontmatter["mode"] || "procedural"
            unless VALID_MODES.include?(mode)
              raise ArgumentError, "Invalid mode '#{mode}' in #{path}. Expected: #{VALID_MODES.join(', ')}"
            end

            execution_model = frontmatter["execution-model"] || "isolated"
            unless VALID_EXECUTION_MODELS.include?(execution_model)
              raise ArgumentError,
                    "Invalid execution-model '#{execution_model}' in #{path}. " \
                    "Expected: #{VALID_EXECUTION_MODELS.join(', ')}"
            end
          end

          # Discover and parse TC-*.tc.md files in the scenario directory
          #
          # @param scenario_dir [String] Path to the scenario directory
          # @return [Array<Models::TestCase>] Parsed test case models, sorted by filename
          def discover_test_cases(scenario_dir, mode:)
            if mode == "goal"
              discover_goal_mode_test_cases(scenario_dir)
            else
              discover_inline_test_cases(scenario_dir)
            end
          end

          def discover_inline_test_cases(scenario_dir)
            tc_files = Dir.glob(File.join(scenario_dir, "TC-*.tc.md")).sort
            tc_files.map { |file| parse_test_case(file) }
          end

          def discover_goal_mode_test_cases(scenario_dir)
            runner_files = Dir.glob(File.join(scenario_dir, "TC-*.runner.md")).sort
            verify_files = Dir.glob(File.join(scenario_dir, "TC-*.verify.md")).sort

            return discover_inline_test_cases(scenario_dir) if runner_files.empty? && verify_files.empty?

            validate_goal_mode_files!(scenario_dir, runner_files, verify_files)

            runner_by_id = runner_files.to_h { |f| [extract_tc_id_from_standalone_name(f), f] }
            verify_by_id = verify_files.to_h { |f| [extract_tc_id_from_standalone_name(f), f] }

            runner_by_id.keys.sort.map do |tc_id|
              runner_file = runner_by_id.fetch(tc_id)
              verify_file = verify_by_id.fetch(tc_id)
              parse_goal_test_case(tc_id, runner_file, verify_file)
            end
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

            tc_mode = parse_tc_mode(frontmatter["mode"], file_path)
            validate_inline_goal_structure!(body, file_path) if tc_mode == "goal"

            Models::TestCase.new(
              tc_id: frontmatter["tc-id"],
              title: frontmatter["title"],
              content: body,
              file_path: File.expand_path(file_path),
              pending: frontmatter["pending"],
              mode: tc_mode,
              goal_format: (tc_mode == "goal" ? "inline" : nil)
            )
          end

          def parse_goal_test_case(tc_id, runner_file, verify_file)
            runner_content = File.read(runner_file)
            verify_content = File.read(verify_file)

            Models::TestCase.new(
              tc_id: tc_id,
              title: extract_title_from_markdown(runner_content) || tc_id,
              content: build_goal_mode_content(runner_content, verify_content),
              file_path: File.expand_path(runner_file),
              pending: nil,
              mode: "goal",
              goal_format: "standalone"
            )
          end

          def extract_tc_id_from_standalone_name(file_path)
            basename = File.basename(file_path)
            match = basename.match(/\A(TC-\d+[a-z]*)(?:-[^.]+)?\.(?:runner|verify)\.md\z/i)
            return match[1].upcase if match

            raise ArgumentError, "Invalid goal-mode test case filename: #{basename}"
          end

          def extract_title_from_markdown(markdown)
            line = markdown.each_line.find { |l| l.strip.start_with?("#") }
            return nil unless line

            line.sub(/\A#+\s*/, "").strip
          end

          def build_goal_mode_content(runner_content, verify_content)
            <<~CONTENT
              ## Runner

              #{runner_content.rstrip}

              ## Verifier

              #{verify_content.rstrip}
            CONTENT
          end

          def validate_goal_mode_files!(scenario_dir, runner_files, verify_files)
            missing_runner_ids = verify_files
                                 .map { |f| extract_tc_id_from_standalone_name(f) }
                                 .uniq - runner_files.map { |f| extract_tc_id_from_standalone_name(f) }.uniq
            missing_verify_ids = runner_files
                                 .map { |f| extract_tc_id_from_standalone_name(f) }
                                 .uniq - verify_files.map { |f| extract_tc_id_from_standalone_name(f) }.uniq

            unless missing_runner_ids.empty?
              raise ArgumentError,
                    "Missing standalone runner file(s) for: #{missing_runner_ids.join(', ')} in #{scenario_dir}"
            end

            unless missing_verify_ids.empty?
              raise ArgumentError,
                    "Missing standalone verify file(s) for: #{missing_verify_ids.join(', ')} in #{scenario_dir}"
            end

            runner_yml = File.join(scenario_dir, "runner.yml.md")
            verifier_yml = File.join(scenario_dir, "verifier.yml.md")

            raise ArgumentError, "Missing goal-mode file: #{runner_yml}" unless File.exist?(runner_yml)
            raise ArgumentError, "Missing goal-mode file: #{verifier_yml}" unless File.exist?(verifier_yml)
          end

          def parse_tags(raw_tags)
            return [] unless raw_tags

            tags = raw_tags.is_a?(Array) ? raw_tags : [raw_tags]
            tags.map(&:to_s).map(&:strip).reject(&:empty?).map(&:downcase)
          end

          def parse_mode(raw_mode)
            raw_mode || "procedural"
          end

          def parse_tc_mode(raw_mode, file_path)
            mode = raw_mode || "procedural"
            return mode if VALID_TC_MODES.include?(mode)

            raise ArgumentError, "Invalid tc mode '#{mode}' in #{file_path}. Expected: #{VALID_TC_MODES.join(', ')}"
          end

          def parse_execution_model(raw_execution_model)
            raw_execution_model || "isolated"
          end

          def validate_inline_goal_structure!(body, file_path)
            required = [
              "## Objective",
              "## Available Tools",
              "## Success Criteria"
            ]
            missing = required.reject { |heading| body.match?(/^#{Regexp.escape(heading)}\b/i) }
            unless missing.empty?
              raise ArgumentError,
                    "Goal-mode TC missing required section(s) in #{file_path}: #{missing.join(', ')}"
            end

            if body.match?(/^##\s+Steps\b/i)
              raise ArgumentError,
                    "Goal-mode TC must not include '## Steps' in #{file_path}; use success criteria instead"
            end
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
