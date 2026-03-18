# frozen_string_literal: true

require_relative "../test_helper"

class SelectCommandTest < AceAssignTestCase
  def test_select_sets_current_assignment
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      config_path = create_test_config(cache_dir)
      result = executor.start(config_path)
      assignment_id = result[:assignment].id

      output = capture_io do
        Ace::Assign::CLI::Commands::Select.new.call(id: assignment_id)
      end

      assert_includes output.first, "Selected assignment:"
      assert_includes output.first, assignment_id

      # Verify symlink was created
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)
      assert_equal assignment_id, manager.current_id

      Ace::Assign.reset_config!
    end
  end

  def test_select_clear
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      config_path = create_test_config(cache_dir)
      result = executor.start(config_path)
      assignment_id = result[:assignment].id

      # Select then clear
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir)
      manager.set_current(assignment_id)

      output = capture_io do
        Ace::Assign::CLI::Commands::Select.new.call(clear: true)
      end

      assert_includes output.first, "Cleared current assignment"
      assert_nil manager.current_id

      Ace::Assign.reset_config!
    end
  end

  def test_select_without_id_raises_error
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      error = assert_raises(Ace::Support::Cli::Error) do
        Ace::Assign::CLI::Commands::Select.new.call
      end

      assert_includes error.message, "Assignment ID required"

      Ace::Assign.reset_config!
    end
  end

  def test_select_nonexistent_raises_error
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      # Ensure cache_base directory exists
      FileUtils.mkdir_p(cache_dir)

      error = assert_raises(Ace::Support::Cli::Error) do
        Ace::Assign::CLI::Commands::Select.new.call(id: "nonexistent")
      end

      assert_includes error.message, "not found"

      Ace::Assign.reset_config!
    end
  end
end
