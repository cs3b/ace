# frozen_string_literal: true

require_relative "../test_helper"

class StatusCommandTest < AceCoworkerTestCase
  def test_status_with_active_session
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Coworker.config["cache_dir"] = cache_dir

      # Start a session first
      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      result = nil
      output = capture_io do
        result = Ace::Coworker::CLI::Commands::Status.new.call
      end

      assert_equal 0, result
      assert_includes output.first, "QUEUE - Session: test-session"
      assert_includes output.first, "010-init.j.md"
      assert_includes output.first, "In Progress"

      Ace::Coworker.reset_config!
    end
  end

  def test_status_without_session
    with_temp_cache do |cache_dir|
      Ace::Coworker.config["cache_dir"] = cache_dir

      result = nil
      output = capture_io do
        result = Ace::Coworker::CLI::Commands::Status.new.call
      end

      assert_equal 2, result
      assert_includes output.first, "Error:"
      assert_includes output.first, "No active session"

      Ace::Coworker.reset_config!
    end
  end
end
