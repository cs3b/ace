# frozen_string_literal: true

require_relative "../test_helper"

class ForkRunCommandTest < AceAssignTestCase
  class CompletingLauncher
    def initialize(cache_base:)
      @cache_base = cache_base
    end

    def launch(assignment_id:, fork_root:, provider: nil, cli_args: nil, timeout: nil, cache_dir: nil)
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
      writer = Ace::Assign::Molecules::StepWriter.new

      assignment = manager.load(assignment_id)
      state = scanner.scan(assignment.steps_dir, assignment: assignment)
      state.subtree_steps(fork_root).each do |step|
        next if step.status == :done

        writer.mark_done(step.file_path, report_content: "Completed by subtree launcher", reports_dir: assignment.reports_dir)
      end
    end
  end

  def test_fork_run_with_explicit_root_launches_and_completes_subtree
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task work-on-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

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
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

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

      error = assert_raises(Ace::Support::Cli::Error) do
        Ace::Assign::CLI::Commands::ForkRun.new.call(root: "010", assignment: result[:assignment].id)
      end

      assert_includes error.message, "not fork-enabled"

      Ace::Assign.reset_config!
    end
  end

  def test_fork_run_errors_when_subtree_not_completed_by_launcher
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      error = assert_raises(Ace::Support::Cli::Error) do
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
      # Two top-level steps: first non-fork, second fork with sub_steps.
      # start() marks 010 as in_progress, so 020.01 stays pending.
      steps = [
        { "name" => "pre-step", "instructions" => "Run pre-step" },
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

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
          writer = Ace::Assign::Molecules::StepWriter.new

          assignment = manager.load(assignment_id)
          state = scanner.scan(assignment.steps_dir, assignment: assignment)
          marked_status = state.find_by_number("020.01")&.status

          # Complete all steps so fork_run doesn't error
          state.subtree_steps(fork_root).each do |step|
            next if step.status == :done
            writer.mark_done(step.file_path, report_content: "Done", reports_dir: assignment.reports_dir)
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

  def test_fork_run_marks_leaf_root_as_in_progress_before_launch
    with_temp_cache do |cache_dir|
      steps = [
        { "name" => "pre-step", "instructions" => "Run pre-step" },
        { "name" => "leaf-fork", "instructions" => "Run leaf in fork", "context" => "fork" }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      launch_snapshot = {}
      spy_launcher = Class.new do
        define_method(:initialize) do |cache_base:, snapshot:|
          @cache_base = cache_base
          @snapshot = snapshot
        end

        define_method(:launch) do |assignment_id:, fork_root:, **_kwargs|
          manager = Ace::Assign::Molecules::AssignmentManager.new(cache_base: @cache_base)
          scanner = Ace::Assign::Molecules::QueueScanner.new
          writer = Ace::Assign::Molecules::StepWriter.new

          assignment = manager.load(assignment_id)
          state = scanner.scan(assignment.steps_dir, assignment: assignment)
          leaf = state.find_by_number(fork_root)
          @snapshot[:leaf_status] = leaf&.status

          writer.mark_done(leaf.file_path, report_content: "Done", reports_dir: assignment.reports_dir) if leaf
        end
      end

      capture_io do
        Ace::Assign::CLI::Commands::ForkRun.new(
          launcher: spy_launcher.new(cache_base: cache_dir, snapshot: launch_snapshot)
        ).call(assignment: "#{result[:assignment].id}@020")
      end

      assert_equal :in_progress, launch_snapshot[:leaf_status]

      Ace::Assign.reset_config!
    end
  end

  def test_fork_run_reuses_existing_active_step_in_subtree
    with_temp_cache do |cache_dir|
      steps = [
        { "name" => "pre-step", "instructions" => "Run pre-step" },
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assignment = result[:assignment]
      scanner = Ace::Assign::Molecules::QueueScanner.new
      writer = Ace::Assign::Molecules::StepWriter.new
      state_before = scanner.scan(assignment.steps_dir, assignment: assignment)
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
          writer = Ace::Assign::Molecules::StepWriter.new

          assignment = manager.load(assignment_id)
          state = scanner.scan(assignment.steps_dir, assignment: assignment)
          @snapshot[:child_a] = state.find_by_number("020.01")&.status
          @snapshot[:child_b] = state.find_by_number("020.02")&.status

          state.subtree_steps(fork_root).each do |step|
            next if step.status == :done

            writer.mark_done(step.file_path, report_content: "Done", reports_dir: assignment.reports_dir)
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

  def test_fork_run_fails_when_multiple_steps_are_already_in_progress_in_subtree
    with_temp_cache do |cache_dir|
      steps = [
        { "name" => "pre-step", "instructions" => "Run pre-step" },
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assignment = result[:assignment]
      scanner = Ace::Assign::Molecules::QueueScanner.new
      writer = Ace::Assign::Molecules::StepWriter.new
      state_before = scanner.scan(assignment.steps_dir, assignment: assignment)
      writer.mark_in_progress(state_before.find_by_number("020.01").file_path)
      writer.mark_in_progress(state_before.find_by_number("020.02").file_path)

      error = assert_raises(Ace::Assign::StepErrors::InvalidState) do
        Ace::Assign::CLI::Commands::ForkRun.new(
          launcher: NoopLauncher.new
        ).call(root: "020", assignment: assignment.id, quiet: true)
      end

      assert_includes error.message, "multiple steps are already in progress"

      Ace::Assign.reset_config!
    end
  end

  def test_fork_run_accepts_assignment_scope_without_root_and_without_current_in_scope
    with_temp_cache do |cache_dir|
      steps = [
        { "name" => "pre-step", "instructions" => "Run pre-step" },
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork"
        },
        { "name" => "post-step", "instructions" => "Run post-step" }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      # Initial current step is 010 (pre-step), while requested fork scope is 020.
      output = capture_io do
        Ace::Assign::CLI::Commands::ForkRun.new(
          launcher: DirectSubtreeCompletingLauncher.new(cache_base: cache_dir)
        ).call(assignment: "#{result[:assignment].id}@020")
      end

      assert_includes output.first, "Starting fork subtree execution: 020 - work-on-task"
      assert_includes output.first, "Fork subtree 020 completed successfully."

      state = executor.status[:state]
      assert state.find_by_number("020").complete?, "Scoped subtree step should be done"
      refute state.find_by_number("010").complete?, "Outside step 010 should stay incomplete"
      refute state.find_by_number("030").complete?, "Outside step 030 should stay incomplete"

      Ace::Assign.reset_config!
    end
  end

  def test_stall_error_includes_last_message_when_file_exists
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assignment = result[:assignment]
      sessions_dir = File.join(assignment.cache_dir, "sessions")
      FileUtils.mkdir_p(sessions_dir)
      File.write(File.join(sessions_dir, "010-last-message.md"), "I need your direction before I continue.")

      error = assert_raises(Ace::Support::Cli::Error) do
        Ace::Assign::CLI::Commands::ForkRun.new(
          launcher: NoopLauncher.new
        ).call(root: "010", assignment: assignment.id, quiet: true)
      end

      assert_includes error.message, "did not complete"
      assert_includes error.message, "Agent's last message:"
      assert_includes error.message, "I need your direction before I continue."

      Ace::Assign.reset_config!
    end
  end

  def test_stall_error_includes_session_id_when_metadata_file_exists
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assignment = result[:assignment]
      sessions_dir = File.join(assignment.cache_dir, "sessions")
      FileUtils.mkdir_p(sessions_dir)
      File.write(File.join(sessions_dir, "010-session.yml"), { "session_id" => "sess-xyz789", "provider" => "claude" }.to_yaml)

      error = assert_raises(Ace::Support::Cli::Error) do
        Ace::Assign::CLI::Commands::ForkRun.new(
          launcher: NoopLauncher.new
        ).call(root: "010", assignment: assignment.id, quiet: true)
      end

      assert_includes error.message, "Session: sess-xyz789"

      Ace::Assign.reset_config!
    end
  end

  def test_stall_error_omits_session_id_when_no_metadata_file
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      error = assert_raises(Ace::Support::Cli::Error) do
        Ace::Assign::CLI::Commands::ForkRun.new(
          launcher: NoopLauncher.new
        ).call(root: "010", assignment: result[:assignment].id, quiet: true)
      end

      assert_includes error.message, "did not complete"
      refute_includes error.message, "Session:"

      Ace::Assign.reset_config!
    end
  end

  def test_stall_error_omits_last_message_section_when_file_absent
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      error = assert_raises(Ace::Support::Cli::Error) do
        Ace::Assign::CLI::Commands::ForkRun.new(
          launcher: NoopLauncher.new
        ).call(root: "010", assignment: result[:assignment].id, quiet: true)
      end

      assert_includes error.message, "did not complete"
      refute_includes error.message, "Agent's last message:"

      Ace::Assign.reset_config!
    end
  end

  def test_stall_writes_stall_reason_to_active_step_frontmatter
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assignment = result[:assignment]
      sessions_dir = File.join(assignment.cache_dir, "sessions")
      FileUtils.mkdir_p(sessions_dir)
      File.write(File.join(sessions_dir, "010-last-message.md"), "Unexpected state change encountered.")

      assert_raises(Ace::Support::Cli::Error) do
        Ace::Assign::CLI::Commands::ForkRun.new(
          launcher: NoopLauncher.new
        ).call(root: "010", assignment: assignment.id, quiet: true)
      end

      scanner = Ace::Assign::Molecules::QueueScanner.new
      state = scanner.scan(assignment.steps_dir, assignment: assignment)
      active = state.current
      assert_equal "Unexpected state change encountered.", active.stall_reason

      Ace::Assign.reset_config!
    end
  end

  def test_stall_truncates_long_last_message_in_error
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "sub_steps" => %w[onboard]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)

      assignment = result[:assignment]
      sessions_dir = File.join(assignment.cache_dir, "sessions")
      FileUtils.mkdir_p(sessions_dir)
      long_message = "x" * 2500
      File.write(File.join(sessions_dir, "010-last-message.md"), long_message)

      error = assert_raises(Ace::Support::Cli::Error) do
        Ace::Assign::CLI::Commands::ForkRun.new(
          launcher: NoopLauncher.new
        ).call(root: "010", assignment: assignment.id, quiet: true)
      end

      assert_includes error.message, "... (truncated)"
      last_msg_section = error.message.split("Agent's last message:\n").last
      assert_equal Ace::Assign::CLI::Commands::ForkRun::STALL_REASON_MAX + "... (truncated)".length,
                   last_msg_section.length

      Ace::Assign.reset_config!
    end
  end

  def test_stall_reason_cleared_after_successful_rerun
    with_temp_cache do |cache_dir|
      steps = [
        {
          "name" => "work-on-task",
          "instructions" => "Implement task",
          "context" => "fork",
          "sub_steps" => %w[onboard plan-task]
        }
      ]
      config_path = create_test_config(cache_dir, steps: steps)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      result = executor.start(config_path)
      assignment = result[:assignment]

      # First run: stall with a last-message to set stall_reason
      sessions_dir = File.join(assignment.cache_dir, "sessions")
      FileUtils.mkdir_p(sessions_dir)
      File.write(File.join(sessions_dir, "010-last-message.md"), "Something went wrong.")

      assert_raises(Ace::Support::Cli::Error) do
        Ace::Assign::CLI::Commands::ForkRun.new(
          launcher: NoopLauncher.new
        ).call(root: "010", assignment: assignment.id, quiet: true)
      end

      scanner = Ace::Assign::Molecules::QueueScanner.new
      state = scanner.scan(assignment.steps_dir, assignment: assignment)
      assert state.current.stall_reason, "expected stall_reason to be set after stall"

      # Second run: complete successfully and verify stall_reason is cleared
      capture_io do
        Ace::Assign::CLI::Commands::ForkRun.new(
          launcher: CompletingLauncher.new(cache_base: cache_dir)
        ).call(root: "010", assignment: assignment.id, quiet: true)
      end

      state2 = scanner.scan(assignment.steps_dir, assignment: assignment)
      state2.subtree_steps("010").each do |step|
        assert_nil step.stall_reason,
                   "expected stall_reason to be nil on step #{step.number} after successful rerun"
      end

      Ace::Assign.reset_config!
    end
  end
end
