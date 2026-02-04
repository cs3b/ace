# frozen_string_literal: true

require "test_helper"

module Ace
  module Scheduler
    class TaskExecutorTest < AceSchedulerTestCase
      def test_run_command
        config = { tasks: {} }
        executor = Molecules::TaskExecutor.new(config)

        result = executor.run_command("echo hello", task: "test")
        assert_equal "success", result.status
        assert_equal 0, result.exit_code
        assert_includes result.stdout, "hello"
      end
    end
  end
end
