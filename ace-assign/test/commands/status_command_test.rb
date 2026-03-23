# frozen_string_literal: true

require_relative "../test_helper"
require "json"

class StatusCommandTest < AceAssignTestCase
  def test_status_with_active_assignment
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Assign.config["cache_dir"] = cache_dir

      # Start an assignment first
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      result = nil
      output = capture_io do
        result = Ace::Assign::CLI::Commands::Status.new.call
      end
      assert_nil result  # Verify success returns nil
      assert_includes output.first, "QUEUE - Assignment: test-session"
      assert_includes output.first, "010-init.st.md"
      assert_includes output.first, "Active"

      Ace::Assign.reset_config!
    end
  end

  def test_status_without_assignment
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      error = assert_raises(Ace::Support::Cli::Error) do
        Ace::Assign::CLI::Commands::Status.new.call
      end

      assert_equal 2, error.exit_code
      assert_includes error.message, "No active assignment"

      Ace::Assign.reset_config!
    end
  end

  def test_status_with_json_format
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(format: "json")
      end

      payload = JSON.parse(output.first)
      assert_equal result[:assignment].id, payload.dig("assignment", "id")
      assert_equal "test-session", payload.dig("assignment", "name")
      assert_equal "running", payload.dig("assignment", "state")
      assert_equal "0/3 done", payload["progress"]
      assert_equal 3, payload["steps"].size
      assert_equal "010", payload.dig("steps", 0, "number")
      assert_equal "init", payload.dig("steps", 0, "name")
      assert_equal "in_progress", payload.dig("steps", 0, "status")
      assert_equal "010", payload.dig("current_step", "number")
      assert_equal "init", payload.dig("current_step", "name")
      assert_nil payload.dig("steps", 0, "parallel")
      assert_nil payload.dig("steps", 0, "max_parallel")

      Ace::Assign.reset_config!
    end
  end

  def test_status_with_json_format_has_null_current_step_when_completed
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)
      report = create_report(cache_dir, "done")
      3.times { executor.advance(report) }

      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(format: "json")
      end

      payload = JSON.parse(output.first)
      assert_equal "completed", payload.dig("assignment", "state")
      assert_nil payload["current_step"]
      assert_equal "3/3 done", payload["progress"]

      Ace::Assign.reset_config!
    end
  end

  def test_status_json_includes_batch_scheduler_metadata
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "batch-items",
          "instructions" => "Batch parent",
          "batch_parent" => true,
          "parallel" => true,
          "max_parallel" => 3,
          "fork_retry_limit" => 1
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(format: "json", assignment: result[:assignment].id)
      end

      payload = JSON.parse(output.first)
      step = payload.fetch("steps").first
      assert_equal true, step["batch_parent"]
      assert_equal true, step["parallel"]
      assert_equal 3, step["max_parallel"]
      assert_equal 1, step["fork_retry_limit"]

      Ace::Assign.reset_config!
    end
  end

  def test_status_with_scoped_done_fork_step_omits_fork_execution_guidance
    with_temp_cache do |cache_dir|
      steps = [
        {"name" => "leaf-fork", "instructions" => "Run leaf in fork", "context" => "fork"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)
      report = create_report(cache_dir, "done")
      executor.advance(report)

      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(assignment: "#{result[:assignment].id}@010")
      end

      assert_includes output.first, "Assignment completed!"
      refute_includes output.first, "Current Step:"
      refute_includes output.first, "Execute this step in a forked context:"
      refute_includes output.first, "To execute entire subtree in one forked process:"

      Ace::Assign.reset_config!
    end
  end

  def test_status_shows_fork_subtree_guidance_for_leaf_step
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(assignment: "#{result[:assignment].id}@010")
      end

      assert_includes output.first, "Current Step: 010.01 - onboard"
      assert_includes output.first, "Instructions:"

      Ace::Assign.reset_config!
    end
  end

  def test_status_with_assignment_scope_shows_scoped_step_when_global_current_is_elsewhere
    with_temp_cache do |cache_dir|
      steps = [
        {"name" => "subtree-a-step", "instructions" => "Work on A"},
        {"name" => "midcheck", "instructions" => "Run midcheck"},
        {"name" => "subtree-b-step", "instructions" => "Work on B"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(assignment: "#{result[:assignment].id}@020")
      end

      assert_includes output.first, "020-midcheck.st.md"
      assert_includes output.first, "Current Step: 020 - midcheck"
      assert_includes output.first, "Instructions:"
      assert_includes output.first, "Run midcheck"
      refute_includes output.first, "010-subtree-a-step.st.md"
      refute_includes output.first, "030-subtree-b-step.st.md"

      Ace::Assign.reset_config!
    end
  end

  def test_status_with_assignment_scope_uses_actionable_step_within_scope
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        },
        {"name" => "post-step", "instructions" => "Run post-step"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Global current is 010.01 (onboard), and scoped status should show actionable step inside scope.
      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(assignment: "#{result[:assignment].id}@010")
      end

      assert_includes output.first, "Current Step: 010.01 - onboard"

      Ace::Assign.reset_config!
    end
  end

  def test_status_ignores_fork_root_env_and_uses_explicit_targeting_only
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        },
        {"name" => "post-step", "instructions" => "Run post-step"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      ENV["ACE_ASSIGN_FORK_ROOT"] = "010"
      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(assignment: result[:assignment].id)
      end

      # Env var is ignored; without explicit scope full assignment status is shown.
      assert_includes output.first, "010.01"
      assert_includes output.first, "post-step"
    ensure
      ENV.delete("ACE_ASSIGN_FORK_ROOT")
      Ace::Assign.reset_config!
    end
  end

  def test_status_with_explicit_scope_remains_scoped_even_if_env_is_set
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        },
        {"name" => "post-step", "instructions" => "Run post-step"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      ENV["ACE_ASSIGN_FORK_ROOT"] = "010"
      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(assignment: "#{result[:assignment].id}@020")
      end

      assert_includes output.first, "020-post-step.st.md"
      assert_includes output.first, "Current Step: 020 - post-step"
      refute_includes output.first, "010.01"
    ensure
      ENV.delete("ACE_ASSIGN_FORK_ROOT")
      Ace::Assign.reset_config!
    end
  end

  def test_status_with_nested_scope_renders_subtree_hierarchy
    with_temp_cache do |cache_dir|
      steps = [
        {"name" => "root-step", "instructions" => "Start root"},
        {"name" => "post-step", "instructions" => "Run post-step"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)
      executor.add("child-step", "Child work", after: "010", as_child: true)
      executor.add("grandchild-step", "Grandchild work", after: "010.01", as_child: true)

      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(assignment: "#{result[:assignment].id}@010.01")
      end

      assert_includes output.first, "010.01"
      assert_includes output.first, "010.01.01"
      assert_includes output.first, "Current Step: 010.01.01 - grandchild-step"
      refute_includes output.first, "020-post-step.st.md"

      Ace::Assign.reset_config!
    end
  end

  def test_status_prefers_assignment_target_over_filter
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        },
        {"name" => "post-step", "instructions" => "Run post-step"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(
          assignment: "#{result[:assignment].id}@020",
          filter: "010.01"
        )
      end

      assert_includes output.first, "020-post-step.st.md"
      assert_includes output.first, "Current Step: 020 - post-step"
      refute_includes output.first, "Current Step: 010.01 - onboard"

      Ace::Assign.reset_config!
    end
  end

  def test_status_shows_fork_pid_info_when_available
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "sub_steps" => ["onboard"]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)
      step_writer = Ace::Assign::Molecules::StepWriter.new
      step_writer.record_fork_pid_info(
        File.join(cache_dir, result[:assignment].id, "steps", "010-work-on-task.st.md"),
        launch_pid: 35_5349,
        tracked_pids: [3_553_666, 3_553_667],
        pid_file: File.join(cache_dir, result[:assignment].id, "pids", "010.pid.yml")
      )

      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(assignment: "#{result[:assignment].id}@010")
      end

      assert_includes output.first, "Scoped Fork PID: 355349"
      assert_includes output.first, "Scoped Fork PID Tree: 3553666, 3553667"
      assert_includes output.first, "Scoped Fork PID File:"

      Ace::Assign.reset_config!
    end
  end

  def test_status_shows_fork_column_for_steps_with_children
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "batch-items",
          "instructions" => "Batch container without fork context",
          "batch_parent" => true,
          "parallel" => true,
          "max_parallel" => 3
        },
        {"name" => "fork-leaf", "instructions" => "Run leaf in fork", "context" => "fork"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)
      executor.add("child-inline", "Inline child", after: "010", as_child: true)

      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(assignment: result[:assignment].id)
      end

      # Header should include FORK column
      assert_includes output.first, "FORK"

      # Step with children (010) but no fork context should not show "yes" in FORK column.
      assert_match(/010\s+.*batch-items\s+\s+\(0\/1 done\)/, output.first)
      refute_match(/010\s+.*batch-items\s+yes/, output.first)

      # Child step without fork context should not show "yes".
      refute_match(/010\.01\s+.*child-inline\s+yes/, output.first)

      # Leaf step with context: fork should show "yes" even without children.
      assert_match(/020\s+.*fork-leaf\s+yes/, output.first)

      Ace::Assign.reset_config!
    end
  end
end
