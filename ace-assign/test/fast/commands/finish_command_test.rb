# frozen_string_literal: true

require_relative "../../test_helper"

class FinishCommandTest < AceAssignTestCase
  def test_finish_completes_step
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir, "Step done!")

      Ace::Assign.config["cache_dir"] = cache_dir

      # Start an assignment first
      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)
      executor.start_step

      result = nil
      output = capture_io do
        command = Ace::Assign::CLI::Commands::Finish.new
        with_fast_command_executor(command, cache_base: cache_dir) do
          result = command.call(message: report_path)
        end
      end
      assert_nil result  # Verify success returns nil
      assert_includes output.first, "Step 010 (init) completed"
      assert_includes output.first, "No active step selected."
      assert_includes output.first, "Next pending step: 020 - build"
      refute_includes output.first, "Instructions:"

      Ace::Assign.reset_config!
    end
  end

  def test_finish_with_explicit_step_completes_targeted_step
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir, "Step done!")

      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)
      executor.start_step

      output = capture_io do
        command = Ace::Assign::CLI::Commands::Finish.new
        with_fast_command_executor(command, cache_base: cache_dir) do
          command.call(step: "010", message: report_path)
        end
      end

      assert_includes output.first, "Step 010 (init) completed"
      assert_includes output.first, "No active step selected."
      assert_includes output.first, "Next pending step: 020 - build"

      Ace::Assign.reset_config!
    end
  end

  def test_finish_with_nonexistent_path_uses_inline_message
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)
      executor.start_step
      executor.start_step

      output = capture_io do
        command = Ace::Assign::CLI::Commands::Finish.new
        with_fast_command_executor(command, cache_base: cache_dir) do
          command.call(message: "nonexistent.md")
        end
      end
      assert_includes output.first, "Step 010 (init) completed"

      assignment_cache = Dir.glob(File.join(cache_dir, "*/reports/010-init.r.md")).first
      report_saved = File.read(assignment_cache)
      assert_includes report_saved, "nonexistent.md"

      Ace::Assign.reset_config!
    end
  end

  def test_finish_without_assignment
    with_temp_cache do |cache_dir|
      report_path = create_report(cache_dir)

      Ace::Assign.config["cache_dir"] = cache_dir

      error = assert_raises(Ace::Support::Cli::Error) do
        command = Ace::Assign::CLI::Commands::Finish.new
        with_fast_command_executor(command, cache_base: cache_dir) do
          command.call(message: report_path)
        end
      end

      assert_equal 2, error.exit_code
      assert_includes error.message, "No active assignment"

      Ace::Assign.reset_config!
    end
  end

  def test_finish_with_assignment_flag
    with_temp_cache do |cache_dir|
      report_path = create_report(cache_dir, "Step done!")

      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)

      config1 = create_test_config(cache_dir, name: "first-task")
      result1 = executor.start(config1)

      config2 = create_test_config(cache_dir, name: "second-task")
      result2 = executor.start(config2)
      target_id = result2[:assignment].id
      executor.start_step

      output = capture_io do
        command = Ace::Assign::CLI::Commands::Finish.new
        with_fast_command_executor(command, cache_base: cache_dir) do
          command.call(
            message: report_path,
            assignment: target_id
          )
        end
      end

      assert_includes output.first, "Step 010 (init) completed"
      assert_includes output.first, "No active step selected."
      assert_includes output.first, "Next pending step: 020 - build"

      # Verify the targeted assignment advanced
      scanner = Ace::Assign::Molecules::QueueScanner.new
      target_state = scanner.scan(result2[:assignment].steps_dir, assignment: result2[:assignment])
      assert_nil target_state.current
      assert_equal "020", target_state.next_workable.number

      # Verify the first assignment was not affected (still paused on 010)
      first_state = scanner.scan(result1[:assignment].steps_dir, assignment: result1[:assignment])
      assert_nil first_state.current
      assert_equal "010", first_state.next_workable.number

      Ace::Assign.reset_config!
    end
  end

  def test_finish_with_assignment_scope_completes_scoped_step
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
      executor.advance(report_path)
      step_path = File.join(start[:assignment].steps_dir, "020-work-on-task.st.md")
      Ace::Assign::Molecules::StepWriter.new.mark_active(step_path)
      executor.start_step(fork_root: "020")

      output = capture_io do
        command = Ace::Assign::CLI::Commands::Finish.new
        with_fast_command_executor(command, cache_base: cache_dir) do
          command.call(
            message: report_path,
            assignment: "#{target_id}@020"
          )
        end
      end

      assert_includes output.first, "Step 020.01 (onboard) completed"
      assert_includes output.first, "Active steps remaining: 020 work-on-task"

      scanner = Ace::Assign::Molecules::QueueScanner.new
      state = scanner.scan(start[:assignment].steps_dir, assignment: start[:assignment])

      assert_equal :done, state.find_by_number("010").status
      assert_equal :done, state.find_by_number("020.01").status
      assert_equal :active, state.find_by_number("020").status
      assert_equal :pending, state.find_by_number("020.02").status

      Ace::Assign.reset_config!
    end
  end

  def test_finish_with_stdin_input
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)
      executor.start_step

      cmd = Ace::Assign::CLI::Commands::Finish.new
      stdin = StringIO.new("stdin report")
      stdin.define_singleton_method(:tty?) { false }
      original_stdin = $stdin
      $stdin = stdin

      output = capture_io do
        with_fast_command_executor(cmd, cache_base: cache_dir) do
          cmd.call
        end
      end

      assert_includes output.first, "Step 010 (init) completed"
    ensure
      $stdin = original_stdin
      Ace::Assign.reset_config!
    end
  end

  def test_finish_with_missing_report_input
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)
      executor.start_step

      cmd = Ace::Assign::CLI::Commands::Finish.new
      stdin = StringIO.new("")
      stdin.define_singleton_method(:tty?) { true }
      original_stdin = $stdin
      $stdin = stdin

      error = assert_raises(Ace::Support::Cli::Error) do
        with_fast_command_executor(cmd, cache_base: cache_dir) do
          cmd.call
        end
      end

      assert_equal 1, error.exit_code
      assert_includes error.message, "Missing report input"
    ensure
      $stdin = original_stdin
      Ace::Assign.reset_config!
    end
  end

  def test_finish_message_takes_precedence_over_stdin
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir, "file report content")
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)
      executor.start_step

      cmd = Ace::Assign::CLI::Commands::Finish.new
      stdin = StringIO.new("stdin report content")
      stdin.define_singleton_method(:tty?) { false }
      original_stdin = $stdin
      $stdin = stdin

      output = capture_io do
        with_fast_command_executor(cmd, cache_base: cache_dir) do
          cmd.call(message: report_path)
        end
      end

      assert_includes output.first, "Step 010 (init) completed"

      # Verify file content was used (report file path recorded, not stdin)
      assignment_cache = Dir.glob(File.join(cache_dir, "*/reports/010-init.r.md")).first
      report_saved = File.read(assignment_cache)
      assert_includes report_saved, "file report content"
      refute_includes report_saved, "stdin report content"
    ensure
      $stdin = original_stdin
      Ace::Assign.reset_config!
    end
  end

  def test_lifecycle_finish_auto_advances_and_start_fails_until_free
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir, "Step done!")
      Ace::Assign.config["cache_dir"] = cache_dir

      # Create assignment via executor, then explicitly start 010
      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)
      executor.start_step

      # Finish 010 via CLI — leaves 020 pending until explicitly started
      finish_output = capture_io do
        command = Ace::Assign::CLI::Commands::Finish.new
        with_fast_command_executor(command, cache_base: cache_dir) do
          command.call(message: report_path)
        end
      end
      assert_includes finish_output.first, "Step 010 (init) completed"
      assert_includes finish_output.first, "No active step selected."
      assert_includes finish_output.first, "Next pending step: 020 - build"

      start_output = capture_io do
        Ace::Assign::CLI::Commands::Start.new.call
      end
      assert_includes start_output.first, "Step 020 (build) started"

      # Finish 020 via CLI — leaves 030 pending until explicitly started
      finish_output2 = capture_io do
        command = Ace::Assign::CLI::Commands::Finish.new
        with_fast_command_executor(command, cache_base: cache_dir) do
          command.call(message: report_path)
        end
      end
      assert_includes finish_output2.first, "Step 020 (build) completed"
      assert_includes finish_output2.first, "No active step selected."
      assert_includes finish_output2.first, "Next pending step: 030 - test"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_finish_rejects_step_with_assignment_option
    error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Assign::CLI::Commands::Finish.new.call(step: "010", assignment: "abc123")
    end

    assert_includes error.message, "Positional STEP targeting is only supported"
  end

  def test_finish_rejects_pending_parent_after_child_injection
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir, "Parent completion attempt")
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)
      executor.add("child-step", "Child work", after: "010", as_child: true)

      error = assert_raises(Ace::Assign::StepErrors::InvalidState) do
        command = Ace::Assign::CLI::Commands::Finish.new
        with_fast_command_executor(command, cache_base: cache_dir) do
          command.call(step: "010", message: report_path)
        end
      end

      assert_equal "Cannot finish step 010: status is pending, expected active.", error.message
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_finish_with_empty_message_rejected
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)

      error = assert_raises(Ace::Support::Cli::Error) do
        command = Ace::Assign::CLI::Commands::Finish.new
        with_fast_command_executor(command, cache_base: cache_dir) do
          command.call(message: "")
        end
      end

      assert_equal 1, error.exit_code
      assert_equal "Missing report input: provide --message <string|file> or pipe stdin.", error.message
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_finish_with_whitespace_message_rejected
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = build_fast_executor(cache_base: cache_dir)
      executor.start(config_path)

      error = assert_raises(Ace::Support::Cli::Error) do
        command = Ace::Assign::CLI::Commands::Finish.new
        with_fast_command_executor(command, cache_base: cache_dir) do
          command.call(message: "   ")
        end
      end

      assert_equal 1, error.exit_code
      assert_equal "Missing report input: provide --message <string|file> or pipe stdin.", error.message
    ensure
      Ace::Assign.reset_config!
    end
  end
end
