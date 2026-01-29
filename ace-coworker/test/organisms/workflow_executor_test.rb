# frozen_string_literal: true

require_relative "../test_helper"

class WorkflowExecutorTest < AceCoworkerTestCase
  def test_start_creates_session_and_steps
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assert_equal "test-session", result[:session].name
      assert_equal 3, result[:state].size
      assert_equal "init", result[:current].name
      assert_equal :in_progress, result[:current].status
    end
  end

  def test_start_raises_for_missing_config
    with_temp_cache do |cache_dir|
      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)

      assert_raises(Ace::Coworker::ConfigNotFoundError) do
        executor.start("nonexistent.yaml")
      end
    end
  end

  def test_status_returns_current_state
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      result = executor.status

      assert_equal "test-session", result[:session].name
      assert_equal 3, result[:state].size
      assert_equal "init", result[:current].name
    end
  end

  def test_status_raises_without_session
    with_temp_cache do |cache_dir|
      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)

      assert_raises(Ace::Coworker::NoActiveSessionError) do
        executor.status
      end
    end
  end

  def test_advance_completes_step_and_moves_to_next
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir)

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)
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

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      result = executor.fail("Something went wrong")

      assert_equal "init", result[:failed].name
      assert_equal :failed, result[:state].find_by_number("010").status
    end
  end

  def test_add_creates_dynamic_step
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)
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

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)
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
        { "name" => "onboard", "skill" => "ace:onboard", "instructions" => "Load context" },
        { "name" => "work", "skill" => "ace:work-on-task", "instructions" => "Do work" },
        { "name" => "review", "instructions" => "Review changes" }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Verify skill is persisted in step files
      jobs_dir = result[:session].jobs_dir
      step_files = Dir.glob(File.join(jobs_dir, "*.j.md")).sort

      first_content = File.read(step_files[0])
      assert_includes first_content, "skill: ace:onboard"

      second_content = File.read(step_files[1])
      assert_includes second_content, "skill: ace:work-on-task"

      # Third step has no skill — should not have skill key
      third_content = File.read(step_files[2])
      refute_includes third_content, "skill:"
    end
  end

  def test_start_persists_skill_readable_by_queue_scanner
    with_temp_cache do |cache_dir|
      steps = [
        { "name" => "work", "skill" => "ace:work-on-task", "instructions" => "Do work" },
        { "name" => "review", "instructions" => "Review" }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assert_equal "ace:work-on-task", result[:current].skill
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

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)
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

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Original should be gone
      refute File.exist?(config_path), "Original job.yaml should be removed"

      # Archived copy should exist in task's jobs/ dir
      archived = File.join(task_dir, "jobs", "#{result[:session].id}-job.yml")
      assert File.exist?(archived), "Archived job.yml should exist in task jobs dir"

      # Content should be valid YAML
      data = YAML.safe_load_file(archived)
      assert_equal "test-session", data["session"]["name"]
    end
  end

  def test_full_workflow
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)

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

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      session = result[:session]
      reports_dir = session.reports_dir

      executor.advance(report_path)

      # Report should be in reports/ directory
      report_file = File.join(reports_dir, "010-init.r.md")
      assert File.exist?(report_file), "Report file should exist in reports directory"

      report_content = File.read(report_file)
      assert_includes report_content, "job: '010'"
      assert_includes report_content, "name: init"
      assert_includes report_content, "All done!"

      # Job file should not have report embedded
      job_file = File.join(session.jobs_dir, "010-init.j.md")
      job_content = File.read(job_file)
      refute_includes job_content, "All done!"
    end
  end
end
