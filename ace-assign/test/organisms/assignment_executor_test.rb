# frozen_string_literal: true

require_relative "../test_helper"

class AssignmentExecutorTest < AceAssignTestCase
  def test_start_creates_assignment_and_phases
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

      assert_raises(Ace::Assign::ConfigNotFoundError) do
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

      assert_raises(Ace::Assign::NoActiveAssignmentError) do
        executor.status
      end
    end
  end

  def test_advance_completes_phase_and_moves_to_next
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

  def test_fail_marks_phase_as_failed
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      result = executor.fail("Something went wrong")

      assert_equal "init", result[:failed].name
      assert_equal :failed, result[:state].find_by_number("010").status
    end
  end

  def test_add_creates_dynamic_phase
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      result = executor.add("fix-bug", "Fix the bug")

      assert_equal "fix-bug", result[:added].name
      assert_equal "dynamic", result[:added].added_by
    end
  end

  def test_retry_creates_linked_phase
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)
      executor.advance(report_path) # Complete init
      executor.fail("Tests failed") # Fail build

      result = executor.retry_phase("020")

      assert_equal "build", result[:retry].name
      assert_equal "retry_of:020", result[:retry].added_by
      assert_equal :failed, result[:original].status
    end
  end

  def test_start_persists_skill_in_phase_files
    with_temp_cache do |cache_dir|
      phases = [
        { "name" => "onboard", "skill" => "as-onboard", "instructions" => "Load context" },
        { "name" => "work", "skill" => "ace_custom_work", "instructions" => "Do work" },
        { "name" => "review", "instructions" => "Review changes" }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Verify skill is persisted in phase files
      phases_dir = result[:assignment].phases_dir
      phase_files = Dir.glob(File.join(phases_dir, "*.ph.md")).sort

      first_content = File.read(phase_files[0])
      assert_includes first_content, "skill: as-onboard"

      second_content = File.read(phase_files[1])
      assert_includes second_content, "skill: ace_custom_work"

      # Third phase has no skill — should not have skill key
      third_content = File.read(phase_files[2])
      refute_includes third_content, "skill:"
    end
  end

  def test_start_persists_skill_readable_by_queue_scanner
    with_temp_cache do |cache_dir|
      phases = [
        { "name" => "work", "skill" => "ace_custom_work", "instructions" => "Do work" },
        { "name" => "review", "instructions" => "Review" }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assert_equal "ace_custom_work", result[:current].skill
      assert_nil result[:state].phases[1].skill
    end
  end

  def test_start_handles_array_instructions
    with_temp_cache do |cache_dir|
      phases = [
        { "name" => "array-phase", "instructions" => ["Line one.", "Line two.", "Line three."] },
        { "name" => "string-phase", "instructions" => "Single string instructions." }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Array instructions should be joined with newlines
      current = result[:current]
      assert_equal "array-phase", current.name
      assert_includes current.instructions, "Line one."
      assert_includes current.instructions, "Line two."
      assert_includes current.instructions, "Line three."

      # String instructions should pass through unchanged
      string_phase = result[:state].phases[1]
      assert_equal "Single string instructions.", string_phase.instructions.strip
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
      assert_equal "test-session", data["session"]["name"]
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

  def test_start_preserves_legacy_phase_archive_path
    with_temp_cache do |cache_dir|
      legacy_phases_dir = File.join(cache_dir, "task-folder", "phases")
      FileUtils.mkdir_p(legacy_phases_dir)
      config_path = create_test_config(legacy_phases_dir, name: "legacy-phase-spec")

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assert File.exist?(config_path), "Legacy phases config should remain in-place"
      assert_equal File.expand_path(config_path), result[:assignment].source_config

      unexpected_archive = File.join(legacy_phases_dir, "jobs", "#{result[:assignment].id}-job.yml")
      refute File.exist?(unexpected_archive), "Legacy phases config should not be moved into nested jobs/ directory"
    end
  end

  def test_full_workflow
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)

      # Start
      result = executor.start(config_path)

      # Complete all phases
      3.times do
        report_path = create_report(cache_dir, "Phase completed")
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
      assert_includes report_content, "phase: '010'"
      assert_includes report_content, "name: init"
      assert_includes report_content, "All done!"

      # Phase file should not have report embedded
      phase_file = File.join(assignment.phases_dir, "010-init.ph.md")
      phase_content = File.read(phase_file)
      refute_includes phase_content, "All done!"
    end
  end

  def test_start_persists_context_in_phase_files
    with_temp_cache do |cache_dir|
      phases = [
        { "name" => "prepare", "instructions" => "Load context" },
        { "name" => "implement", "context" => "fork", "instructions" => "Do the work" },
        { "name" => "verify", "instructions" => "Run tests" }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Verify context is persisted in phase files
      phases_dir = result[:assignment].phases_dir
      phase_files = Dir.glob(File.join(phases_dir, "*.ph.md")).sort

      # First phase has no context
      first_content = File.read(phase_files[0])
      refute_includes first_content, "context:"

      # Second phase has fork context
      second_content = File.read(phase_files[1])
      assert_includes second_content, "context: fork"

      # Third phase has no context
      third_content = File.read(phase_files[2])
      refute_includes third_content, "context:"
    end
  end

  def test_start_persists_context_readable_by_queue_scanner
    with_temp_cache do |cache_dir|
      phases = [
        { "name" => "prepare", "instructions" => "Load context" },
        { "name" => "implement", "context" => "fork", "instructions" => "Do the work" }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # First phase (current) has no context
      assert_nil result[:current].context
      refute result[:current].fork?

      # Second phase has fork context
      implement_phase = result[:state].phases[1]
      assert_equal "fork", implement_phase.context
      assert implement_phase.fork?
    end
  end

  # === Hierarchical Phase Tests ===

  def test_add_with_after_creates_sibling
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      # Add a phase after 010 (init)
      result = executor.add("verify", "Verify initialization", after: "010")

      assert_equal "verify", result[:added].name
      assert_equal "011", result[:added].number
      assert_equal "injected_after:010", result[:added].added_by
    end
  end

  def test_add_with_after_renumbers_existing
    with_temp_cache do |cache_dir|
      # Create assignment with phases at 010, 020, 030
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Add a phase after 010 - should create 011
      # Existing 020 and 030 should remain unchanged (they're not siblings of 010.xx)
      result = executor.add("verify", "Verify", after: "010")

      # The new phase should be 011
      assert_equal "011", result[:added].number

      # Get all current numbers
      numbers = result[:state].all_numbers
      assert_includes numbers, "010"
      assert_includes numbers, "011"
      assert_includes numbers, "020"
      assert_includes numbers, "030"
    end
  end

  def test_add_with_as_child_creates_nested_phase
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      # Add a child phase under 010 (init)
      result = executor.add("verify", "Verify initialization", after: "010", as_child: true)

      assert_equal "verify", result[:added].name
      assert_equal "010.01", result[:added].number
    end
  end

  def test_add_child_under_active_phase_rebalances_to_child
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

  def test_add_child_under_non_active_phase_keeps_existing_current
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

  def test_add_sibling_does_not_change_current_phase
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

      # Add nested phases
      executor.add("verify-init", "Verify", after: "010", as_child: true)
      result = executor.add("fix-init", "Fix issues", after: "010.01")

      # Get hierarchical structure
      hierarchy = result[:state].hierarchical

      # Should have 3 top-level phases (010, 020, 030)
      assert_equal 3, hierarchy.size

      # First phase (010) should have children
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

      # Add nested phases
      executor.add("verify", "Verify", after: "010", as_child: true) # 010.01
      executor.add("deep", "Deep", after: "010.01", as_child: true)  # 010.01.01

      result = executor.status

      # children_of should return only direct children
      children = result[:state].children_of("010")
      assert_equal 1, children.size
      assert_equal "010.01", children[0].number
    end
  end

  # === Sub-phase fork enforcement tests ===

  def test_start_with_sub_phases_creates_batch_parent_and_children
    with_temp_cache do |cache_dir|
      phases = [
        { "name" => "onboard", "instructions" => "Load context" },
        {
          "name" => "work-on-task",
          "instructions" => "Container for sub-phases",
          "sub_phases" => %w[onboard implement verify-tests]
        },
        { "name" => "review", "instructions" => "Review changes" }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

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
      parent_phase = state.find_by_number("020")
      assert_equal "fork", parent_phase.context

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

  def test_start_without_sub_phases_unchanged
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Standard 3-phase setup, no sub-phases
      assert_equal 3, result[:state].size
      numbers = result[:state].all_numbers
      assert_equal %w[010 020 030], numbers.sort
    end
  end

  def test_start_resolves_skill_assign_source_and_expands_sub_phases
    with_temp_cache do |cache_dir|
      project_root = File.join(cache_dir, "project")
      FileUtils.mkdir_p(File.join(project_root, ".claude", "skills", "ace_work-on-task"))
      FileUtils.mkdir_p(File.join(project_root, "ace-taskflow", "handbook", "workflow-instructions"))

      File.write(File.join(project_root, ".claude", "skills", "ace_work-on-task", "SKILL.md"), <<~MD)
        ---
        name: as-task-work
        assign:
          source: wfi://work-on-task
        ---
      MD

      File.write(File.join(project_root, "ace-taskflow", "handbook", "workflow-instructions", "work-on-task.wf.md"), <<~MD)
        ---
        assign:
          sub-phases:
            - onboard
            - task-load
            - plan-task
            - work-on-task
            - pre-commit-review
            - verify-test
            - release-minor
          context: fork
        ---
      MD

      phases = [
        { "name" => "work-on-task", "skill" => "as-task-work", "instructions" => "Do work" },
        { "name" => "review", "instructions" => "Review changes" }
      ]
      config_path = create_test_config(project_root, steps: phases)

      Dir.chdir(project_root) do
        original_project_root = ENV["PROJECT_ROOT_PATH"]
        ENV["PROJECT_ROOT_PATH"] = project_root
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

        parent_phase = state.find_by_number("010")
        assert_equal "fork", parent_phase.context
        assert_nil parent_phase.skill
        assert_includes parent_phase.instructions, "Subtree root orchestrator phase."
        assert_includes parent_phase.instructions, "ace-assign fork-run --assignment <assignment-id>@010"
        assert_includes parent_phase.instructions, "Do work"

        onboard_phase = state.find_by_number("010.01")
        task_load_phase = state.find_by_number("010.02")
        plan_phase = state.find_by_number("010.03")
        work_phase = state.find_by_number("010.04")
        review_phase = state.find_by_number("010.05")
        verify_phase = state.find_by_number("010.06")
        release_phase = state.find_by_number("010.07")

        assert_equal "onboard", onboard_phase.name
        assert_equal "plan-task", plan_phase.name
        assert_equal "work-on-task", work_phase.name
        assert_equal "task-load", task_load_phase.name
        assert_equal "pre-commit-review", review_phase.name
        assert_equal "verify-test", verify_phase.name
        assert_equal "release-minor", release_phase.name

        # First actionable child is activated (parent container is skipped)
        assert_equal "010.01", result[:current].number

        # Child phases materialize from phase catalog metadata
        assert_equal "as-onboard", onboard_phase.skill
        assert_equal "as-task-plan", plan_phase.skill
        assert_equal "as-task-work", work_phase.skill
        assert_nil review_phase.skill
        assert_nil verify_phase.skill
        assert_nil release_phase.skill

        # Parent is fork context: children remain non-fork and execute in same delegated subtree process
        assert_nil onboard_phase.context
        assert_nil plan_phase.context
        assert_nil work_phase.context
        assert_nil review_phase.context
        assert_nil task_load_phase.context
        assert_nil verify_phase.context
        assert_nil release_phase.context

        # Child instructions include parent task context for parameter extraction
        assert_includes work_phase.instructions, "Task context:"
        assert_includes work_phase.instructions, "Do work"
        assert_includes verify_phase.instructions, "Action:"
        assert_includes verify_phase.instructions, "Identify modified packages"
        assert_includes verify_phase.instructions, "ace-test --profile 6"
        assert_includes review_phase.instructions, "run native `/review`"
        assert_includes review_phase.instructions, "pre_commit_review_block"
        assert_includes release_phase.instructions, "Action:"
        assert_includes release_phase.instructions, "Run /as-release"
        assert_includes release_phase.instructions, "release all modified packages"
      ensure
        Ace::Assign.reset_config!
      end
    end
  end

  def test_child_action_instructions_support_release_suffix_variants
    executor = Ace::Assign::Organisms::AssignmentExecutor.new

    instructions = executor.send(:child_action_instructions, "release-patch-1", "Patch release follow-up")

    assert_includes instructions, "Run /as-release"
    assert_includes instructions, "release all modified packages"
  end

  def test_start_with_sub_phases_compacts_child_context_and_avoids_parent_boilerplate
    with_temp_dir do |project_root|
      cache_dir = File.join(project_root, ".cache", "ace-assign")
      FileUtils.mkdir_p(cache_dir)

      skill_dir = File.join(project_root, ".agents", "skills", "ace_work-on-task")
      FileUtils.mkdir_p(skill_dir)
      File.write(File.join(skill_dir, "SKILL.md"), <<~MD)
        ---
        name: as-task-work
        assign:
          sub-phases:
            - onboard
            - plan-task
            - work-on-task
          context: fork
        ---
      MD

      phases = [
        {
          "name" => "work-on-task",
          "skill" => "as-task-work",
          "taskref" => "235.01",
          "sub_phases" => %w[onboard plan-task work-on-task],
          "instructions" => "First: onboard yourself using /as-onboard skill to load project context.\n" \
                            "Implement the selected task.\n" \
                            "When complete, mark the task as done: run `ace-taskflow task done 235.01`"
        }
      ]
      config_path = create_test_config(project_root, steps: phases)

      Dir.chdir(project_root) do
        original_project_root = ENV["PROJECT_ROOT_PATH"]
        ENV["PROJECT_ROOT_PATH"] = project_root
        Ace::Assign.reset_config!
        executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
        result = executor.start(config_path)
        state = result[:state]

        plan_phase = state.find_by_number("010.02")
        work_phase = state.find_by_number("010.03")

        assert_includes plan_phase.instructions, "Task reference: 235.01"
        assert_includes work_phase.instructions, "Task reference: 235.01"
        assert_includes File.read(plan_phase.file_path), "taskref: '235.01'"
        assert_includes File.read(work_phase.file_path), "taskref: '235.01'"
        assert_includes plan_phase.instructions, "Action:"
        assert_includes plan_phase.instructions, "Analyze requirements for task 235.01."
        assert_includes work_phase.instructions, "Action:"
        assert_includes work_phase.instructions, "Implement the required changes for task 235.01."
        assert_includes plan_phase.instructions, "Verification checklist (from parent phase goals):"
        assert_includes plan_phase.instructions, "- First: onboard yourself using /as-onboard skill to load project context."
        assert_includes work_phase.instructions, "- When complete, mark the task as done: run `ace-taskflow task done 235.01`"
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

  def test_start_with_sub_phases_uses_project_split_parent_template_and_preserves_default_catalog_entries
    with_temp_dir do |project_root|
      cache_dir = File.join(project_root, ".cache", "ace-assign")
      FileUtils.mkdir_p(cache_dir)

      project_catalog_dir = File.join(project_root, ".ace", "assign", "catalog", "phases")
      FileUtils.mkdir_p(project_catalog_dir)
      File.write(File.join(project_catalog_dir, "split-subtree-root.phase.yml"), <<~YAML)
        name: split-subtree-root
        instructions:
          common:
            - "CUSTOM ROOT {{parent_number}}"
            - "children={{sub_phases}}"
          fork:
            - "CUSTOM FORK {{parent_number}}"
        goal_header: "Custom goal header:"
      YAML

      phases = [
        {
          "name" => "work-on-task",
          "context" => "fork",
          "instructions" => "Implement task 235.01",
          "sub_phases" => ["onboard"]
        }
      ]
      config_path = create_test_config(project_root, steps: phases)

      Dir.chdir(project_root) do
        original_project_root = ENV["PROJECT_ROOT_PATH"]
        ENV["PROJECT_ROOT_PATH"] = project_root
        Ace::Assign.reset_config!
        executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
        result = executor.start(config_path)
        state = result[:state]

        parent_phase = state.find_by_number("010")
        child_phase = state.find_by_number("010.01")

        assert_includes parent_phase.instructions, "CUSTOM ROOT 010"
        assert_includes parent_phase.instructions, "children=onboard"
        assert_includes parent_phase.instructions, "CUSTOM FORK 010"
        assert_includes parent_phase.instructions, "Custom goal header:"

        # Project override should not replace entire catalog; default child phase metadata must still resolve.
        assert_equal "as-onboard", child_phase.skill
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

      # Add nested phases
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
      phases = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_phases" => %w[onboard plan-task]
        },
        { "name" => "review", "instructions" => "Review changes" }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

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

  def test_advance_with_fork_root_uses_subtree_phase_when_global_current_is_outside_scope
    with_temp_cache do |cache_dir|
      phases = [
        { "name" => "precheck", "instructions" => "Run precheck" },
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_phases" => %w[onboard plan-task]
        },
        { "name" => "postcheck", "instructions" => "Run postcheck" }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

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

  def test_advance_with_fork_root_raises_when_multiple_subtree_phases_are_in_progress
    with_temp_cache do |cache_dir|
      phases = [
        { "name" => "precheck", "instructions" => "Run precheck" },
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_phases" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      start_result = executor.start(config_path)
      assignment = start_result[:assignment]

      scanner = Ace::Assign::Molecules::QueueScanner.new
      writer = Ace::Assign::Molecules::PhaseWriter.new
      state = scanner.scan(assignment.phases_dir, assignment: assignment)
      writer.mark_in_progress(state.find_by_number("020.01").file_path)
      writer.mark_in_progress(state.find_by_number("020.02").file_path)

      report_path = create_report(cache_dir, "Scoped progress")
      error = assert_raises(Ace::Assign::InvalidPhaseStateError) do
        executor.advance(report_path, fork_root: "020")
      end

      assert_includes error.message, "multiple phases are in progress"
    end
  end
end
