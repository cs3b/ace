# frozen_string_literal: true

require "minitest/autorun"
require "tmpdir"

require "ace/test/end_to_end_runner/molecules/integration_runner"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        class IntegrationRunnerCaseReportingTest < Minitest::Test
          FakeStatus = Struct.new(:success?)

          def setup
            @runner = IntegrationRunner.allocate
          end

          def test_parse_test_cases_preserves_tc_identifiers
            stdout = <<~OUT
              Run options: --verbose --seed 123

              # Running:

              TSB36TS001IntegrationTest#test_tc_001_help_surface = 0.01 s = .
              TSB36TS001IntegrationTest#test_tc_002_encode_timestamp = 0.02 s = F
            OUT

            test_cases = @runner.send(
              :parse_test_cases,
              "test-e2e/integration/ts_b36ts_001_test.rb",
              stdout,
              FakeStatus.new(false),
              "stderr"
            )

            assert_equal %w[TC-001 TC-002], test_cases.map { |test_case| test_case[:id] }
            assert_equal %w[pass fail], test_cases.map { |test_case| test_case[:status] }
          end

          def test_determine_file_status_uses_case_failures
            status = @runner.send(
              :determine_file_status,
              FakeStatus.new(true),
              [
                {id: "TC-001", status: "pass"},
                {id: "TC-002", status: "fail"}
              ]
            )

            assert_equal "fail", status
          end

          def test_parse_test_cases_falls_back_to_file_result_when_stdout_has_no_verbose_rows
            test_cases = @runner.send(
              :parse_test_cases,
              "test-e2e/integration/ts_b36ts_001_test.rb",
              "",
              FakeStatus.new(true),
              ""
            )

            assert_equal 1, test_cases.size
            assert_equal "pass", test_cases.first[:status]
          end
        end
      end
    end
  end
end
