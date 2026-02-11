# frozen_string_literal: true

require_relative "../test_helper"

class FailCommandTest < AceAssignTestCase
  def test_fail_marks_phase_failed
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      result = nil
      output = capture_io do
        result = Ace::Assign::CLI::Commands::Fail.new.call(message: "Tests failed")
      end
      assert_nil result  # Verify success returns nil
      assert_includes output.first, "marked as failed"
      assert_includes output.first, "Tests failed"

      Ace::Assign.reset_config!
    end
  end

  def test_fail_without_assignment
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      error = assert_raises(Ace::Core::CLI::Error) do
        Ace::Assign::CLI::Commands::Fail.new.call(message: "Error")
      end

      assert_equal 2, error.exit_code
      assert_includes error.message, "No active assignment"

      Ace::Assign.reset_config!
    end
  end
end
