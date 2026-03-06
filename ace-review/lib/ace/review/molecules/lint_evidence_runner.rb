# frozen_string_literal: true

require "open3"
require "time"

module Ace
  module Review
    module Molecules
      # Executes ace-lint and emits a reviewer report consumable by feedback synthesis.
      class LintEvidenceRunner
        LINTABLE_EXTENSIONS = %w[.md .rb .yml .yaml].freeze

        def initialize(project_root: nil)
          @project_root = project_root || Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
        end

        # @param reviewer [Ace::Review::Models::Reviewer]
        # @param session_dir [String]
        # @return [Hash]
        def run(reviewer:, session_dir:)
          started_at = Time.now
          slug = Ace::Review::Atoms::SlugGenerator.generate(reviewer.name || "lint")
          output_file = File.join(session_dir, "review-#{slug}.md")

          files = lint_candidate_files
          stdout = ""
          stderr = ""
          exit_code = 0

          if files.any?
            command = lint_command(files)
            stdout, stderr, status = Open3.capture3(*command, chdir: @project_root)
            exit_code = status.exitstatus
          else
            stdout = "No lint-eligible files were detected from git diff."
          end

          duration = (Time.now - started_at).round(2)
          write_report(
            output_file: output_file,
            reviewer: reviewer,
            files: files,
            exit_code: exit_code,
            stdout: stdout,
            stderr: stderr,
            duration: duration
          )

          {
            success: true,
            output_file: output_file,
            model_slug: slug,
            duration: duration,
            lint_exit_code: exit_code
          }
        rescue StandardError => e
          duration = (Time.now - started_at).round(2)
          File.write(output_file, lint_error_report(reviewer, e)) if output_file

          {
            success: false,
            output_file: output_file,
            duration: duration,
            error: e.message
          }
        end

        private

        def lint_command(files)
          local_binary = File.join(@project_root, "bin", "ace-lint")
          binary = File.exist?(local_binary) ? local_binary : "ace-lint"
          [binary, *files]
        end

        def lint_candidate_files
          files = []
          files.concat(changed_files("origin...HEAD"))
          files.concat(changed_files("HEAD"))

          files
            .uniq
            .select { |path| lintable_path?(path) }
            .select { |path| File.file?(File.join(@project_root, path)) }
            .first(200)
        end

        def changed_files(range)
          stdout, _stderr, status = Open3.capture3("git", "diff", "--name-only", range, chdir: @project_root)
          return [] unless status.success?

          stdout.lines.map(&:strip).reject(&:empty?)
        rescue StandardError
          []
        end

        def lintable_path?(path)
          extension = File.extname(path)
          LINTABLE_EXTENSIONS.include?(extension)
        end

        def write_report(output_file:, reviewer:, files:, exit_code:, stdout:, stderr:, duration:)
          content = +""
          content << "---\n"
          content << "reviewer: #{reviewer.name}\n"
          content << "provider: #{reviewer.provider || 'lint'}\n"
          content << "reviewer_type: tool\n"
          content << "tool: lint\n"
          content << "exit_code: #{exit_code}\n"
          content << "duration_seconds: #{duration}\n"
          content << "timestamp: #{Time.now.iso8601}\n"
          content << "---\n\n"
          content << "# Lint Evidence\n\n"

          if files.any?
            content << "## Files Checked\n"
            files.each { |file| content << "- #{file}\n" }
            content << "\n"
          else
            content << "## Files Checked\n- none\n\n"
          end

          content << "## Findings\n"
          content << "```text\n"
          content << (stdout.to_s.empty? ? "(no output)\n" : stdout)
          content << "```\n\n"

          unless stderr.to_s.empty?
            content << "## stderr\n"
            content << "```text\n"
            content << stderr
            content << "```\n"
          end

          File.write(output_file, content)
        end

        def lint_error_report(reviewer, error)
          <<~MARKDOWN
            ---
            reviewer: #{reviewer&.name || "lint"}
            reviewer_type: tool
            tool: lint
            status: failed
            timestamp: #{Time.now.iso8601}
            ---

            # Lint Evidence Failure

            Failed to collect lint evidence:

            #{error.class}: #{error.message}
          MARKDOWN
        end
      end
    end
  end
end
