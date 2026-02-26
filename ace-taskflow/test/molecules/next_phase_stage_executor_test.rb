# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/next_phase_stage_executor"

class NextPhaseStageExecutorTest < AceTaskflowTestCase
  def test_call_normalizes_json_payload
    source_body = "# Source content\n"
    llm_calls = []
    executor = Ace::Taskflow::Molecules::NextPhaseStageExecutor.new(
      file_reader: lambda { |path|
        path.include?("simulate-next-phase-") ? "workflow text" : source_body
      },
      model_resolver: -> { "glite" },
      llm_query: lambda { |model, prompt, **kwargs|
        llm_calls << { model: model, prompt: prompt, kwargs: kwargs }
        {
          text: <<~JSON
            {
              "status": "ok",
              "findings": ["F1"],
              "questions": ["Q1"],
              "refinements": ["R1"]
            }
          JSON
        }
      }
    )

    payload = executor.call(
      resolved_source: { input: "285.06", type: "task", path: "/tmp/source.s.md" },
      mode: "plan",
      run_id: "abc123",
      previous_stage_output: { status: "ok", findings: ["draft finding"] }
    )

    assert_equal "ok", payload[:status]
    assert_equal ["F1"], payload[:findings]
    assert_equal ["Q1"], payload[:questions]
    assert_equal ["R1"], payload[:refinements]
    assert_equal "glite", llm_calls.first[:model]
    assert_includes llm_calls.first[:kwargs][:sandbox].to_s, "read-only"
    assert_includes llm_calls.first[:prompt], "draft finding"
  end

  def test_call_parses_semantic_text_response
    executor = Ace::Taskflow::Molecules::NextPhaseStageExecutor.new(
      file_reader: ->(_path) { "workflow and source" },
      model_resolver: -> { "glite" },
      llm_query: lambda { |_model, _prompt, **_kwargs|
        {
          text: <<~TEXT
            Status: partial
            Findings:
            - Missing acceptance check
            Questions:
            - Which test command proves completion?
            Refinements:
            - Add deterministic validation command.
            Unresolved gaps:
            - No rollback detail provided.
          TEXT
        }
      }
    )

    payload = executor.call(
      resolved_source: { input: "285.06", type: "task", path: "/tmp/source.s.md" },
      mode: "draft",
      run_id: "abc123"
    )

    assert_equal "partial", payload[:status]
    assert_equal ["Missing acceptance check"], payload[:findings]
    assert_equal ["Which test command proves completion?"], payload[:questions]
    assert_equal ["Add deterministic validation command."], payload[:refinements]
    assert_equal ["No rollback detail provided."], payload[:unresolved_gaps]
  end

  def test_call_raises_when_llm_response_is_empty
    executor = Ace::Taskflow::Molecules::NextPhaseStageExecutor.new(
      file_reader: ->(_path) { "workflow and source" },
      llm_query: ->(_model, _prompt, **_kwargs) { { text: "   " } }
    )

    error = assert_raises(ArgumentError) do
      executor.call(
        resolved_source: { input: "285.06", type: "task", path: "/tmp/source.s.md" },
        mode: "plan",
        run_id: "abc123"
      )
    end

    assert_includes error.message, "execution failed"
    assert_includes error.message, "empty response"
  end
end
