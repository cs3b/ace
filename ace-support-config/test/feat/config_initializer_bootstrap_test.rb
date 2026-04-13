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
            assert File.exist?(".gitignore")
            assert File.exist?("AGENTS.md")
            assert File.exist?("CLAUDE.md")

            project_preset = File.read(".ace/bundle/presets/project.md")
            readme = File.read(".ace/README.md")
            gitignore = File.read(".gitignore")
            agents = File.read("AGENTS.md")
            claude = File.read("CLAUDE.md")

            refute_includes project_preset, "ace-task"
            refute_includes project_preset, "Coding Agent Workflow Toolkit (Meta)"
            assert_includes readme, "ace-task"
            assert_includes gitignore, ".ace-local/"
            assert_includes agents, "Run `ace-*` commands directly."
            assert_includes claude, "Do not use pipes, redirects, or shell post-processors"
          end
        end

        def test_init_appends_gitignore_but_preserves_existing_agent_guidance_without_force
          with_temp_config(
            ".gitignore" => "node_modules/\n",
            "AGENTS.md" => "# Custom AGENTS\n",
            "CLAUDE.md" => "# Custom CLAUDE\n"
          ) do
            initializer = Organisms::ConfigInitializer.new
            initializer.send(:init_gem, "ace-support-core")

            gitignore = File.read(".gitignore")

            assert_includes gitignore, "node_modules/"
            assert_equal 1, gitignore.scan(".ace-local/").length
            assert_equal "# Custom AGENTS\n", File.read("AGENTS.md")
            assert_equal "# Custom CLAUDE\n", File.read("CLAUDE.md")
          end
        end

        def test_init_force_refreshes_generated_agent_guidance
          with_temp_config(
            "AGENTS.md" => "# Old AGENTS\n",
            "CLAUDE.md" => "# Old CLAUDE\n"
          ) do
            initializer = Organisms::ConfigInitializer.new(force: true)
            initializer.send(:init_gem, "ace-support-core")

            assert_includes File.read("AGENTS.md"), "Run `ace-*` commands directly."
            assert_includes File.read("CLAUDE.md"), "Do not use pipes, redirects, or shell post-processors"
          end
        end

        def test_init_force_preserves_existing_gitignore_rules
          with_temp_config(
            ".gitignore" => "node_modules/\n",
            ".git" => {}
          ) do
            initializer = Organisms::ConfigInitializer.new(force: true)
            initializer.send(:init_gem, "ace-support-core")

            gitignore = File.read(".gitignore")

            assert_includes gitignore, "node_modules/"
            assert_equal 1, gitignore.scan(".ace-local/").length
          end
        end

        def test_init_from_subdirectory_targets_repo_root_for_project_root_files
          with_temp_config(
            ".git" => {},
            "subdir" => {}
          ) do |tmpdir|
            Dir.chdir(File.join(tmpdir, "subdir")) do
              initializer = Organisms::ConfigInitializer.new(force: true)
              initializer.send(:init_gem, "ace-support-core")
            end

            assert File.exist?(File.join(tmpdir, "AGENTS.md"))
            assert File.exist?(File.join(tmpdir, "CLAUDE.md"))
            assert File.exist?(File.join(tmpdir, ".gitignore"))

            refute File.exist?(File.join(tmpdir, "subdir", "AGENTS.md"))
            refute File.exist?(File.join(tmpdir, "subdir", "CLAUDE.md"))
            refute File.exist?(File.join(tmpdir, "subdir", ".gitignore"))
          end
        end
      end
    end
  end
end
