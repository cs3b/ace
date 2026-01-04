# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/configuration"

class ConfigurationTest < AceTaskflowTestCase
  # ADR-022: Configuration copies example config on initialization

  def test_initialize_structure_creates_directories
    Dir.mktmpdir do |dir|
      TestFactory.with_stubbed_project_root(dir) do
        Dir.chdir(dir) do
          # Create minimal taskflow directory for find_root to succeed
          taskflow_root = File.join(dir, ".ace-taskflow")
          FileUtils.mkdir_p(taskflow_root)

          config = Ace::Taskflow::Configuration.new
          config.initialize_structure!

          # Verify standard directories were created
          assert Dir.exist?(File.join(taskflow_root, config.backlog_dir)),
                 "backlog directory should exist"
          assert Dir.exist?(File.join(taskflow_root, config.done_dir)),
                 "done directory should exist"
        end
      end
    end
  end

  def test_initialize_structure_copies_example_config_when_missing
    Dir.mktmpdir do |dir|
      TestFactory.with_stubbed_project_root(dir) do
        Dir.chdir(dir) do
          # Create minimal taskflow directory for find_root to succeed
          taskflow_root = File.join(dir, ".ace-taskflow")
          FileUtils.mkdir_p(taskflow_root)

          # Verify no config exists yet
          config_file = File.join(dir, ".ace", "taskflow", "config.yml")
          refute File.exist?(config_file), "config.yml should not exist before initialization"

          config = Ace::Taskflow::Configuration.new
          config.initialize_structure!

          # Verify config was created from gem's example
          assert File.exist?(config_file), "config.yml should be created from example"

          # Verify it has expected content from .ace-defaults/
          content = File.read(config_file)
          assert_match(/taskflow:/, content, "config should have taskflow root key")
          assert_match(/root:/, content, "config should have root setting")
          assert_match(/idea:/, content, "config should have idea section")
        end
      end
    end
  end

  def test_initialize_structure_does_not_overwrite_existing_config
    Dir.mktmpdir do |dir|
      TestFactory.with_stubbed_project_root(dir) do
        Dir.chdir(dir) do
          # Create minimal taskflow directory for find_root to succeed
          taskflow_root = File.join(dir, ".ace-taskflow")
          FileUtils.mkdir_p(taskflow_root)

          # Create existing config (using default root so find_root succeeds)
          config_dir = File.join(dir, ".ace", "taskflow")
          FileUtils.mkdir_p(config_dir)
          config_file = File.join(config_dir, "config.yml")
          original_content = "# Custom config\ntaskflow:\n  root: .ace-taskflow\n  active_strategy: highest\n"
          File.write(config_file, original_content)

          config = Ace::Taskflow::Configuration.new
          config.initialize_structure!

          # Verify original config was preserved
          assert_equal original_content, File.read(config_file),
                       "existing config should not be overwritten"
        end
      end
    end
  end

  def test_path_in_done_dir_matches_exact_directory
    with_test_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!
        config = Ace::Taskflow.configuration

        # Path with done directory as a complete path component should match
        assert config.path_in_done_dir?("/project/.ace-taskflow/_archive/v.0.8.0/t/001/task.md"),
               "Should match when _archive is a complete path component"
        assert config.path_in_done_dir?("_archive/v.0.8.0/t/001/task.md"),
               "Should match at beginning of path"
        assert config.path_in_done_dir?("/project/_archive/task.md"),
               "Should match in middle of path"
      end
    end
  end

  def test_path_in_done_dir_avoids_substring_false_positives
    with_test_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!
        config = Ace::Taskflow.configuration

        # Paths with archive directory name as a substring should NOT match
        refute config.path_in_done_dir?("/project/.ace-taskflow/v.0.9.0/my_archive_tasks/t/099/task.md"),
               "Should NOT match when _archive is a substring of directory name"
        refute config.path_in_done_dir?("/project/_archive_backup/task.md"),
               "Should NOT match _archive_backup (prefix match)"
        refute config.path_in_done_dir?("/project/old_archive/task.md"),
               "Should NOT match old_archive (suffix match)"
        refute config.path_in_done_dir?("/project/not_archived_yet/task.md"),
               "Should NOT match not_archived_yet (contains archive as substring)"
      end
    end
  end

  def test_done_dir_pattern_is_memoized
    with_test_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!
        config = Ace::Taskflow.configuration

        # Call twice and verify we get the same object (memoized)
        pattern1 = config.done_dir_pattern
        pattern2 = config.done_dir_pattern

        assert_same pattern1, pattern2, "Pattern should be memoized"
      end
    end
  end

  def test_done_dir_pattern_resets_on_reload
    with_test_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!
        config = Ace::Taskflow.configuration

        # Get initial pattern
        pattern1 = config.done_dir_pattern

        # Reload config
        config.reload!

        # Get pattern again - should be a new object
        pattern2 = config.done_dir_pattern

        refute_same pattern1, pattern2, "Pattern should be reset after reload"
      end
    end
  end

end
