# frozen_string_literal: true

require_relative "../../test_helper"

class StartCommandTest < AceAssignTestCase
  def test_start_starts_next_workable_step
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir, "Step done!")
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)
      executor.advance(report_path) # 010 done, 020 in_progress
      executor.fail("Blocked for retry") # no active step, 030 remains pending

      output = capture_io do
        Ace::Assign::CLI::Commands::Start.new.call
      end

      assert_includes output.first, "Step 030 (test) started"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_start_fails_when_step_already_in_progress
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      error = assert_raises(Ace::Support::Cli::Error) do
        Ace::Assign::CLI::Commands::Start.new.call
      end

      assert_includes error.message, "already in progress"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_start_with_explicit_step_starts_targeted_step
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir, "Step done!")
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)
      executor.advance(report_path) # 010 done, 020 in_progress
      executor.fail("Skipping build")  # 020 failed, 030 pending

      output = capture_io do
        Ace::Assign::CLI::Commands::Start.new.call(step: "030")
      end

      assert_includes output.first, "Step 030 (test) started"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_start_rejects_step_with_assignment_option
    error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Assign::CLI::Commands::Start.new.call(step: "010", assignment: "abc123")
    end

    assert_includes error.message, "Positional STEP targeting is only supported"
  end
end
