# frozen_string_literal: true

require_relative "../test_helper"
require "tmpdir"

class WorktreeProvisionerTest < AceOverseerTestCase
  class FakeManager
    attr_reader :switch_calls, :create_task_calls, :prune_calls

    def initialize(switch_result: nil, create_result: nil, switch_results: nil, create_results: nil)
      @switch_result = switch_result
      @create_result = create_result
      @switch_results = Array(switch_results) if switch_results
      @create_results = Array(create_results) if create_results
      @switch_calls = []
      @create_task_calls = []
      @prune_calls = 0
    end

    def switch(task_ref)
      @switch_calls << task_ref
      return @switch_results.shift if @switch_results && !@switch_results.empty?

      @switch_result
    end

    def create_task(task_ref)
      @create_task_calls << task_ref
      return @create_results.shift if @create_results && !@create_results.empty?

      @create_result
    end

    def prune
      @prune_calls += 1
      {success: true}
    end
  end

  def test_returns_existing_worktree_without_creation
    Dir.mktmpdir("task.230") do |worktree|
      manager = FakeManager.new(
        switch_result: {success: true, worktree_path: worktree, branch: "230-feature"}
      )

      provisioner = Ace::Overseer::Molecules::WorktreeProvisioner.new(manager: manager)
      result = provisioner.provision("230")

      assert_equal worktree, result[:worktree_path]
      assert_equal "230-feature", result[:branch]
      assert_equal false, result[:created]
      assert_equal ["230"], manager.switch_calls
      assert_equal [], manager.create_task_calls
    end
  end

  def test_creates_worktree_when_missing
    Dir.mktmpdir("task.231") do |worktree|
      manager = FakeManager.new(
        switch_result: {success: false, error: "not found"},
        create_result: {success: true, worktree_path: worktree, branch: "231-feature"}
      )

      provisioner = Ace::Overseer::Molecules::WorktreeProvisioner.new(manager: manager)
      result = provisioner.provision("231")

      assert_equal worktree, result[:worktree_path]
      assert_equal "231-feature", result[:branch]
      assert_equal true, result[:created]
      assert_equal ["231"], manager.switch_calls
      assert_equal ["231"], manager.create_task_calls
    end
  end

  def test_marks_existing_create_result_as_not_created
    Dir.mktmpdir("task.232") do |worktree|
      manager = FakeManager.new(
        switch_result: {success: false, error: "not found"},
        create_result: {success: true, existing: true, worktree_path: worktree, branch: "232-feature"}
      )

      provisioner = Ace::Overseer::Molecules::WorktreeProvisioner.new(manager: manager)
      result = provisioner.provision("232")

      assert_equal false, result[:created]
      assert_equal 0, manager.prune_calls
    end
  end

  def test_recovers_when_switch_returns_stale_missing_path
    Dir.mktmpdir("task.233") do |worktree|
      manager = FakeManager.new(
        switch_result: {success: true, worktree_path: "/missing/task.233", branch: "233-feature"},
        create_result: {success: true, existing: false, worktree_path: worktree, branch: "233-feature"}
      )

      provisioner = Ace::Overseer::Molecules::WorktreeProvisioner.new(manager: manager)
      result = provisioner.provision("233")

      assert_equal worktree, result[:worktree_path]
      assert_equal true, result[:created]
      assert_equal 1, manager.prune_calls
      assert_equal ["233"], manager.switch_calls
      assert_equal ["233"], manager.create_task_calls
    end
  end

  def test_recovers_when_create_returns_stale_missing_path
    Dir.mktmpdir("task.234") do |worktree|
      manager = FakeManager.new(
        switch_result: {success: false, error: "not found"},
        create_results: [
          {success: true, existing: true, worktree_path: "/missing/task.234", branch: "234-feature"},
          {success: true, existing: false, worktree_path: worktree, branch: "234-feature"}
        ]
      )

      provisioner = Ace::Overseer::Molecules::WorktreeProvisioner.new(manager: manager)
      result = provisioner.provision("234")

      assert_equal worktree, result[:worktree_path]
      assert_equal true, result[:created]
      assert_equal 1, manager.prune_calls
      assert_equal ["234"], manager.switch_calls
      assert_equal ["234", "234"], manager.create_task_calls
    end
  end

  def test_raises_when_worktree_path_still_missing_after_recovery
    manager = FakeManager.new(
      switch_result: {success: false, error: "not found"},
      create_results: [
        {success: true, existing: true, worktree_path: "/missing/task.235", branch: "235-feature"},
        {success: true, existing: true, worktree_path: "/missing/task.235", branch: "235-feature"}
      ]
    )

    provisioner = Ace::Overseer::Molecules::WorktreeProvisioner.new(manager: manager)

    error = assert_raises(Ace::Overseer::Error) do
      provisioner.provision("235")
    end

    assert_includes error.message, "ace-git-worktree prune"
    assert_equal 1, manager.prune_calls
  end
end
