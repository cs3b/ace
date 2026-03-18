# frozen_string_literal: true

require_relative "../test_helper"

class RetryCmdTest < AceAssignTestCase
  def test_retry_creates_linked_step
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
        result = Ace::Assign::CLI::Commands::RetryCmd.new.call(step_ref: "020")
      end
      assert_nil result  # Verify success returns nil
      assert_includes output.first, "retry of 020"

      Ace::Assign.reset_config!
    end
  end

  def test_retry_nonexistent_step
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      error = assert_raises(Ace::Support::Cli::Error) do
        Ace::Assign::CLI::Commands::RetryCmd.new.call(step_ref: "999")
      end

      assert_equal 4, error.exit_code
      assert_includes error.message, "not found"

      Ace::Assign.reset_config!
    end
  end

  def test_retry_without_assignment
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      error = assert_raises(Ace::Support::Cli::Error) do
        Ace::Assign::CLI::Commands::RetryCmd.new.call(step_ref: "010")
      end

      assert_equal 2, error.exit_code
      assert_includes error.message, "No active assignment"

      Ace::Assign.reset_config!
    end
  end

  def test_retry_with_assignment_flag
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)

      config1 = create_test_config(cache_dir, name: "first-task")
      result1 = executor.start(config1)
      first_step_count = Dir.glob(File.join(result1[:assignment].steps_dir, "*.st.md")).size

      config2 = create_test_config(cache_dir, name: "second-task")
      result2 = executor.start(config2)
      target_id = result2[:assignment].id

      # Advance and fail the second assignment so we can retry
      report_path = create_report(cache_dir, "Done")
      target_executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      target_executor.assignment_manager.define_singleton_method(:find_active) { result2[:assignment] }
      target_executor.advance(report_path) # Complete step 010
      target_executor.fail("Failed")       # Fail step 020

      output = capture_io do
        Ace::Assign::CLI::Commands::RetryCmd.new.call(
          step_ref: "020",
          assignment: "#{target_id}@020"
        )
      end

      assert_includes output.first, "retry of 020"

      # Verify the retry step was added to the targeted assignment (4 steps: 3 original + 1 retry)
      target_steps = Dir.glob(File.join(result2[:assignment].steps_dir, "*.st.md"))
      assert_equal 4, target_steps.size, "Targeted assignment should have 4 steps (3 original + 1 retry)"

      # Verify the first assignment was not affected (still has original 3 steps)
      first_steps = Dir.glob(File.join(result1[:assignment].steps_dir, "*.st.md"))
      assert_equal first_step_count, first_steps.size, "First assignment should not have extra steps"

      Ace::Assign.reset_config!
    end
  end
end
