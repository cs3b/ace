# frozen_string_literal: true

require_relative "../test_helper"

class RetryCmdTest < AceCoworkerTestCase
  def test_retry_creates_linked_step
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir)

      Ace::Coworker.config["cache_dir"] = cache_dir

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)
      executor.start(config_path)
      executor.advance(report_path) # Complete init
      executor.fail("Failed")       # Fail build

      result = nil
      output = capture_io do
        result = Ace::Coworker::CLI::Commands::RetryCmd.new.call(step_ref: "020")
      end
      assert_nil result  # Verify success returns nil
      assert_includes output.first, "retry of 020"

      Ace::Coworker.reset_config!
    end
  end

  def test_retry_nonexistent_step
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Coworker.config["cache_dir"] = cache_dir

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      error = assert_raises(Ace::Core::CLI::Error) do
        Ace::Coworker::CLI::Commands::RetryCmd.new.call(step_ref: "999")
      end

      assert_equal 4, error.exit_code
      assert_includes error.message, "not found"

      Ace::Coworker.reset_config!
    end
  end

  def test_retry_without_session
    with_temp_cache do |cache_dir|
      Ace::Coworker.config["cache_dir"] = cache_dir

      error = assert_raises(Ace::Core::CLI::Error) do
        Ace::Coworker::CLI::Commands::RetryCmd.new.call(step_ref: "010")
      end

      assert_equal 2, error.exit_code
      assert_includes error.message, "No active session"

      Ace::Coworker.reset_config!
    end
  end
end
