# frozen_string_literal: true

require_relative "../test_helper"
require "fileutils"
require "ace/core/organisms/config_initializer"

module Ace
  module Core
    class ConfigInitializerBootstrapTest < AceTestCase
      def test_init_copies_generic_bootstrap_files
        with_temp_dir do
          initializer = ConfigInitializer.new(force: true)
          initializer.send(:init_gem, "ace-bundle")
          initializer.send(:init_gem, "ace-support-core")

          assert File.exist?(".ace/bundle/presets/project.md")
          assert File.exist?(".ace/bundle/presets/project-base.md")
          assert File.exist?(".ace/README.md")

          project_preset = File.read(".ace/bundle/presets/project.md")
          readme = File.read(".ace/README.md")

          refute_includes project_preset, "ace-taskflow"
          refute_includes project_preset, "Coding Agent Workflow Toolkit (Meta)"
          assert_includes readme, "ace-task"
        end
      end
    end
  end
end
