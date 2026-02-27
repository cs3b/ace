# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/next_phase_stage_executor"

class NextPhaseStageExecutorTest < AceTaskflowTestCase
  def test_call_normalizes_json_payload
    source_body = "# Source content\n"
    llm_calls = []
    executor = build_executor(
      source_body: source_body,
      llm_response: <<~JSON,
        {
          "status": "ok",
          "findings": ["F1"],
          "questions": ["Q1"],
          "refinements": ["R1"]
        }
      JSON
      llm_calls: llm_calls
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
    executor = build_executor(
      source_body: "idea content",
      llm_response: <<~YAML
        status: ok
        artifact: |
          # Task: Add retry policy

          ## Description
          Add configurable retry logic to the HTTP client.

          ## Acceptance Criteria
          - Configurable retry count and backoff
        questions: []
      YAML
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
    executor = build_executor(
      source_body: "source content",
      llm_response: "status: ok\nquestions: []\n",
      capture_prompt: ->(prompt) { captured_prompt = prompt }
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
    executor = build_executor(
      source_body: "source content",
      llm_response: "status: ok\nquestions: []\n",
      capture_prompt: ->(prompt) { captured_prompt = prompt }
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
    executor = build_executor(
      source_body: "source content",
      llm_response: <<~TEXT
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
    executor = build_executor(
      source_body: "source content",
      llm_response: "   "
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

  def test_call_generates_bundle_config_with_project_preset_and_workflow
    captured_config_path = nil
    executor = build_executor(
      source_body: "source content",
      llm_response: "status: ok\nquestions: []\n",
      capture_config_path: ->(path) { captured_config_path = path }
    )

    payload = executor.call(
      resolved_source: { input: "285.06", type: "task", path: "/tmp/source.s.md" },
      mode: "draft",
      run_id: "abc123"
    )

    # Verify bundle config content
    config = payload[:bundle_config]
    assert config, "should include bundle_config in payload"
    assert_includes config, "presets:"
    assert_includes config, "- project"
    assert_includes config, "ace-taskflow/handbook/workflow-instructions/task/simulate-next-phase-draft.wf.md"
    assert_includes config, "embed_document_source: true"
    assert_includes config, "format: markdown-xml"
    assert_includes config, "sections:"
  end

  def test_call_user_prompt_is_pure_source_content_for_draft
    captured_prompt = nil
    executor = build_executor(
      source_body: "# My Idea\n\nSome great idea content.",
      llm_response: "status: ok\nquestions: []\n",
      capture_prompt: ->(prompt) { captured_prompt = prompt }
    )

    payload = executor.call(
      resolved_source: { input: "idea-ref", type: "idea", path: "/tmp/idea.idea.s.md" },
      mode: "draft",
      run_id: "abc123"
    )

    # User prompt should be raw source content, no template wrapping
    assert_equal "# My Idea\n\nSome great idea content.", captured_prompt
    # Should not contain template markers
    refute_includes captured_prompt, "{{source_content}}"
    refute_includes captured_prompt, "Source Reference:"
    refute_includes captured_prompt, "Source Type:"
  end

  def test_call_user_prompt_includes_previous_artifact_for_plan
    captured_prompt = nil
    executor = build_executor(
      source_body: "# My Idea",
      llm_response: "status: ok\nquestions: []\n",
      capture_prompt: ->(prompt) { captured_prompt = prompt }
    )

    executor.call(
      resolved_source: { input: "idea-ref", type: "idea", path: "/tmp/idea.idea.s.md" },
      mode: "plan",
      run_id: "abc123",
      previous_stage_output: { status: "ok", artifact: "# Draft Spec\n\nThe draft." }
    )

    assert_includes captured_prompt, "# My Idea"
    assert_includes captured_prompt, "---"
    assert_includes captured_prompt, "# Draft Spec"
  end

  def test_call_system_prompt_comes_from_bundle_content
    captured_system = nil
    bundle_content = "Formatted project context and workflow instructions"
    executor = build_executor(
      source_body: "source",
      llm_response: "status: ok\nquestions: []\n",
      bundle_content: bundle_content,
      capture_system: ->(system) { captured_system = system }
    )

    executor.call(
      resolved_source: { input: "285.06", type: "task", path: "/tmp/source.s.md" },
      mode: "draft",
      run_id: "abc123"
    )

    assert_equal bundle_content, captured_system
  end

  def test_call_uses_plan_workflow_for_plan_mode
    executor = build_executor(
      source_body: "source",
      llm_response: "status: ok\nquestions: []\n"
    )

    payload = executor.call(
      resolved_source: { input: "285.06", type: "task", path: "/tmp/source.s.md" },
      mode: "plan",
      run_id: "abc123"
    )

    config = payload[:bundle_config]
    assert_includes config, "simulate-next-phase-plan.wf.md"
  end

  private

  def build_executor(source_body:, llm_response:, llm_calls: nil, capture_prompt: nil,
                     capture_system: nil, capture_config_path: nil, bundle_content: "bundle content")
    mock_bundle = Struct.new(:content).new(bundle_content)

    Ace::Taskflow::Molecules::NextPhaseStageExecutor.new(
      file_reader: ->(_path) { source_body },
      model_resolver: -> { "glite" },
      bundle_load_file: lambda { |path|
        capture_config_path&.call(path)
        mock_bundle
      },
      llm_query: lambda { |model, prompt, **kwargs|
        llm_calls&.push({ model: model, prompt: prompt, kwargs: kwargs })
        capture_prompt&.call(prompt)
        capture_system&.call(kwargs[:system])
        { text: llm_response }
      }
    )
  end
end
