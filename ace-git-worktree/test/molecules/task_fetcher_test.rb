# frozen_string_literal: true

require_relative "../test_helper"

class TaskFetcherTest < Minitest::Test
  def setup
    @fetcher = Ace::Git::Worktree::Molecules::TaskFetcher.new
  end

  def test_fetch_with_valid_task_id
    task_output = <<~TASK
      Task: task.081
      Title: Fix authentication bug
      Status: 🟡 In Progress
      Estimate: 2-4 hours
      --- Content ---
      ## Description
      Users experiencing authentication issues.
    TASK

    mock_status = Object.new
    mock_status.define_singleton_method(:success?) { true }

    @fetcher.stub(:ace_task_available?, false) do
      Open3.stub(:capture3, [task_output, "", mock_status]) do
        task = @fetcher.fetch("081")
        refute_nil task
      end
    end
  end

  def test_fetch_with_various_valid_formats
    task_output = <<~TASK
      Task: task.081
      Title: Test Task
      --- Content ---
      Description
    TASK

    mock_status = Object.new
    mock_status.define_singleton_method(:success?) { true }

    valid_formats = ["081", "8pp.t.q7w"]

    @fetcher.stub(:ace_task_available?, false) do
      Open3.stub(:capture3, [task_output, "", mock_status]) do
        valid_formats.each do |format|
          task = @fetcher.fetch(format)
          refute_nil task, "Should accept format: #{format}"
        end
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

  def test_ace_task_available
    assert @fetcher.ace_task_available?
  end
end
