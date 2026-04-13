# frozen_string_literal: true

require_relative "../../test_helper"

class WorktreeManagerTest < Minitest::Test
  def setup
    setup_temp_dir
    @manager = Ace::Git::Worktree::Organisms::WorktreeManager.new
  end

  def teardown
    teardown_temp_dir
  end

  # Smoke tests - verify API exists and basic validation works
  # These don't mock internals since organisms initialize their own dependencies

  def test_create_task_api_exists
    # Just verify the API exists and handles validation
    result = @manager.create_task(nil)
    assert result.is_a?(Hash)
    assert result.key?(:success)
  end

  def test_create_api_exists_and_validates
    result = @manager.create(nil)
    refute result[:success]
    assert result[:message] || result[:error]
  end

  def test_create_with_empty_string_validates
    result = @manager.create("")
    refute result[:success]
  end

  def test_list_all_api_exists
    result = @manager.list_all
    assert result.is_a?(Hash)
    assert result.key?(:success)
    assert result.key?(:worktrees)
  end

  def test_switch_api_exists_and_validates
    result = @manager.switch(nil)
    refute result[:success]
    assert result[:message] || result[:error]
  end

  def test_switch_with_empty_string_validates
    result = @manager.switch("")
    refute result[:success]
  end

  def test_remove_api_exists_and_validates
    result = @manager.remove(nil)
    refute result[:success]
    assert result[:message] || result[:error]
  end

  def test_remove_with_empty_string_validates
    result = @manager.remove("")
    refute result[:success]
  end

  def test_remove_forwards_ignore_untracked_option
    worktree = Struct.new(:path, :description).new("/tmp/.ace-wt/task.001", "task.001")
    captured = nil
    fake_remover = Object.new
    fake_remover.define_singleton_method(:remove) do |path, **options|
      captured = {path: path, options: options}
      {success: true}
    end
    @manager.instance_variable_set(:@worktree_remover, fake_remover)

    @manager.stub(:find_worktree_by_identifier, worktree) do
      result = @manager.remove("001", ignore_untracked: true)
      assert result[:success]
    end

    assert_equal "/tmp/.ace-wt/task.001", captured[:path]
    assert_equal true, captured[:options][:ignore_untracked]
    assert_nil captured[:options][:force]
  end

  def test_remove_task_api_exists
    result = @manager.remove_task(nil)
    assert result.is_a?(Hash)
    assert result.key?(:success)
  end

  def test_prune_api_exists
    result = @manager.prune
    assert result.is_a?(Hash)
    assert result.key?(:success)
  end

  def test_list_all_with_false_task_associated_does_not_raise
    result = @manager.list_all(task_associated: false)
    assert result.is_a?(Hash)
    assert result.key?(:success)
  end

  def test_list_all_with_false_usable_does_not_raise
    result = @manager.list_all(usable: false)
    assert result.is_a?(Hash)
    assert result.key?(:success)
  end

  def test_list_all_uses_task_resolved_listing_when_task_filter_requested
    calls = []
    fake_lister = Object.new
    worktrees = []

    fake_lister.define_singleton_method(:list_all) do
      calls << :list_all
      worktrees
    end

    fake_lister.define_singleton_method(:list_with_tasks) do
      calls << :list_with_tasks
      worktrees
    end

    fake_lister.define_singleton_method(:filter) do |items, task_associated:, usable:, branch_pattern:|
      calls << [:filter, task_associated, usable, branch_pattern]
      items
    end

    fake_lister.define_singleton_method(:format_for_display) do |_items, _format|
      ""
    end

    fake_lister.define_singleton_method(:get_statistics) do |_items|
      {
        total: 0,
        task_associated: 0,
        non_task_associated: 0,
        usable: 0,
        unusable: 0,
        bare: 0,
        detached: 0,
        branches: [],
        task_ids: []
      }
    end

    @manager.instance_variable_set(:@worktree_lister, fake_lister)
    result = @manager.list_all(task_associated: false)

    assert result[:success]
    assert_includes calls, :list_with_tasks
    refute_includes calls, :list_all
  end

  def test_list_all_uses_plain_listing_when_no_task_filter_and_show_tasks_disabled
    calls = []
    fake_lister = Object.new
    worktrees = []

    fake_lister.define_singleton_method(:list_all) do
      calls << :list_all
      worktrees
    end

    fake_lister.define_singleton_method(:list_with_tasks) do
      calls << :list_with_tasks
      worktrees
    end

    fake_lister.define_singleton_method(:filter) do |items, task_associated:, usable:, branch_pattern:|
      calls << [:filter, task_associated, usable, branch_pattern]
      items
    end

    fake_lister.define_singleton_method(:format_for_display) do |_items, _format|
      ""
    end

    fake_lister.define_singleton_method(:get_statistics) do |_items|
      {
        total: 0,
        task_associated: 0,
        non_task_associated: 0,
        usable: 0,
        unusable: 0,
        bare: 0,
        detached: 0,
        branches: [],
        task_ids: []
      }
    end

    @manager.instance_variable_set(:@worktree_lister, fake_lister)
    result = @manager.list_all(format: :table)

    assert result[:success]
    assert_includes calls, :list_all
    refute_includes calls, :list_with_tasks
  end

  def test_get_status_api_exists
    status = @manager.get_status
    assert status.is_a?(Hash)
    assert status.key?(:success)
  end
end
