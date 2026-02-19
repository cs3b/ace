# frozen_string_literal: true

require_relative "../test_helper"

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
      captured = { path: path, options: options }
      { success: true }
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

  def test_get_status_api_exists
    status = @manager.get_status
    assert status.is_a?(Hash)
    assert status.key?(:success)
  end
end
