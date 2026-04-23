# frozen_string_literal: true

require "date"
require "fileutils"
require "time"
require "yaml"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Prepares deterministic runner/verifier prompt files for pipeline execution.
        class PipelinePromptBundler
          RUNNER_SYSTEM_PROMPT = <<~PROMPT
            You are an E2E test executor working in a sandbox directory.

            Rules:
            - Execute each goal in order
            - Treat the initial working directory as SANDBOX_ROOT; if a goal needs commands in a created worktree, cd there for execution but keep any declared outcome artifacts under SANDBOX_ROOT/results
            - Preserve the sandbox runtime environment; do not reset PATH, HOME, or other provided env vars
            - If `ACE_E2E_SANDBOX_RUNTIME_ROOT` is set, make sure command execution uses `$ACE_E2E_SANDBOX_RUNTIME_ROOT/bin` on PATH in the shell where you run scenario commands
            - Run `ace-*` commands directly; do not wrap them with `timeout`, `env -i`, or other execution wrappers that can change behavior or hide diagnostics
            - Do not bypass the public CLI with repo-local executables such as `./exe/ace-*`, `bin/ace-*`, or `ruby .../exe/ace-*`
            - Do not fabricate output - all artifacts must come from real tool execution
            - Never background commands or start dependent verification captures before the command they verify has completed
            - When a goal requires command captures, keep stdout and stderr separate; do not merge streams and do not use `2>&1`
            - A command capture set is incomplete unless the matching `.stdout`, `.stderr`, and `.exit` files all exist
            - Persist each command's `.stdout`, `.stderr`, and `.exit` files immediately after that command finishes, before starting the next command
            - For commands that establish state, write that command's `.exit` file before running any list/status/fs-check/tmux verification for the same goal
            - When a successful command prints a filesystem path to a generated artifact, copy that artifact into `results/` if the goal asks for supporting evidence from the generated file
            - If a goal fails, note the failure and continue to the next goal
            - Do not create synthetic helper reports or temp input files under results/ unless the scenario explicitly treats them as product outcomes
            - After all goals, return concise runner observations describing what you did and what happened
          PROMPT

          VERIFIER_SYSTEM_PROMPT = <<~PROMPT
            You are an E2E test verifier. You inspect artifacts and render PASS/FAIL verdicts.

            Rules:
            - Evaluate each goal independently based on sandbox state first, then runner observations, then raw debug captures only when needed
            - Treat declared artifacts and helper filenames as hints, not as the source of truth
            - If a helper file is missing or stale, inspect the sandbox directly before failing the goal
            - Use artifact mtimes to detect runner ordering mistakes; if postcondition captures are older than the primary command's stdout/stderr/exit, classify the goal as `runner-error` unless direct sandbox state proves a product failure after the command completed
            - Use read-only commands in the sandbox when they materially improve confidence (for example: git log/status/show, ls/find/cat)
            - Do not speculate beyond the provided sandbox evidence and runner observations
            - For each failed goal, include a category:
              test-spec-error | tool-bug | runner-error | infrastructure-error | missing-artifact
            - For each goal, cite specific evidence (filenames, content snippets)
            - Follow the output format exactly
          PROMPT

          # @param scenario [Models::TestScenario]
          # @param sandbox_path [String]
          # @param test_cases [Array<String>, nil]
          # @return [Hash]
          def prepare_runner(scenario:, sandbox_path:, test_cases: nil, artifact_contract: nil, repair_mode: false)
            cache_dir = ensure_cache_dir(sandbox_path)
            file_prefix = repair_mode ? "runner-repair" : "runner"
            system_path = File.join(cache_dir, "#{file_prefix}-system.md")
            prompt_path = File.join(cache_dir, "#{file_prefix}-prompt.md")

            File.write(system_path, RUNNER_SYSTEM_PROMPT)

            bundled = bundle_markdown_file(File.join(scenario.dir_path, "runner.yml.md"), test_cases: test_cases)
            bundled = bundled.gsub("Workspace root: (current directory)", "Workspace root: #{File.expand_path(sandbox_path)}")
            contract = build_runner_artifact_contract_section(artifact_contract, repair_mode: repair_mode)
            File.write(prompt_path, [bundled, contract].reject(&:empty?).join("\n\n---\n\n"))

            {
              system_path: system_path,
              prompt_path: prompt_path,
              output_path: File.join(cache_dir, "#{file_prefix}-output.md")
            }
          end

          # @param scenario [Models::TestScenario]
          # @param sandbox_path [String]
          # @param test_cases [Array<String>, nil]
          # @return [Hash]
          def prepare_verifier(scenario:, sandbox_path:, test_cases: nil, runner_observations: nil, artifact_contract: nil)
            cache_dir = ensure_cache_dir(sandbox_path)
            system_path = File.join(cache_dir, "verifier-system.md")
            prompt_path = File.join(cache_dir, "verifier-prompt.md")

            File.write(system_path, VERIFIER_SYSTEM_PROMPT)

            project_context = build_project_context_section(scenario)
            sandbox_context = build_sandbox_context_section(sandbox_path)
            artifacts = build_artifact_section(sandbox_path)
            contract = build_artifact_contract_section(artifact_contract)
            observations = build_runner_observation_section(runner_observations)
            criteria = bundle_markdown_file(File.join(scenario.dir_path, "verifier.yml.md"), test_cases: test_cases)
            File.write(prompt_path, [project_context, sandbox_context, artifacts, contract, observations, criteria].join("\n\n---\n\n"))

            {
              system_path: system_path,
              prompt_path: prompt_path,
              output_path: File.join(cache_dir, "verifier-output.md")
            }
          end

          private

          def ensure_cache_dir(sandbox_path)
            cache_dir = File.join(File.expand_path(sandbox_path), ".ace-local", "e2e")
            FileUtils.mkdir_p(cache_dir)
            cache_dir
          end

          def bundle_markdown_file(path, test_cases: nil)
            raw = File.read(path)
            frontmatter, body = split_frontmatter(raw)
            bundle_files = parse_bundle_files(frontmatter, path)
            selected_ids = normalize_selected_ids(test_cases)

            included_paths = bundle_files.select do |entry|
              include_bundle_entry?(entry, selected_ids)
            end

            sections = [body.rstrip]
            included_paths.each do |entry|
              full_path = File.expand_path(entry, File.dirname(path))
              sections << File.read(full_path).rstrip
            end
            sections.reject(&:empty?).join("\n\n---\n\n")
          end

          def split_frontmatter(raw)
            match = raw.match(/\A---\s*\r?\n(.*?)\r?\n---\s*\r?\n(.*)\z/m)
            return [{}, raw] unless match

            parsed = YAML.safe_load(match[1], permitted_classes: [Date]) || {}
            [parsed, match[2]]
          end

          def parse_bundle_files(frontmatter, path)
            files = frontmatter.dig("bundle", "files")
            return [] unless files.is_a?(Array)

            files.map(&:to_s).reject(&:empty?)
          rescue Psych::SyntaxError => e
            raise ArgumentError, "Invalid YAML frontmatter in #{path}: #{e.message}"
          end

          def normalize_selected_ids(test_cases)
            return nil unless test_cases && !test_cases.empty?

            test_cases.map { |tc| tc.to_s.upcase }.to_set
          end

          def include_bundle_entry?(entry, selected_ids)
            return true unless selected_ids

            tc_id = extract_tc_id(entry)
            return true if tc_id.nil?

            selected_ids.include?(tc_id)
          end

          def extract_tc_id(path)
            match = File.basename(path).match(/\A(TC-\d+[a-z]*)/i)
            match ? match[1].upcase : nil
          end

          def build_artifact_section(sandbox_path)
            sandbox_path = File.expand_path(sandbox_path)
            files = Dir.glob(File.join(sandbox_path, "results", "**", "*")).select { |f| File.file?(f) }.sort
            tree_entries = files.map { |f| relative_path(f, sandbox_path) }

            parts = []
            parts << "# Sandbox Artifacts"
            parts << ""
            parts << "## Directory tree"
            parts << "```"
            parts.concat(tree_entries)
            parts << "```"
            parts << ""
            parts << "## File metadata"
            parts << "```"
            files.each do |file|
              parts << "#{relative_path(file, sandbox_path)}\tmtime=#{File.mtime(file).utc.iso8601}"
            end
            parts << "```"
            parts << ""
            parts << "## File contents"
            parts << ""

            files.each do |file|
              parts << "### `#{relative_path(file, sandbox_path)}`"
              parts << "```"
              parts << safe_read(file)
              parts << "```"
              parts << ""
            end

            parts.join("\n").rstrip
          end

          def build_project_context_section(scenario)
            package_root = File.expand_path("../../..", scenario.dir_path)
            source_root = File.expand_path("..", package_root)
            files = [
              File.join(package_root, "README.md"),
              File.join(package_root, "docs", "usage.md"),
              File.join(package_root, "docs", "getting-started.md"),
              File.join(source_root, "CLAUDE.md")
            ].select { |path| File.file?(path) }.first(3)

            parts = []
            parts << "# Project Context"
            parts << ""
            parts << "- Package: `#{scenario.package}`"
            parts << "- Test ID: `#{scenario.test_id}`"
            parts << "- Sandbox profile: `#{scenario.sandbox_profile}`"
            parts << ""

            files.each do |file|
              parts << "## `#{File.basename(file)}`"
              parts << "```"
              parts << safe_read(file)
              parts << "```"
              parts << ""
            end

            parts.join("\n").rstrip
          end

          def build_sandbox_context_section(sandbox_path)
            sandbox_path = File.expand_path(sandbox_path)
            entries = Dir.glob(File.join(sandbox_path, "*"), File::FNM_DOTMATCH)
              .reject { |path| %w[. ..].include?(File.basename(path)) }
              .sort

            parts = []
            parts << "# Sandbox Context"
            parts << ""
            parts << "- Sandbox root: `#{sandbox_path}`"
            parts << "- Inspect the sandbox directly when verifying source-of-truth state."
            parts << ""
            parts << "## Top-level entries"
            parts << "```"
            parts.concat(entries.map { |path| relative_path(path, sandbox_path) })
            parts << "```"

            parts.join("\n").rstrip
          end

          def build_runner_observation_section(runner_observations)
            <<~MARKDOWN.rstrip
              # Runner Observations

              #{runner_observations.to_s.strip.empty? ? "(none provided)" : runner_observations.to_s.strip}
            MARKDOWN
          end

          def build_runner_artifact_contract_section(artifact_contract, repair_mode:)
            return "" if artifact_contract.nil? || artifact_contract.empty?

            parts = []
            parts << "# Artifact Contract"
            parts << ""
            if repair_mode
              parts << "This is a bounded repair pass."
              parts << "- Do not rerun goals whose required artifacts are already complete."
              parts << "- For each goal with missing required artifacts, produce only the missing files."
              parts << "- Prefer the minimal real public command needed to create the missing capture set."
              parts << "- If the missing file is supporting evidence copied from an already-generated real artifact, copy that real artifact into `results/`."
              parts << "- Do not invent content, fabricate captures, or rewrite unrelated artifacts."
            else
              parts << "A goal is not complete unless every required artifact for that goal exists on disk under `results/`."
              parts << "- After finishing each goal, self-check the required artifact list below."
              parts << "- If a required artifact is missing, fix it before moving on."
            end
            parts << ""

            artifact_contract.sort.each do |tc_id, entry|
              parts << "## #{tc_id}"
              parts << ""
              parts << "- Required artifacts: #{format_artifact_list(entry["required_artifacts"])}"
              missing = Array(entry["missing_required_artifacts"])
              unless missing.empty?
                parts << "- Missing required artifacts: #{format_artifact_list(missing)}"
              end
              optional = Array(entry["optional_artifacts"])
              parts << "- Optional artifacts: #{format_artifact_list(optional)}" unless optional.empty?
              parts << ""
            end

            parts.join("\n").rstrip
          end

          def build_artifact_contract_section(artifact_contract)
            return "# Artifact Contract\n\n(no snapshot provided)" if artifact_contract.nil? || artifact_contract.empty?

            parts = []
            parts << "# Artifact Contract"
            parts << ""
            parts << "Use this only as supporting context. Missing helper artifacts may be acceptable when sandbox state still proves the goal."
            parts << ""

            artifact_contract.sort.each do |tc_id, entry|
              parts << "## #{tc_id}"
              parts << ""
              parts << "- Required artifacts: #{format_artifact_list(entry["required_artifacts"])}"
              parts << "- Present required artifacts: #{format_artifact_list(entry["present_required_artifacts"])}"
              parts << "- Missing required artifacts: #{format_artifact_list(entry["missing_required_artifacts"])}"
              parts << "- Optional artifacts: #{format_artifact_list(entry["optional_artifacts"])}"
              parts << "- Present optional artifacts: #{format_artifact_list(entry["present_optional_artifacts"])}"
              parts << ""
            end

            parts.join("\n").rstrip
          end

          def format_artifact_list(paths)
            items = Array(paths)
            return "(none)" if items.empty?

            items.map { |path| "`#{path}`" }.join(", ")
          end

          def relative_path(path, root)
            File.expand_path(path).sub("#{File.expand_path(root)}/", "")
          end

          def safe_read(path)
            File.binread(path).encode("UTF-8", invalid: :replace, undef: :replace, replace: "?")
          end
        end
      end
    end
  end
end
