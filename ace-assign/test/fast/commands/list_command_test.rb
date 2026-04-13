# frozen_string_literal: true

require_relative "../../test_helper"

class ListCommandTest < AceAssignTestCase
  def test_list_shows_assignments
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      config_path = create_test_config(cache_dir)
      executor.start(config_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::List.new.call
      end

      assert_includes output.first, "test-session"
      assert_includes output.first, "running"
      assert_includes output.first, "1 assignment(s) found"

      Ace::Assign.reset_config!
    end
  end

  def test_list_no_assignments
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      output = capture_io do
        Ace::Assign::CLI::Commands::List.new.call
      end

      assert_includes output.first, "No assignments found"

      Ace::Assign.reset_config!
    end
  end

  def test_list_json_format
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      config_path = create_test_config(cache_dir)
      executor.start(config_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::List.new.call(format: "json")
      end

      parsed = JSON.parse(output.first)
      assert_instance_of Array, parsed
      assert_equal 1, parsed.size
      assert_equal "test-session", parsed.first["name"]
      assert_equal "running", parsed.first["state"]

      Ace::Assign.reset_config!
    end
  end

  def test_list_excludes_completed_by_default
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      # Create and complete an assignment
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      config_path = create_test_config(cache_dir, steps: [
        {"name" => "only-step", "instructions" => "Do it"}
      ])
      executor.start(config_path)
      report_path = create_report(cache_dir, "Done!")
      executor.advance(report_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::List.new.call
      end

      assert_includes output.first, "No active assignments"
      assert_includes output.first, "1 completed"
      assert_includes output.first, "--all"

      Ace::Assign.reset_config!
    end
  end

  def test_list_all_includes_completed
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      # Create and complete an assignment
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      config_path = create_test_config(cache_dir, steps: [
        {"name" => "only-step", "instructions" => "Do it"}
      ])
      executor.start(config_path)
      report_path = create_report(cache_dir, "Done!")
      executor.advance(report_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::List.new.call(all: true)
      end

      assert_includes output.first, "completed"
      assert_includes output.first, "1 assignment(s) found"

      Ace::Assign.reset_config!
    end
  end

  def test_list_filter_by_task
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      config_path = create_test_config(cache_dir)
      executor.start(config_path)

      # Match by name
      output = capture_io do
        Ace::Assign::CLI::Commands::List.new.call(task: "test-session")
      end
      assert_includes output.first, "test-session"
      assert_includes output.first, "1 assignment(s) found"

      # No match
      output = capture_io do
        Ace::Assign::CLI::Commands::List.new.call(task: "nonexistent")
      end
      assert_includes output.first, "No assignments found"

      Ace::Assign.reset_config!
    end
  end

  def test_list_tree_format
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      config_path = create_test_config(cache_dir)
      executor.start(config_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::List.new.call(tree: true)
      end

      # Tree output should contain the assignment name
      assert_includes output.first, "test-session"
      # Should not have table header
      refute_includes output.first, "ID"
      refute_includes output.first, "STATUS"

      Ace::Assign.reset_config!
    end
  end

  def test_list_tree_no_assignments
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      output = capture_io do
        Ace::Assign::CLI::Commands::List.new.call(tree: true)
      end

      assert_includes output.first, "No assignments found"

      Ace::Assign.reset_config!
    end
  end

  def test_list_marks_current_assignment
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      config_path = create_test_config(cache_dir)
      result = executor.start(config_path)

      # Set as current
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)
      manager.set_current(result[:assignment].id)

      output = capture_io do
        Ace::Assign::CLI::Commands::List.new.call
      end

      assert_includes output.first, "* = current selection"

      Ace::Assign.reset_config!
    end
  end
end
