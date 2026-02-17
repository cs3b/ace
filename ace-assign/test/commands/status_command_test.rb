# frozen_string_literal: true

require_relative "../test_helper"

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

  def test_status_shows_fork_subtree_marker_for_current_fork_root
    with_temp_cache do |cache_dir|
      phases = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork"
        }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)
      assignment_id = result[:assignment].id

      output = capture_io do
        Ace::Assign::CLI::Commands::Status.new.call(assignment: assignment_id)
      end

      assert_includes output.first, "Current Phase: 010 - work-on-task"
      assert_includes output.first, "Fork subtree detected (root: 010 - work-on-task)."
      assert_includes output.first, "ace-assign fork-run --assignment #{assignment_id}@010"

      Ace::Assign.reset_config!
    end
  end

  def test_status_in_fork_scope_shows_scope_only
    with_temp_cache do |cache_dir|
      phases = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork"
        }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)
      assignment_id = result[:assignment].id

      begin
        ENV["ACE_ASSIGN_FORK_ROOT"] = "010"
        output = capture_io do
          Ace::Assign::CLI::Commands::Status.new.call(assignment: assignment_id)
        end

        assert_includes output.first, "Fork scope: 010 (ACE_ASSIGN_FORK_ROOT=010)"
        refute_includes output.first, "Fork subtree detected (root:"
      ensure
        ENV.delete("ACE_ASSIGN_FORK_ROOT")
      end

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

end
