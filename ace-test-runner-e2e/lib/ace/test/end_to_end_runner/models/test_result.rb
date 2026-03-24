# frozen_string_literal: true

module Ace
  module Test
    module EndToEndRunner
      module Models
        # Data model representing the result of an E2E test execution
        #
        # Contains the status, individual test case results, and metadata
        # from executing a test scenario via LLM.
        class TestResult
          attr_reader :test_id, :status, :test_cases, :summary,
            :started_at, :completed_at, :report_dir, :error

          # @param test_id [String] Test identifier
          # @param status [String] Overall status: "pass", "fail", "partial", "error"
          # @param test_cases [Array<Hash>] Individual test case results
          # @param summary [String] Brief execution summary
          # @param started_at [Time] When execution started
          # @param completed_at [Time] When execution completed
          # @param report_dir [String, nil] Path to the reports directory
          # @param error [String, nil] Error message if execution failed
          def initialize(test_id:, status:, test_cases: [], summary: "",
            started_at: nil, completed_at: nil, report_dir: nil, error: nil)
            @test_id = test_id
            @status = status
            @test_cases = test_cases
            @summary = summary
            @started_at = started_at || Time.now
            @completed_at = completed_at || Time.now
            @report_dir = report_dir
            @error = error
          end

          # Check if the test passed
          # @return [Boolean]
          def success?
            status == "pass"
          end

          # Check if the test failed (non-pass, non-skip status)
          # @return [Boolean]
          def failed?
            !success? && !skipped?
          end

          # Check if the test was skipped
          # @return [Boolean]
          def skipped?
            status == "skip"
          end

          # Count of passed test cases
          # @return [Integer]
          def passed_count
            test_cases.count { |tc| tc[:status] == "pass" }
          end

          # Count of failed test cases
          # @return [Integer]
          def failed_count
            test_cases.count { |tc| tc[:status] == "fail" }
          end

          # Total number of test cases
          # @return [Integer]
          def total_count
            test_cases.size
          end

          # IDs of failed test cases
          # @return [Array<String>] List of test case IDs with "fail" status
          def failed_test_case_ids
            test_cases
              .select { |tc| tc[:status] == "fail" }
              .map { |tc| tc[:id] }
          end

          # Duration in seconds
          # @return [Float]
          def duration
            (completed_at - started_at).to_f
          end

          # Return a copy with the report_dir set
          # @param dir [String] Path to the reports directory
          # @return [TestResult] New result with report_dir
          def with_report_dir(dir)
            TestResult.new(
              test_id: test_id,
              status: status,
              test_cases: test_cases,
              summary: summary,
              started_at: started_at,
              completed_at: completed_at,
              report_dir: dir,
              error: error
            )
          end

          # Human-readable duration string
          # @return [String]
          def duration_display
            d = duration
            if d < 60
              "#{d.round(1)}s"
            else
              "#{(d / 60).floor}m #{(d % 60).round(0)}s"
            end
          end
        end
      end
    end
  end
end
