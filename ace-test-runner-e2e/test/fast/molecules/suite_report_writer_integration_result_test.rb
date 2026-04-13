# frozen_string_literal: true

require "ostruct"
require "tmpdir"
require_relative "../../test_helper"

class SuiteReportWriterIntegrationResultTest < Minitest::Test
  def test_writes_suite_report_when_results_include_integration_phase
    Dir.mktmpdir do |tmpdir|
      integration_report_dir = File.join(tmpdir, "integration-reports")
      scenario_report_dir = File.join(tmpdir, "scenario-reports")
      FileUtils.mkdir_p(integration_report_dir)
      FileUtils.mkdir_p(scenario_report_dir)

      integration_result = Ace::Test::EndToEndRunner::Models::TestResult.new(
        test_id: "INTEGRATION",
        status: "pass",
        test_cases: [{id: "test/integration/sample_test.rb", status: "pass"}],
        summary: "Integration passed",
        report_dir: integration_report_dir,
        metadata: {phase: "integration"}
      )

      scenario_result = Ace::Test::EndToEndRunner::Models::TestResult.new(
        test_id: "TS-DEMO-001",
        status: "pass",
        test_cases: [{id: "TC-001", status: "pass"}],
        summary: "Scenario passed",
        report_dir: scenario_report_dir
      )

      scenario = OpenStruct.new(test_id: "TS-DEMO-001", title: "Demo scenario")
      writer = Ace::Test::EndToEndRunner::Molecules::SuiteReportWriter.new(config: {"reporting" => {"timeout" => 1}})

      Ace::LLM::QueryInterface.define_singleton_method(:query) do |_model, _prompt, **_opts|
        raise StandardError, "offline"
      end
      begin
        report_path = writer.write(
          [integration_result, scenario_result],
          [scenario],
          package: "ace-demo",
          timestamp: "abc123",
          base_dir: tmpdir
        )

        assert File.exist?(report_path)
      ensure
        if Ace::LLM::QueryInterface.singleton_class.method_defined?(:query)
          Ace::LLM::QueryInterface.singleton_class.remove_method(:query)
        end
      end
    end
  end
end
