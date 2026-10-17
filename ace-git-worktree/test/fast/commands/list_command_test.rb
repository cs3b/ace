# frozen_string_literal: true

require_relative "../../test_helper"

class ListCommandTest < Minitest::Test
  class RecordingReporter
    attr_reader :options

    def initialize(result: {success: true, output: "rendered"})
      @result = result
    end

    def run(options)
      @options = options
      @result
    end
  end

  def setup
    @reporter = RecordingReporter.new
    @command = Ace::Git::Worktree::Commands::ListCommand.new(reporter: @reporter)
  end

  def run_command(args)
    stdout, = capture_io do
      @result = @command.run(args)
    end
    [@result, stdout]
  end

  def test_help_prints_contract_without_show_tasks
    code, output = run_command(["--help"])

    assert_equal 0, code
    assert_includes output, "--active-within"
    assert_includes output, "--full"
    assert_includes output, "--format"
    assert_includes output, "Task"
    refute_includes output, "show-tasks"
  end

  def test_default_options
    code, output = run_command([])

    assert_equal 0, code
    assert_equal "rendered\n", output
    assert_equal "table", @reporter.options[:format]
    assert_equal false, @reporter.options[:full]
    assert_equal false, @reporter.options[:compact]
    assert_nil @reporter.options[:active_within]
  end

  def test_detail_and_window_flags_are_passed
    run_command(["--full", "--active-within", "3d"])

    assert_equal true, @reporter.options[:full]
    assert_equal "3d", @reporter.options[:active_within]
  end

  def test_format_is_passed_through
    run_command(["--format", "json"])

    assert_equal "json", @reporter.options[:format]
  end

  def test_filters_are_passed_through
    run_command(["--task-associated", "--no-usable", "--search", "auth"])

    assert_equal true, @reporter.options[:task_associated]
    assert_equal false, @reporter.options[:usable]
    assert_equal "auth", @reporter.options[:search]
  end

  def test_quiet_verbose_debug_flags
    run_command(["-q", "-v", "-d"])

    assert_equal true, @reporter.options[:quiet]
    assert_equal true, @reporter.options[:verbose]
    assert_equal true, @reporter.options[:debug]
  end

  def test_show_tasks_is_rejected_as_unknown_option
    code, output = run_command(["--show-tasks"])

    assert_equal 1, code
    assert_includes output, "Unknown option: --show-tasks"
    refute_includes output, "USAGE:"
  end

  def test_invalid_duration_is_actionable_and_non_zero
    code, output = run_command(["--active-within", "abc"])

    assert_equal 1, code
    assert_includes output, "invalid duration 'abc'. Use forms like 30m, 18h, 2d, or bare hours."
    refute_includes output, "USAGE:"
  end

  def test_zero_duration_is_rejected
    code, output = run_command(["--active-within", "0"])

    assert_equal 1, code
    assert_includes output, "invalid duration '0'"
  end

  def test_compact_and_full_are_mutually_exclusive
    code, output = run_command(["--compact", "--full"])

    assert_equal 1, code
    assert_includes output, "--compact and --full are mutually exclusive"
  end

  def test_invalid_format_is_rejected
    code, output = run_command(["--format", "yaml"])

    assert_equal 1, code
    assert_includes output, "Invalid format: yaml"
  end

  def test_empty_search_is_rejected
    code, output = run_command(["--search", ""])

    assert_equal 1, code
    assert_includes output, "Search pattern cannot be empty"
  end

  def test_dangerous_search_is_rejected
    ["; rm -rf /", "$(whoami)", "`cat /etc/passwd`", "../etc/passwd"].each do |pattern|
      code, output = run_command(["--search", pattern])

      assert_equal 1, code
      assert_includes output, "dangerous"
    end
  end

  def test_unexpected_argument_is_rejected
    code, output = run_command(["extra"])

    assert_equal 1, code
    assert_includes output, "Unexpected argument: extra"
  end

  def test_report_failure_is_reported
    reporter = RecordingReporter.new(result: {success: false, error: "not a git repository"})
    command = Ace::Git::Worktree::Commands::ListCommand.new(reporter: reporter)

    stdout, = capture_io { @result = command.run([]) }

    assert_equal 1, @result
    assert_includes stdout, "Failed to list worktrees: not a git repository"
  end
end
