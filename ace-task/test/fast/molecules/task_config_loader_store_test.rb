# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class TaskConfigLoaderStoreTest < AceTaskTestCase
  def test_configured_store_resolves_relative_to_project_root
    config = {"task" => {"stores" => {"_overseer" => ".ace-local/overseer/tasks"}}}

    root = Ace::Task::Molecules::TaskConfigLoader.store_root(config, "_overseer", project_root: "/tmp/project")

    assert_equal "/tmp/project/.ace-local/overseer/tasks", root
  end

  def test_absolute_store_path_is_used_as_is
    config = {"task" => {"stores" => {"_private" => "/var/lib/ace/tasks"}}}

    root = Ace::Task::Molecules::TaskConfigLoader.store_root(config, "_private", project_root: "/tmp/project")

    assert_equal "/var/lib/ace/tasks", root
  end

  def test_unconfigured_name_is_not_a_store
    config = {"task" => {"stores" => {"_overseer" => ".ace-local/overseer/tasks"}}}

    assert_nil Ace::Task::Molecules::TaskConfigLoader.store_root(config, "maybe", project_root: "/tmp/project")
    assert_nil Ace::Task::Molecules::TaskConfigLoader.store_root({}, "_overseer", project_root: "/tmp/project")
  end

  def test_default_config_exposes_untracked_overseer_store
    config = Ace::Task::Molecules::TaskConfigLoader.load

    assert_includes Ace::Task::Molecules::TaskConfigLoader.store_names(config), "_overseer"
    assert_equal File.join("/tmp/project", ".ace-local", "overseer", "tasks"),
      Ace::Task::Molecules::TaskConfigLoader.store_root(config, "_overseer", project_root: "/tmp/project")
  end

  def test_project_config_adds_stores_and_keeps_default_overseer
    Dir.mktmpdir("task-store-config") do |dir|
      FileUtils.mkdir_p(File.join(dir, ".git"))
      FileUtils.mkdir_p(File.join(dir, ".ace", "task"))
      File.write(File.join(dir, ".ace", "task", "config.yml"), <<~YAML)
        task:
          stores:
            _custom: .ace-local/custom/tasks
      YAML

      Dir.chdir(dir) do
        config = Ace::Task::Molecules::TaskConfigLoader.load
        project_root = File.realpath(dir)

        assert_equal File.join(project_root, ".ace-local", "custom", "tasks"),
          Ace::Task::Molecules::TaskConfigLoader.store_root(config, "_custom")
        assert_equal File.join(project_root, ".ace-local", "overseer", "tasks"),
          Ace::Task::Molecules::TaskConfigLoader.store_root(config, "_overseer")
      end
    end
  end
end
