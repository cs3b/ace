# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "ace/task/molecules/task_plan_prompt_builder"

class TaskPlanPromptBuilderTest < AceTaskTestCase
  def setup
    @tmpdir = Dir.mktmpdir("task-plan-prompt-builder-test")
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)

    @task_file = File.join(@tmpdir, "task.s.md")
    File.write(@task_file, <<~TASK)
      ---
      id: 8pp.t.q7w
      status: pending
      bundle:
        presets: [project]
        files: [lib/feature.rb]
      ---

      # Implement feature X

      Add the feature X to the system.
    TASK

    @task = Struct.new(:id, :file_path).new("8pp.t.q7w", @task_file)
    @cache_dir = File.join(@tmpdir, ".cache", "ace-task", "8pp.t.q7w")
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_build_returns_system_and_prompt_file_paths
    builder = build_builder
    result = stub_ace_bundle(builder) { builder.build }

    assert result.key?(:system_file)
    assert result.key?(:prompt_file)
    assert File.file?(result[:system_file])
    assert File.file?(result[:prompt_file])
  end

  def test_files_written_to_prompts_directory
    builder = build_builder
    result = stub_ace_bundle(builder) { builder.build }

    prompts_dir = File.join(@cache_dir, "prompts")
    assert File.directory?(prompts_dir)
    assert result[:system_file].start_with?(prompts_dir)
    assert result[:prompt_file].start_with?(prompts_dir)
  end

  def test_system_config_file_written_with_bundle_frontmatter
    builder = build_builder
    stub_ace_bundle(builder) { builder.build }

    prompts_dir = File.join(@cache_dir, "prompts")
    config_files = Dir.glob(File.join(prompts_dir, "*-system.config.md"))
    assert_equal 1, config_files.size

    content = File.read(config_files.first)
    assert_includes content, "base: tmpl://agent/plan-mode"
    assert_includes content, "format: markdown-xml"
    assert_includes content, "sections:"
    assert_includes content, "workflow:"
    assert_includes content, "- wfi://task/plan"
    assert_includes content, "project_context:"
    assert_includes content, "presets:"
    assert_includes content, "- project"
    assert_includes content, "repeat_instruction:"
    assert_includes content, "- tmpl://agent/plan-mode"
  end

  def test_system_config_orders_base_then_sections_with_repeat_instruction_last
    builder = build_builder
    stub_ace_bundle(builder) { builder.build }

    prompts_dir = File.join(@cache_dir, "prompts")
    config_files = Dir.glob(File.join(prompts_dir, "*-system.config.md"))
    assert_equal 1, config_files.size

    content = File.read(config_files.first)
    base_pos = content.index("base: tmpl://agent/plan-mode")
    workflow_pos = content.index("workflow:")
    project_pos = content.index("project_context:")
    repeat_pos = content.index("repeat_instruction:")

    refute_nil base_pos
    refute_nil workflow_pos
    refute_nil project_pos
    refute_nil repeat_pos
    assert_operator base_pos, :<, workflow_pos
    assert_operator workflow_pos, :<, project_pos
    assert_operator project_pos, :<, repeat_pos
  end

  def test_user_config_file_is_copy_of_task_spec
    builder = build_builder
    stub_ace_bundle(builder) { builder.build }

    prompts_dir = File.join(@cache_dir, "prompts")
    config_files = Dir.glob(File.join(prompts_dir, "*-user.config.md"))
    assert_equal 1, config_files.size

    config_content = File.read(config_files.first)
    task_content = File.read(@task_file)
    assert_equal task_content, config_content
  end

  def test_system_prompt_calls_ace_bundle_with_config_file
    builder = build_builder
    calls = []
    stub_ace_bundle(builder, recorder: calls) { builder.build }

    system_call = calls.find { |c| c[:input].end_with?("-system.config.md") }
    assert system_call, "Expected ace-bundle to be called with system config file"
    assert system_call[:output_path].end_with?("-system.md")
  end

  def test_user_prompt_calls_ace_bundle_with_task_file
    builder = build_builder
    calls = []
    stub_ace_bundle(builder, recorder: calls) { builder.build }

    task_call = calls.find { |c| c[:input] == @task_file }
    assert task_call, "Expected ace-bundle to be called with task file path"
    assert task_call[:output_path].end_with?("-user.md")
  end

  def test_system_prompt_contains_ace_bundle_output
    builder = build_builder
    result = stub_ace_bundle(builder, content: "Bundled project context") { builder.build }

    content = File.read(result[:system_file])
    assert_equal "Bundled project context", content
  end

  def test_user_prompt_contains_ace_bundle_output
    builder = build_builder
    result = stub_ace_bundle(builder, content: "Bundled task context") { builder.build }

    content = File.read(result[:prompt_file])
    assert_equal "Bundled task context", content
  end

  def test_graceful_degradation_when_ace_bundle_unavailable
    builder = build_builder
    builder.define_singleton_method(:run_ace_bundle) do |input, output_path|
      File.write(output_path, "(ace-bundle not found)")
    end

    result = builder.build

    content = File.read(result[:system_file])
    assert_includes content, "ace-bundle not found"
  end

  def test_graceful_degradation_when_ace_bundle_fails
    builder = build_builder
    builder.define_singleton_method(:run_ace_bundle) do |input, output_path|
      File.write(output_path, "(ace-bundle failed for: #{input})")
    end

    result = builder.build

    content = File.read(result[:system_file])
    assert_includes content, "ace-bundle failed for:"
  end

  def test_file_names_contain_b36ts_timestamp
    builder = build_builder
    result = stub_ace_bundle(builder) { builder.build }

    system_basename = File.basename(result[:system_file])
    prompt_basename = File.basename(result[:prompt_file])

    assert_match(/\A[0-9a-z]{6}-system\.md\z/, system_basename)
    assert_match(/\A[0-9a-z]{6}-user\.md\z/, prompt_basename)
  end

  def test_plan_mode_template_contains_all_required_headings
    template_path = File.expand_path(
      "../../../ace-llm/handbook/templates/agent/plan-mode.template.md",
      __dir__
    )
    skip "plan-mode.template.md not found" unless File.exist?(template_path)
    content = File.read(template_path)

    required_headings = %w[
      Task\ Summary
      Execution\ Context
      Technical\ Approach
      File\ Modifications
      Plan\ Checklist
      Test\ Plan
      Risk\ Assessment
      Freshness\ Summary
    ]

    required_headings.each do |heading|
      assert_includes content, "## #{heading}",
        "plan-mode.template.md missing required heading: ## #{heading}"
    end
  end

  def test_plan_wf_contains_all_required_headings
    wf_path = File.expand_path(
      "../../handbook/workflow-instructions/task/plan.wf.md",
      __dir__
    )
    skip "task/plan.wf.md not found" unless File.exist?(wf_path)
    content = File.read(wf_path)

    required_headings = %w[
      Task\ Summary
      Execution\ Context
      Technical\ Approach
      File\ Modifications
      Plan\ Checklist
      Test\ Plan
      Risk\ Assessment
      Freshness\ Summary
    ]

    required_headings.each do |heading|
      assert_includes content, "## #{heading}",
        "task/plan.wf.md missing required heading: ## #{heading}"
    end
  end

  private

  def build_builder
    Ace::Task::Molecules::TaskPlanPromptBuilder.new(
      task: @task,
      cache_dir: @cache_dir
    )
  end

  def stub_ace_bundle(builder, content: "stubbed ace-bundle output", recorder: nil)
    builder.define_singleton_method(:run_ace_bundle) do |input, output_path|
      recorder&.push({input: input, output_path: output_path})
      File.write(output_path, content)
    end
    yield
  end
end
