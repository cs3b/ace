# frozen_string_literal: true

require_relative "../test_helper"

class ForkRunCommandTest < AceAssignTestCase
  class CompletingLauncher
    def initialize(cache_base:)
      @cache_base = cache_base
    end

    def launch(assignment_id:, fork_root:, provider: nil, cli_args: nil, timeout: nil)
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: @cache_base)
      assignment = manager.load(assignment_id)

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: @cache_base)
      executor.assignment_manager.define_singleton_method(:find_active) { assignment }

      report_path = File.join(@cache_base, "fork-launch-report.md")
      File.write(report_path, "Completed by test launcher")

      loop do
        state = executor.status[:state]
        break if state.subtree_complete?(fork_root) || state.subtree_failed?(fork_root)
        break unless state.current

        executor.advance(report_path, fork_root: fork_root)
      end
    end
  end

  class NoopLauncher
    def launch(**_kwargs); end
  end

  class DirectSubtreeCompletingLauncher
    def initialize(cache_base:)
      @cache_base = cache_base
    end

    def launch(assignment_id:, fork_root:, **_kwargs)
      manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: @cache_base)
      scanner = Ace::Assign::Molecules::QueueScanner.new
      writer = Ace::Assign::Molecules::PhaseWriter.new

      assignment = manager.load(assignment_id)
      state = scanner.scan(assignment.phases_dir, assignment: assignment)
      state.subtree_phases(fork_root).each do |phase|
        next if phase.status == :done

        writer.mark_done(phase.file_path, report_content: "Completed by subtree launcher", reports_dir: assignment.reports_dir)
      end
    end
  end

  def test_fork_run_with_explicit_root_launches_and_completes_subtree
    with_temp_cache do |cache_dir|
      phases = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_phases" => %w[onboard plan-task work-on-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::ForkRun.new(
          launcher: CompletingLauncher.new(cache_base: cache_dir)
        ).call(root: "010", assignment: result[:assignment].id)
      end

      assert_includes output.first, "Starting fork subtree execution: 010 - work-on-task"
      assert_includes output.first, "Fork subtree 010 completed successfully."

      Ace::Assign.reset_config!
    end
  end

  def test_fork_run_auto_detects_nearest_fork_ancestor
    with_temp_cache do |cache_dir|
      phases = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_phases" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::ForkRun.new(
          launcher: CompletingLauncher.new(cache_base: cache_dir)
        ).call(assignment: result[:assignment].id)
      end

      assert_includes output.first, "Starting fork subtree execution: 010 - work-on-task"

      Ace::Assign.reset_config!
    end
  end

  def test_fork_run_rejects_non_fork_root
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      error = assert_raises(Ace::Core::CLI::Error) do
        Ace::Assign::CLI::Commands::ForkRun.new.call(root: "010", assignment: result[:assignment].id)
      end

      assert_includes error.message, "not fork-enabled"

      Ace::Assign.reset_config!
    end
  end

  def test_fork_run_errors_when_subtree_not_completed_by_launcher
    with_temp_cache do |cache_dir|
      phases = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_phases" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      error = assert_raises(Ace::Core::CLI::Error) do
        Ace::Assign::CLI::Commands::ForkRun.new(
          launcher: NoopLauncher.new
        ).call(root: "010", assignment: result[:assignment].id, quiet: true)
      end

      assert_includes error.message, "did not complete"

      Ace::Assign.reset_config!
    end
  end

  def test_fork_run_marks_first_workable_child_as_in_progress
    with_temp_cache do |cache_dir|
      # Two top-level phases: first non-fork, second fork with sub_phases.
      # start() marks 010 as in_progress, so 020.01 stays pending.
      phases = [
        { "name" => "pre-step", "instructions" => "Run pre-step" },
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_phases" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Verify first child of fork subtree starts as pending
      state_before = executor.status[:state]
      first_child = state_before.find_by_number("020.01")
      assert_equal :pending, first_child.status, "First fork child should be pending before fork_run"

      # Use a launcher that captures state after mark but before completing
      marked_status = nil
      spy_launcher = Class.new do
        define_method(:initialize) { |cache_base:| @cache_base = cache_base }
        define_method(:launch) do |assignment_id:, fork_root:, **_kwargs|
          manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: @cache_base)
          scanner = Ace::Assign::Molecules::QueueScanner.new
          writer = Ace::Assign::Molecules::PhaseWriter.new

          assignment = manager.load(assignment_id)
          state = scanner.scan(assignment.phases_dir, assignment: assignment)
          marked_status = state.find_by_number("020.01")&.status

          # Complete all phases so fork_run doesn't error
          state.subtree_phases(fork_root).each do |phase|
            next if phase.status == :done
            writer.mark_done(phase.file_path, report_content: "Done", reports_dir: assignment.reports_dir)
          end
        end
      end

      capture_io do
        Ace::Assign::CLI::Commands::ForkRun.new(
          launcher: spy_launcher.new(cache_base: cache_dir)
        ).call(root: "020", assignment: result[:assignment].id)
      end

      assert_equal :in_progress, marked_status, "First workable child should be marked in_progress before launch"

      Ace::Assign.reset_config!
    end
  end

  def test_fork_run_reuses_existing_active_phase_in_subtree
    with_temp_cache do |cache_dir|
      phases = [
        { "name" => "pre-step", "instructions" => "Run pre-step" },
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_phases" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assignment = result[:assignment]
      scanner = Ace::Assign::Molecules::QueueScanner.new
      writer = Ace::Assign::Molecules::PhaseWriter.new
      state_before = scanner.scan(assignment.phases_dir, assignment: assignment)
      writer.mark_in_progress(state_before.find_by_number("020.01").file_path)

      launch_snapshot = {}
      spy_launcher = Class.new do
        define_method(:initialize) do |cache_base:, snapshot:|
          @cache_base = cache_base
          @snapshot = snapshot
        end

        define_method(:launch) do |assignment_id:, fork_root:, **_kwargs|
          manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: @cache_base)
          scanner = Ace::Assign::Molecules::QueueScanner.new
          writer = Ace::Assign::Molecules::PhaseWriter.new

          assignment = manager.load(assignment_id)
          state = scanner.scan(assignment.phases_dir, assignment: assignment)
          @snapshot[:child_a] = state.find_by_number("020.01")&.status
          @snapshot[:child_b] = state.find_by_number("020.02")&.status

          state.subtree_phases(fork_root).each do |phase|
            next if phase.status == :done

            writer.mark_done(phase.file_path, report_content: "Done", reports_dir: assignment.reports_dir)
          end
        end
      end

      capture_io do
        Ace::Assign::CLI::Commands::ForkRun.new(
          launcher: spy_launcher.new(cache_base: cache_dir, snapshot: launch_snapshot)
        ).call(root: "020", assignment: assignment.id)
      end

      assert_equal :in_progress, launch_snapshot[:child_a]
      assert_equal :pending, launch_snapshot[:child_b]

      Ace::Assign.reset_config!
    end
  end

  def test_fork_run_fails_when_multiple_phases_are_already_in_progress_in_subtree
    with_temp_cache do |cache_dir|
      phases = [
        { "name" => "pre-step", "instructions" => "Run pre-step" },
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_phases" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assignment = result[:assignment]
      scanner = Ace::Assign::Molecules::QueueScanner.new
      writer = Ace::Assign::Molecules::PhaseWriter.new
      state_before = scanner.scan(assignment.phases_dir, assignment: assignment)
      writer.mark_in_progress(state_before.find_by_number("020.01").file_path)
      writer.mark_in_progress(state_before.find_by_number("020.02").file_path)

      error = assert_raises(Ace::Assign::InvalidPhaseStateError) do
        Ace::Assign::CLI::Commands::ForkRun.new(
          launcher: NoopLauncher.new
        ).call(root: "020", assignment: assignment.id, quiet: true)
      end

      assert_includes error.message, "multiple phases are already in progress"

      Ace::Assign.reset_config!
    end
  end

  def test_fork_run_accepts_assignment_scope_without_root_and_without_current_in_scope
    with_temp_cache do |cache_dir|
      phases = [
        { "name" => "pre-step", "instructions" => "Run pre-step" },
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork"
        },
        { "name" => "post-step", "instructions" => "Run post-step" }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Initial current phase is 010 (pre-step), while requested fork scope is 020.
      output = capture_io do
        Ace::Assign::CLI::Commands::ForkRun.new(
          launcher: DirectSubtreeCompletingLauncher.new(cache_base: cache_dir)
        ).call(assignment: "#{result[:assignment].id}@020")
      end

      assert_includes output.first, "Starting fork subtree execution: 020 - work-on-task"
      assert_includes output.first, "Fork subtree 020 completed successfully."

      state = executor.status[:state]
      assert state.find_by_number("020").complete?, "Scoped subtree phase should be done"
      refute state.find_by_number("010").complete?, "Outside phase 010 should stay incomplete"
      refute state.find_by_number("030").complete?, "Outside phase 030 should stay incomplete"

      Ace::Assign.reset_config!
    end
  end
end
