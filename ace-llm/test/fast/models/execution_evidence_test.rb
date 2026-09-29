# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/llm/models/execution_evidence"

module Ace
  module LLM
    module Models
      class ExecutionEvidenceTest < AceLlmTestCase
        def test_rejects_unknown_outcome
          assert_raises(ArgumentError) do
            ExecutionEvidence.new(outcome: :banana)
          end
        end

        def test_uncertain_execution_reflects_whether_execution_began
          deadline = ExecutionEvidence.new(outcome: :deadline_exceeded, elapsed_seconds: 300)

          assert deadline.uncertain_execution?

          spawn = ExecutionEvidence.new(outcome: :transport_failure, execution_began: false)

          refute spawn.uncertain_execution?
        end

        def test_summary_includes_observed_facts_only
          evidence = ExecutionEvidence.new(
            outcome: :deadline_exceeded,
            invocation_id: "abcd1234",
            provider_name: "Codex",
            deadline_seconds: 300,
            elapsed_seconds: 300.42
          )

          assert_equal "deadline_exceeded, elapsed 300.4s, deadline 300.0s, invocation abcd1234", evidence.summary
        end

        def test_summary_for_nonzero_exit
          evidence = ExecutionEvidence.new(outcome: :nonzero_exit, exit_status: 3)

          assert_equal "nonzero_exit, exit 3", evidence.summary
        end

        def test_excerpts_are_bounded
          evidence = ExecutionEvidence.new(
            outcome: :nonzero_exit,
            stdout_excerpt: "x" * 5000,
            stderr_excerpt: "y" * 2000
          )

          assert_equal ExecutionEvidence::EXCERPT_LIMIT + "…[truncated]".length, evidence.stdout_excerpt.length
          assert_equal 2000, evidence.stderr_excerpt.length
        end

        def test_to_h_omits_excerpts_and_nil_fields
          evidence = ExecutionEvidence.new(outcome: :nonzero_exit, exit_status: 2)
          hash = evidence.to_h

          assert_nil hash[:stdout_excerpt]
          assert_nil hash[:invocation_id]
          assert_equal 2, hash[:exit_status]
          assert_equal true, hash[:execution_began]
        end

        def test_from_h_restores_outcome_and_facts
          evidence = ExecutionEvidence.new(
            outcome: :no_response,
            invocation_id: "abcd1234",
            exit_status: 0,
            execution_began: true
          )
          restored = ExecutionEvidence.from_h(evidence.to_h)

          assert_equal :no_response, restored.outcome
          assert_equal "abcd1234", restored.invocation_id
          assert restored.uncertain_execution?
        end

        def test_from_h_returns_nil_for_unknown_or_missing_outcome
          assert_nil ExecutionEvidence.from_h({"outcome" => "nonsense"})
          assert_nil ExecutionEvidence.from_h(nil)
        end

        def test_excerpts_redact_credential_shapes
          evidence = ExecutionEvidence.new(
            outcome: :nonzero_exit,
            stderr_excerpt: "auth failed for Bearer sk-proj-abcdefghij1234567890 with api_key=ApiKeySuperSecret99"
          )

          refute_includes evidence.stderr_excerpt, "sk-proj-abcdefghij1234567890"
          refute_includes evidence.stderr_excerpt, "ApiKeySuperSecret99"
          assert_includes evidence.stderr_excerpt, "[redacted]"
          assert_includes evidence.stderr_excerpt, "auth failed for"
        end

        def test_redact_leaves_normal_output_untouched
          output = "Bundle complete! 48 Gemfile dependencies, 73 gems now installed."

          assert_equal output, ExecutionEvidence.redact(output)
        end
      end
    end
  end
end
