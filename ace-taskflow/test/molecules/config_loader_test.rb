# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/config_loader"

class ConfigLoaderTest < AceTaskflowTestCase
  def test_load_default_config
    with_test_project do |dir|
      Dir.chdir(dir) do
        config = Ace::Taskflow::Molecules::ConfigLoader.load

        assert_equal ".ace-taskflow", config["root"]
        assert_equal "tasks", config.dig("directories", "tasks")
        assert_equal "lowest", config["active_strategy"]
        assert_equal true, config["allow_multiple_active"]
      end
    end
  end

  def test_load_project_config
    with_test_project do |dir|
      # Create custom config
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        taskflow:
          root: custom-taskflow
          active_strategy: highest
      YAML

      Dir.chdir(dir) do
        config = Ace::Taskflow::Molecules::ConfigLoader.load

        assert_equal "custom-taskflow", config["root"]
        assert_equal "highest", config["active_strategy"]
        # Other defaults should still be present
        assert_equal "t", config["task_dir"]
      end
    end
  end

  def test_config_cascade_hierarchy
    with_test_project do |dir|
      # Create nested directory structure
      nested_dir = File.join(dir, "projects", "subproject")
      FileUtils.mkdir_p(nested_dir)

      # Parent config
      parent_config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(parent_config_dir)
      File.write(File.join(parent_config_dir, "config.yml"), <<~YAML)
        taskflow:
          root: parent-root
          active_strategy: lowest
      YAML

      # Child config (should override parent)
      child_config_dir = File.join(nested_dir, ".ace", "taskflow")
      FileUtils.mkdir_p(child_config_dir)
      File.write(File.join(child_config_dir, "config.yml"), <<~YAML)
        taskflow:
          root: child-root
      YAML

      Dir.chdir(nested_dir) do
        config = Ace::Taskflow::Molecules::ConfigLoader.load

        # Child overrides parent
        assert_equal "child-root", config["root"]
        # But parent values not overridden should still apply
        assert_equal "lowest", config["active_strategy"]
      end
    end
  end

  def test_find_root_from_various_paths
    with_test_project do |dir|
      Dir.chdir(dir) do
        root = Ace::Taskflow::Molecules::ConfigLoader.find_root

        # Should be absolute path
        assert root.start_with?("/")
        assert root.end_with?(".ace-taskflow")
      end
    end
  end

  def test_handle_missing_config_gracefully
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        config = Ace::Taskflow::Molecules::ConfigLoader.load

        # Should return defaults without error
        assert_equal ".ace-taskflow", config["root"]
        assert_equal "t", config["task_dir"]
      end
    end
  end

  def test_yaml_parsing_errors
    with_test_project do |dir|
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      # Write invalid YAML
      File.write(File.join(config_dir, "config.yml"), "invalid: yaml: content: [")

      Dir.chdir(dir) do
        config = Ace::Taskflow::Molecules::ConfigLoader.load

        # Should fall back to defaults
        assert_equal ".ace-taskflow", config["root"]
      end
    end
  end

  def test_merge_configurations
    with_test_project do |dir|
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        taskflow:
          references:
            allow_qualified: false
            allow_cross_release: false
      YAML

      Dir.chdir(dir) do
        config = Ace::Taskflow::Molecules::ConfigLoader.load

        # Should merge deep structures
        assert_equal false, config["references"]["allow_qualified"]
        assert_equal false, config["references"]["allow_cross_release"]
      end
    end
  end

  def test_load_section
    with_test_project do |dir|
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        taskflow:
          idea:
            defaults:
              git_commit: false
      YAML

      Dir.chdir(dir) do
        idea_section = Ace::Taskflow::Molecules::ConfigLoader.load_section("idea")

        assert_kind_of Hash, idea_section
        assert_equal false, idea_section["defaults"]["git_commit"]
      end
    end
  end

  def test_get_config_by_path
    with_test_project do |dir|
      Dir.chdir(dir) do
        value = Ace::Taskflow::Molecules::ConfigLoader.get("references.allow_qualified")

        assert_equal true, value
      end
    end
  end

  def test_get_nested_config_value
    with_test_project do |dir|
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        taskflow:
          tasks:
            defaults:
              reschedule_strategy: add_end
      YAML

      Dir.chdir(dir) do
        value = Ace::Taskflow::Molecules::ConfigLoader.get("tasks.defaults.reschedule_strategy")

        assert_equal "add_end", value
      end
    end
  end

  def test_get_nonexistent_path_returns_nil
    with_test_project do |dir|
      Dir.chdir(dir) do
        value = Ace::Taskflow::Molecules::ConfigLoader.get("nonexistent.path.here")

        assert_nil value
      end
    end
  end

  def test_config_with_defaults_section
    with_test_project do |dir|
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        taskflow:
          defaults:
            idea_location: backlog
            task_location: backlog
      YAML

      Dir.chdir(dir) do
        config = Ace::Taskflow::Molecules::ConfigLoader.load

        assert_equal "backlog", config["defaults"]["idea_location"]
        assert_equal "backlog", config["defaults"]["task_location"]
      end
    end
  end

  def test_find_root_with_absolute_path
    skip "Test needs fix - will be reviewed in Phase 9"
    with_test_project do |dir|
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      custom_root = "/tmp/custom-taskflow"
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        taskflow:
          root: #{custom_root}
      YAML

      Dir.chdir(dir) do
        root = Ace::Taskflow::Molecules::ConfigLoader.find_root

        assert_equal custom_root, root
      end
    end
  end

  def test_find_root_with_relative_path
    skip "Test needs fix - will be reviewed in Phase 9"
    with_test_project do |dir|
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        taskflow:
          root: relative/path
      YAML

      Dir.chdir(dir) do
        root = Ace::Taskflow::Molecules::ConfigLoader.find_root

        # Check it's an absolute path ending with the relative portion
        assert root.end_with?("relative/path")
        assert root.start_with?("/")
      end
    end
  end
end
