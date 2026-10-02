# frozen_string_literal: true

require "test_helper"
require "ace/task/cli"

class IssueSyncCommandTest < AceTaskTestCase
  def test_requires_one_selection_mode
    error = assert_raises(Ace::Support::Cli::Error) do
      Ace::Task::TaskCLI.start(["issue-sync"])
    end
    assert_match(/Provide REF, --all, or --pending/, error.message)
  end

  def test_ref_and_bulk_flags_conflict
    assert_raises(Ace::Support::Cli::Error) do
      Ace::Task::TaskCLI.start(["issue-sync", "q7w", "--all"])
    end
    assert_raises(Ace::Support::Cli::Error) do
      Ace::Task::TaskCLI.start(["issue-sync", "--all", "--pending"])
    end
  end

  def test_empty_pending_set_reports_zero
    manager = Object.new
    manager.define_singleton_method(:issue_sync) do |**_opts|
      {synced: 0, failed: 0, pending: 0, skipped: 0, failures: []}
    end
    Ace::Task::Organisms::TaskManager.stub(:new, manager) do
      output = capture_io { Ace::Task::TaskCLI.start(["issue-sync", "--pending"]) }.first
      assert_match(/synced 0, failed 0, pending 0/, output)
    end
  end

  def test_partial_failure_is_nonzero_and_shows_identity
    manager = Object.new
    manager.define_singleton_method(:issue_sync) do |**_opts|
      {synced: 1, failed: 1, pending: 0, skipped: 0,
       failures: [{task_id: "8pp.t.q7w", remote_issues: [{"server_name" => "lab", "number" => 42}],
                   error: "offline"}]}
    end
    Ace::Task::Organisms::TaskManager.stub(:new, manager) do
      _stdout, stderr = capture_io do
        assert_raises(Ace::Support::Cli::Error) do
          Ace::Task::TaskCLI.start(["issue-sync", "--all"])
        end
      end
      assert_match(/server_name.*lab/, stderr)
    end
  end
end
