# frozen_string_literal: true

require_relative "../../test_helper"

class WorkOnTaskTerminalFilterContractTest < AceAssignTestCase
  def test_work_on_task_preset_supports_single_task_and_batch_expansion_contract
    content = preset_content

    assert_includes content, "name: work-on-task"
    assert_includes content, "taskrefs:"
    assert_includes content, "type: array"
    assert_includes content, "batch-tasks"
    assert_includes content, 'name: "work-on-{{item}}"'
    assert_includes content, "foreach: taskrefs"
  end

  def test_work_on_task_preset_documents_single_task_shorthand_and_batch_examples
    content = preset_content

    assert_includes content, "Usage: /as-assign-prepare work-on-task --taskref 123"
    assert_includes content, "/as-assign-prepare work-on-task --taskrefs 148,149,150"
  end

  def test_prepare_workflow_uses_shared_terminal_status_contract
    section = markdown_section(
      prepare_workflow,
      "### 3.1 Resolve Requested Taskrefs and Filter Terminal Tasks (`work-on-task` only)"
    )

    assert_includes section, "Ace::Task::Atoms::TaskValidationRules::TERMINAL_STATUSES"
    assert_includes section, "If status is terminal (`done`, `skipped`, `cancelled`) → add to `skipped_terminal_refs`"
    assert_includes section, "Mixed set (`effective_taskrefs` non-empty, `skipped_terminal_refs` non-empty):"
    assert_includes section, "All-terminal set (`effective_taskrefs` empty, `skipped_terminal_refs` non-empty):"
    assert_includes section, "All requested tasks are already terminal (done/skipped/cancelled): <refs>"
  end

  def test_prepare_examples_cover_mixed_and_all_terminal_paths
    mixed_example = markdown_section(prepare_workflow, "### Example 7: Mixed Set with Terminal Tasks")
    all_terminal_example = markdown_section(prepare_workflow, "### Example 8: All Requested Tasks Already Terminal")

    assert_includes mixed_example, "Skipped terminal tasks (done/skipped/cancelled): 149"
    assert_includes all_terminal_example, "All requested tasks are already terminal (done/skipped/cancelled): 148,149"
    assert_includes all_terminal_example, "No assignment created."
  end

  def test_create_workflow_blocks_hidden_spec_and_create_for_all_terminal_requests
    content = create_workflow

    assert_includes content, "If prepare reports all requested refs are already terminal (`done/skipped/cancelled`), stop and return that no assignment was created"
    assert_includes content, "Do not render a hidden spec for all-terminal `work-on-task` requests that aborted in Path B."
    assert_includes content, "All requested tasks are already terminal (done/skipped/cancelled): ..."
    assert_includes content, "skip hidden-spec render and `ace-assign create`"
    refute_includes content, "already done"
    refute_includes content, "all-done `work-on-task` requests"
  end

  def test_usage_docs_match_terminal_filter_contract
    content = usage_docs

    assert_includes content, "Terminal refs (`done`, `skipped`, `cancelled`) are skipped before queue expansion."
    assert_includes content, "Mixed sets continue with remaining non-terminal refs and report skipped terminal refs."
    assert_includes content, "All requested tasks are already terminal (done/skipped/cancelled): <refs>"
    refute_includes content, "Refs with `status: done` are skipped before queue expansion."
  end

  private

  def prepare_workflow
    @prepare_workflow ||= File.read(File.expand_path("../../../handbook/workflow-instructions/assign/prepare.wf.md", __dir__))
  end

  def create_workflow
    @create_workflow ||= File.read(File.expand_path("../../../handbook/workflow-instructions/assign/create.wf.md", __dir__))
  end

  def usage_docs
    @usage_docs ||= File.read(File.expand_path("../../../docs/usage.md", __dir__))
  end

  def preset_content
    @preset_content ||= File.read(File.expand_path("../../../.ace-defaults/assign/presets/work-on-task.yml", __dir__))
  end

  def markdown_section(content, heading)
    start = content.index(heading)
    refute_nil start, "Missing heading: #{heading}"

    remainder = content[start..]
    next_heading = remainder.index("\n### ", heading.length)
    next_heading ? remainder[0...next_heading] : remainder
  end
end
