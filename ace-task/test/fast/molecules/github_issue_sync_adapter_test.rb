# frozen_string_literal: true

require "test_helper"

class GithubIssueSyncAdapterTest < AceTaskTestCase
  def test_sync_task_resolves_sync_task_integration
    adapter = Ace::Task::Molecules::GithubIssueSyncAdapter.new
    expected_method = nil
    captured = nil

    fake_receiver = Object.new
    fake_receiver.define_singleton_method(:available?) { true }
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

    adapter.stub(:resolve_integration, ->(method = nil) {
      expected_method = method
      [fake_receiver, :sync_task]
    }) do
      adapter.sync_task(task: task, reason: "manual-sync")
    end

    assert_equal :sync_task, expected_method
    assert_equal [276], captured[:issue_ids]
  end

  def test_sync_task_uses_spec_file_path_for_task_link
    adapter = Ace::Task::Molecules::GithubIssueSyncAdapter.new
    captured = nil

    fake_receiver = Object.new
    fake_receiver.define_singleton_method(:validate_link!) { |**_payload| }
    fake_receiver.define_singleton_method(:available?) { true }
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

  def test_sync_task_skips_silently_when_unavailable
    adapter = Ace::Task::Molecules::GithubIssueSyncAdapter.new

    fake_receiver = Object.new
    fake_receiver.define_singleton_method(:available?) { false }
    fake_receiver.define_singleton_method(:sync_task) { |**_payload| flunk("sync_task must not run when unavailable") }

    task = Ace::Task::Models::Task.new(
      id: "8pp.t.q7w",
      title: "Example task",
      status: "pending",
      path: "/tmp/tasks/8pp.t.q7w-example",
      file_path: "/tmp/tasks/8pp.t.q7w-example/8pp.t.q7w-example.s.md",
      metadata: {"github_issue" => 276}
    )

    result = nil
    adapter.stub(:resolve_integration, [fake_receiver, :sync_task]) do
      result = adapter.sync_task(task: task, reason: "update")
    end

    assert_equal({synced: 0, issues: []}, result)
  end

  def test_validate_link_skips_silently_when_unavailable
    adapter = Ace::Task::Molecules::GithubIssueSyncAdapter.new

    fake_receiver = Object.new
    fake_receiver.define_singleton_method(:available?) { false }
    fake_receiver.define_singleton_method(:validate_link!) { |**_payload| flunk("must not run when unavailable") }

    previous = Ace::Task::Models::Task.new(id: "8pp.t.q7w")

    adapter.stub(:resolve_integration, [fake_receiver, :validate_link!]) do
      adapter.validate_link!(issue_id: 276, previous_task: previous)
    end
  end
end
