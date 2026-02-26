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
    captured_system = nil
    captured_user = nil

    # Create a simple mock bundle object
    mock_bundle = Class.new do
      def content
        "Project context"
      end

      def get_section(name)
        if name == "system"
          { content: "System context with workflow instruction including output contract" }
        elsif name == "user"
          { content: "Source Reference: {{source_reference}}\nSource Type: {{source_type}}\n\n--- Source Content ---\n{{source_content}}\n\n--- Previous Stage Output ---\n{{previous_artifact}}" }
        else
          nil
        end
      end
    end.new

    executor = Ace::Taskflow::Molecules::NextPhaseStageExecutor.new(
      file_reader: ->(_path) { "source content text" },
      model_resolver: -> { "glite" },
      bundle_loader: ->(_preset) { mock_bundle },
      llm_query: lambda { |_model, user_prompt, **kwargs|
        captured_user = user_prompt
        captured_system = kwargs[:system]
        { text: "status: ok\nquestions: []\n" }
      }
    )

    executor.call(
      resolved_source: { input: "285.06", type: "task", path: "/tmp/source.s.md" },
      mode: "plan",
      run_id: "abc123"
    )

    # System prompt should contain the workflow instruction with output contract
    assert_includes captured_system, "workflow instruction"
    assert_includes captured_system, "output contract"

    # User prompt should NOT hard-code schema - it's just source content
    refute_includes captured_user, "findings: string[]"
    refute_includes captured_user, "refinements: string[]"
    assert_includes captured_user, "Source Reference: 285.06"
    assert_includes captured_user, "source content text"
  end
end
