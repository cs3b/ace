# frozen_string_literal: true

require "test_helper"

class GithubIssueSyncAdapterTest < AceTaskTestCase
  def test_sync_task_uses_spec_file_path_for_task_link
    adapter = Ace::Task::Molecules::GithubIssueSyncAdapter.new
    captured = nil

    fake_receiver = Object.new
    fake_receiver.define_singleton_method(:validate_link!) { |**_payload| }
    fake_receiver.define_singleton_method(:sync_task) do |**payload|
      captured = payload
      {success: true}
    end

    task = Ace::Task::Models::Task.new(
      id: "8pp.t.q7w",
      title: "Example task",
      status: "pending",
      path: "/tmp/tasks/8pp.t.q7w-example",
      file_path: "/tmp/tasks/8pp.t.q7w-example/8pp.t.q7w-example.s.md",
      metadata: {"github_issue" => 276}
    )

    adapter.stub(:resolve_integration, [fake_receiver, :sync_task]) do
      adapter.sync_task(task: task, reason: "manual-sync")
    end

    assert_equal task.file_path, captured[:task_path]
  end
end
