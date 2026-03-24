# frozen_string_literal: true

require "date"
require "fileutils"
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
            - Save all artifacts to results/tc/{NN}/ directories as specified
            - Treat the initial working directory as SANDBOX_ROOT; if a goal needs commands in a created worktree, cd there for execution but keep artifact writes under SANDBOX_ROOT/results
            - Do not fabricate output - all artifacts must come from real tool execution
            - If a goal fails, note the failure and continue to the next goal
            - After all goals, output a brief summary of what you produced for each goal
          PROMPT

          VERIFIER_SYSTEM_PROMPT = <<~PROMPT
            You are an E2E test verifier. You inspect artifacts and render PASS/FAIL verdicts.

            Rules:
            - Evaluate each goal independently based solely on the artifacts provided
            - Do not speculate about what the runner did - only judge what exists
            - For each failed goal, include a category:
              test-spec-error | tool-bug | runner-error | infrastructure-error
            - For each goal, cite specific evidence (filenames, content snippets)
            - Follow the output format exactly
          PROMPT

          # @param scenario [Models::TestScenario]
          # @param sandbox_path [String]
          # @param test_cases [Array<String>, nil]
          # @return [Hash]
          def prepare_runner(scenario:, sandbox_path:, test_cases: nil)
            cache_dir = ensure_cache_dir(sandbox_path)
            system_path = File.join(cache_dir, "runner-system.md")
            prompt_path = File.join(cache_dir, "runner-prompt.md")

            File.write(system_path, RUNNER_SYSTEM_PROMPT)

            bundled = bundle_markdown_file(File.join(scenario.dir_path, "runner.yml.md"), test_cases: test_cases)
            bundled = bundled.gsub("Workspace root: (current directory)", "Workspace root: #{File.expand_path(sandbox_path)}")
            File.write(prompt_path, bundled)

            {
              system_path: system_path,
              prompt_path: prompt_path,
              output_path: File.join(cache_dir, "runner-output.md")
            }
          end

          # @param scenario [Models::TestScenario]
          # @param sandbox_path [String]
          # @param test_cases [Array<String>, nil]
          # @return [Hash]
          def prepare_verifier(scenario:, sandbox_path:, test_cases: nil)
            cache_dir = ensure_cache_dir(sandbox_path)
            system_path = File.join(cache_dir, "verifier-system.md")
            prompt_path = File.join(cache_dir, "verifier-prompt.md")

            File.write(system_path, VERIFIER_SYSTEM_PROMPT)

            artifacts = build_artifact_section(sandbox_path)
            criteria = bundle_markdown_file(File.join(scenario.dir_path, "verifier.yml.md"), test_cases: test_cases)
            File.write(prompt_path, [artifacts, criteria].join("\n\n---\n\n"))

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
