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

          writer = Molecules::ReportWriter.new(report_dir: dir, timestamp: "20260204-120000")
          report_dir = writer.write_all([result])

          summary_path = File.join(report_dir, "summary.r.md")
          test_summary = File.join(report_dir, "MT-TEST-001", "summary.r.md")

          assert File.exist?(summary_path)
          assert File.exist?(test_summary)
        end
      end
    end
  end
end
