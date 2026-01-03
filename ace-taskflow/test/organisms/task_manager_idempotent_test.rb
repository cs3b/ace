# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/organisms/task_manager"

class TaskManagerIdempotentTest < AceTaskflowTestCase
  # Include ConfigHelpers for with_real_config
  include Ace::TestSupport::ConfigHelpers

  # Test idempotent status updates
  def test_update_status_to_same_status_succeeds
    with_real_config do
      with_test_project do |dir|
        Dir.chdir(dir) do
          manager = Ace::Taskflow::Organisms::TaskManager.new
          # Update a task to its current status
          result = manager.update_task_status("001", "done")

          assert result[:success], "Should succeed when updating to same status"
          assert_match(/already has status/, result[:message])
        end
      end
    end
  end

  def test_update_status_idempotent_multiple_times
    with_real_config do
      with_test_project do |dir|
        Dir.chdir(dir) do
          manager = Ace::Taskflow::Organisms::TaskManager.new
          # First update
          result1 = manager.update_task_status("002", "in-progress")
          assert result1[:success]

          # Second update to same status (idempotent)
          result2 = manager.update_task_status("002", "in-progress")
          assert result2[:success], "Second update should succeed (idempotent)"
          assert_match(/already has status/, result2[:message])

          # Third update to same status (still idempotent)
          result3 = manager.update_task_status("002", "in-progress")
          assert result3[:success], "Third update should succeed (idempotent)"
          assert_match(/already has status/, result3[:message])
        end
      end
    end
  end

  # Test flexible transitions (default behavior)
  def test_flexible_transition_pending_to_done
    with_real_config do
      with_test_project do |dir|
        Dir.chdir(dir) do
          manager = Ace::Taskflow::Organisms::TaskManager.new
          # In flexible mode (default), can go directly from pending to done
          result = manager.update_task_status("003", "done")
          assert result[:success], "Should allow pending → done in flexible mode"
        end
      end
    end
  end

  def test_flexible_transition_draft_to_done
    with_real_config do
      with_test_project do |dir|
        Dir.chdir(dir) do
          manager = Ace::Taskflow::Organisms::TaskManager.new
          # Create a task in draft status
          task_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "050", "task.050.s.md")
          FileUtils.mkdir_p(File.dirname(task_file))
          File.write(task_file, TestFactory.sample_task_content(
            id: "v.0.9.0+task.050",
            status: "draft"
          ))

          # In flexible mode, can go directly from draft to done
          result = manager.update_task_status("050", "done")
          assert result[:success], "Should allow draft → done in flexible mode"
        end
      end
    end
  end

  def test_flexible_transition_custom_status_to_done
    with_real_config do
      with_test_project do |dir|
        Dir.chdir(dir) do
          manager = Ace::Taskflow::Organisms::TaskManager.new
          # Create a task with custom status
          task_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "051", "task.051.s.md")
          FileUtils.mkdir_p(File.dirname(task_file))
          File.write(task_file, TestFactory.sample_task_content(
            id: "v.0.9.0+task.051",
            status: "ready-for-review"
          ))

          # In flexible mode, can transition from custom status
          result = manager.update_task_status("051", "done")
          assert result[:success], "Should allow custom → done in flexible mode"
        end
      end
    end
  end

  # Test complete_task idempotency
  def test_complete_task_idempotent
    with_real_config do
      with_test_project do |dir|
        Dir.chdir(dir) do
          manager = Ace::Taskflow::Organisms::TaskManager.new
          # First complete
          result1 = manager.complete_task("003")
          assert result1[:success], "First complete should succeed"

          # Get task to verify it's now in done status
          task = manager.show_task("003")
          assert_equal "done", task[:status]

          # Second complete (idempotent) - task already has done status
          result2 = manager.complete_task("003")
          assert result2[:success], "Second complete should succeed (idempotent)"
        end
      end
    end
  end

  def test_complete_already_done_task
    with_real_config do
      with_test_project do |dir|
        Dir.chdir(dir) do
          manager = Ace::Taskflow::Organisms::TaskManager.new
          # Task 001 is already done in test fixtures
          result = manager.complete_task("001")

          assert result[:success], "Completing already-done task should succeed"
          # Message should indicate it's already done
          assert_match(/already/, result[:message])
        end
      end
    end
  end

  # Test strict mode (opt-in via configuration)
  def test_strict_mode_enforces_rigid_validation
    with_real_config do
      with_test_project do |dir|
        Dir.chdir(dir) do
          # Enable strict transitions via configuration file (ADR-022 pattern)
          # Only override what we need - other settings come from gem defaults via ace-config
          config_file = File.join(dir, ".ace", "taskflow", "config.yml")
          FileUtils.mkdir_p(File.dirname(config_file))
          File.write(config_file, <<~YAML)
            taskflow:
              strict_transitions: true
              root: .ace-taskflow
          YAML

          # Reset all caches to pick up the new configuration
          Ace::Taskflow::Molecules::ConfigLoader.reset_gem_defaults!
          Ace::Taskflow.reset_configuration!
          Ace::Taskflow::Molecules::TaskLoader.clear_cache!
          Ace::Taskflow::Molecules::ReleaseResolver.clear_cache!

          strict_manager = Ace::Taskflow::Organisms::TaskManager.new

          # In strict mode, cannot go directly from pending to done
          result = strict_manager.update_task_status("003", "done")
          refute result[:success], "Should reject pending → done in strict mode"
          assert_match(/Invalid status transition/, result[:message])
        end
      end
    end
  end

  def test_strict_mode_rejects_custom_statuses
    with_real_config do
      with_test_project do |dir|
        Dir.chdir(dir) do
          # Create a task with custom status (using t/ directory matching gem defaults)
          task_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "052", "task.052.s.md")
          FileUtils.mkdir_p(File.dirname(task_file))
          File.write(task_file, TestFactory.sample_task_content(
            id: "v.0.9.0+task.052",
            status: "ready-for-review"
          ))

          # Enable strict transitions via configuration file (ADR-022 pattern)
          # Only override what we need - other settings come from gem defaults via ace-config
          config_file = File.join(dir, ".ace", "taskflow", "config.yml")
          FileUtils.mkdir_p(File.dirname(config_file))
          File.write(config_file, <<~YAML)
            taskflow:
              strict_transitions: true
              root: .ace-taskflow
          YAML

          # Reset all caches to pick up the new configuration
          Ace::Taskflow::Molecules::ConfigLoader.reset_gem_defaults!
          Ace::Taskflow.reset_configuration!
          Ace::Taskflow::Molecules::TaskLoader.clear_cache!
          Ace::Taskflow::Molecules::ReleaseResolver.clear_cache!

          strict_manager = Ace::Taskflow::Organisms::TaskManager.new

          # In strict mode, custom status transitions should fail
          result = strict_manager.update_task_status("052", "done")
          refute result[:success], "Should reject custom status in strict mode"
        end
      end
    end
  end

  # Test that flexible mode is the default
  def test_flexible_mode_is_default
    with_real_config do
      with_test_project do |dir|
        Dir.chdir(dir) do
          # Default manager (no config) should use flexible mode
          default_manager = Ace::Taskflow::Organisms::TaskManager.new

          # Should allow pending → done
          result = default_manager.update_task_status("003", "done")
          assert result[:success], "Default should be flexible mode"
        end
      end
    end
  end
end
