# frozen_string_literal: true

require_relative "../test_helper"

# E2E Test: MT-COWORKER-001 - Work Queue Session Lifecycle
#
# This test validates the complete ace-coworker workflow:
# - Start session from YAML config
# - Progress through steps with reports
# - Handle failures
# - Add dynamic steps
# - Retry failed steps
# - Complete workflow
class SessionLifecycleE2ETest < AceCoworkerTestCase
  def test_complete_session_lifecycle
    with_temp_cache do |cache_dir|
      Ace::Coworker.config["cache_dir"] = cache_dir

      # Create realistic job config
      config = {
        "session" => {
          "name" => "foobar-gem-session",
          "description" => "Create a minimal Ruby gem with FooBar class"
        },
        "steps" => [
          { "name" => "init-project", "instructions" => "Create lib/ and test/ directories" },
          { "name" => "write-tests", "instructions" => "Create test/foo_bar_test.rb" },
          { "name" => "implement-foobar", "instructions" => "Create lib/foo_bar.rb" },
          { "name" => "run-tests", "instructions" => "Run ruby -Ilib:test test/*" },
          { "name" => "report-status", "instructions" => "Final summary" }
        ]
      }
      config_path = File.join(cache_dir, "job.yaml")
      File.write(config_path, config.to_yaml)

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)

      # TC-001: Start session
      result = executor.start(config_path)
      assert_equal "foobar-gem-session", result[:session].name
      assert_equal 5, result[:state].size
      assert_equal "init-project", result[:current].name
      assert_equal :in_progress, result[:current].status

      # Verify initial queue state
      state = result[:state]
      assert_equal 1, state.done.size + state.failed.size + (state.current ? 1 : 0) - 1 + 1 # 1 in_progress
      assert_equal 4, state.pending.size

      # TC-002: Complete init
      report_path = File.join(cache_dir, "init-report.md")
      File.write(report_path, "Created lib/ and test/ directories")
      result = executor.advance(report_path)
      assert_equal "init-project", result[:completed].name
      assert_equal "write-tests", result[:current].name

      # TC-003: Progress through implementation
      File.write(report_path, "Created test file")
      executor.advance(report_path)

      File.write(report_path, "Implemented FooBar class")
      result = executor.advance(report_path)
      assert_equal "run-tests", result[:current].name

      # TC-004: Simulate test failure
      result = executor.fail("2 tests failed: test_greet, test_shout")
      assert_equal :failed, result[:state].find_by_number("040").status
      assert_nil result[:state].current # No current step after failure

      # TC-005: Add fix step dynamically
      result = executor.add("fix-implementation", "Fix the FooBar bug")
      assert_equal "fix-implementation", result[:added].name
      assert_equal "dynamic", result[:added].added_by
      # Note: when there's no current step, add creates one as in_progress
      assert_equal :in_progress, result[:added].status

      # Complete fix step
      File.write(report_path, "Fixed the implementation bug")
      result = executor.advance(report_path)
      assert_equal "fix-implementation", result[:completed].name

      # TC-006: Retry failed step
      result = executor.retry_step("040")
      assert_equal "run-tests", result[:retry].name
      assert_equal "retry_of:040", result[:retry].added_by
      # Original should still show as failed
      original = result[:state].find_by_number("040")
      assert_equal :failed, original.status

      # Mark retry step as in_progress and complete
      retry_step = result[:retry]
      writer = Ace::Coworker::Molecules::StepWriter.new
      writer.mark_in_progress(retry_step.file_path)

      File.write(report_path, "All tests pass now!")
      result = executor.advance(report_path)

      # Complete final step
      File.write(report_path, "Created FooBar gem successfully")
      result = executor.advance(report_path)

      # TC-007: Verify complete workflow
      final_state = executor.status[:state]

      # Should have 7 items total (5 original + 1 fix + 1 retry)
      assert_equal 7, final_state.size

      # Check that original failed step is preserved
      failed_step = final_state.find_by_number("040")
      assert_equal :failed, failed_step.status
      assert_equal "2 tests failed: test_greet, test_shout", failed_step.error

      # Session should be complete
      assert final_state.complete?

      # Verify history preservation
      done_count = final_state.done.size
      failed_count = final_state.failed.size
      assert done_count >= 5 # At least original steps minus failed + fix + retry
      assert_equal 1, failed_count # One failed step preserved

      Ace::Coworker.reset_config!
    end
  end

  def test_happy_path_no_failures
    with_temp_cache do |cache_dir|
      Ace::Coworker.config["cache_dir"] = cache_dir

      config = {
        "session" => { "name" => "simple-session" },
        "steps" => [
          { "name" => "step-1", "instructions" => "First step" },
          { "name" => "step-2", "instructions" => "Second step" },
          { "name" => "step-3", "instructions" => "Third step" }
        ]
      }
      config_path = File.join(cache_dir, "job.yaml")
      File.write(config_path, config.to_yaml)

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      report_path = File.join(cache_dir, "report.md")

      # Complete all steps
      3.times do |i|
        File.write(report_path, "Step #{i + 1} done")
        executor.advance(report_path)
      end

      final_state = executor.status[:state]

      assert final_state.complete?
      assert_equal 3, final_state.done.size
      assert_equal 0, final_state.failed.size
      assert_nil final_state.current

      Ace::Coworker.reset_config!
    end
  end

  def test_dynamic_step_insertion_order
    with_temp_cache do |cache_dir|
      Ace::Coworker.config["cache_dir"] = cache_dir

      config = {
        "session" => { "name" => "insertion-test" },
        "steps" => [
          { "name" => "step-010", "instructions" => "First" },
          { "name" => "step-020", "instructions" => "Second" },
          { "name" => "step-030", "instructions" => "Third" }
        ]
      }
      config_path = File.join(cache_dir, "job.yaml")
      File.write(config_path, config.to_yaml)

      executor = Ace::Coworker::Organisms::WorkflowExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      # Add dynamic step while step 010 is in progress
      result = executor.add("dynamic-step", "Inserted step")

      # Dynamic step should be 011 (after current 010)
      assert_equal "011", result[:added].number

      # Verify order in queue
      state = result[:state]
      numbers = state.steps.map(&:number)
      assert_equal ["010", "011", "020", "030"], numbers

      Ace::Coworker.reset_config!
    end
  end
end
