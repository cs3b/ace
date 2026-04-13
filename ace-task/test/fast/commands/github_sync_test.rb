# frozen_string_literal: true

require "test_helper"
require "ace/task/cli"

class GithubSyncCommandTest < AceTaskTestCase
  def test_requires_ref_or_all
    err = assert_raises(Ace::Support::Cli::Error) do
      capture_io { Ace::Task::TaskCLI.start(["github-sync"]) }
    end

    assert_match(/Provide a task reference or use --all/, err.message)
  end

  def test_sync_single_task
    fake_manager = Object.new
    fake_manager.define_singleton_method(:github_sync) do |ref:, all:|
      raise "unexpected all=true" if all
      raise "unexpected ref" unless ref == "q7w"

      {synced: 1, failed: 0, skipped: 0, task_id: "8pp.t.q7w", failures: []}
    end

    output = nil
    Ace::Task::Organisms::TaskManager.stub(:new, fake_manager) do
      output = capture_io { Ace::Task::TaskCLI.start(["github-sync", "q7w"]) }.first
    end

    assert_match(/GitHub sync complete: 8pp\.t\.q7w/, output)
  end

  def test_sync_all
    fake_manager = Object.new
    fake_manager.define_singleton_method(:github_sync) do |ref:, all:|
      raise "unexpected ref" unless ref.nil?
      raise "expected all=true" unless all

      {synced: 2, failed: 0, skipped: 3, failures: []}
    end

    output = nil
    Ace::Task::Organisms::TaskManager.stub(:new, fake_manager) do
      output = capture_io { Ace::Task::TaskCLI.start(["github-sync", "--all"]) }.first
    end

    assert_match(/synced 2 linked task\(s\), skipped 3 task\(s\)/, output)
  end

  def test_raises_when_sync_has_failures
    fake_manager = Object.new
    fake_manager.define_singleton_method(:github_sync) do |ref:, all:|
      raise "unexpected all=true" if all
      raise "unexpected ref" unless ref == "q7w"

      {
        synced: 0,
        failed: 1,
        skipped: 0,
        task_id: "8pp.t.q7w",
        failures: [{task_id: "8pp.t.q7w", error: "gh auth failed"}]
      }
    end

    stdout = nil
    stderr = nil
    err = nil
    Ace::Task::Organisms::TaskManager.stub(:new, fake_manager) do
      stdout, stderr = capture_io do
        err = assert_raises(Ace::Support::Cli::Error) { Ace::Task::TaskCLI.start(["github-sync", "q7w"]) }
      end
    end

    assert_equal "", stdout
    assert_match(/GitHub sync failed for 8pp\.t\.q7w: gh auth failed/, stderr)
    assert_match(/GitHub sync incomplete/, err.message)
  end
end
