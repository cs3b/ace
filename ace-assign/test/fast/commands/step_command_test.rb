# frozen_string_literal: true

require_relative "../../test_helper"

class StepCommandTest < AceAssignTestCase
  def run_step_command(cache_base:, **kwargs)
    command = Ace::Assign::CLI::Commands::Step.new
    with_fast_command_executor(command, cache_base: cache_base) do
      command.call(**kwargs)
    end
  end

  def capture_step_command(cache_base:, **kwargs)
    capture_io do
      run_step_command(cache_base: cache_base, **kwargs)
    end
  end

  def test_step_defaults_to_current_step_instructions
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)

      output = capture_step_command(cache_base: cache_dir).first
      assert_equal "Initialize project\n", output
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_step_falls_back_to_next_workable_when_no_active_step
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir, "done")
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      start = executor.start(config_path)
      executor.advance(report_path)
      executor.fail("blocked")

      output = capture_step_command(cache_base: cache_dir, assignment: start[:assignment].id).first
      assert_equal "Run tests\n", output
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_step_with_explicit_step_uses_exact_lookup
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)

      output = capture_step_command(cache_base: cache_dir, step: "020", assignment: result[:assignment].id).first
      assert_equal "Build the project\n", output
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_step_respects_scope_for_default_lookup
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        },
        {"name" => "post-step", "instructions" => "Run post-step"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)

      output = capture_step_command(cache_base: cache_dir, assignment: "#{result[:assignment].id}@010").first
      assert_includes output, "Task context:"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_step_shows_info_line_when_no_current_or_next_work_exists
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report = create_report(cache_dir, "done")
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      3.times { executor.advance(report) }

      output = capture_step_command(cache_base: cache_dir, assignment: result[:assignment].id).first
      lines = output.lines.map(&:chomp)

      assert_equal 2, lines.length
      assert_includes lines[0], "Assignment: #{result[:assignment].id}"
      assert_includes lines[0], "Status: completed"
      assert_includes lines[0], "Progress: 3/3 done"
      assert_equal "Last done: 030 test | No current or next workable step", lines[1]
    ensure
      Ace::Assign.reset_config!
    end
  end
end
