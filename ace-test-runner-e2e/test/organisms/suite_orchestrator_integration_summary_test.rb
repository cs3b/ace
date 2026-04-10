# frozen_string_literal: true

require "minitest/autorun"
require "stringio"

require "ace/test/end_to_end_runner/models/test_result"
require "ace/test/end_to_end_runner/organisms/suite_orchestrator"

module Ace
  module Test
    module EndToEndRunner
      module Organisms
        class SuiteOrchestratorIntegrationSummaryTest < Minitest::Test
          def setup
            @orchestrator = SuiteOrchestrator.allocate
          end

          def test_summarize_integration_results_accumulates_file_and_case_counts
            result = Models::TestResult.new(
              test_id: "INTEGRATION",
              status: "pass",
              test_cases: [
                {id: "TC-001", status: "pass"},
                {id: "TC-002", status: "pass"},
                {id: "TC-003", status: "fail"}
              ],
              metadata: {
                "package" => "ace-b36ts",
                "files_total" => 2,
                "files_passed" => 1
              }
            )

            summary = @orchestrator.send(:summarize_integration_results, [result])

            assert_equal 1, summary[:total]
            assert_equal 1, summary[:passed]
            assert_equal 2, summary[:files_total]
            assert_equal 1, summary[:files_passed]
            assert_equal 3, summary[:total_cases]
            assert_equal 2, summary[:passed_cases]
          end

          def test_integration_only_results_use_file_totals
            result = Models::TestResult.new(
              test_id: "INTEGRATION",
              status: "pass",
              test_cases: [
                {id: "TC-001", status: "pass"},
                {id: "TC-002", status: "pass"}
              ],
              metadata: {
                "package" => "ace-b36ts",
                "files_total" => 1,
                "files_passed" => 1
              }
            )

            summary = @orchestrator.send(:integration_only_results, [result])

            assert_equal 1, summary[:total]
            assert_equal 1, summary[:passed]
            assert_equal 2, summary[:total_cases]
            assert_equal 2, summary[:passed_cases]
          end
        end
      end
    end
  end
end
