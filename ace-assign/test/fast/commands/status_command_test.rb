# frozen_string_literal: true

require_relative "../../test_helper"
require "json"

class StatusCommandTest < AceAssignTestCase
  def run_status_command(cache_base:, **kwargs)
    command = Ace::Assign::CLI::Commands::Status.new
    with_fast_command_executor(command, cache_base: cache_base) do
      command.call(**kwargs)
    end
  end

  def capture_status_command(cache_base:, **kwargs)
    capture_io do
      run_status_command(cache_base: cache_base, **kwargs)
    end
  end

  def complete_all_steps(executor, report_path, count)
    count.times do
      executor.start_step
      executor.advance(report_path)
    end
  end

  def test_status_without_assignment
    with_temp_cache do |cache_dir|
      Ace::Assign.config["cache_dir"] = cache_dir

      error = assert_raises(Ace::Support::Cli::Error) do
        run_status_command(cache_base: cache_dir)
      end

      assert_equal 2, error.exit_code
      assert_includes error.message, "No active assignment"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_compact_is_default_and_under_ten_lines
    with_temp_cache do |cache_dir|
      steps = [
        {"name" => "onboard", "instructions" => "Load context"},
        {"name" => "plan", "instructions" => "Plan work"},
        {"name" => "work", "instructions" => "Do work"},
        {"name" => "verify", "instructions" => "Verify output"},
        {"name" => "release", "instructions" => "Release"},
        {"name" => "retro", "instructions" => "Retrospective"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)

      output = capture_status_command(cache_base: cache_dir).first
      lines = output.lines.map(&:chomp)

      assert_operator lines.length, :<=, 10
      assert_includes lines.first, "Assignment:"
      assert_includes lines.first, "Status:"
      assert_includes lines.first, "Status: paused"
      assert_includes lines.first, "Next: 010 onboard"
      assert_equal "Last done: none", lines[1]
      assert_equal "Pending steps:", lines[2]
      assert_includes output, "010 next onboard"
      assert_includes lines.last, "Steps:"
      assert_includes lines.last, "Pending: 6"
      refute_includes output, "Instructions:"
      refute_includes output, "QUEUE - Assignment:"
      refute_includes output, "Preview:"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_progress_mode_prints_single_line
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)

      output = capture_status_command(cache_base: cache_dir, mode: "progress").first
      assert_equal 1, output.lines.count
      assert_includes output, "State: paused"
      assert_includes output, "Progress: 0/3 done"
      assert_includes output, "Next: 010 init"
      refute_includes output, "Preview:"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_compact_completed_assignment_reads_cleanly
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report = create_report(cache_dir, "done")
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      complete_all_steps(executor, report, 3)

      output = capture_status_command(cache_base: cache_dir, assignment: result[:assignment].id).first
      lines = output.lines.map(&:chomp)

      assert_includes lines[0], "Assignment: #{result[:assignment].id}"
      assert_includes lines[0], "Status: completed"
      assert_equal "Last done: 030 test", lines[1]
      assert_includes lines[2], "Steps:"
      assert_includes lines[2], "3/3 done"
      refute_includes output, "Pending: none"
      refute_includes output, "current: none"
      refute_includes output, "Preview:"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_compact_completed_assignment_hides_failed_retry_history_from_pending_preview
    with_temp_cache do |cache_dir|
      steps = [
        {"name" => "analyze", "instructions" => "Analyze requirements"},
        {"name" => "implement", "instructions" => "Implement change"},
        {"name" => "verify", "instructions" => "Verify output"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      report = create_report(cache_dir, "done")
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      executor.start_step
      executor.advance(report)
      executor.start_step

      failed_report = create_report(cache_dir, "HITL: stalled implementation requires fix")
      executor.fail(failed_report)
      output = capture_io do
        Ace::Assign::CLI::Commands::RetryCmd.new.call(step_ref: "020")
      end
      executor.start_step
      executor.advance(report)
      executor.start_step
      executor.advance(report)

      status_output = capture_status_command(cache_base: cache_dir, assignment: result[:assignment].id).first

      assert_includes output.first, "retry of 020"
      assert_includes status_output, "Status: completed"
      refute_includes status_output, "Pending steps:"
      refute_includes status_output, "020 failed implement"
      refute_includes status_output, "Failed steps:"
      assert_includes status_output, "Pending: 0"
      assert_includes status_output, "Failed: 1"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_full_mode_prints_tree_without_instructions
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "fork" => {"provider" => "codex:gpt-fit"},
          "sub_steps" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)

      output = capture_status_command(cache_base: cache_dir, mode: "full", assignment: "#{result[:assignment].id}@010").first

      assert_includes output, "QUEUE - Assignment:"
      assert_includes output, "Next Step: 010.01 - onboard"
      assert_includes output, "Fork Provider: codex:gpt-fit"
      refute_includes output, "Instructions:"
      refute_includes output, "Fork subtree detected"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_full_mode_shows_hitl_guidance
    with_temp_cache do |cache_dir|
      steps = [
        {"name" => "decision-point", "instructions" => "Need human judgment"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      step_path = File.join(cache_dir, result[:assignment].id, "steps", "010-decision-point.st.md")
      Ace::Assign::Molecules::StepWriter.new.update_frontmatter(
        step_path,
        {"stall_reason" => "HITL: htl123 .ace-local/hitl/next/htl123-need-decision.md"}
      )
      executor.start_step

      output = capture_status_command(cache_base: cache_dir, mode: "full", assignment: result[:assignment].id).first

      assert_includes output, "HITL Guidance:"
      assert_includes output, "ace-hitl show htl123"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_json_reports_active_steps_and_next_step
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)

      output = capture_status_command(cache_base: cache_dir, format: "json")
      payload = JSON.parse(output.first)

      assert_equal result[:assignment].id, payload.dig("assignment", "id")
      assert_equal "paused", payload.dig("assignment", "state")
      assert_equal "0/3 done", payload["progress"]
      assert_equal [], payload["active_steps"]
      assert_equal "010", payload.dig("next_step", "number")
      assert_equal "init", payload.dig("next_step", "name")
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_status_json_with_scope_uses_scope_root_fork_provider_for_next_step
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "fork" => {"provider" => "codex:gpt-fit"},
          "sub_steps" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)

      output = capture_status_command(cache_base: cache_dir, format: "json", assignment: "#{result[:assignment].id}@010")
      payload = JSON.parse(output.first)

      assert_equal [], payload["active_steps"]
      assert_equal "010.01", payload.dig("next_step", "number")
      assert_equal "codex:gpt-fit", payload.dig("next_step", "fork_provider")
    ensure
      Ace::Assign.reset_config!
    end
  end
end
