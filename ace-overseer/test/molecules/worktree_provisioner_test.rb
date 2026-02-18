# frozen_string_literal: true

require_relative "../test_helper"

class WorktreeProvisionerTest < AceOverseerTestCase
  class FakeManager
    attr_reader :switch_calls, :create_task_calls

    def initialize(switch_result:, create_result: nil)
      @switch_result = switch_result
      @create_result = create_result
      @switch_calls = []
      @create_task_calls = []
    end

    def switch(task_ref)
      @switch_calls << task_ref
      @switch_result
    end

    def create_task(task_ref)
      @create_task_calls << task_ref
      @create_result
    end
  end

  def test_returns_existing_worktree_without_creation
    manager = FakeManager.new(
      switch_result: { success: true, worktree_path: "/wt/task.230", branch: "230-feature" }
    )

    provisioner = Ace::Overseer::Molecules::WorktreeProvisioner.new(manager: manager)
    result = provisioner.provision("230")

    assert_equal "/wt/task.230", result[:worktree_path]
    assert_equal "230-feature", result[:branch]
    assert_equal false, result[:created]
    assert_equal ["230"], manager.switch_calls
    assert_equal [], manager.create_task_calls
  end

  def test_creates_worktree_when_missing
    manager = FakeManager.new(
      switch_result: { success: false, error: "not found" },
      create_result: { success: true, worktree_path: "/wt/task.231", branch: "231-feature" }
    )

    provisioner = Ace::Overseer::Molecules::WorktreeProvisioner.new(manager: manager)
    result = provisioner.provision("231")

    assert_equal "/wt/task.231", result[:worktree_path]
    assert_equal "231-feature", result[:branch]
    assert_equal true, result[:created]
    assert_equal ["231"], manager.switch_calls
    assert_equal ["231"], manager.create_task_calls
  end
end
