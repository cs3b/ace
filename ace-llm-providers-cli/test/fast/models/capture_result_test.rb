# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../lib/ace/llm/providers/cli/models/capture_result"

module Ace
  module LLM
    module Providers
      module CLI
        module Models
          class CaptureResultTest < Minitest::Test
            def test_invocation_ids_are_unique_and_opaque
              first = CaptureResult.next_invocation_id
              second = CaptureResult.next_invocation_id

              refute_equal first, second
              assert_match(/\A[A-Za-z0-9]{8}\z/, first)
            end

            def test_completed_success_outcome
              result = CaptureResult.new(
                outcome: CaptureResult::OUTCOME_COMPLETED,
                stdout: "answer",
                stderr: "",
                status: success_status,
                provider_name: "Codex",
                invocation_id: "abcd1234",
                deadline_seconds: 300,
                elapsed_seconds: 12.5
              )

              assert result.success?
              assert result.execution_began?
              assert_equal 0, result.exit_status
              assert_nil result.signal
            end

            def test_completed_nonzero_exit_is_not_success
              result = CaptureResult.new(
                outcome: CaptureResult::OUTCOME_COMPLETED,
                stdout: "",
                stderr: "boom",
                status: failed_status(2),
                provider_name: "Codex"
              )

              refute result.success?
              assert result.execution_began?
              assert_equal 2, result.exit_status
            end

            def test_provider_error_attaches_evidence_with_bounded_excerpts
              result = CaptureResult.new(
                outcome: CaptureResult::OUTCOME_COMPLETED,
                stdout: "a" * 5000,
                stderr: "request timed out while flushing",
                status: failed_status(1),
                provider_name: "Codex",
                invocation_id: "abcd1234",
                deadline_seconds: 300,
                elapsed_seconds: 45.0
              )
              error = result.provider_error

              assert_instance_of Ace::LLM::ProviderError, error
              evidence = error.execution_evidence
              assert_equal :nonzero_exit, evidence.outcome
              assert_equal "abcd1234", evidence.invocation_id
              assert_equal 1, evidence.exit_status
              assert_equal 300, evidence.deadline_seconds
              assert_equal 45.0, evidence.elapsed_seconds
              assert_equal 2000 + "…[truncated]".length, evidence.stdout_excerpt.length
              assert_equal "request timed out while flushing", evidence.stderr_excerpt
            end

            def test_provider_error_message_defaults_by_outcome
              deadline = CaptureResult.new(
                outcome: CaptureResult::OUTCOME_DEADLINE_EXCEEDED,
                provider_name: "Codex",
                deadline_seconds: 300.0,
                elapsed_seconds: 300.4
              )

              assert_match(/Codex CLI execution exceeded its 300\.0s deadline/, deadline.provider_error.message)

              transport = CaptureResult.new(
                outcome: CaptureResult::OUTCOME_TRANSPORT_FAILURE,
                provider_name: "Codex",
                signal: "KILL"
              )

              assert_match(/Codex CLI session ended unexpectedly \(KILL\)/, transport.provider_error.message)

              spawn = CaptureResult.new(
                outcome: CaptureResult::OUTCOME_SPAWN_FAILURE,
                provider_name: "Codex",
                spawn_error: Errno::ENOENT.new("codex")
              )

              assert_match(/Codex CLI could not be started: Errno::ENOENT/, spawn.provider_error.message)

              exit_failure = CaptureResult.new(
                outcome: CaptureResult::OUTCOME_COMPLETED,
                status: failed_status(9),
                provider_name: "Codex"
              )

              assert_match(/Codex CLI failed with exit status 9/, exit_failure.provider_error.message)
            end

            def test_raise_unless_success_passes_through_success
              result = CaptureResult.new(
                outcome: CaptureResult::OUTCOME_COMPLETED,
                status: success_status
              )

              assert_same result, result.raise_unless_success
            end

            def test_raise_unless_success_raises_on_deadline
              result = CaptureResult.new(
                outcome: CaptureResult::OUTCOME_DEADLINE_EXCEEDED,
                provider_name: "Test"
              )

              error = assert_raises(Ace::LLM::ProviderError) { result.raise_unless_success }

              assert_equal :deadline_exceeded, error.execution_evidence.outcome
            end

            def test_spawn_failure_reports_execution_not_begun
              result = CaptureResult.new(
                outcome: CaptureResult::OUTCOME_SPAWN_FAILURE,
                provider_name: "Codex",
                spawn_error: Errno::ENOENT.new("codex")
              )

              refute result.success?
              refute result.execution_began?
              refute result.execution_evidence.uncertain_execution?
            end

            def test_transport_failure_evidence_is_uncertain
              result = CaptureResult.new(
                outcome: CaptureResult::OUTCOME_TRANSPORT_FAILURE,
                stdout: "partial",
                provider_name: "Codex",
                signal: "KILL"
              )

              assert result.execution_began?
              assert_equal :transport_failure, result.execution_evidence.outcome
              assert_equal "KILL", result.execution_evidence.signal
              assert result.execution_evidence.uncertain_execution?
              assert_equal "partial", result.execution_evidence.stdout_excerpt
            end

            def test_with_no_response_evidence_marks_completed_without_response
              result = CaptureResult.new(
                outcome: CaptureResult::OUTCOME_COMPLETED,
                status: success_status,
                provider_name: "Codex",
                invocation_id: "abcd1234"
              )
              error = result.with_no_response_evidence(Ace::LLM::ProviderError.new("no final message"))

              evidence = error.execution_evidence

              assert_equal :no_response, evidence.outcome
              assert_equal "abcd1234", evidence.invocation_id
              assert_equal 0, evidence.exit_status
              assert evidence.uncertain_execution?
            end

            def test_evidence_from_h_roundtrip_without_excerpts
              result = CaptureResult.new(
                outcome: CaptureResult::OUTCOME_DEADLINE_EXCEEDED,
                provider_name: "Codex",
                invocation_id: "abcd1234",
                deadline_seconds: 300,
                elapsed_seconds: 300.2
              )
              evidence = result.execution_evidence
              restored = Ace::LLM::Models::ExecutionEvidence.from_h(evidence.to_h)

              assert_equal evidence.outcome, restored.outcome
              assert_equal evidence.invocation_id, restored.invocation_id
              assert_equal evidence.deadline_seconds, restored.deadline_seconds
              assert_nil restored.stderr_excerpt
            end

            private

            def success_status
              failed_status(0)
            end

            def failed_status(code)
              status = Object.new
              define_status(status, code)
              status
            end

            def define_status(status, code)
              status.define_singleton_method(:success?) { code.zero? }
              status.define_singleton_method(:exitstatus) { code }
              status.define_singleton_method(:termsig) { nil }
              status.define_singleton_method(:exited?) { true }
            end
          end
        end
      end
    end
  end
end
