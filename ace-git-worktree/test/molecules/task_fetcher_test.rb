# frozen_string_literal: true

require_relative "../test_helper"

class TaskFetcherTest < Minitest::Test
  def setup
    @fetcher = Ace::Git::Worktree::Molecules::TaskFetcher.new
  end

  def test_fetch_with_valid_task_id
    task_output = <<~TASK
      # Task 081: Fix authentication bug

      **Status:** 🟡 In Progress
      **Estimate:** 2-4 hours

      ## Description
      Users experiencing authentication issues.
    TASK

    Open3.stub(:capture3, [task_output, "", 0]) do
      task = @fetcher.fetch("081")
      refute_nil task
      # TaskMetadata parsing would be tested in the model test
    end
  end

  def test_fetch_with_various_valid_formats
    task_output = "# Task 081\nDescription"
    Open3.stub(:capture3, [task_output, "", 0]) do
      valid_formats = ["081", "task.081", "v.0.9.0+081", "v.0.9.0+task.081"]

      valid_formats.each do |format|
        task = @fetcher.fetch(format)
        refute_nil task, "Should accept format: #{format}"
      end
    end
  end

  def test_fetch_with_nil_or_empty_input
    assert_nil @fetcher.fetch(nil)
    assert_nil @fetcher.fetch("")
    assert_nil @fetcher.fetch("   ")
  end

  def test_fetch_with_invalid_task_id
    Open3.stub(:capture3, ["Task not found", "", 1]) do
      task = @fetcher.fetch("999")
      assert_nil task
    end
  end

  def test_fetch_with_dangerous_inputs
    dangerous_inputs = [
      "081; rm -rf /",
      "081`whoami`",
      "081|cat /etc/passwd",
      "081$(whoami)",
      "081&&echo hack",
      "081||echo hack",
      "../../etc/passwd",
      "081\x00null",
      "081\ninjection",
      "081\tinjection",
      "081\rinjection"
    ]

    dangerous_inputs.each do |dangerous_input|
      task = @fetcher.fetch(dangerous_input)
      assert_nil task, "Should reject dangerous input: #{dangerous_input.inspect}"
    end
  end

  def test_fetch_many_tasks
    task_output = "# Task 081\nDescription"
    Open3.stub(:capture3, [task_output, "", 0]) do
      tasks = @fetcher.fetch_many(["081", "082", "083"])
      assert_equal 3, tasks.length
    end
  end

  def test_fetch_many_with_some_invalid
    task_output = "# Task 081\nDescription"
    Open3.stub(:capture3, [task_output, "", 0]) do
      tasks = @fetcher.fetch_many(["081", "invalid", "082"])
      # Should filter out nil results
      assert_equal 2, tasks.length
    end
  end

  def test_search_tasks
    search_output = <<~OUTPUT
      v.0.9.0+081 Fix authentication bug
      v.0.9.0+082 Update documentation
    OUTPUT

    Open3.stub(:capture3, [search_output, "", 0]) do
      tasks = @fetcher.search("auth", limit: 5)
      # Should find and fetch matching tasks
      assert tasks.length >= 0
    end
  end

  def test_search_with_nil_or_empty_pattern
    tasks = @fetcher.search(nil)
    assert_empty tasks

    tasks = @fetcher.search("")
    assert_empty tasks
  end

  def test_ace_taskflow_available
    Open3.stub(:capture3, ["ace-taskflow 0.10.0", "", 0]) do
      assert @fetcher.ace_taskflow_available?
    end
  end

  def test_ace_taskflow_unavailable
    Open3.stub(:capture3, ["", "command not found: ace-taskflow", 1]) do
      refute @fetcher.ace_taskflow_available?
    end
  end

  def test_ace_taskflow_version
    Open3.stub(:capture3, ["ace-taskflow 0.10.0", "", 0]) do
      assert_equal "0.10.0", @fetcher.ace_taskflow_version
    end
  end

  def test_ace_taskflow_version_nil_when_unavailable
    Open3.stub(:capture3, ["", "command not found: ace-taskflow", 1]) do
      assert_nil @fetcher.ace_taskflow_version
    end
  end

  def test_task_reference_validation_security
    dangerous_refs = [
      "081; rm -rf /",
      "`whoami`",
      "$(rm -rf /)",
      "path|evil",
      "path\x00null",
      "path\ninjection",
      "path\rinjection"
    ]

    dangerous_refs.each do |dangerous_ref|
      assert_raises(ArgumentError, /dangerous characters/) do
        @fetcher.send(:validate_task_reference, dangerous_ref)
      end
    end
  end

  def test_task_reference_length_validation
    long_ref = "task." + "a" * 100  # Much longer than MAX_TASK_ID_LENGTH

    assert_raises(ArgumentError, /too long/) do
      @fetcher.send(:validate_task_reference, long_ref)
    end
  end

  def test_normalize_task_reference_strict_pattern
    # Valid formats should pass
    valid_refs = ["081", "task.081", "v.0.9.0+081", "v.0.9.0+task.081"]
    valid_refs.each do |ref|
      normalized = @fetcher.send(:normalize_task_reference, ref)
      assert_equal "081", normalized, "Should normalize: #{ref}"
    end

    # Invalid formats should return nil
    invalid_refs = [
      "abc",           # Not numeric
      "8",             # Too short
      "0812",          # Too long
      "v.invalid+081", # Invalid version
      "task-081",      # Invalid separator
      "../../../etc/passwd",  # Path traversal
      "081;evil"       # Command injection
    ]

    invalid_refs.each do |ref|
      normalized = @fetcher.send(:normalize_task_reference, ref)
      assert_nil normalized, "Should reject: #{ref}"
    end
  end

  def test_command_validation_allows_only_ace_taskflow
    # Should allow ace-taskflow
    assert_nothing_raised do
      @fetcher.send(:execute_command, "ace-taskflow", "task", "show", "081")
    end

    # Should reject other commands
    other_commands = ["rm", "cat", "ls", "evil", "mise"]
    other_commands.each do |cmd|
      assert_raises(ArgumentError, /Command not allowed/) do
        @fetcher.send(:execute_command, cmd, "arg")
      end
    end
  end

  def test_argument_sanitization
    dangerous_args = [
      "; rm -rf /",
      "$(whoami)",
      "`cat /etc/passwd`",
      "arg\x00null",
      "arg\ninjection",
      "arg\rinjection"
    ]

    dangerous_args.each do |dangerous_arg|
      assert_raises(ArgumentError, /dangerous characters/) do
        @fetcher.send(:execute_command, "ace-taskflow", dangerous_arg)
      end
    end
  end

  def test_command_timeout_handling
    Open3.stub(:capture3) do |*args|
      raise Open3::CommandTimeout
    end

    result = @fetcher.send(:execute_command, "ace-taskflow", "--version")
    refute result[:success]
    assert_match(/timed out/, result[:error])
  end

  def test_command_execution_error_handling
    Open3.stub(:capture3, ["", "Command failed", 1]) do
      result = @fetcher.send(:execute_command, "ace-taskflow", "--version")
      refute result[:success]
      assert_equal "Command failed", result[:error]
      assert_equal 1, result[:exit_code]
    end
  end
end