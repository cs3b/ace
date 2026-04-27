# frozen_string_literal: true

require_relative "../../test_helper"

class WatchCommandTest < AceAssignTestCase
  ResolverTarget = Ace::Assign::CLI::Commands::AssignmentTarget::Target

  class CompletingLauncher
    attr_reader :calls

    def initialize(cache_base:)
      @cache_base = cache_base
      @calls = []
    end

    def launch(assignment_id:, fork_root:, **kwargs)
      @calls << kwargs.merge(assignment_id: assignment_id, fork_root: fork_root)
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: @cache_base)
      scanner = Ace::Assign::Molecules::QueueScanner.new
      writer = Ace::Assign::Molecules::StepWriter.new
      assignment = manager.load(assignment_id)
      state = scanner.scan(assignment.steps_dir, assignment: assignment)

      state.subtree_steps(fork_root).each do |step|
        next if step.status == :done

        writer.mark_done(step.file_path, report_content: "Completed by watcher launcher", reports_dir: assignment.reports_dir)
      end
    end
  end

  class SpyLauncher
    attr_reader :calls

    def initialize
      @calls = []
    end

    def launch(**kwargs)
      @calls << kwargs
    end
  end

  class FakeTmuxRunner
    attr_reader :captures

    def initialize(alive_panes: [])
      @alive_panes = Array(alive_panes)
      @captures = []
    end

    def capture_recent_output(pane_target:, lines:)
      @captures << {pane_target: pane_target, lines: lines}
      raise Ace::Assign::Error, "pane not found" unless @alive_panes.include?(pane_target)

      "fork pane is still running"
    end
  end

  def run_watch_command(cache_base:, launcher: nil, sleeper: nil, pid_probe: nil, tmux_runner: nil, **kwargs)
    command = Ace::Assign::CLI::Commands::Watch.new(
      launcher: launcher,
      sleeper: sleeper,
      pid_probe: pid_probe,
      tmux_runner: tmux_runner
    )
    with_fast_command_executor(command, cache_base: cache_base) do
      command.call(**kwargs)
    end
  end

  def capture_watch_command(cache_base:, launcher: nil, sleeper: nil, pid_probe: nil, tmux_runner: nil, **kwargs)
    capture_io do
      run_watch_command(
        cache_base: cache_base,
        launcher: launcher,
        sleeper: sleeper,
        pid_probe: pid_probe,
        tmux_runner: tmux_runner,
        **kwargs
      )
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

  def step_for(assignment, number)
    scanner = Ace::Assign::Molecules::QueueScanner.new
    state = scanner.scan(assignment.steps_dir, assignment: assignment)
    state.find_by_number(number)
  end

  def record_fork_pid_info(step, pid:)
    Ace::Assign::Molecules::StepWriter.new.record_fork_pid_info(
      step.file_path,
      launch_pid: pid,
      tracked_pids: [pid]
    )
  end

  def write_tmux_session_meta(assignment, root_number, pane: "%42")
    sessions_dir = File.join(assignment.cache_dir, "sessions")
    FileUtils.mkdir_p(sessions_dir)
    File.write(
      File.join(sessions_dir, "#{root_number}-session.yml"),
      {
        "launch_mode" => "tmux",
        "tmux_session" => "demo",
        "tmux_window" => "work-fs",
        "tmux_pane_id" => pane
      }.to_yaml
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

  def test_watch_scoped_leaf_root_recovers_active_root_instead_of_reporting_no_fork_work
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir, steps: [{"name" => "forked", "instructions" => "Work", "context" => "fork"}])
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      assignment = load_assignment(cache_dir, result[:assignment].id)
      root = result[:state].find_by_number("010")
      Ace::Assign::Molecules::StepWriter.new.mark_active(root.file_path)
      record_fork_pid_info(root, pid: 11_111)

      launcher = CompletingLauncher.new(cache_base: cache_dir)
      output = capture_watch_command(
        cache_base: cache_dir,
        assignment: "#{assignment.id}@010",
        launcher: launcher,
        pid_probe: ->(_pid) { false }
      )

      assert_equal ["010"], launcher.calls.map { |call| call[:fork_root] }
      assert_includes output.first, "Recovering watched scope #{assignment.id}@010 from assignment state via subtree 010."
      assert_includes output.first, "Watch target #{assignment.id}@010 is already complete."

      Ace::Assign.reset_config!
    end
  end

  def test_watch_waits_for_live_active_fork_work_without_duplicate_relaunch
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir, steps: [{"name" => "forked", "instructions" => "Work", "context" => "fork"}])
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      assignment = load_assignment(cache_dir, result[:assignment].id)
      root = result[:state].find_by_number("010")
      Ace::Assign::Molecules::StepWriter.new.mark_active(root.file_path)
      record_fork_pid_info(root, pid: 12_345)

      launcher = SpyLauncher.new
      waited = false
      sleeper = lambda do |_seconds|
        waited = true
        refreshed_root = step_for(assignment, "010")
        mark_step_done(assignment, refreshed_root)
      end

      output = capture_watch_command(
        cache_base: cache_dir,
        assignment: assignment.id,
        launcher: launcher,
        sleeper: sleeper,
        pid_probe: ->(pid) { pid == 12_345 }
      )

      assert waited
      assert_empty launcher.calls
      assert_includes output.first, "Waiting for active fork subtree 010 in watched assignment #{assignment.id}."
      assert_includes output.first, "Watch target #{assignment.id} is already complete."

      Ace::Assign.reset_config!
    end
  end

  def test_watch_treats_live_tmux_pane_metadata_as_active_fork_telemetry
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir, steps: [{"name" => "forked", "instructions" => "Work", "context" => "fork", "fork" => {"mode" => "tmux"}}])
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      assignment = load_assignment(cache_dir, result[:assignment].id)
      root = result[:state].find_by_number("010")
      Ace::Assign::Molecules::StepWriter.new.mark_active(root.file_path)
      write_tmux_session_meta(assignment, "010", pane: "%42")

      launcher = SpyLauncher.new
      tmux_runner = FakeTmuxRunner.new(alive_panes: ["%42"])
      sleeper = lambda do |_seconds|
        refreshed_root = step_for(assignment, "010")
        mark_step_done(assignment, refreshed_root)
      end

      output = capture_watch_command(
        cache_base: cache_dir,
        assignment: assignment.id,
        launcher: launcher,
        sleeper: sleeper,
        pid_probe: ->(_pid) { false },
        tmux_runner: tmux_runner
      )

      assert_empty launcher.calls
      assert_equal [{pane_target: "%42", lines: 1}], tmux_runner.captures
      assert_includes output.first, "Waiting for active fork subtree 010 in watched assignment #{assignment.id}."

      Ace::Assign.reset_config!
    end
  end

  def test_watch_uses_extracted_runtime_for_assignment_and_scoped_paths
    command = Ace::Assign::CLI::Commands::Watch.new
    runtime = command.send(:runtime)

    assert_instance_of Ace::Assign::CLI::Commands::WatchRuntime, runtime
  end

  def test_watch_treats_eperm_pid_probe_as_alive
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir, steps: [{"name" => "forked", "instructions" => "Work", "context" => "fork"}])
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      assignment = load_assignment(cache_dir, result[:assignment].id)
      root = result[:state].find_by_number("010")
      Ace::Assign::Molecules::StepWriter.new.mark_active(root.file_path)
      record_fork_pid_info(root, pid: 54_321)

      launcher = SpyLauncher.new
      sleeper = lambda do |_seconds|
        refreshed_root = step_for(assignment, "010")
        mark_step_done(assignment, refreshed_root)
      end

      output = capture_watch_command(
        cache_base: cache_dir,
        assignment: assignment.id,
        launcher: launcher,
        sleeper: sleeper,
        pid_probe: lambda do |pid|
          raise Errno::EPERM, pid.to_s
        end
      )

      assert_empty launcher.calls
      assert_includes output.first, "Waiting for active fork subtree 010 in watched assignment #{assignment.id}."

      Ace::Assign.reset_config!
    end
  end

  def test_watch_recovers_stale_active_fork_from_assignment_state
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir, steps: [{"name" => "forked", "instructions" => "Work", "context" => "fork"}])
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      assignment = load_assignment(cache_dir, result[:assignment].id)
      root = result[:state].find_by_number("010")
      Ace::Assign::Molecules::StepWriter.new.mark_active(root.file_path)
      record_fork_pid_info(root, pid: 11_111)

      launcher = CompletingLauncher.new(cache_base: cache_dir)
      output = capture_watch_command(
        cache_base: cache_dir,
        assignment: assignment.id,
        launcher: launcher,
        pid_probe: ->(_pid) { false }
      )

      assert_equal ["010"], launcher.calls.map { |call| call[:fork_root] }
      assert_includes output.first, "Recovering watched assignment #{assignment.id} from assignment state via subtree 010."
      assert_includes output.first, "Watch target #{assignment.id} is already complete."

      Ace::Assign.reset_config!
    end
  end

  def test_watch_continues_across_multiple_pending_fork_roots_in_order
    with_temp_cache do |cache_dir|
      steps = [
        {"name" => "fork-a", "instructions" => "Work", "context" => "fork"},
        {"name" => "fork-b", "instructions" => "Work", "context" => "fork"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      launcher = CompletingLauncher.new(cache_base: cache_dir)

      output = capture_watch_command(
        cache_base: cache_dir,
        assignment: result[:assignment].id,
        launcher: launcher,
        pid_probe: ->(_pid) { false }
      )

      assert_equal %w[010 020], launcher.calls.map { |call| call[:fork_root] }
      assert_includes output.first, "Launching next fork subtree 010 for watched assignment #{result[:assignment].id}."
      assert_includes output.first, "Launching next fork subtree 020 for watched assignment #{result[:assignment].id}."
      assert_includes output.first, "Watch target #{result[:assignment].id} is already complete."

      Ace::Assign.reset_config!
    end
  end

  def test_watch_scoped_target_does_not_widen_into_later_siblings
    with_temp_cache do |cache_dir|
      steps = [
        {"name" => "fork-a", "instructions" => "Work", "context" => "fork"},
        {"name" => "fork-b", "instructions" => "Work", "context" => "fork"}
      ]
      config_path = create_test_config(cache_dir, steps: steps)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      assignment = load_assignment(cache_dir, result[:assignment].id)
      root = result[:state].find_by_number("010")
      mark_step_done(assignment, root)

      launcher = SpyLauncher.new
      output = capture_watch_command(
        cache_base: cache_dir,
        assignment: "#{assignment.id}@010",
        launcher: launcher
      )

      assert_empty launcher.calls
      assert_includes output.first, "Watch target #{assignment.id}@010 is already complete."

      Ace::Assign.reset_config!
    end
  end
end
