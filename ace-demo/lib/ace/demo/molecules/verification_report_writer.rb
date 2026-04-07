# frozen_string_literal: true

require "fileutils"
require "json"

module Ace
  module Demo
    module Molecules
      class VerificationReportWriter
        def initialize(base_dir: ".ace-local/demo")
          @base_dir = base_dir
        end

        def write(demo_name:, verification:)
          FileUtils.mkdir_p(@base_dir)
          basename = demo_name.to_s.strip.empty? ? "demo" : demo_name.to_s.strip.gsub(/[^A-Za-z0-9._-]+/, "-")
          markdown_path = File.expand_path(File.join(@base_dir, "#{basename}-error-report.md"), Dir.pwd)
          json_path = markdown_path.sub(/\.md\z/, ".json")

          File.write(markdown_path, markdown_content(verification))
          File.write(json_path, JSON.pretty_generate(json_payload(verification)))
          verification.report_path = markdown_path
          markdown_path
        end

        private

        def markdown_content(verification)
          details = verification.details || {}
          lines = []
          lines << "# Demo Verification Failure"
          lines << ""
          lines << "- Status: `#{verification.status}`"
          lines << "- Classification: `#{verification.classification}`"
          lines << "- Retryable: `#{verification.retryable?}`"
          lines << "- Summary: #{verification.summary}"
          lines << "- Cast: `#{details[:cast_path]}`" if details[:cast_path]
          lines << ""

          append_list(lines, "Missing Commands", verification.commands_missing)
          append_list(lines, "Missing Vars", details[:missing_vars])
          append_hits(lines, "Forbidden Output Hits", details[:forbidden_hits])
          append_assertions(lines, details[:assertion_failures])

          if details[:error]
            lines << "## Error"
            lines << ""
            lines << "```text"
            lines << details[:error].to_s
            lines << "```"
            lines << ""
          end

          lines.join("\n")
        end

        def json_payload(verification)
          {
            status: verification.status,
            classification: verification.classification,
            retryable: verification.retryable?,
            summary: verification.summary,
            commands_found: verification.commands_found,
            commands_missing: verification.commands_missing,
            details: verification.details
          }
        end

        def append_list(lines, title, items)
          return if items.nil? || items.empty?

          lines << "## #{title}"
          lines << ""
          items.each { |item| lines << "- `#{item}`" }
          lines << ""
        end

        def append_hits(lines, title, hits)
          return if hits.nil? || hits.empty?

          lines << "## #{title}"
          lines << ""
          hits.each do |hit|
            lines << "- Pattern: `#{hit[:pattern]}`"
            lines << "  Line: `#{hit[:line]}`"
          end
          lines << ""
        end

        def append_assertions(lines, assertions)
          return if assertions.nil? || assertions.empty?

          lines << "## Assertion Failures"
          lines << ""
          assertions.each do |failure|
            lines << "- Command: `#{failure[:command]}`"
            lines << "  Exit: `#{failure[:exit_code]}`"
            lines << "  Stdout: `#{failure[:stdout]}`" unless failure[:stdout].to_s.empty?
            lines << "  Stderr: `#{failure[:stderr]}`" unless failure[:stderr].to_s.empty?
          end
          lines << ""
        end
      end
    end
  end
end
