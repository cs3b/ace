# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/organisms/release_manager"

class ReleaseManagerTest < AceTaskflowTestCase
  def test_show_active_with_no_releases
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Remove the default v.0.9.0 active release created by TestFactory
        FileUtils.rm_rf(File.join(dir, ".ace-taskflow", "v.0.9.0"))

        manager = Ace::Taskflow::Organisms::ReleaseManager.new
        result = manager.show_active

        assert_equal [], result
      end
    end
  end

  def test_show_active_with_active_release
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Remove default v.0.9.0 to have clean state
        FileUtils.rm_rf(File.join(dir, ".ace-taskflow", "v.0.9.0"))

        create_test_release(dir, "v.1.0.0", "active")

        manager = Ace::Taskflow::Organisms::ReleaseManager.new
        result = manager.show_active

        assert_equal 1, result.length
        assert_equal "v.1.0.0", result.first[:name]
      end
    end
  end

  def test_show_specific_release_found
    with_test_project do |dir|
      Dir.chdir(dir) do
        create_test_release(dir, "v.1.0.0", "active")

        manager = Ace::Taskflow::Organisms::ReleaseManager.new
        result = manager.show_release("v.1.0.0")

        refute_nil result
        assert_equal "v.1.0.0", result[:name]
      end
    end
  end

  def test_show_specific_release_not_found
    with_test_project do |dir|
      Dir.chdir(dir) do
        manager = Ace::Taskflow::Organisms::ReleaseManager.new
        result = manager.show_release("v.99.99.99")

        assert_nil result
      end
    end
  end

  def test_list_all_releases
    with_test_project do |dir|
      Dir.chdir(dir) do
        create_test_release(dir, "v.1.0.0", "active")
        create_test_release(dir, "v.1.1.0", "backlog")
        create_test_release(dir, "v.0.8.0", "done")

        manager = Ace::Taskflow::Organisms::ReleaseManager.new
        result = manager.list_releases

        # Should find our 3 releases plus the existing v.0.9.0 and v.0.8.0 from TestFactory
        assert result.length >= 3
      end
    end
  end

  def test_list_releases_filtered_by_status
    with_test_project do |dir|
      Dir.chdir(dir) do
        create_test_release(dir, "v.1.0.0", "active")
        create_test_release(dir, "v.1.1.0", "backlog")

        manager = Ace::Taskflow::Organisms::ReleaseManager.new
        backlog_releases = manager.list_releases("backlog")

        assert backlog_releases.any? { |r| r[:name] == "v.1.1.0" }
      end
    end
  end

  def test_promote_release_from_backlog
    with_test_project do |dir|
      Dir.chdir(dir) do
        create_test_release(dir, "v.1.0.0", "backlog")

        manager = Ace::Taskflow::Organisms::ReleaseManager.new
        result = manager.promote_release("v.1.0.0")

        assert result[:success], "Promotion failed: #{result[:message]}"
        assert_match(/Promoted/, result[:message])
      end
    end
  end

  def test_promote_release_not_found
    with_test_project do |dir|
      Dir.chdir(dir) do
        manager = Ace::Taskflow::Organisms::ReleaseManager.new
        result = manager.promote_release("v.99.99.99")

        refute result[:success]
        assert_match(/not found/, result[:message])
      end
    end
  end

  def test_promote_release_not_in_backlog
    with_test_project do |dir|
      Dir.chdir(dir) do
        create_test_release(dir, "v.1.0.0", "active")

        manager = Ace::Taskflow::Organisms::ReleaseManager.new
        result = manager.promote_release("v.1.0.0")

        refute result[:success]
        assert_match(/not in backlog/, result[:message])
      end
    end
  end

  def test_promote_release_auto_select_from_backlog
    with_test_project do |dir|
      Dir.chdir(dir) do
        create_test_release(dir, "v.1.0.0", "backlog")
        create_test_release(dir, "v.1.1.0", "backlog")

        manager = Ace::Taskflow::Organisms::ReleaseManager.new
        result = manager.promote_release(nil)

        assert result[:success], "Auto-promotion failed: #{result[:message]}"
      end
    end
  end

  def test_demote_release_to_done
    with_test_project do |dir|
      Dir.chdir(dir) do
        create_test_release(dir, "v.1.0.0", "active", with_tasks: true, all_done: true)

        manager = Ace::Taskflow::Organisms::ReleaseManager.new
        result = manager.demote_release("v.1.0.0", to: "done")

        assert result[:success], "Demotion failed: #{result[:message]}"
        assert_match(/Demoted/, result[:message])
      end
    end
  end

  def test_demote_release_to_backlog
    with_test_project do |dir|
      Dir.chdir(dir) do
        create_test_release(dir, "v.1.0.0", "active", with_tasks: true, all_done: true)

        manager = Ace::Taskflow::Organisms::ReleaseManager.new
        result = manager.demote_release("v.1.0.0", to: "backlog")

        assert result[:success], "Demotion to backlog failed: #{result[:message]}"
      end
    end
  end

  def test_demote_release_not_found
    with_test_project do |dir|
      Dir.chdir(dir) do
        manager = Ace::Taskflow::Organisms::ReleaseManager.new
        result = manager.demote_release("v.99.99.99")

        refute result[:success]
        assert_match(/not found/, result[:message])
      end
    end
  end

  def test_demote_release_not_active
    with_test_project do |dir|
      Dir.chdir(dir) do
        create_test_release(dir, "v.1.0.0", "backlog")

        manager = Ace::Taskflow::Organisms::ReleaseManager.new
        result = manager.demote_release("v.1.0.0")

        refute result[:success]
        assert_match(/not active/, result[:message])
      end
    end
  end

  def test_validate_release_with_valid_release
    with_test_project do |dir|
      Dir.chdir(dir) do
        create_test_release(dir, "v.1.0.0", "active", with_tasks: true, all_done: true)

        manager = Ace::Taskflow::Organisms::ReleaseManager.new
        result = manager.validate_release("v.1.0.0")

        assert result[:valid], "Expected valid release but got issues: #{result[:issues]}"
      end
    end
  end

  def test_validate_release_with_pending_tasks
    with_test_project do |dir|
      Dir.chdir(dir) do
        create_test_release(dir, "v.1.0.0", "active", with_tasks: true, all_done: false)

        manager = Ace::Taskflow::Organisms::ReleaseManager.new
        result = manager.validate_release("v.1.0.0")

        refute result[:valid]
        assert result[:issues].any? { |issue| issue.include?("pending") }
      end
    end
  end

  def test_generate_changelog_with_tasks
    with_test_project do |dir|
      Dir.chdir(dir) do
        create_test_release(dir, "v.1.0.0", "active", with_tasks: true, all_done: true)

        manager = Ace::Taskflow::Organisms::ReleaseManager.new
        result = manager.generate_changelog("v.1.0.0")

        assert_includes result, "## v.1.0.0"
        assert_includes result, "Completed"
      end
    end
  end

  def test_generate_changelog_release_not_found
    with_test_project do |dir|
      Dir.chdir(dir) do
        manager = Ace::Taskflow::Organisms::ReleaseManager.new
        result = manager.generate_changelog("v.99.99.99")

        assert_equal "Release not found", result
      end
    end
  end

  private

  def create_test_release(base_dir, name, status, with_tasks: false, all_done: false)
    taskflow_root = File.join(base_dir, ".ace-taskflow")

    # Determine directory based on status
    case status
    when "active"
      release_dir = File.join(taskflow_root, name)
    when "backlog"
      release_dir = File.join(taskflow_root, "backlog", name)
    when "done"
      release_dir = File.join(taskflow_root, "done", name)
    end

    FileUtils.mkdir_p(release_dir)
    FileUtils.mkdir_p(File.join(release_dir, "t"))
    FileUtils.mkdir_p(File.join(release_dir, "i"))
    FileUtils.mkdir_p(File.join(release_dir, "docs"))

    # Create .active marker for active releases
    File.write(File.join(release_dir, ".active"), "") if status == "active"

    # Create release.md
    File.write(File.join(release_dir, "release.md"), <<~RELEASE)
      ---
      version: #{name}
      status: #{status}
      ---
      # Release #{name}
    RELEASE

    if with_tasks
      # Create sample tasks
      2.times do |i|
        task_num = sprintf("%03d", i + 1)
        task_dir = File.join(release_dir, "t", task_num)
        FileUtils.mkdir_p(task_dir)

        task_status = all_done ? "done" : (i == 0 ? "done" : "pending")
        File.write(File.join(task_dir, "task.#{task_num}.md"), <<~TASK)
          ---
          id: #{name}+task.#{task_num}
          status: #{task_status}
          title: Test task #{task_num}
          ---
          # Task #{task_num}
        TASK
      end
    end
  end
end
