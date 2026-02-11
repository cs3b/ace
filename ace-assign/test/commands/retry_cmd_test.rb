# frozen_string_literal: true

require_relative "../test_helper"

class RetryCmdTest < AceAssignTestCase
  def test_retry_creates_linked_phase
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir)

      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)
      executor.advance(report_path) # Complete init
      executor.fail("Failed")       # Fail build

      result = nil
      output = capture_io do
        result = Ace::Assign::CLI::Commands::RetryCmd.new.call(phase_ref: "020")
      end
      assert_nil result  # Verify success returns nil
      assert_includes output.first, "retry of 020"

      Ace::Assign.reset_config!
    end
  end

  def test_retry_nonexistent_phase
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      error = assert_raises(Ace::Core::CLI::Error) do
        Ace::Assign::CLI::Commands::RetryCmd.new.call(phase_ref: "999")
      end

      assert_equal 4, error.exit_code
      assert_includes error.message, "not found"

      Ace::Assign.reset_config!
    end
  end

  def test_retry_without_assignment
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      error = assert_raises(Ace::Core::CLI::Error) do
        Ace::Assign::CLI::Commands::RetryCmd.new.call(phase_ref: "010")
      end

      assert_equal 2, error.exit_code
      assert_includes error.message, "No active assignment"

      Ace::Assign.reset_config!
    end
  end
end
