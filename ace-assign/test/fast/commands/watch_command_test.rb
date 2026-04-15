# frozen_string_literal: true

require_relative "../../test_helper"

class WatchCommandTest < AceAssignTestCase
  class CompletingForkRunner
    attr_reader :calls

    def initialize(cache_base:)
      @cache_base = cache_base
      @calls = []
    end

    def call(root_number, assignment_id, quiet:, debug:)
      @calls << {root_number: root_number, assignment_id: assignment_id, quiet: quiet, debug: debug}

      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: @cache_base)
      assignment = manager.load(assignment_id)
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: @cache_base)
      executor.assignment_manager.define_singleton_method(:find_active) { assignment }

      report_path = File.join(@cache_base, "watch-report-#{root_number.gsub('.', '_')}.md")
      File.write(report_path, "Completed #{root_number}")

      loop do
        state = executor.status[:state]
        break if state.subtree_complete?(root_number) || state.subtree_failed?(root_number)
        before = state.subtree_steps(root_number).map { |step| [step.number, step.status] }
        executor.advance(report_path, fork_root: root_number)
        after = executor.status[:state].subtree_steps(root_number).map { |step| [step.number, step.status] }
        raise "test runner made no subtree progress for #{root_number}" if before == after
      end
    end
  end

  def run_watch_command(cache_base:, command: nil, **kwargs)
    command ||= Ace::Assign::CLI::Commands::Watch.new
    with_fast_command_executor(command, cache_base: cache_base) do
      command.call(**kwargs)
    end
  end

  def capture_watch_command(cache_base:, command: nil, **kwargs)
    capture_io do
      run_watch_command(cache_base: cache_base, command: command, **kwargs)
    end
  end

  def test_watch_runs_sequential_fork_children_until_inline_work_remains
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "child-one",
          "instructions" => "Fork child one",
          "context" => "fork",
          "sub_steps" => %w[do-one]
        },
        {
          "name" => "child-two",
          "instructions" => "Fork child two",
          "context" => "fork",
          "sub_steps" => %w[do-two]
        },
        {
          "name" => "inline-tail",
          "instructions" => "Manual follow-up"
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps, name: "watch-sequential")

      Ace::Assign.config["cache_dir"] = cache_dir
      result = build_fast_executor(cache_base: cache_dir).start(config_path)
      runner = CompletingForkRunner.new(cache_base: cache_dir)
      command = Ace::Assign::CLI::Commands::Watch.new(
        fork_runner: runner,
        sleeper: ->(_seconds) { flunk "did not expect sleep while completing local fork runs" }
      )

      output = capture_watch_command(
        cache_base: cache_dir,
        command: command,
        assignment: result[:assignment].id
      )

      assert_equal %w[010 020], runner.calls.map { |call| call[:root_number] }
      assert_includes output.first, "Watching assignment #{result[:assignment].id} for forked continuation."
      assert_includes output.first, "No fork work remains to watch"
      assert_includes output.first, "inline-tail"

      state = build_fast_executor(cache_base: cache_dir).status[:state]
      assert_equal :done, state.find_by_number("010")&.status
      assert_equal :done, state.find_by_number("020")&.status
      assert_equal :pending, state.find_by_number("030")&.status

      Ace::Assign.reset_config!
    end
  end

  def test_watch_waits_while_existing_fork_process_is_alive_before_recovering
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "child-one",
          "instructions" => "Fork child one",
          "context" => "fork",
          "sub_steps" => %w[do-one]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps, name: "watch-live-pid")

      Ace::Assign.config["cache_dir"] = cache_dir
      result = build_fast_executor(cache_base: cache_dir).start(config_path)
      state = build_fast_executor(cache_base: cache_dir).status[:state]
      root_step = state.find_by_number("010")
      Ace::Assign::Molecules::StepWriter.new.record_fork_pid_info(
        root_step.file_path,
        launch_pid: 42_001,
        tracked_pids: [42_002]
      )

      sleeps = []
      pid_checks = []
      pid_checker = lambda do |pid|
        pid_checks << pid
        sleeps.empty?
      end

      runner = CompletingForkRunner.new(cache_base: cache_dir)
      command = Ace::Assign::CLI::Commands::Watch.new(
        fork_runner: runner,
        sleeper: ->(seconds) { sleeps << seconds },
        pid_alive_checker: pid_checker
      )

      output = capture_watch_command(
        cache_base: cache_dir,
        command: command,
        assignment: result[:assignment].id,
        root: "010",
        poll_interval: 12
      )

      assert_equal [12], sleeps
      refute_empty pid_checks
      assert_equal ["010"], runner.calls.map { |call| call[:root_number] }
      assert_includes output.first, "Waiting 12s for fork subtree 010 to finish..."
      assert_includes output.first, "Recovering fork subtree 010 from assignment state..."

      Ace::Assign.reset_config!
    end
  end

  def test_watch_reports_completed_scoped_subtree_without_launching_runner
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "fork-root",
          "instructions" => "Fork child one",
          "context" => "fork",
          "sub_steps" => %w[do-one]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps, name: "watch-scoped-complete")

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = build_fast_executor(cache_base: cache_dir)
      result = executor.start(config_path)
      report_path = create_report(cache_dir, "done")
      executor.advance(report_path, fork_root: "010")

      runner_called = false
      command = Ace::Assign::CLI::Commands::Watch.new(
        fork_runner: lambda do |_root_number, _assignment_id, **_kwargs|
          runner_called = true
        end
      )

      output = capture_watch_command(
        cache_base: cache_dir,
        command: command,
        assignment: "#{result[:assignment].id}@010"
      )

      refute runner_called
      assert_includes output.first, "Fork subtree 010 is complete"

      Ace::Assign.reset_config!
    end
  end

  def test_watch_rejects_non_fork_root
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir, name: "watch-invalid-root")
      Ace::Assign.config["cache_dir"] = cache_dir
      result = build_fast_executor(cache_base: cache_dir).start(config_path)

      error = assert_raises(Ace::Support::Cli::Error) do
        run_watch_command(cache_base: cache_dir, assignment: result[:assignment].id, root: "010")
      end

      assert_includes error.message, "not fork-enabled"
      Ace::Assign.reset_config!
    end
  end
end
