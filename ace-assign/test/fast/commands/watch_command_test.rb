# frozen_string_literal: true

require_relative "../../test_helper"

class WatchCommandTest < AceAssignTestCase
  ResolverTarget = Ace::Assign::CLI::Commands::AssignmentTarget::Target

  def run_watch_command(cache_base:, **kwargs)
    command = Ace::Assign::CLI::Commands::Watch.new
    with_fast_command_executor(command, cache_base: cache_base) do
      command.call(**kwargs)
    end
  end

  def capture_watch_command(cache_base:, **kwargs)
    capture_io do
      run_watch_command(cache_base: cache_base, **kwargs)
    end
  end

  def load_assignment(cache_dir, assignment_id)
    Ace::Assign::Molecules::AssignmentManager.new(cache_base: cache_dir).load(assignment_id)
  end

  def mark_step_done(assignment, step)
    Ace::Assign::Molecules::StepWriter.new.mark_done(
      step.file_path,
      report_content: "Done",
      reports_dir: assignment.reports_dir
    )
  end

  def test_watch_scoped_target_exits_success_when_subtree_already_complete
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir, steps: [{"name" => "forked", "instructions" => "Work", "context" => "fork"}])
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      assignment = load_assignment(cache_dir, result[:assignment].id)
      mark_step_done(assignment, result[:state].find_by_number("010"))

      output = capture_watch_command(cache_base: cache_dir, assignment: "#{assignment.id}@010")

      assert_includes output.first, "Watching #{assignment.id}@010 (poll interval: 300s)"
      assert_includes output.first, "Watch target #{assignment.id}@010 is already complete."

      Ace::Assign.reset_config!
    end
  end

  def test_watch_assignment_plus_root_matches_scoped_assignment_output
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir, steps: [{"name" => "forked", "instructions" => "Work", "context" => "fork"}])
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      assignment = load_assignment(cache_dir, result[:assignment].id)
      mark_step_done(assignment, result[:state].find_by_number("010"))

      scoped_output = capture_watch_command(cache_base: cache_dir, assignment: "#{assignment.id}@010")
      explicit_root_output = capture_watch_command(cache_base: cache_dir, assignment: assignment.id, root: "010")

      assert_equal scoped_output.first, explicit_root_output.first

      Ace::Assign.reset_config!
    end
  end

  def test_watch_rejects_conflicting_scoped_root_forms
    with_temp_cache do |cache_dir|
      steps = [
        {"name" => "forked-a", "instructions" => "Work", "context" => "fork"},
        {"name" => "forked-b", "instructions" => "Work", "context" => "fork"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)

      error = assert_raises(Ace::Support::Cli::Error) do
        run_watch_command(cache_base: cache_dir, assignment: "#{result[:assignment].id}@010", root: "020")
      end

      assert_includes error.message, "Conflicting subtree roots"

      Ace::Assign.reset_config!
    end
  end

  def test_watch_rejects_non_positive_poll_interval
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir, steps: [{"name" => "forked", "instructions" => "Work", "context" => "fork"}])
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)

      error = assert_raises(Ace::Support::Cli::Error) do
        run_watch_command(cache_base: cache_dir, assignment: "#{result[:assignment].id}@010", poll_interval: 0)
      end

      assert_includes error.message, "Poll interval must be a positive integer"

      Ace::Assign.reset_config!
    end
  end

  def test_watch_rejects_non_fork_root
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)

      error = assert_raises(Ace::Support::Cli::Error) do
        run_watch_command(cache_base: cache_dir, assignment: result[:assignment].id, root: "010")
      end

      assert_includes error.message, "not fork-enabled"

      Ace::Assign.reset_config!
    end
  end

  def test_watch_fails_when_scoped_target_contains_failed_work
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir, steps: [{"name" => "forked", "instructions" => "Work", "context" => "fork"}])
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      root = result[:state].find_by_number("010")
      Ace::Assign::Molecules::StepWriter.new.mark_failed(root.file_path, error_message: "boom")

      error = assert_raises(Ace::Support::Cli::Error) do
        run_watch_command(cache_base: cache_dir, assignment: "#{result[:assignment].id}@010")
      end

      assert_includes error.message, "has failed work: 010 forked"

      Ace::Assign.reset_config!
    end
  end

  def test_watch_reports_inline_manual_tail_for_scoped_target
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "forked",
          "instructions" => "Watch subtree",
          "context" => "fork",
          "sub_steps" => ["manual-tail"]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      root = result[:state].find_by_number("010")
      Ace::Assign::Molecules::StepWriter.new.mark_active(root.file_path)

      output = capture_watch_command(cache_base: cache_dir, assignment: "#{result[:assignment].id}@010")

      assert_includes output.first, "No fork work remains in watched scope #{result[:assignment].id}@010."
      assert_includes output.first, "Remaining inline/manual boundary: 010.01 manual-tail."

      Ace::Assign.reset_config!
    end
  end
end
