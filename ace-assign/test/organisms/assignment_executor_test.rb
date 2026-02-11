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
        { "name" => "onboard", "skill" => "ace:onboard", "instructions" => "Load context" },
        { "name" => "work", "skill" => "ace:work-on-task", "instructions" => "Do work" },
        { "name" => "review", "instructions" => "Review changes" }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Verify skill is persisted in phase files
      phases_dir = result[:assignment].phases_dir
      phase_files = Dir.glob(File.join(phases_dir, "*.ph.md")).sort

      first_content = File.read(phase_files[0])
      assert_includes first_content, "skill: ace:onboard"

      second_content = File.read(phase_files[1])
      assert_includes second_content, "skill: ace:work-on-task"

      # Third phase has no skill — should not have skill key
      third_content = File.read(phase_files[2])
      refute_includes third_content, "skill:"
    end
  end

  def test_start_persists_skill_readable_by_queue_scanner
    with_temp_cache do |cache_dir|
      phases = [
        { "name" => "work", "skill" => "ace:work-on-task", "instructions" => "Do work" },
        { "name" => "review", "instructions" => "Review" }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assert_equal "ace:work-on-task", result[:current].skill
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

  def test_start_archives_config_to_task_phases_dir
    with_temp_cache do |cache_dir|
      task_dir = File.join(cache_dir, "task-folder")
      FileUtils.mkdir_p(task_dir)
      config_path = create_test_config(task_dir)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Original should be gone
      refute File.exist?(config_path), "Original job.yaml should be removed"

      # Archived copy should exist in task's phases/ dir
      archived = File.join(task_dir, "phases", "#{result[:assignment].id}-job.yml")
      assert File.exist?(archived), "Archived job.yml should exist in task phases dir"

      # Content should be valid YAML
      data = YAML.safe_load_file(archived)
      assert_equal "test-session", data["session"]["name"]
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
end
