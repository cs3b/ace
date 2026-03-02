# frozen_string_literal: true

require_relative "../test_helper"

class CurrentTaskLinkerTest < Minitest::Test
  def setup
    setup_temp_dir
    @linker = Ace::Git::Worktree::Molecules::CurrentTaskLinker.new(project_root: @temp_dir)
  end

  def teardown
    teardown_temp_dir
  end

  def test_link_creates_symlink_to_task_directory
    # Create a task directory
    task_dir = File.join(@temp_dir, ".ace-tasks", "v.0.9.0", "tasks", "145-feat")
    FileUtils.mkdir_p(task_dir)

    result = @linker.link(task_dir)

    assert result[:success], "Expected success, got error: #{result[:error]}"
    assert_equal File.join(@temp_dir, "_current"), result[:symlink_path]
    assert_equal task_dir, result[:target]

    # Verify symlink exists
    symlink_path = File.join(@temp_dir, "_current")
    assert File.symlink?(symlink_path), "Expected symlink to be created"

    # Verify symlink target is relative
    target = File.readlink(symlink_path)
    assert_equal ".ace-tasks/v.0.9.0/tasks/145-feat", target
  end

  def test_link_replaces_existing_symlink
    # Create task directories
    task_dir_1 = File.join(@temp_dir, ".ace-tasks", "v.0.9.0", "tasks", "145-feat")
    task_dir_2 = File.join(@temp_dir, ".ace-tasks", "v.0.9.0", "tasks", "146-fix")
    FileUtils.mkdir_p(task_dir_1)
    FileUtils.mkdir_p(task_dir_2)

    # Create first symlink
    @linker.link(task_dir_1)

    # Replace with second symlink
    result = @linker.link(task_dir_2)

    assert result[:success]

    # Verify symlink points to second directory
    symlink_path = File.join(@temp_dir, "_current")
    target = File.readlink(symlink_path)
    assert_equal ".ace-tasks/v.0.9.0/tasks/146-fix", target
  end

  def test_link_fails_for_missing_directory
    result = @linker.link("/nonexistent/path")

    refute result[:success]
    assert_match(/does not exist/, result[:error])
  end

  def test_link_fails_for_nil_directory
    result = @linker.link(nil)

    refute result[:success]
    assert_match(/required/, result[:error])
  end

  def test_link_fails_for_empty_directory
    result = @linker.link("")

    refute result[:success]
    assert_match(/required/, result[:error])
  end

  def test_unlink_removes_existing_symlink
    # Create a task directory and symlink
    task_dir = File.join(@temp_dir, ".ace-tasks", "v.0.9.0", "tasks", "145-feat")
    FileUtils.mkdir_p(task_dir)
    @linker.link(task_dir)

    # Verify symlink exists
    symlink_path = File.join(@temp_dir, "_current")
    assert File.symlink?(symlink_path)

    # Remove symlink
    result = @linker.unlink

    assert result[:success]
    assert result[:existed]
    refute File.symlink?(symlink_path)
  end

  def test_unlink_succeeds_when_no_symlink_exists
    result = @linker.unlink

    assert result[:success]
    refute result[:existed]
  end

  def test_symlink_path_returns_correct_path
    assert_equal File.join(@temp_dir, "_current"), @linker.symlink_path
  end

  def test_exists_returns_false_when_no_symlink
    refute @linker.exists?
  end

  def test_exists_returns_true_when_symlink_exists
    task_dir = File.join(@temp_dir, ".ace-tasks", "v.0.9.0", "tasks", "145-feat")
    FileUtils.mkdir_p(task_dir)
    @linker.link(task_dir)

    assert @linker.exists?
  end

  def test_current_target_returns_nil_when_no_symlink
    assert_nil @linker.current_target
  end

  def test_current_target_returns_relative_path
    task_dir = File.join(@temp_dir, ".ace-tasks", "v.0.9.0", "tasks", "145-feat")
    FileUtils.mkdir_p(task_dir)
    @linker.link(task_dir)

    assert_equal ".ace-tasks/v.0.9.0/tasks/145-feat", @linker.current_target
  end

  def test_current_absolute_path_returns_absolute_path
    task_dir = File.join(@temp_dir, ".ace-tasks", "v.0.9.0", "tasks", "145-feat")
    FileUtils.mkdir_p(task_dir)
    @linker.link(task_dir)

    # The absolute path should resolve to the task directory
    assert_equal File.realpath(task_dir), @linker.current_absolute_path
  end

  def test_current_absolute_path_returns_nil_when_no_symlink
    assert_nil @linker.current_absolute_path
  end

  def test_custom_symlink_name
    custom_linker = Ace::Git::Worktree::Molecules::CurrentTaskLinker.new(
      project_root: @temp_dir,
      symlink_name: "_active"
    )

    task_dir = File.join(@temp_dir, ".ace-tasks", "v.0.9.0", "tasks", "145-feat")
    FileUtils.mkdir_p(task_dir)
    result = custom_linker.link(task_dir)

    assert result[:success]
    assert_equal File.join(@temp_dir, "_active"), result[:symlink_path]
    assert File.symlink?(File.join(@temp_dir, "_active"))
  end

  def test_link_returns_relative_target_in_result
    task_dir = File.join(@temp_dir, ".ace-tasks", "v.0.9.0", "tasks", "145-feat")
    FileUtils.mkdir_p(task_dir)

    result = @linker.link(task_dir)

    assert_equal ".ace-tasks/v.0.9.0/tasks/145-feat", result[:relative_target]
  end
end
