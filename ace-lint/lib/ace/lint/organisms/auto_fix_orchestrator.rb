# frozen_string_literal: true

require "ace/support/cli"
require "set"
require_relative "../atoms/type_detector"

module Ace
  module Lint
    module Organisms
      # Coordinates deterministic and agent-assisted auto-fix flows.
      class AutoFixOrchestrator
        FIX_CAPABLE_TYPES = [:markdown, :skill, :workflow, :agent, :ruby].freeze
        DEFAULT_PROVIDER_MODEL = "gemini:flash-latest@yolo".freeze

        def initialize(
          orchestrator:,
          lint_options:,
          with_agent:,
          model:,
          file_block_start:,
          file_block_end:,
          no_changes_marker:,
          max_file_bytes:,
          max_total_bytes:
        )
          @orchestrator = orchestrator
          @lint_options = lint_options
          @with_agent = with_agent
          @model = model
          @file_block_start = file_block_start
          @file_block_end = file_block_end
          @no_changes_marker = no_changes_marker
          @max_file_bytes = max_file_bytes
          @max_total_bytes = max_total_bytes
        end

        def run(paths)
          fix_options = @lint_options.merge(fix: true)
          fix_options.delete(:format)

          fixable_paths, lint_only_paths = partition_fixable_paths(paths)
          fixed_results = if fixable_paths.empty?
            []
          else
            @orchestrator.lint_files(fixable_paths, options: fix_options)
          end

          paths_for_final_lint = if lint_only_paths.empty?
            paths
          else
            fixable_paths + lint_only_paths
          end
          lint_results = @orchestrator.lint_files(paths_for_final_lint, options: lint_only_options(@lint_options))
          merged_results = merge_fix_and_lint_results(fixed_results, lint_results)

          return merged_results unless @with_agent

          run_agent_fix(paths, initial_results: merged_results)
        end

        def run_dry_run(paths)
          lint_results = @orchestrator.lint_files(paths, options: lint_only_options(@lint_options))

          issues = collect_issues(lint_results)
          if issues.empty?
            puts "No violations found."
          else
            issues.each do |issue|
              puts "Would attempt to fix: #{issue}"
            end

            file_count = lint_results.select { |result| result.has_errors? || result.has_warnings? }.map(&:file_path).uniq.count
            puts "#{issues.count} issue(s) detected in #{file_count} file(s) during dry-run."
          end

          return unless @with_agent
          return puts "\nNo remaining issues for agent prompt." if lint_results.none? { |result| result.has_errors? || result.has_warnings? }

          prompt = build_agent_prompt(lint_results)
          puts "\nAgent prompt (dry-run):"
          puts prompt
        end

        private

        def run_agent_fix(paths, initial_results:)
          remaining_results = initial_results.select { |result| result.has_errors? || result.has_warnings? }
          if remaining_results.empty?
            puts "\nAll violations resolved by deterministic auto-fix; agent not launched."
            return initial_results
          end

          prompt = build_agent_prompt(remaining_results)
          editable_files = remaining_results.map(&:file_path).uniq.sort
          original_contents = snapshot_file_contents(editable_files)
          provider_model = @model || Ace::Lint.config.dig("lint", "doctor_agent_model") || DEFAULT_PROVIDER_MODEL
          puts "\nLaunching agent to fix remaining violations..."
          warn "[ace-lint] Warning: --auto-fix-with-agent sends full file contents to #{provider_model}."

          ensure_ace_llm_available!

          begin
            response = Ace::LLM::QueryInterface.query(
              provider_model,
              prompt,
              system: nil,
              timeout: 600,
              fallback: false,
              sandbox: "workspace-write",
              working_dir: Dir.pwd
            )
            response_text = response[:text].to_s
            puts response_text unless response_text.empty?

            edits = parse_agent_file_edits(response_text, allowed_files: editable_files)
            if edits.empty?
              raise Ace::Support::Cli::Error.new(
                "Agent returned no editable file blocks (expected #{@file_block_start}path>> ... #{@file_block_end}).",
                exit_code: 2
              )
            end

            changed_files = apply_agent_file_edits(edits, original_contents: original_contents)
            if changed_files.empty?
              raise Ace::Support::Cli::Error.new(
                "Agent response parsed, but no file content changed on disk.",
                exit_code: 2
              )
            end

            puts "Applied agent edits to #{changed_files.count} file(s): #{changed_files.join(", ")}"
          rescue => e
            raise Ace::Support::Cli::Error.new("Agent fix failed: #{e.message}", exit_code: 2)
          end

          @orchestrator.lint_files(paths, options: lint_only_options(@lint_options))
        end

        def build_agent_prompt(results)
          issue_lines = []
          files = Set.new
          total_payload_bytes = 0

          results.each do |result|
            (result.errors + result.warnings).each do |issue|
              severity = issue.severity == :warning ? "WARNING" : "ERROR"
              location = issue.line ? " (#{result.file_path}:#{issue.line})" : " (#{result.file_path})"
              issue_lines << "- [#{severity}] #{issue.message}#{location}"
            end
            files << result.file_path if result.has_errors? || result.has_warnings?
          end

          file_sections = files.to_a.sort.map do |path|
            content = File.exist?(path) ? File.read(path) : "(file missing)"
            if content.bytesize > @max_file_bytes
              raise Ace::Support::Cli::Error.new(
                "Agent fix input too large for #{path} (#{content.bytesize} bytes, max #{@max_file_bytes}).",
                exit_code: 2
              )
            end

            total_payload_bytes += content.bytesize
            if total_payload_bytes > @max_total_bytes
              raise Ace::Support::Cli::Error.new(
                "Agent fix payload exceeds #{@max_total_bytes} bytes; narrow file selection.",
                exit_code: 2
              )
            end

            fence = markdown_fence_for(content)
            <<~SECTION
              ## File: #{path}

              #{fence}text
              #{content}
              #{fence}
            SECTION
          end

          <<~PROMPT
            The following lint issues remain after deterministic auto-fix:

            #{issue_lines.join("\n")}

            Fix the remaining issues in-place in this repository.

            Full content for files with remaining issues:

            #{file_sections.join("\n")}

            Output contract (required):
            - Return one or more full-file replacement blocks using this exact format:
              #{@file_block_start}relative/path>>
              <full updated file content>
              #{@file_block_end}
            - Only include files listed above.
            - Do not wrap response in markdown code fences.
            - If no changes are possible, respond exactly with: #{@no_changes_marker}

            After fixing, run:
            ace-lint #{files.to_a.sort.join(" ")}
          PROMPT
        end

        def ensure_ace_llm_available!
          require "ace/llm"
        rescue LoadError
          raise Ace::Support::Cli::Error.new(
            "--auto-fix-with-agent requires ace-llm gem. Install with: gem install ace-llm",
            exit_code: 2
          )
        end

        def snapshot_file_contents(paths)
          paths.each_with_object({}) do |path, acc|
            acc[path] = File.exist?(path) ? File.read(path) : nil
          end
        end

        def parse_agent_file_edits(response_text, allowed_files:)
          response = response_text.to_s
          return {} if response.strip == @no_changes_marker

          allowed_map = allowed_files.each_with_object({}) do |path, acc|
            normalized = path.sub(%r{\A\./}, "")
            acc[File.expand_path(normalized, Dir.pwd)] = normalized
          end

          edits = {}
          current_path = nil
          current_buffer = []

          response.each_line do |line|
            stripped = line.strip

            if current_path
              if stripped == @file_block_end
                edits[current_path] = current_buffer.join
                current_path = nil
                current_buffer = []
              else
                current_buffer << line
              end
              next
            end

            next unless stripped.start_with?(@file_block_start) && stripped.end_with?(">>")

            raw_path = stripped.delete_prefix(@file_block_start).delete_suffix(">>").strip
            expanded = File.expand_path(raw_path, Dir.pwd)
            resolved_path = allowed_map[expanded]
            unless resolved_path
              raise Ace::Support::Cli::Error.new(
                "Agent attempted to edit unexpected file: #{raw_path}",
                exit_code: 2
              )
            end
            if edits.key?(resolved_path)
              raise Ace::Support::Cli::Error.new(
                "Agent returned duplicate edit block for #{resolved_path}",
                exit_code: 2
              )
            end

            current_path = resolved_path
          end

          if current_path
            raise Ace::Support::Cli::Error.new(
              "Agent response ended before #{@file_block_end}",
              exit_code: 2
            )
          end

          edits
        end

        def apply_agent_file_edits(edits, original_contents:)
          changed_files = []

          edits.each do |path, content|
            next if original_contents[path] == content

            File.write(path, content)
            changed_files << path
          end

          changed_files
        end

        def lint_only_options(options)
          lint_options = options.dup
          lint_options.delete(:fix)
          lint_options.delete(:format)
          lint_options
        end

        def partition_fixable_paths(paths)
          forced_type = @lint_options[:type]
          if forced_type
            return fix_capable_type?(forced_type) ? [paths, []] : [[], paths]
          end

          paths.partition do |path|
            content = begin
              File.read(path)
            rescue
              nil
            end
            type = Ace::Lint::Atoms::TypeDetector.detect(path, content: content)
            fix_capable_type?(type)
          end
        end

        def fix_capable_type?(type)
          FIX_CAPABLE_TYPES.include?(type)
        end

        def markdown_fence_for(content)
          max_backticks = content.to_s.scan(/`+/).map(&:length).max || 0
          "`" * [3, max_backticks + 1].max
        end

        def merge_fix_and_lint_results(fixed_results, lint_results)
          fixed_by_path = fixed_results.each_with_object({}) { |result, acc| acc[result.file_path] = result }
          lint_paths = lint_results.map(&:file_path)
          merged = lint_results.map do |lint_result|
            merge_result = fixed_by_path[lint_result.file_path]
            next lint_result unless merge_result

            merged_errors = lint_result.errors.dup
            merged_warnings = merge_validation_errors(merge_result.warnings, lint_result.warnings)
            merged_errors = merge_validation_errors(merge_result.errors, merged_errors) if merge_result.failed?

            Models::LintResult.new(
              file_path: lint_result.file_path,
              success: merged_errors.empty?,
              errors: merged_errors,
              warnings: merged_warnings,
              formatted: merge_result.formatted? || lint_result.formatted?,
              skipped: lint_result.skipped?,
              skip_reason: lint_result.skip_reason,
              runner: lint_result.runner
            )
          end

          fixed_results.each do |fixed_result|
            next if lint_paths.include?(fixed_result.file_path)

            merged << fixed_result
          end
          merged
        end

        def merge_validation_errors(left, right)
          combined = []
          seen = {}

          (Array(left) + Array(right)).each do |issue|
            key = "#{issue.line}|#{issue.message}|#{issue.severity}"
            next if seen[key]

            seen[key] = true
            combined << issue
          end
          combined
        end

        def collect_issues(results)
          issues = []
          results.each do |result|
            (result.errors + result.warnings).each do |issue|
              location = issue.line ? "#{result.file_path}:#{issue.line}" : result.file_path
              issues << "#{location}: #{issue.message}"
            end
          end
          issues
        end
      end
    end
  end
end
