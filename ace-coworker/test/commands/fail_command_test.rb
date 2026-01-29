# frozen_string_literal: true

require_relative "../test_helper"

class FailCommandTest < AceCoworkerTestCase
  def test_fail_marks_step_failed
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Coworker.config["cache_dir"] = cache_dir

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      result = nil
      output = capture_io do
        result = Ace::Coworker::CLI::Commands::Fail.new.call(message: "Tests failed")
      end

      assert_equal 0, result
      assert_includes output.first, "marked as failed"
      assert_includes output.first, "Tests failed"

      Ace::Coworker.reset_config!
    end
  end

  def test_fail_without_session
    with_temp_cache do |cache_dir|
      Ace::Coworker.config["cache_dir"] = cache_dir

      result = nil
      output = capture_io do
        result = Ace::Coworker::CLI::Commands::Fail.new.call(message: "Error")
      end

      assert_equal 2, result
      assert_includes output.first, "No active session"

      Ace::Coworker.reset_config!
    end
  end
end
