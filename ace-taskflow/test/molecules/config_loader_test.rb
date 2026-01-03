# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/config_loader"

class ConfigLoaderTest < AceTaskflowTestCase
  # Include ConfigHelpers for with_real_config
  include Ace::TestSupport::ConfigHelpers

  def test_load_default_config
    with_real_test_project do |dir|
      config = Ace::Taskflow::Molecules::ConfigLoader.load

      assert_equal ".ace-taskflow", config["root"]
      # task_dir comes from gem defaults (t/)
      assert_equal "t", config["task_dir"]
      assert_equal "lowest", config["active_strategy"]
      assert_equal true, config["allow_multiple_active"]
    end
  end

  def test_load_project_config
    with_real_test_project do |dir|
      # Create custom config
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        taskflow:
          root: custom-taskflow
          active_strategy: highest
      YAML

      config = Ace::Taskflow::Molecules::ConfigLoader.load

      assert_equal "custom-taskflow", config["root"]
      assert_equal "highest", config["active_strategy"]
      # Other defaults should still be present
      assert_equal "t", config["task_dir"]
    end
  end

  def test_config_cascade_hierarchy
    with_real_test_project do |dir|
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
    with_real_test_project do |_dir|
      root = Ace::Taskflow::Molecules::ConfigLoader.find_root

      # Should be absolute path
      assert root.start_with?("/")
      assert root.end_with?(".ace-taskflow")
    end
  end

  def test_handle_missing_config_gracefully
    with_real_tmpdir do |_dir|
      config = Ace::Taskflow::Molecules::ConfigLoader.load

      # Should return defaults without error
      assert_equal ".ace-taskflow", config["root"]
      assert_equal "t", config["task_dir"]
    end
  end

  def test_yaml_parsing_errors
    with_real_test_project do |dir|
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      # Write invalid YAML - more realistic error (unclosed bracket)
      File.write(File.join(config_dir, "config.yml"), "invalid: yaml: content: [unclosed")

      config = Ace::Taskflow::Molecules::ConfigLoader.load

      # Should fall back to defaults
      assert_equal ".ace-taskflow", config["root"]
    end
  end

  def test_merge_configurations
    with_real_test_project do |dir|
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        taskflow:
          references:
            allow_qualified: false
            allow_cross_release: false
      YAML

      config = Ace::Taskflow::Molecules::ConfigLoader.load

      # Should merge deep structures
      assert_equal false, config["references"]["allow_qualified"]
      assert_equal false, config["references"]["allow_cross_release"]
    end
  end

  def test_load_section
    with_real_test_project do |dir|
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        taskflow:
          idea:
            defaults:
              git_commit: false
      YAML

      idea_section = Ace::Taskflow::Molecules::ConfigLoader.load_section("idea")

      assert_kind_of Hash, idea_section
      assert_equal false, idea_section["defaults"]["git_commit"]
    end
  end

  def test_get_config_by_path
    with_real_test_project do |_dir|
      value = Ace::Taskflow::Molecules::ConfigLoader.get("references.allow_qualified")

      assert_equal true, value
    end
  end

  def test_get_nested_config_value
    with_real_test_project do |dir|
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        taskflow:
          tasks:
            defaults:
              reschedule_strategy: add_end
      YAML

      value = Ace::Taskflow::Molecules::ConfigLoader.get("tasks.defaults.reschedule_strategy")

      assert_equal "add_end", value
    end
  end

  def test_get_nonexistent_path_returns_nil
    with_real_test_project do |_dir|
      value = Ace::Taskflow::Molecules::ConfigLoader.get("nonexistent.path.here")

      assert_nil value
    end
  end

  def test_config_with_defaults_section
    with_real_test_project do |dir|
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        taskflow:
          defaults:
            idea_location: backlog
            task_location: backlog
      YAML

      config = Ace::Taskflow::Molecules::ConfigLoader.load

      assert_equal "backlog", config["defaults"]["idea_location"]
      assert_equal "backlog", config["defaults"]["task_location"]
    end
  end

  def test_find_root_with_absolute_path
    skip "Test needs fix - will be reviewed in Phase 9"
    with_real_test_project do |dir|
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      custom_root = "/tmp/custom-taskflow"
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        taskflow:
          root: #{custom_root}
      YAML

      root = Ace::Taskflow::Molecules::ConfigLoader.find_root

      assert_equal custom_root, root
    end
  end

  def test_find_root_with_relative_path
    skip "Test needs fix - will be reviewed in Phase 9"
    with_real_test_project do |dir|
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        taskflow:
          root: relative/path
      YAML

      root = Ace::Taskflow::Molecules::ConfigLoader.find_root

      # Check it's an absolute path ending with the relative portion
      assert root.end_with?("relative/path")
      assert root.start_with?("/")
    end
  end

  def test_default_terminal_statuses
    with_real_tmpdir do |_dir|
      config = Ace::Taskflow::Molecules::ConfigLoader.load

      assert_equal %w[done cancelled suspended superseded], config["terminal_statuses"]
    end
  end

  def test_custom_terminal_statuses
    with_real_test_project do |dir|
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        taskflow:
          terminal_statuses:
            - done
            - cancelled
            - archived
      YAML

      config = Ace::Taskflow::Molecules::ConfigLoader.load

      assert_equal %w[done cancelled archived], config["terminal_statuses"]
    end
  end

  # ADR-022: Gem default loading tests

  def test_load_gem_defaults_returns_hash
    with_real_config do
      Ace::Taskflow::Molecules::ConfigLoader.reset_gem_defaults!
      defaults = Ace::Taskflow::Molecules::ConfigLoader.load_gem_defaults

      assert_kind_of Hash, defaults
      assert_equal ".ace-taskflow", defaults["root"]
      assert_equal "t", defaults["task_dir"]
    end
  end

  def test_gem_defaults_have_all_expected_keys
    with_real_config do
      Ace::Taskflow::Molecules::ConfigLoader.reset_gem_defaults!
      defaults = Ace::Taskflow::Molecules::ConfigLoader.load_gem_defaults

      # Core configuration
      assert_equal "lowest", defaults["active_strategy"]
      assert_equal true, defaults["allow_multiple_active"]
      assert_includes defaults["terminal_statuses"], "done"
      assert_includes defaults["terminal_statuses"], "cancelled"

      # References section
      assert_kind_of Hash, defaults["references"]
      assert_equal true, defaults["references"]["allow_qualified"]
      assert_equal true, defaults["references"]["allow_cross_release"]

      # Defaults section
      assert_kind_of Hash, defaults["defaults"]
      assert_equal "active", defaults["defaults"]["idea_location"]
      assert_equal "active", defaults["defaults"]["task_location"]

      # Tasks section
      assert_kind_of Hash, defaults["tasks"]
      assert_equal "add_next", defaults.dig("tasks", "defaults", "reschedule_strategy")
    end
  end

  def test_gem_defaults_are_cached
    with_real_config do
      Ace::Taskflow::Molecules::ConfigLoader.reset_gem_defaults!
      first_load = Ace::Taskflow::Molecules::ConfigLoader.load_gem_defaults
      second_load = Ace::Taskflow::Molecules::ConfigLoader.load_gem_defaults

      assert_same first_load, second_load
    end
  end

  def test_reset_gem_defaults_clears_cache
    with_real_config do
      Ace::Taskflow::Molecules::ConfigLoader.reset_gem_defaults!
      first_load = Ace::Taskflow::Molecules::ConfigLoader.load_gem_defaults
      Ace::Taskflow::Molecules::ConfigLoader.reset_gem_defaults!
      second_load = Ace::Taskflow::Molecules::ConfigLoader.load_gem_defaults

      # After reset, should be a different object (re-loaded from file)
      refute_same first_load, second_load
    end
  end

  def test_user_config_overrides_gem_defaults
    with_real_test_project do |dir|
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        taskflow:
          active_strategy: "highest"
          references:
            allow_cross_release: false
      YAML

      config = Ace::Taskflow::Molecules::ConfigLoader.load

      # Overridden values
      assert_equal "highest", config["active_strategy"]
      assert_equal false, config["references"]["allow_cross_release"]

      # Non-overridden values from gem defaults
      assert_equal true, config["allow_multiple_active"]
      assert_equal true, config["references"]["allow_qualified"]
      assert_equal "active", config["defaults"]["idea_location"]
    end
  end

  def test_status_activity_section_is_extracted
    with_real_test_project do |dir|
      config_dir = File.join(dir, ".ace", "taskflow")
      FileUtils.mkdir_p(config_dir)
      File.write(File.join(config_dir, "config.yml"), <<~YAML)
        taskflow:
          status:
            activity:
              recently_done_limit: 5
              up_next_limit: 10
              include_drafts: true
      YAML

      config = Ace::Taskflow::Molecules::ConfigLoader.load

      # Verify status section is properly extracted
      assert_kind_of Hash, config["status"]
      assert_equal 5, config["status"]["activity"]["recently_done_limit"]
      assert_equal 10, config["status"]["activity"]["up_next_limit"]
      assert_equal true, config["status"]["activity"]["include_drafts"]
    end
  end

  def test_gem_defaults_have_status_section
    with_real_config do
      Ace::Taskflow::Molecules::ConfigLoader.reset_gem_defaults!
      defaults = Ace::Taskflow::Molecules::ConfigLoader.load_gem_defaults

      # Verify status activity defaults are present
      assert_kind_of Hash, defaults["status"]
      assert_kind_of Hash, defaults["status"]["activity"]
      assert_equal 3, defaults["status"]["activity"]["recently_done_limit"]
      assert_equal 3, defaults["status"]["activity"]["up_next_limit"]
      assert_equal false, defaults["status"]["activity"]["include_drafts"]
    end
  end

end
