# frozen_string_literal: true

require "test_helper"
require "tmpdir"

module Ace
  module Scheduler
    class StateManagerTest < AceSchedulerTestCase
      def test_record_run_writes_state_and_history
        Dir.mktmpdir do |dir|
          state_dir = File.join(dir, "state")
          manager = Molecules::StateManager.new(state_dir: state_dir)

          result = Models::ExecutionResult.new(
            task: "daily-tests",
            status: "success",
            exit_code: 0,
            duration: 1.2,
            stdout: "ok",
            stderr: "",
            started_at: Time.now.utc
          )

          manager.record_run("daily-tests", result)
          state = manager.load_state

          assert_equal "success", state["daily-tests"]["status"]
          assert state["daily-tests"]["last_run"]

          history = manager.recent_history(limit: 1)
          assert_equal 1, history.length
          assert_equal "daily-tests", history.first["task"]
        end
      end
    end
  end
end
