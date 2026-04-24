# frozen_string_literal: true

require_relative "../../test_helper"

class FailCommandTest < AceAssignTestCase
  def test_fail_marks_step_failed
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)
      executor.start_step(step_number: "010")

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

      error = assert_raises(Ace::Support::Cli::Error) do
        Ace::Assign::CLI::Commands::Fail.new.call(message: "Error")
      end

      assert_equal 2, error.exit_code
      assert_includes error.message, "No active assignment"

      Ace::Assign.reset_config!
    end
  end

  def test_fail_with_assignment_flag
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)

      config1 = create_test_config(cache_dir, name: "first-task")
      result1 = executor.start(config1)

      config2 = create_test_config(cache_dir, name: "second-task")
      result2 = executor.start(config2)
      target_id = result2[:assignment].id

      target_executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      target_executor.assignment_manager.define_singleton_method(:find_active) { result2[:assignment] }
      target_executor.start_step(step_number: "010")

      output = capture_io do
        Ace::Assign::CLI::Commands::Fail.new.call(
          message: "Build broke",
          assignment: "#{target_id}@010"
        )
      end

      assert_includes output.first, "marked as failed"
      assert_includes output.first, "Build broke"

      # Verify the targeted assignment's current step was failed
      scanner = Ace::Assign::Molecules::QueueScanner.new
      target_state = scanner.scan(result2[:assignment].steps_dir, assignment: result2[:assignment])
      assert_equal :failed, target_state.assignment_state

      # Verify the first assignment was not affected
      first_state = scanner.scan(result1[:assignment].steps_dir, assignment: result1[:assignment])
      assert_equal :paused, first_state.assignment_state

      Ace::Assign.reset_config!
    end
  end

  def test_fail_with_assignment_scope_targets_active_step_inside_subtree
    with_temp_cache do |cache_dir|
      report_path = create_report(cache_dir, "Scoped progress")
      steps = [
        {"name" => "precheck", "instructions" => "Run precheck"},
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        },
        {"name" => "postcheck", "instructions" => "Run postcheck"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = build_fast_executor(cache_base: cache_dir)
      start = executor.start(config_path)
      target_id = start[:assignment].id
      executor.start_step(step_number: "010")
      writer = Ace::Assign::Molecules::StepWriter.new
      writer.mark_active(start[:state].find_by_number("020").file_path)
      executor.start_step(fork_root: "020")
      executor.start_step(step_number: "030")

      output = capture_io do
        Ace::Assign::CLI::Commands::Fail.new.call(
          message: "Scoped failure",
          assignment: "#{target_id}@020"
        )
      end

      assert_includes output.first, "Step 020.01 (onboard) marked as failed"

      scanner = Ace::Assign::Molecules::QueueScanner.new
      state = scanner.scan(start[:assignment].steps_dir, assignment: start[:assignment])
      assert_equal :failed, state.find_by_number("020.01").status
      assert_equal :active, state.find_by_number("030").status
    ensure
      Ace::Assign.reset_config!
    end
  end
end
