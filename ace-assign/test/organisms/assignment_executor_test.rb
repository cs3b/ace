# frozen_string_literal: true

require_relative "../test_helper"

class AssignmentExecutorTest < AceAssignTestCase
  include Ace::TestSupport::ConfigHelpers

  def test_start_creates_assignment_and_steps
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assert_equal "test-session", result[:assignment].name
      assert_equal 3, result[:state].size
      assert_equal "init", result[:current].name
      assert_equal :in_progress, result[:current].status
    end
  end

  def test_start_raises_for_missing_config
    with_temp_cache do |cache_dir|
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)

      assert_raises(Ace::Assign::ConfigErrors::NotFound) do
        executor.start("nonexistent.yaml")
      end
    end
  end

  def test_status_returns_current_state
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      result = executor.status

      assert_equal "test-session", result[:assignment].name
      assert_equal 3, result[:state].size
      assert_equal "init", result[:current].name
    end
  end

  def test_status_raises_without_assignment
    with_temp_cache do |cache_dir|
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)

      assert_raises(Ace::Assign::AssignmentErrors::NoActive) do
        executor.status
      end
    end
  end

  def test_load_gem_defaults_include_codex_native_review_client
    allowlist = Ace::Assign.load_gem_defaults.dig("subtree", "native_review_clients")

    assert_includes allowlist, "claude"
    assert_includes allowlist, "codex"
  end

  def test_advance_completes_step_and_moves_to_next
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      result = executor.advance(report_path)

      assert_equal "init", result[:completed].name
      assert_equal "build", result[:current].name
      assert_equal :in_progress, result[:current].status
    end
  end

  def test_fail_marks_step_as_failed
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      result = executor.fail("Something went wrong")

      assert_equal "init", result[:failed].name
      assert_equal :failed, result[:state].find_by_number("010").status
    end
  end

  def test_add_creates_dynamic_step
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      result = executor.add("fix-bug", "Fix the bug")

      assert_equal "fix-bug", result[:added].name
      assert_equal "dynamic", result[:added].added_by
    end
  end

  def test_retry_creates_linked_step
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)
      executor.advance(report_path) # Complete init
      executor.fail("Tests failed") # Fail build

      result = executor.retry_step("020")

      assert_equal "build", result[:retry].name
      assert_equal "retry_of:020", result[:retry].added_by
      assert_equal :failed, result[:original].status
    end
  end

  def test_start_persists_skill_in_step_files
    with_temp_cache do |cache_dir|
      steps = [
        { "name" => "onboard", "skill" => "as-onboard", "instructions" => "Load context" },
        { "name" => "work", "skill" => "ace_custom_work", "instructions" => "Do work" },
        { "name" => "review", "instructions" => "Review changes" }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Verify skill is persisted in step files
      steps_dir = result[:assignment].steps_dir
      step_files = Dir.glob(File.join(steps_dir, "*.st.md")).sort

      first_content = File.read(step_files[0])
      assert_includes first_content, "skill: as-onboard"

      second_content = File.read(step_files[1])
      assert_includes second_content, "skill: ace_custom_work"

      # Third step has no skill — should not have skill key
      third_content = File.read(step_files[2])
      refute_includes third_content, "skill:"
    end
  end

  def test_start_persists_skill_readable_by_queue_scanner
    with_temp_cache do |cache_dir|
      steps = [
        { "name" => "work", "skill" => "ace_custom_work", "instructions" => "Do work" },
        { "name" => "review", "instructions" => "Review" }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assert_equal "ace_custom_work", result[:current].skill
      assert_nil result[:state].steps[1].skill
    end
  end

  def test_start_handles_array_instructions
    with_temp_cache do |cache_dir|
      steps = [
        { "name" => "array-step", "instructions" => ["Line one.", "Line two.", "Line three."] },
        { "name" => "string-step", "instructions" => "Single string instructions." }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Array instructions should be joined with newlines
      current = result[:current]
      assert_equal "array-step", current.name
      assert_includes current.instructions, "Line one."
      assert_includes current.instructions, "Line two."
      assert_includes current.instructions, "Line three."

      # String instructions should pass through unchanged
      string_step = result[:state].steps[1]
      assert_equal "Single string instructions.", string_step.instructions.strip
    end
  end

  def test_start_archives_config_to_task_jobs_dir
    with_temp_cache do |cache_dir|
      task_dir = File.join(cache_dir, "task-folder")
      FileUtils.mkdir_p(task_dir)
      config_path = create_test_config(task_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Original should be gone
      refute File.exist?(config_path), "Original job.yaml should be removed"

      # Archived copy should exist in task's jobs/ dir
      archived = File.join(task_dir, "jobs", "#{result[:assignment].id}-job.yml")
      assert File.exist?(archived), "Archived job.yml should exist in task jobs dir"
      assert_equal archived, result[:assignment].source_config

      # Content should be valid YAML
      data = YAML.safe_load_file(archived)
      assert_equal "test-session", data["assignment"]["name"]
    end
  end

  def test_start_preserves_hidden_spec_path_in_assign_jobs_dir
    with_temp_cache do |cache_dir|
      hidden_jobs_dir = File.join(cache_dir, ".ace-local", "assign", "jobs")
      FileUtils.mkdir_p(hidden_jobs_dir)
      config_path = create_test_config(hidden_jobs_dir, name: "hidden-spec")

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assert File.exist?(config_path), "Hidden spec should remain in-place"
      assert_equal File.expand_path(config_path), result[:assignment].source_config

      unexpected_archive = File.join(hidden_jobs_dir, "jobs", "#{result[:assignment].id}-job.yml")
      refute File.exist?(unexpected_archive), "Hidden spec should not be moved into nested jobs/ directory"
    end
  end

  def test_start_preserves_legacy_step_archive_path
    with_temp_cache do |cache_dir|
      legacy_steps_dir = File.join(cache_dir, "task-folder", "steps")
      FileUtils.mkdir_p(legacy_steps_dir)
      config_path = create_test_config(legacy_steps_dir, name: "legacy-step-spec")

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assert File.exist?(config_path), "Legacy steps config should remain in-place"
      assert_equal File.expand_path(config_path), result[:assignment].source_config

      unexpected_archive = File.join(legacy_steps_dir, "jobs", "#{result[:assignment].id}-job.yml")
      refute File.exist?(unexpected_archive), "Legacy steps config should not be moved into nested jobs/ directory"
    end
  end

  def test_full_workflow
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)

      # Start
      result = executor.start(config_path)

      # Complete all steps
      3.times do
        report_path = create_report(cache_dir, "Step completed")
        result = executor.advance(report_path)
      end

      result = executor.status

      assert result[:state].complete?
      assert_nil result[:current]
      assert_equal 3, result[:state].done.size
    end
  end

  def test_advance_creates_report_in_reports_dir
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir, "All done!")

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assignment = result[:assignment]
      reports_dir = assignment.reports_dir

      executor.advance(report_path)

      # Report should be in reports/ directory
      report_file = File.join(reports_dir, "010-init.r.md")
      assert File.exist?(report_file), "Report file should exist in reports directory"

      report_content = File.read(report_file)
      assert_includes report_content, "step: '010'"
      assert_includes report_content, "name: init"
      assert_includes report_content, "All done!"

      # Step file should not have report embedded
      step_file = File.join(assignment.steps_dir, "010-init.st.md")
      step_content = File.read(step_file)
      refute_includes step_content, "All done!"
    end
  end

  def test_start_persists_context_in_step_files
    with_temp_cache do |cache_dir|
      steps = [
        { "name" => "prepare", "instructions" => "Load context" },
        { "name" => "implement", "context" => "fork", "instructions" => "Do the work" },
        { "name" => "verify", "instructions" => "Run tests" }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Verify context is persisted in step files
      steps_dir = result[:assignment].steps_dir
      step_files = Dir.glob(File.join(steps_dir, "*.st.md")).sort

      # First step has no context
      first_content = File.read(step_files[0])
      refute_includes first_content, "context:"

      # Second step has fork context
      second_content = File.read(step_files[1])
      assert_includes second_content, "context: fork"

      # Third step has no context
      third_content = File.read(step_files[2])
      refute_includes third_content, "context:"
    end
  end

  def test_start_persists_context_readable_by_queue_scanner
    with_temp_cache do |cache_dir|
      steps = [
        { "name" => "prepare", "instructions" => "Load context" },
        { "name" => "implement", "context" => "fork", "instructions" => "Do the work" }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # First step (current) has no context
      assert_nil result[:current].context
      refute result[:current].fork?

      # Second step has fork context
      implement_step = result[:state].steps[1]
      assert_equal "fork", implement_step.context
      assert implement_step.fork?
    end
  end

  # === Hierarchical Step Tests ===

  def test_add_with_after_creates_sibling
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      # Add a step after 010 (init)
      result = executor.add("verify", "Verify initialization", after: "010")

      assert_equal "verify", result[:added].name
      assert_equal "011", result[:added].number
      assert_equal "injected_after:010", result[:added].added_by
    end
  end

  def test_add_with_after_renumbers_existing
    with_temp_cache do |cache_dir|
      # Create assignment with steps at 010, 020, 030
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Add a step after 010 - should create 011
      # Existing 020 and 030 should remain unchanged (they're not siblings of 010.xx)
      result = executor.add("verify", "Verify", after: "010")

      # The new step should be 011
      assert_equal "011", result[:added].number

      # Get all current numbers
      numbers = result[:state].all_numbers
      assert_includes numbers, "010"
      assert_includes numbers, "011"
      assert_includes numbers, "020"
      assert_includes numbers, "030"
    end
  end

  def test_add_with_as_child_creates_nested_step
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      # Add a child step under 010 (init)
      result = executor.add("verify", "Verify initialization", after: "010", as_child: true)

      assert_equal "verify", result[:added].name
      assert_equal "010.01", result[:added].number
    end
  end

  def test_add_child_under_active_step_rebalances_to_child
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir, steps: [
        { "name" => "parent-job", "instructions" => "Parent work" },
        { "name" => "final-step", "instructions" => "Final work" }
      ])

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assert_equal "010", result[:current].number

      result = executor.add("child-task-1", "Child work", after: "010", as_child: true)

      assert_equal "010.01", result[:state].current.number
      assert_equal :pending, result[:state].find_by_number("010").status
      assert_equal :in_progress, result[:state].find_by_number("010.01").status
      assert_nil result[:state].find_by_number("010").started_at
    end
  end

  def test_add_grandchild_under_active_child_rebalances_to_grandchild
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir, steps: [
        { "name" => "grandparent", "instructions" => "Top level" },
        { "name" => "next-task", "instructions" => "Next task" }
      ])

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)
      child_result = executor.add("parent", "Parent work", after: "010", as_child: true)

      assert_equal "010.01", child_result[:state].current.number

      result = executor.add("grandchild", "Grandchild work", after: "010.01", as_child: true)

      assert_equal "010.01.01", result[:state].current.number
      assert_equal :pending, result[:state].find_by_number("010.01").status
      assert_equal :in_progress, result[:state].find_by_number("010.01.01").status
    end
  end

  def test_add_child_under_non_active_step_keeps_existing_current
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir, "done")

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)
      executor.advance(report_path)

      result = executor.add("late-child", "Late child", after: "010", as_child: true)

      assert_equal "020", result[:state].current.number
      assert_equal :done, result[:state].find_by_number("010").status
      assert_equal :pending, result[:state].find_by_number("010.01").status
    end
  end

  def test_add_sibling_does_not_change_current_step
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assert_equal "010", result[:current].number

      result = executor.add("sibling-check", "Sibling work", after: "010")

      assert_equal "010", result[:state].current.number
      assert_equal :in_progress, result[:state].find_by_number("010").status
      assert_equal :pending, result[:added].status
    end
  end

  def test_add_multiple_children
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      # Add first child
      executor.add("verify-1", "First verify", after: "010", as_child: true)

      # Add second child
      result = executor.add("verify-2", "Second verify", after: "010", as_child: true)

      assert_equal "010.02", result[:added].number

      # Verify both children exist
      numbers = result[:state].all_numbers
      assert_includes numbers, "010.01"
      assert_includes numbers, "010.02"
    end
  end

  def test_hierarchical_display
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      # Add nested steps
      executor.add("verify-init", "Verify", after: "010", as_child: true)
      result = executor.add("fix-init", "Fix issues", after: "010.01")

      # Get hierarchical structure
      hierarchy = result[:state].hierarchical

      # Should have 3 top-level steps (010, 020, 030)
      assert_equal 3, hierarchy.size

      # First step (010) should have children
      first = hierarchy[0]
      assert_equal "010", first[:step].number
      assert first[:children].size >= 1
    end
  end

  def test_children_of_returns_direct_children
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      # Add nested steps
      executor.add("verify", "Verify", after: "010", as_child: true) # 010.01
      executor.add("deep", "Deep", after: "010.01", as_child: true)  # 010.01.01

      result = executor.status

      # children_of should return only direct children
      children = result[:state].children_of("010")
      assert_equal 1, children.size
      assert_equal "010.01", children[0].number
    end
  end

  # === Sub-step fork enforcement tests ===

  def test_start_with_sub_steps_creates_batch_parent_and_children
    with_temp_cache do |cache_dir|
      steps = [
        { "name" => "onboard", "instructions" => "Load context" },
        {
          "name" => "work-on-task",
          "instructions" => "Container for sub-steps",
          "sub_steps" => %w[onboard implement verify-tests]
        },
        { "name" => "review", "instructions" => "Review changes" }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      state = result[:state]
      numbers = state.all_numbers

      # Should have: 010 (onboard), 020 (batch parent), 020.01, 020.02, 020.03, 030 (review)
      assert_includes numbers, "010"
      assert_includes numbers, "020"
      assert_includes numbers, "020.01"
      assert_includes numbers, "020.02"
      assert_includes numbers, "020.03"
      assert_includes numbers, "030"

      # Batch parent should have fork context
      parent_step = state.find_by_number("020")
      assert_equal "fork", parent_step.context

      # Children should have correct names
      child1 = state.find_by_number("020.01")
      assert_equal "onboard", child1.name

      child2 = state.find_by_number("020.02")
      assert_equal "implement", child2.name

      child3 = state.find_by_number("020.03")
      assert_equal "verify-tests", child3.name
    end
  end

  def test_start_with_parent_id_sets_parent_on_assignment
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path, parent_id: "parent123")

      assert_equal "parent123", result[:assignment].parent
    end
  end

  def test_start_without_sub_steps_unchanged
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Standard 3-step setup, no sub-steps
      assert_equal 3, result[:state].size
      numbers = result[:state].all_numbers
      assert_equal %w[010 020 030], numbers.sort
    end
  end

  def test_start_resolves_skill_assign_source_and_expands_sub_steps
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      FileUtils.mkdir_p(File.join(project_root, "ace-bundle", ".ace-defaults", "nav", "protocols", "skill-sources"))
      FileUtils.mkdir_p(File.join(project_root, "ace-bundle", "handbook", "skills", "as-onboard"))
      FileUtils.mkdir_p(File.join(project_root, "ace-bundle", "handbook", "workflow-instructions"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", "handbook", "skills", "as-task-plan"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", "handbook", "skills", "as-task-work"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", "handbook", "workflow-instructions", "task"))
      FileUtils.mkdir_p(File.join(project_root, "ace-handbook", "handbook", "workflow-instructions", "release"))

      File.write(File.join(project_root, "ace-bundle", ".ace-defaults", "nav", "protocols", "skill-sources", "ace-bundle.yml"), <<~YAML)
        name: ace-bundle
        config:
          relative_path: handbook/skills
      YAML
      File.write(File.join(project_root, "ace-task", ".ace-defaults", "nav", "protocols", "skill-sources", "ace-task.yml"), <<~YAML)
        name: ace-task
        config:
          relative_path: handbook/skills
      YAML

      File.write(File.join(project_root, "ace-bundle", "handbook", "skills", "as-onboard", "SKILL.md"), <<~MD)
        ---
        name: as-onboard
        skill:
          kind: workflow
          execution:
            workflow: wfi://onboard
        ---

        Load and run `ace-bundle wfi://onboard`
      MD
      File.write(File.join(project_root, "ace-bundle", "handbook", "workflow-instructions", "onboard.wf.md"), <<~MD)
        ---
        ---
      MD

      File.write(File.join(project_root, "ace-task", "handbook", "skills", "as-task-plan", "SKILL.md"), <<~MD)
        ---
        name: as-task-plan
        skill:
          kind: workflow
          execution:
            workflow: wfi://task/plan
        assign:
          source: wfi://task/plan
        ---

        Load and run `ace-bundle wfi://task/plan`
      MD

      File.write(File.join(project_root, "ace-task", "handbook", "skills", "as-task-work", "SKILL.md"), <<~MD)
        ---
        name: as-task-work
        skill:
          kind: workflow
          execution:
            workflow: wfi://task/work
        assign:
          source: wfi://task/work
        ---

        read and run `ace-bundle wfi://task/work`
      MD

      File.write(File.join(project_root, "ace-task", "handbook", "workflow-instructions", "task", "plan.wf.md"), <<~MD)
        ---
        ---
      MD
      File.write(File.join(project_root, "ace-handbook", "handbook", "workflow-instructions", "release", "publish.wf.md"), <<~MD)
        ---
        ---

        # Release Workflow

        Follow the release workflow.
      MD

      File.write(File.join(project_root, "ace-task", "handbook", "workflow-instructions", "task", "work.wf.md"), <<~MD)
        ---
        assign:
          sub-steps:
            - onboard
            - task-load
            - plan-task
            - work-on-task
            - pre-commit-review
            - verify-test
            - release-minor
          context: fork
        ---

        # Work on Task

        Follow the workflow body directly.
      MD

      steps = [
        { "name" => "work-on-task", "skill" => "as-task-work", "instructions" => "Do work" },
        { "name" => "review", "instructions" => "Review changes" }
      ]
      workflow_paths = [
        File.join(project_root, "ace-task", "handbook", "workflow-instructions"),
        File.join(project_root, "ace-bundle", "handbook", "workflow-instructions"),
        File.join(project_root, "ace-handbook", "handbook", "workflow-instructions")
      ]
      project_assign_config = File.join(project_root, ".ace", "assign", "config.yml")
      FileUtils.mkdir_p(File.dirname(project_assign_config))
      File.write(project_assign_config, {
        "workflow_source_paths" => workflow_paths,
        "subtree" => {
          "pre_commit_review" => true,
          "pre_commit_review_provider" => "auto",
          "pre_commit_review_block" => false,
          "native_review_clients" => %w[claude codex]
        }
      }.to_yaml)
      config_path = create_test_config(project_root, steps: steps)

      with_real_config do
        Dir.chdir(project_root) do
          original_project_root = ENV["PROJECT_ROOT_PATH"]
          original_home = ENV["HOME"]
          Dir.mktmpdir("ace-assign-home") do |temp_home|
            ENV["PROJECT_ROOT_PATH"] = project_root
            ENV["HOME"] = temp_home
            Ace::Assign.reset_config!

            executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
            result = executor.start(config_path)
            state = result[:state]
            numbers = state.all_numbers

            assert_includes numbers, "010"
            assert_includes numbers, "010.01"
            assert_includes numbers, "010.02"
            assert_includes numbers, "010.03"
            assert_includes numbers, "010.04"
            assert_includes numbers, "010.05"
            assert_includes numbers, "010.06"
            assert_includes numbers, "010.07"
            assert_includes numbers, "020"

            parent_step = state.find_by_number("010")
            assert_equal "fork", parent_step.context
            assert_nil parent_step.skill
            assert_includes parent_step.instructions, "Subtree root orchestrator step."
            assert_includes parent_step.instructions, "ace-assign fork-run --assignment <assignment-id>@010"
            assert_includes parent_step.instructions, "Do work"

            onboard_step = state.find_by_number("010.01")
            task_load_step = state.find_by_number("010.02")
            plan_step = state.find_by_number("010.03")
            work_step = state.find_by_number("010.04")
            review_step = state.find_by_number("010.05")
            verify_step = state.find_by_number("010.06")
            release_step = state.find_by_number("010.07")

            assert_equal "onboard", onboard_step.name
            assert_equal "plan-task", plan_step.name
            assert_equal "work-on-task", work_step.name
            assert_equal "task-load", task_load_step.name
            assert_equal "pre-commit-review", review_step.name
            assert_equal "verify-test", verify_step.name
            assert_equal "release-minor", release_step.name

            # First actionable child is activated (parent container is skipped)
            assert_equal "010.01", result[:current].number

            # Skill-backed steps materialize from canonical skill bodies with provenance metadata.
            assert_nil onboard_step.skill
            assert_nil plan_step.skill
            assert_nil work_step.skill
            assert_nil review_step.skill
            assert_nil verify_step.skill
            assert_nil release_step.skill

            # Parent is fork context: children remain non-fork and execute in same delegated subtree process
            assert_nil onboard_step.context
            assert_nil plan_step.context
            assert_nil work_step.context
            assert_nil review_step.context
            assert_nil task_load_step.context
            assert_nil verify_step.context
            assert_nil release_step.context

            # Child instructions include parent task context for parameter extraction
            assert_includes File.read(onboard_step.file_path), "source_skill: as-onboard"
            assert_includes File.read(plan_step.file_path), "source_skill: as-task-plan"
            assert_includes File.read(work_step.file_path), "source_skill: as-task-work"
            assert_includes File.read(plan_step.file_path), "source_workflow: wfi://task/plan"
            assert_includes File.read(work_step.file_path), "source_workflow: wfi://task/work"
            assert_includes work_step.instructions, "Task request: Do work"
            assert_includes work_step.instructions, "# Work on Task"
            refute_includes work_step.instructions, "Assignment-specific context:\n- Task context:"
            assert_includes verify_step.instructions, "Action:"
            assert_includes verify_step.instructions, "Identify modified packages"
            assert_includes verify_step.instructions, "ace-test --profile 6"
            assert_includes review_step.instructions, "review uncommitted changes and find issues"
            assert_includes review_step.instructions, "Allowed native review clients: claude, codex."
            assert_includes review_step.instructions, "pre_commit_review_block"
            assert_includes release_step.instructions, "Action:"
            refute_includes release_step.instructions, "/as-release"
            assert_includes release_step.instructions, "Release all modified packages"
          end
        ensure
          if original_home.nil?
            ENV.delete("HOME")
          else
            ENV["HOME"] = original_home
          end
          if original_project_root.nil?
            ENV.delete("PROJECT_ROOT_PATH")
          else
            ENV["PROJECT_ROOT_PATH"] = original_project_root
          end
          Ace::Assign.reset_config!
        end
      end
    end
  end

  def test_child_action_instructions_support_release_suffix_variants
    executor = Ace::Assign::Organisms::AssignmentExecutor.new

    instructions = executor.send(:child_action_instructions, "release-patch-1", "Patch release follow-up")

    refute_includes instructions, "/as-release"
    assert_includes instructions, "Release all modified packages"
  end

  def test_assignment_specific_notes_strips_structural_headers_and_nested_bullets
    executor = Ace::Assign::Organisms::AssignmentExecutor.new

    notes = executor.send(
      :assignment_specific_notes,
      step_name: "review-pr",
      instructions: <<~TEXT
        Task context:
        Task request: Execute the valid review cycle via child steps.

        Assignment-specific context:
        - use preset code-valid.
        - Focus: correctness, behavioral regressions, and contract validation.
      TEXT
    )

    refute_includes notes, "Task context:"
    refute_includes notes, "Assignment-specific context:"
    refute_includes notes, "- -"
    refute_includes notes, "Task request:"
    assert_includes notes, "- use preset code-valid."
    assert_includes notes, "- Focus: correctness, behavioral regressions, and contract validation."
  end

  def test_render_skill_backed_step_instructions_uses_step_template_for_verify_test_suite
    executor = Ace::Assign::Organisms::AssignmentExecutor.new

    instructions = executor.send(
      :render_skill_backed_step_instructions,
      step: {
        "name" => "verify-test-suite",
        "taskref" => "8q5.1",
        "instructions" => "Verify only the modified packages.\nSkip if the change is docs-only."
      },
      rendering: {
        "name" => "verify-test-suite",
        "workflow" => "wfi://test/verify-suite",
        "render" => "step_template",
        "description" => "Run package test suites with profiling to verify correctness and performance",
        "steps" => [
          { "description" => "Run ace-test --profile 6 for each modified package", "note" => "Run per-package, not as a full monorepo sweep." },
          { "description" => "Run ace-test-suite to verify no cross-package regressions" }
        ],
        "when_to_skip" => [
          "No code changes that could affect tests (documentation-only)"
        ]
      }
    )

    assert_includes instructions, "Step focus:"
    assert_includes instructions, "Run ace-test --profile 6 for each modified package"
    assert_includes instructions, "Skip when:"
    assert_includes instructions, "Assignment-specific context:"
    refute_includes instructions, "Monthly full audit"
    refute_includes instructions, "flakiness"
    refute_includes instructions, "create follow-up tasks"
  end

  def test_render_skill_backed_step_instructions_uses_step_template_for_verify_e2e
    executor = Ace::Assign::Organisms::AssignmentExecutor.new

    instructions = executor.send(
      :render_skill_backed_step_instructions,
      step: {
        "name" => "verify-e2e",
        "taskref" => "8q5.1",
        "instructions" => "Run only for heavily modified packages with public CLI changes."
      },
      rendering: {
        "name" => "verify-e2e",
        "workflow" => "wfi://e2e/review",
        "render" => "step_template",
        "description" => "Review E2E coverage for modified packages and run targeted scenarios",
        "steps" => [
          { "description" => "Review coverage for heavily modified packages" },
          { "description" => "If coverage matrix shows gaps or stale TCs, update or create E2E tests", "conditional" => "coverage gaps were found" },
          { "description" => "Run targeted E2E scenarios for heavily modified packages" }
        ],
        "when_to_skip" => [
          "No public CLI API changes (internal-only refactoring)"
        ]
      }
    )

    assert_includes instructions, "Review coverage for heavily modified packages"
    assert_includes instructions, "If coverage gaps were found."
    assert_includes instructions, "Run targeted E2E scenarios for heavily modified packages"
    refute_includes instructions, "Stage 1 of 3 (Explore)"
    refute_includes instructions, "wfi://e2e/plan-changes"
    refute_includes instructions, "wfi://e2e/rewrite"
  end

  def test_start_with_sub_steps_compacts_child_context_and_avoids_parent_boilerplate
    with_temp_dir do |project_root|
      cache_dir = File.join(project_root, ".cache", "ace-assign")
      FileUtils.mkdir_p(cache_dir)

      FileUtils.mkdir_p(File.join(project_root, ".ace", "nav", "protocols", "skill-sources"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", "handbook", "skills", "as-task-plan"))
      FileUtils.mkdir_p(File.join(project_root, "ace-task", "handbook", "workflow-instructions", "task"))
      FileUtils.mkdir_p(File.join(project_root, "ace-bundle", "handbook", "skills", "as-onboard"))
      FileUtils.mkdir_p(File.join(project_root, "ace-bundle", "handbook", "workflow-instructions"))
      File.write(File.join(project_root, ".ace", "nav", "protocols", "skill-sources", "ace-task.yml"), <<~YAML)
        name: ace-task
        config:
          relative_path: ace-task/handbook/skills
      YAML
      File.write(File.join(project_root, ".ace", "nav", "protocols", "skill-sources", "ace-bundle.yml"), <<~YAML)
        name: ace-bundle
        config:
          relative_path: handbook/skills
      YAML
      File.write(File.join(project_root, "ace-bundle", "handbook", "skills", "as-onboard", "SKILL.md"), <<~MD)
        ---
        name: as-onboard
        skill:
          kind: workflow
          execution:
            workflow: wfi://onboard
        ---

        Load and run `ace-bundle wfi://onboard`
      MD
      File.write(File.join(project_root, "ace-task", "handbook", "skills", "as-task-plan", "SKILL.md"), <<~MD)
        ---
        name: as-task-plan
        skill:
          kind: workflow
          execution:
            workflow: wfi://task/plan
        assign:
          source: wfi://task/plan
        ---

        Load and run `ace-bundle wfi://task/plan`
      MD
      File.write(File.join(project_root, "ace-bundle", "handbook", "workflow-instructions", "onboard.wf.md"), <<~MD)
        ---
        ---
      MD
      File.write(File.join(project_root, "ace-task", "handbook", "workflow-instructions", "task", "plan.wf.md"), <<~MD)
        ---
        ---
      MD

      skill_dir = File.join(project_root, ".agents", "skills", "ace_work-on-task")
      FileUtils.mkdir_p(skill_dir)
      File.write(File.join(skill_dir, "SKILL.md"), <<~MD)
        ---
        name: as-task-work
        skill:
          kind: workflow
          execution:
            workflow: wfi://task/work
        assign:
          source: wfi://task/work
          sub-steps:
            - onboard
            - plan-task
            - work-on-task
          context: fork
        ---

        read and run `ace-bundle wfi://task/work`
      MD

      steps = [
        {
          "name" => "work-on-task",
          "skill" => "as-task-work",
          "taskref" => "235.01",
          "sub_steps" => %w[onboard plan-task work-on-task],
          "instructions" => "First: onboard yourself using /as-onboard skill to load project context.\n" \
                            "Implement the selected task.\n" \
                            "When complete, mark the task as done: run `ace-taskflow task done 235.01`"
        }
      ]
      config_path = create_test_config(project_root, steps: steps)

      Dir.chdir(project_root) do
        original_project_root = ENV["PROJECT_ROOT_PATH"]
        ENV["PROJECT_ROOT_PATH"] = project_root
        Ace::Assign.reset_config!
        executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
        result = executor.start(config_path)
        state = result[:state]

        plan_step = state.find_by_number("010.02")
        work_step = state.find_by_number("010.03")

        assert_includes plan_step.instructions, "Task reference: 235.01"
        assert_includes work_step.instructions, "Task reference: 235.01"
        assert_includes File.read(plan_step.file_path), "taskref: '235.01'"
        assert_includes File.read(work_step.file_path), "taskref: '235.01'"
        assert_equal "as-task-plan", plan_step.skill
        assert_equal "as-task-work", work_step.skill
        refute_includes plan_step.instructions, "Verification checklist (from parent step goals):"
        refute_includes work_step.instructions, "Verification checklist (from parent step goals):"
      ensure
        if original_project_root.nil?
          ENV.delete("PROJECT_ROOT_PATH")
        else
          ENV["PROJECT_ROOT_PATH"] = original_project_root
        end
        Ace::Assign.reset_config!
      end
    end
  end

  def test_start_with_sub_steps_uses_project_split_parent_template_and_preserves_default_catalog_entries
    with_temp_dir do |project_root|
      cache_dir = File.join(project_root, ".cache", "ace-assign")
      FileUtils.mkdir_p(cache_dir)

      FileUtils.mkdir_p(File.join(project_root, ".ace", "nav", "protocols", "skill-sources"))
      FileUtils.mkdir_p(File.join(project_root, "ace-bundle", "handbook", "skills", "as-onboard"))
      FileUtils.mkdir_p(File.join(project_root, "ace-bundle", "handbook", "workflow-instructions"))
      File.write(File.join(project_root, ".ace", "nav", "protocols", "skill-sources", "ace-bundle.yml"), <<~YAML)
        name: ace-bundle
        config:
          relative_path: handbook/skills
      YAML
      File.write(File.join(project_root, "ace-bundle", "handbook", "skills", "as-onboard", "SKILL.md"), <<~MD)
        ---
        name: as-onboard
        skill:
          kind: workflow
          execution:
            workflow: wfi://onboard
        ---

        Load and run `ace-bundle wfi://onboard`
      MD
      File.write(File.join(project_root, "ace-bundle", "handbook", "workflow-instructions", "onboard.wf.md"), <<~MD)
        ---
        ---
      MD

      project_catalog_dir = File.join(project_root, ".ace", "assign", "catalog", "steps")
      FileUtils.mkdir_p(project_catalog_dir)
      File.write(File.join(project_catalog_dir, "split-subtree-root.step.yml"), <<~YAML)
        name: split-subtree-root
        instructions:
          common:
            - "CUSTOM ROOT {{parent_number}}"
            - "children={{sub_steps}}"
          fork:
            - "CUSTOM FORK {{parent_number}}"
        goal_header: "Custom goal header:"
      YAML

      steps = [
        {
          "name" => "work-on-task",
          "context" => "fork",
          "instructions" => "Implement task 235.01",
          "sub_steps" => ["onboard"]
        }
      ]
      config_path = create_test_config(project_root, steps: steps)

      Dir.chdir(project_root) do
        original_project_root = ENV["PROJECT_ROOT_PATH"]
        ENV["PROJECT_ROOT_PATH"] = project_root
        Ace::Assign.reset_config!
        executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
        result = executor.start(config_path)
        state = result[:state]

        parent_step = state.find_by_number("010")
        child_step = state.find_by_number("010.01")

        assert_includes parent_step.instructions, "CUSTOM ROOT 010"
        assert_includes parent_step.instructions, "children=onboard"
        assert_includes parent_step.instructions, "CUSTOM FORK 010"
        assert_includes parent_step.instructions, "Custom goal header:"

        # Project override should not replace entire catalog; child metadata still resolves from default catalog.
        assert_equal "as-onboard", child_step.skill
      ensure
        if original_project_root.nil?
          ENV.delete("PROJECT_ROOT_PATH")
        else
          ENV["PROJECT_ROOT_PATH"] = original_project_root
        end
        Ace::Assign.reset_config!
      end
    end
  end

  def test_descendants_of_returns_all_nested
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      # Add nested steps
      executor.add("verify", "Verify", after: "010", as_child: true) # 010.01
      executor.add("deep", "Deep", after: "010.01", as_child: true)  # 010.01.01

      result = executor.status

      # descendants_of should return all nested
      descendants = result[:state].descendants_of("010")
      assert_equal 2, descendants.size
      numbers = descendants.map(&:number).sort
      assert_equal ["010.01", "010.01.01"], numbers
    end
  end

  def test_advance_respects_fork_root_scope_and_does_not_escape_subtree
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        },
        { "name" => "review", "instructions" => "Review changes" }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assert_equal "010.01", result[:current].number

      report_path = create_report(cache_dir, "Done")

      result = executor.advance(report_path, fork_root: "010")
      assert_equal "010.02", result[:current].number

      result = executor.advance(report_path, fork_root: "010")
      assert_nil result[:current], "Subtree-scoped execution should stop after subtree completes"
    end
  end

  def test_advance_with_fork_root_uses_subtree_step_when_global_current_is_outside_scope
    with_temp_cache do |cache_dir|
      steps = [
        { "name" => "precheck", "instructions" => "Run precheck" },
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        },
        { "name" => "postcheck", "instructions" => "Run postcheck" }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      start_result = executor.start(config_path)
      assert_equal "010", start_result[:current].number

      report_path = create_report(cache_dir, "Scoped progress")
      result = executor.advance(report_path, fork_root: "020")

      scoped_state = result[:state]
      refute_equal :done, scoped_state.find_by_number("010").status
      assert_equal :done, scoped_state.find_by_number("020.01").status
      assert_equal :in_progress, scoped_state.find_by_number("020.02").status
      assert_equal "010", result[:current]&.number
    end
  end

  def test_advance_with_fork_root_raises_when_multiple_subtree_steps_are_in_progress
    with_temp_cache do |cache_dir|
      steps = [
        { "name" => "precheck", "instructions" => "Run precheck" },
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      start_result = executor.start(config_path)
      assignment = start_result[:assignment]

      scanner = Ace::Assign::Molecules::QueueScanner.new
      writer = Ace::Assign::Molecules::StepWriter.new
      state = scanner.scan(assignment.steps_dir, assignment: assignment)
      writer.mark_in_progress(state.find_by_number("020.01").file_path)
      writer.mark_in_progress(state.find_by_number("020.02").file_path)

      report_path = create_report(cache_dir, "Scoped progress")
      error = assert_raises(Ace::Assign::StepErrors::InvalidState) do
        executor.advance(report_path, fork_root: "020")
      end

      assert_includes error.message, "multiple steps are in progress"
    end
  end

  def test_start_with_work_on_task_preset_emits_canonical_skill_backed_steps
    with_temp_cache do |cache_dir|
      project_root = File.expand_path("../../..", __dir__)
      steps = materialize_preset_steps(project_root, "work-on-task", "taskref" => "148")
      config_path = create_test_config(cache_dir, steps: steps, name: "work-on-task-148")

      with_real_config do
        Dir.chdir(project_root) do
          original_project_root = ENV["PROJECT_ROOT_PATH"]
          original_home = ENV["HOME"]
          Dir.mktmpdir("ace-assign-home") do |temp_home|
            ENV["PROJECT_ROOT_PATH"] = project_root
            ENV["HOME"] = temp_home
            Ace::Assign.reset_config!

            executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
            result = executor.start(config_path)
            state = result[:state]

            onboard = state.steps.find { |step| step.name == "onboard" }
            work_steps = state.steps.select { |step| step.name == "work-on-task" }
            verify_suite = state.steps.find { |step| step.name == "verify-test-suite" }
            create_pr = state.steps.find { |step| step.name == "create-pr" }

            refute_nil onboard
            assert_equal 1, work_steps.length
            refute_nil verify_suite
            refute_nil create_pr

            assert_nil onboard.skill
            assert_nil work_steps.first.skill
            assert_nil verify_suite.skill
            assert_nil create_pr.skill
            assert_includes File.read(onboard.file_path), "source_skill: as-onboard"
            assert_includes File.read(work_steps.first.file_path), "source_skill: as-task-work"
            assert_includes work_steps.first.instructions, "# Work on Task"
            assert_includes File.read(verify_suite.file_path), "source_skill: as-test-verify-suite"
            assert_includes File.read(create_pr.file_path), "source_skill: as-github-pr-create"
          end
        ensure
          ENV["PROJECT_ROOT_PATH"] = original_project_root
          ENV["HOME"] = original_home
          Ace::Assign.reset_config!
        end
      end
    end
  end

  def test_start_with_work_on_task_batch_emits_canonical_skill_backed_batch_steps
    with_temp_cache do |cache_dir|
      project_root = File.expand_path("../../..", __dir__)
      steps = materialize_preset_steps(project_root, "work-on-task", "taskrefs" => %w[148 149])
      config_path = create_test_config(cache_dir, steps: steps, name: "work-on-task-148-149")

      with_real_config do
        Dir.chdir(project_root) do
          original_project_root = ENV["PROJECT_ROOT_PATH"]
          original_home = ENV["HOME"]
          Dir.mktmpdir("ace-assign-home") do |temp_home|
            ENV["PROJECT_ROOT_PATH"] = project_root
            ENV["HOME"] = temp_home
            Ace::Assign.reset_config!

            executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
            result = executor.start(config_path)
            state = result[:state]

            onboard = state.steps.find { |step| step.name == "onboard" }
            work_steps = state.steps.select { |step| step.name == "work-on-task" }
            verify_suite = state.steps.find { |step| step.name == "verify-test-suite" }
            create_pr = state.steps.find { |step| step.name == "create-pr" }
            mark_tasks_done = state.steps.find { |step| step.name == "mark-tasks-done" }

            refute_nil onboard
            assert_equal 2, work_steps.length
            refute_nil verify_suite
            refute_nil create_pr
            refute_nil mark_tasks_done

            assert_nil onboard.skill
            work_steps.each { |step| assert_nil step.skill }
            assert_nil verify_suite.skill
            assert_nil create_pr.skill
            assert_nil mark_tasks_done.skill
            assert_includes File.read(onboard.file_path), "source_skill: as-onboard"
            assert_includes File.read(work_steps[0].file_path), "source_skill: as-task-work"
            assert_includes File.read(work_steps[1].file_path), "source_skill: as-task-work"
            assert_includes work_steps[0].instructions, "# Work on Task"
            assert_includes File.read(verify_suite.file_path), "source_skill: as-test-verify-suite"
            assert_includes File.read(create_pr.file_path), "source_skill: as-github-pr-create"

            assert_equal "mark-tasks-done", mark_tasks_done.name
            assert_includes File.read(mark_tasks_done.file_path), "source_workflow: wfi://task/update"
            refute_includes File.read(mark_tasks_done.file_path), "<taskref>"
          end
        ensure
          ENV["PROJECT_ROOT_PATH"] = original_project_root
          ENV["HOME"] = original_home
          Ace::Assign.reset_config!
        end
      end
    end
  end

  private

  def materialize_preset_steps(project_root, preset_name, params)
    preset_path = File.join(project_root, "ace-assign", ".ace-defaults", "assign", "presets", "#{preset_name}.yml")
    preset = YAML.safe_load_file(preset_path, permitted_classes: [Date, Time]) || {}

    if Ace::Assign::Atoms::PresetExpander.has_expansion?(preset)
      Ace::Assign::Atoms::PresetExpander.expand(preset, params)
    else
      deep_replace_placeholders(preset.fetch("steps"), params)
    end
  end

  def deep_replace_placeholders(value, params)
    case value
    when Array
      value.map { |entry| deep_replace_placeholders(entry, params) }
    when Hash
      value.transform_values { |entry| deep_replace_placeholders(entry, params) }
    when String
      params.reduce(value) do |text, (key, replacement)|
        text.gsub("{{#{key}}}", Array(replacement).join(", "))
      end
    else
      value
    end
  end
end
