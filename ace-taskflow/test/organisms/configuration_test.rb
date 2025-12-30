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

end
