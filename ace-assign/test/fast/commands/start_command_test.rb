# frozen_string_literal: true

require_relative "../../test_helper"

class StartCommandTest < AceAssignTestCase
  def test_start_starts_next_workable_step
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir, "Step done!")
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)
      executor.start_step
      executor.advance(report_path) # 010 done, 020 pending
      executor.start_step
      executor.fail("Blocked for retry") # no active step, 030 remains pending

      output = capture_io do
        Ace::Assign::CLI::Commands::Start.new.call
      end

      assert_includes output.first, "Step 030 (test) started"
      assert_includes output.first, "Next: ace-assign step 030"
      refute_includes output.first, "Instructions:"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_start_can_activate_another_pending_step_while_work_is_already_active
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)
      executor.start_step

      output = capture_io do
        Ace::Assign::CLI::Commands::Start.new.call
      end

      assert_includes output.first, "Step 020 (build) started"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_start_with_explicit_step_starts_targeted_step
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir, "Step done!")
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)
      executor.start_step
      executor.advance(report_path) # 010 done, 020 pending
      executor.start_step
      executor.fail("Skipping build")  # 020 failed, 030 pending

      output = capture_io do
        Ace::Assign::CLI::Commands::Start.new.call(step: "030")
      end

      assert_includes output.first, "Step 030 (test) started"
      assert_includes output.first, "Next: ace-assign step 030"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_start_prefers_marked_batch_parent_over_pending_child_descendants
    with_temp_cache do |cache_dir|
      steps = [
        {"number" => "000", "name" => "onboard", "instructions" => "Load context"},
        {"number" => "010", "name" => "batch-tasks", "instructions" => "Batch container instructions", "batch_parent" => true, "parallel" => false, "fork_retry_limit" => 1},
        {"number" => "010.01", "name" => "work-on-148", "parent" => "010", "context" => "fork", "instructions" => "Task context:\nWork on task 148"},
        {"number" => "020", "name" => "finalize", "instructions" => "Finalize"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      report_path = create_report(cache_dir, "Step done!")
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)
      executor.start_step
      executor.advance(report_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::Start.new.call
      end

      assert_includes output.first, "Step 010 (batch-tasks) started"
      assert_includes output.first, "Next: ace-assign step 010"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_start_with_explicit_step_allows_marked_batch_parent
    with_temp_cache do |cache_dir|
      steps = [
        {"number" => "000", "name" => "onboard", "instructions" => "Load context"},
        {"number" => "010", "name" => "batch-tasks", "instructions" => "Batch container instructions", "batch_parent" => true, "parallel" => false, "fork_retry_limit" => 1},
        {"number" => "010.01", "name" => "work-on-148", "parent" => "010", "context" => "fork", "instructions" => "Task context:\nWork on task 148"},
        {"number" => "020", "name" => "finalize", "instructions" => "Finalize"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      report_path = create_report(cache_dir, "Step done!")
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)
      executor.start_step
      executor.advance(report_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::Start.new.call(step: "010")
      end

      assert_includes output.first, "Step 010 (batch-tasks) started"
      assert_includes output.first, "Next: ace-assign step 010"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_start_prefers_pending_fork_root_over_child_descendants_globally
    with_temp_cache do |cache_dir|
      steps = [
        {"number" => "010", "name" => "precheck", "instructions" => "Precheck"},
        {"number" => "020", "name" => "review-cycle", "instructions" => "Review cycle", "context" => "fork"},
        {"number" => "020.01", "name" => "review-pr", "parent" => "020", "instructions" => "Review PR"},
        {"number" => "020.02", "name" => "release", "parent" => "020", "instructions" => "Release"},
        {"number" => "030", "name" => "postcheck", "instructions" => "Postcheck"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      report_path = create_report(cache_dir, "Step done!")
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)
      executor.start_step
      executor.advance(report_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::Start.new.call(assignment: result[:assignment].id)
      end

      assert_includes output.first, "Step 020 (review-cycle) started"
      assert_includes output.first, %(Next: ace-assign step 020 --assignment "#{result[:assignment].id}")
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_start_rejects_step_with_assignment_option
    error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Assign::CLI::Commands::Start.new.call(step: "010", assignment: "abc123")
    end

    assert_includes error.message, "Positional STEP targeting is only supported"
  end
end
