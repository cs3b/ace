# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module Ace
  module E2eRunner
    class ReportWriterTest < AceE2eRunnerTestCase
      def test_write_all_creates_reports
        Dir.mktmpdir do |dir|
          result = Models::TestResult.new(
            test_id: "MT-TEST-001",
            status: "pass",
            summary: "ok",
            duration: 1.0,
            package: "ace-test"
          )

          scenario = Models::TestScenario.new(
            id: "MT-TEST-001",
            title: "Sample",
            area: "test",
            package: "ace-test",
            path: "test/e2e/MT-TEST-001.mt.md",
            content: "body",
            frontmatter: {}
          )

          writer = Molecules::ReportWriter.new(report_dir: dir, run_id: "8p3ywe")
          report_map = writer.write_all([result], scenarios: { "MT-TEST-001" => scenario })

          report_dir = report_map["MT-TEST-001"][:report_dir]
          assert File.exist?(File.join(report_dir, "summary.r.md"))
          assert File.exist?(File.join(report_dir, "experience.r.md"))
          assert File.exist?(File.join(report_dir, "metadata.yml"))
        end
      end
    end
  end
end
