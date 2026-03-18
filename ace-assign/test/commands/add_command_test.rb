# frozen_string_literal: true

require_relative "../test_helper"

class AddCommandTest < AceAssignTestCase
  def test_add_creates_phase
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      result = nil
      output = capture_io do
        result = Ace::Assign::CLI::Commands::Add.new.call(
          name: "fix-bug",
          instructions: "Fix the bug"
        )
      end
      assert_nil result  # Verify success returns nil
      assert_includes output.first, "Created: phases/"
      assert_includes output.first, "fix-bug"

      Ace::Assign.reset_config!
    end
  end

  def test_add_without_assignment
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      error = assert_raises(Ace::Support::Cli::Error) do
        Ace::Assign::CLI::Commands::Add.new.call(name: "fix-bug")
      end

      assert_equal 2, error.exit_code
      assert_includes error.message, "No active assignment"

      Ace::Assign.reset_config!
    end
  end

  def test_add_with_after_option
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::Add.new.call(
          name: "verify",
          instructions: "Verify initialization",
          after: "010"
        )
      end

      assert_includes output.first, "Created: phases/"
      assert_includes output.first, "011-verify"
      assert_includes output.first, "sibling after 010"

      Ace::Assign.reset_config!
    end
  end

  def test_add_with_child_option
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::Add.new.call(
          name: "verify",
          instructions: "Verify initialization",
          after: "010",
          child: true
        )
      end

      assert_includes output.first, "Created: phases/"
      assert_includes output.first, "010.01-verify"
      assert_includes output.first, "child of 010"

      Ace::Assign.reset_config!
    end
  end

  def test_add_with_assignment_flag
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)

      config1 = create_test_config(cache_dir, name: "first-task")
      result1 = executor.start(config1)

      config2 = create_test_config(cache_dir, name: "second-task")
      result2 = executor.start(config2)
      target_id = result2[:assignment].id

      output = capture_io do
        Ace::Assign::CLI::Commands::Add.new.call(
          name: "hotfix",
          instructions: "Apply hotfix",
          assignment: "#{target_id}@010"
        )
      end

      assert_includes output.first, "Created: phases/"
      assert_includes output.first, "hotfix"

      # Verify the phase was added to the targeted assignment, not the first one
      target_phases_dir = result2[:assignment].phases_dir
      added_files = Dir.glob(File.join(target_phases_dir, "*hotfix*"))
      refute_empty added_files, "Phase should be added to the targeted assignment"

      # Verify the first assignment was not modified
      first_phases_dir = result1[:assignment].phases_dir
      first_hotfix = Dir.glob(File.join(first_phases_dir, "*hotfix*"))
      assert_empty first_hotfix, "First assignment should not have the new phase"

      Ace::Assign.reset_config!
    end
  end
end
