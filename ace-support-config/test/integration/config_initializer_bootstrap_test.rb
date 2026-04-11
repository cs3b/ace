# frozen_string_literal: true

require "test_helper"
require "ace/support/config/organisms/config_initializer"

module Ace
  module Support
    module Config
      class ConfigInitializerBootstrapTest < TestCase
        def test_init_copies_generic_bootstrap_files
          with_temp_config do
            initializer = Organisms::ConfigInitializer.new(force: true)
            initializer.send(:init_gem, "ace-bundle")
            initializer.send(:init_gem, "ace-support-core")

            assert File.exist?(".ace/bundle/presets/project.md")
            assert File.exist?(".ace/bundle/presets/project-base.md")
            assert File.exist?(".ace/README.md")

            project_preset = File.read(".ace/bundle/presets/project.md")
            readme = File.read(".ace/README.md")

            refute_includes project_preset, "ace-task"
            refute_includes project_preset, "Coding Agent Workflow Toolkit (Meta)"
            assert_includes readme, "ace-task"
          end
        end
      end
    end
  end
end
