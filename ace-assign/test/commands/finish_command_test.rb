# frozen_string_literal: true

require_relative "../test_helper"

class FinishCommandTest < AceAssignTestCase
  def test_finish_completes_phase
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir, "Phase done!")

      Ace::Assign.config["cache_dir"] = cache_dir

      # Start an assignment first
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      result = nil
      output = capture_io do
        result = Ace::Assign::CLI::Commands::Finish.new.call(message: report_path)
      end
      assert_nil result  # Verify success returns nil
      assert_includes output.first, "Phase 010 (init) completed"
      assert_includes output.first, "Advancing to phase 020"

      Ace::Assign.reset_config!
    end
  end

  def test_finish_with_explicit_step_completes_targeted_phase
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      report_path = create_report(cache_dir, "Phase done!")

      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path) # 010 in_progress

      output = capture_io do
        Ace::Assign::CLI::Commands::Finish.new.call(step: "010", message: report_path)
      end

      assert_includes output.first, "Phase 010 (init) completed"
      assert_includes output.first, "Advancing to phase 020"

      Ace::Assign.reset_config!
    end
  end

  def test_finish_with_nonexistent_path_uses_inline_message
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)

      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      output = capture_io do
        Ace::Assign::CLI::Commands::Finish.new.call(message: "nonexistent.md")
      end
      assert_includes output.first, "Phase 010 (init) completed"

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

      error = assert_raises(Ace::Core::CLI::Error) do
        Ace::Assign::CLI::Commands::Finish.new.call(message: report_path)
      end

      assert_equal 2, error.exit_code
      assert_includes error.message, "No active assignment"

      Ace::Assign.reset_config!
    end
  end

  def test_finish_with_assignment_flag
    with_temp_cache do |cache_dir|
      report_path = create_report(cache_dir, "Phase done!")

      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)

      config1 = create_test_config(cache_dir, name: "first-task")
      result1 = executor.start(config1)

      config2 = create_test_config(cache_dir, name: "second-task")
      result2 = executor.start(config2)
      target_id = result2[:assignment].id

      output = capture_io do
        Ace::Assign::CLI::Commands::Finish.new.call(
          message: report_path,
          assignment: target_id
        )
      end

      assert_includes output.first, "Phase 010 (init) completed"
      assert_includes output.first, "Advancing to phase 020"

      # Verify the targeted assignment advanced
      scanner = Ace::Assign::Molecules::QueueScanner.new
      target_state = scanner.scan(result2[:assignment].phases_dir, assignment: result2[:assignment])
      assert_equal "020", target_state.current.number

      # Verify the first assignment was not affected (still on 010)
      first_state = scanner.scan(result1[:assignment].phases_dir, assignment: result1[:assignment])
      assert_equal "010", first_state.current.number

      Ace::Assign.reset_config!
    end
  end

  def test_finish_with_assignment_scope_completes_scoped_phase
    with_temp_cache do |cache_dir|
      report_path = create_report(cache_dir, "Scoped progress")
      phases = [
        { "name" => "precheck", "instructions" => "Run precheck" },
        {
          "name" => "work-on-task",
          "instructions" => "Implement task 235.01",
          "context" => "fork",
          "sub_phases" => %w[onboard plan-task]
        },
        { "name" => "postcheck", "instructions" => "Run postcheck" }
      ]
      config_path = create_test_config(cache_dir, steps: phases)

      Ace::Assign.config["cache_dir"] = cache_dir
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      start = executor.start(config_path)
      target_id = start[:assignment].id
      executor.advance(report_path) # complete 010 precheck, activate 020.01

      output = capture_io do
        Ace::Assign::CLI::Commands::Finish.new.call(
          message: report_path,
          assignment: "#{target_id}@020"
        )
      end

      assert_includes output.first, "Phase 020.01 (onboard) completed"

      scanner = Ace::Assign::Molecules::QueueScanner.new
      state = scanner.scan(start[:assignment].phases_dir, assignment: start[:assignment])

      assert_equal :done, state.find_by_number("010").status
      assert_equal :done, state.find_by_number("020.01").status
      assert_equal :in_progress, state.find_by_number("020.02").status

      Ace::Assign.reset_config!
    end
  end

  def test_finish_with_stdin_input
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      cmd = Ace::Assign::CLI::Commands::Finish.new
      stdin = StringIO.new("stdin report")
      stdin.define_singleton_method(:tty?) { false }
      original_stdin = $stdin
      $stdin = stdin

      output = capture_io do
        cmd.call
      end

      assert_includes output.first, "Phase 010 (init) completed"
    ensure
      $stdin = original_stdin
      Ace::Assign.reset_config!
    end
  end

  def test_finish_with_missing_report_input
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      cmd = Ace::Assign::CLI::Commands::Finish.new
      stdin = StringIO.new("")
      stdin.define_singleton_method(:tty?) { true }
      original_stdin = $stdin
      $stdin = stdin

      error = assert_raises(Ace::Core::CLI::Error) do
        cmd.call
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

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      cmd = Ace::Assign::CLI::Commands::Finish.new
      stdin = StringIO.new("stdin report content")
      stdin.define_singleton_method(:tty?) { false }
      original_stdin = $stdin
      $stdin = stdin

      output = capture_io do
        cmd.call(message: report_path)
      end

      assert_includes output.first, "Phase 010 (init) completed"

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
      report_path = create_report(cache_dir, "Phase done!")
      Ace::Assign.config["cache_dir"] = cache_dir

      # Create assignment via executor — 010 is in_progress
      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      # Finish 010 via CLI — auto-advances to 020
      finish_output = capture_io do
        Ace::Assign::CLI::Commands::Finish.new.call(message: report_path)
      end
      assert_includes finish_output.first, "Phase 010 (init) completed"
      assert_includes finish_output.first, "Advancing to phase 020"

      # start fails — 020 is already in_progress after auto-advance
      error = assert_raises(Ace::Core::CLI::Error) do
        Ace::Assign::CLI::Commands::Start.new.call
      end
      assert_includes error.message, "already in progress"

      # Finish 020 via CLI — auto-advances to 030
      finish_output2 = capture_io do
        Ace::Assign::CLI::Commands::Finish.new.call(message: report_path)
      end
      assert_includes finish_output2.first, "Phase 020 (build) completed"
      assert_includes finish_output2.first, "Advancing to phase 030"
    ensure
      Ace::Assign.reset_config!
    end
  end

  def test_finish_rejects_step_with_assignment_option
    error = assert_raises(Ace::Core::CLI::Error) do
      Ace::Assign::CLI::Commands::Finish.new.call(step: "010", assignment: "abc123")
    end

    assert_includes error.message, "Positional STEP targeting is only supported"
  end

  def test_finish_with_empty_message_rejected
    with_temp_cache do |cache_dir|
      config_path = create_test_config(cache_dir)
      Ace::Assign.config["cache_dir"] = cache_dir

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      error = assert_raises(Ace::Core::CLI::Error) do
        Ace::Assign::CLI::Commands::Finish.new.call(message: "")
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

      executor = Ace::Assign::Organisms::AssignmentExecutor.new(cache_base: cache_dir)
      executor.start(config_path)

      error = assert_raises(Ace::Core::CLI::Error) do
        Ace::Assign::CLI::Commands::Finish.new.call(message: "   ")
      end

      assert_equal 1, error.exit_code
      assert_equal "Missing report input: provide --message <string|file> or pipe stdin.", error.message
    ensure
      Ace::Assign.reset_config!
    end
  end
end
