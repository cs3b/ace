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
end
