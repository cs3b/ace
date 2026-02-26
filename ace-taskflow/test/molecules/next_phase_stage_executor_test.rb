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

  def test_call_extracts_artifact_from_yaml_response
    executor = Ace::Taskflow::Molecules::NextPhaseStageExecutor.new(
      file_reader: ->(_path) { "workflow text" },
      model_resolver: -> { "glite" },
      llm_query: lambda { |_model, _prompt, **_kwargs|
        {
          text: <<~YAML
            status: ok
            artifact: |
              # Task: Add retry policy

              ## Description
              Add configurable retry logic to the HTTP client.

              ## Acceptance Criteria
              - Configurable retry count and backoff
            questions: []
          YAML
        }
      }
    )

    payload = executor.call(
      resolved_source: { input: "idea-ref", type: "idea", path: "/tmp/idea.idea.s.md" },
      mode: "draft",
      run_id: "abc123"
    )

    assert_equal "ok", payload[:status]
    assert payload[:artifact], "should have artifact field"
    assert_includes payload[:artifact], "# Task: Add retry policy"
    assert_includes payload[:artifact], "## Description"
    assert_includes payload[:artifact], "## Acceptance Criteria"
  end

  def test_call_passes_previous_artifact_as_readable_text_in_prompt
    captured_prompt = nil
    executor = Ace::Taskflow::Molecules::NextPhaseStageExecutor.new(
      file_reader: ->(_path) { "workflow text" },
      model_resolver: -> { "glite" },
      llm_query: lambda { |_model, prompt, **_kwargs|
        captured_prompt = prompt
        { text: "status: ok\nquestions: []\n" }
      }
    )

    draft_artifact = "# Task: My Draft Spec\n\n## Description\nDo the thing.\n"
    executor.call(
      resolved_source: { input: "285.06", type: "task", path: "/tmp/source.s.md" },
      mode: "plan",
      run_id: "abc123",
      previous_stage_output: {
        status: "ok",
        artifact: draft_artifact,
        questions: ["Some question"]
      }
    )

    assert_includes captured_prompt, "# Task: My Draft Spec"
    assert_includes captured_prompt, "## Description"
    # Should NOT include JSON structure when artifact is present
    refute_includes captured_prompt, '"status"'
    refute_includes captured_prompt, '"questions"'
  end

  def test_call_falls_back_to_json_when_no_artifact_in_previous_output
    captured_prompt = nil
    executor = Ace::Taskflow::Molecules::NextPhaseStageExecutor.new(
      file_reader: ->(_path) { "workflow text" },
      model_resolver: -> { "glite" },
      llm_query: lambda { |_model, prompt, **_kwargs|
        captured_prompt = prompt
        { text: "status: ok\nquestions: []\n" }
      }
    )

    executor.call(
      resolved_source: { input: "285.06", type: "task", path: "/tmp/source.s.md" },
      mode: "plan",
      run_id: "abc123",
      previous_stage_output: { status: "ok", questions: ["prior question"] }
    )

    assert_includes captured_prompt, "prior question"
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

  def test_call_prompt_does_not_hard_code_schema
    captured_prompt = nil
    executor = Ace::Taskflow::Molecules::NextPhaseStageExecutor.new(
      file_reader: ->(_path) { "workflow text" },
      model_resolver: -> { "glite" },
      llm_query: lambda { |_model, prompt, **_kwargs|
        captured_prompt = prompt
        { text: "status: ok\nquestions: []\n" }
      }
    )

    executor.call(
      resolved_source: { input: "285.06", type: "task", path: "/tmp/source.s.md" },
      mode: "plan",
      run_id: "abc123"
    )

    # New prompt defers to the workflow for the output contract, not a hard-coded schema
    refute_includes captured_prompt, "findings: string[]"
    refute_includes captured_prompt, "refinements: string[]"
    assert_includes captured_prompt, "output contract defined in the workflow instruction"
  end
end
