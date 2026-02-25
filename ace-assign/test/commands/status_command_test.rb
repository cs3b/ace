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
      assert_includes output.first, "010-init.ph.md"
      assert_includes output.first, "Active"

      Ace::Assign.reset_config!
    end
  end

  def test_status_without_assignment
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      error = assert_raises(Ace::Core::CLI::Error) do
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
      assert_equal 3, payload["phases"].size
      assert_equal "010", payload.dig("phases", 0, "number")
      assert_equal "init", payload.dig("phases", 0, "name")
      assert_equal "in_progress", payload.dig("phases", 0, "status")
      assert_equal "010", payload.dig("current_phase", "number")
      assert_equal "init", payload.dig("current_phase", "name")

      Ace::Assign.reset_config!
    end
  end

  def test_status_with_json_format_has_null_current_phase_when_completed
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
      assert_nil payload["current_phase"]
      assert_equal "3/3 done", payload["progress"]

      Ace::Assign.reset_config!
    end
  end

  def test_status_shows_fork_subtree_guidance_for_leaf_phase
    with_temp_cache do |cache_dir|
      phases = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_phases" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(assignment: "#{result[:assignment].id}@010")
      end

      assert_includes output.first, "Current Phase: 010.01 - onboard"
      assert_includes output.first, "Instructions:"

      Ace::Assign.reset_config!
    end
  end

  def test_status_with_assignment_scope_shows_scoped_phase_when_global_current_is_elsewhere
    with_temp_cache do |cache_dir|
      phases = [
        { "name" => "subtree-a-step", "instructions" => "Work on A" },
        { "name" => "midcheck", "instructions" => "Run midcheck" },
        { "name" => "subtree-b-step", "instructions" => "Work on B" }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(assignment: "#{result[:assignment].id}@020")
      end

      assert_includes output.first, "020-midcheck.ph.md"
      assert_includes output.first, "Current Phase: 020 - midcheck"
      assert_includes output.first, "Instructions:"
      assert_includes output.first, "Run midcheck"
      refute_includes output.first, "010-subtree-a-step.ph.md"
      refute_includes output.first, "030-subtree-b-step.ph.md"

      Ace::Assign.reset_config!
    end
  end

  def test_status_with_assignment_scope_uses_actionable_phase_within_scope
    with_temp_cache do |cache_dir|
      phases = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_phases" => %w[onboard plan-task]
        },
        { "name" => "post-step", "instructions" => "Run post-step" }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Global current is 010.01 (onboard), and scoped status should show actionable phase inside scope.
      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(assignment: "#{result[:assignment].id}@010")
      end

      assert_includes output.first, "Current Phase: 010.01 - onboard"

      Ace::Assign.reset_config!
    end
  end

  def test_status_auto_scopes_to_fork_root_env
    with_temp_cache do |cache_dir|
      phases = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "sub_phases" => %w[onboard plan-task]
        },
        { "name" => "post-step", "instructions" => "Run post-step" }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      ENV["ACE_ASSIGN_FORK_ROOT"] = "010"
      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(assignment: result[:assignment].id)
      end

      # Should only show subtree phases, not post-step
      assert_includes output.first, "010"
      assert_includes output.first, "010.01"
      refute_includes output.first, "020-post-step.ph.md"
    ensure
      ENV.delete("ACE_ASSIGN_FORK_ROOT")
      Ace::Assign.reset_config!
    end
  end

  def test_status_explicit_scope_takes_priority_over_fork_root_env
    with_temp_cache do |cache_dir|
      phases = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "sub_phases" => %w[onboard plan-task]
        },
        { "name" => "post-step", "instructions" => "Run post-step" }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Set fork root to 010, but explicitly scope to 020
      ENV["ACE_ASSIGN_FORK_ROOT"] = "010"
      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(assignment: "#{result[:assignment].id}@020")
      end

      # Explicit scope @020 should win over env var
      assert_includes output.first, "020-post-step.ph.md"
      assert_includes output.first, "Current Phase: 020 - post-step"
      refute_includes output.first, "010.01"
    ensure
      ENV.delete("ACE_ASSIGN_FORK_ROOT")
      Ace::Assign.reset_config!
    end
  end

  def test_status_with_nested_scope_renders_subtree_hierarchy
    with_temp_cache do |cache_dir|
      phases = [
        { "name" => "root-step", "instructions" => "Start root" },
        { "name" => "post-step", "instructions" => "Run post-step" }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

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
      assert_includes output.first, "Current Phase: 010.01.01 - grandchild-step"
      refute_includes output.first, "020-post-step.ph.md"

      Ace::Assign.reset_config!
    end
  end

  def test_status_filter_scopes_by_phase_without_assignment_override
    with_temp_cache do |cache_dir|
      phases = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "sub_phases" => %w[onboard plan-task]
        },
        { "name" => "post-step", "instructions" => "Run post-step" }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(filter: "010.01")
      end

      assert_includes output.first, "010.01"
      refute_includes output.first, "020"

      Ace::Assign.reset_config!
    end
  end

  def test_status_filter_with_parenthesized_assignment_and_scope
    with_temp_cache do |cache_dir|
      phases = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "sub_phases" => %w[onboard plan-task]
        },
        { "name" => "post-step", "instructions" => "Run post-step" }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(filter: "(#{result[:assignment].id}@)010.01")
      end

      assert_includes output.first, "010.01"
      refute_includes output.first, "020"

      Ace::Assign.reset_config!
    end
  end

  def test_status_shows_fork_pid_info_when_available
    with_temp_cache do |cache_dir|
      phases = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "sub_phases" => ["onboard"]
        }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)
      phase_writer = Ace::Assign::Molecules::PhaseWriter.new
      phase_writer.record_fork_pid_info(
        File.join(cache_dir, result[:assignment].id, "phases", "010-work-on-task.ph.md"),
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

end
