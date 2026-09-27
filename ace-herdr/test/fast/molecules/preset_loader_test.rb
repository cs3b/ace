# frozen_string_literal: true

require "test_helper"

module Ace
  module Herdr
    module Molecules
      class PresetLoaderTest < Minitest::Test
        def setup
          @gem_root = File.join(Dir.mktmpdir("k84_gem"), "gem")
          @project = Dir.mktmpdir("k84_project")
          write_preset(@gem_root, ".ace-defaults/herdr/workspaces/dev.yml", "label: gem-dev")
          write_preset(@gem_root, ".ace-defaults/herdr/tabs/agent.yml", "label: gem-agent")
          write_preset(@project, ".ace/herdr/workspaces/dev.yml", "label: project-dev")
          write_preset(@project, ".ace/herdr/workspaces/custom.yml", "label: project-custom")
          @loader = PresetLoader.new(gem_root: @gem_root, start_path: @project)
        end

        def teardown
          FileUtils.rm_rf(@gem_root)
          FileUtils.rm_rf(@project)
        end

        def write_preset(root, relative, content)
          path = File.join(root, relative)
          FileUtils.mkdir_p(File.dirname(path))
          File.write(path, content)
        end

        def test_project_preset_wins_over_gem_default
          assert_equal({"label" => "project-dev"}, @loader.load("workspaces", "dev"))
        end

        def test_gem_default_serves_when_project_has_no_override
          assert_equal({"label" => "gem-agent"}, @loader.load("tabs", "agent"))
        end

        def test_project_only_preset_is_visible
          assert_equal({"label" => "project-custom"}, @loader.load("workspaces", "custom"))
        end

        def test_unknown_preset_returns_nil
          assert_nil @loader.load("workspaces", "nope")
        end

        def test_list_merges_names_across_the_cascade
          assert_equal %w[custom dev], @loader.list("workspaces")
          assert_equal %w[agent], @loader.list("tabs")
        end

        def test_list_all_skips_empty_types
          assert_equal({"workspaces" => %w[custom dev], "tabs" => %w[agent]}, @loader.list_all)
        end

        def test_lookup_proc_loads_by_name
          assert_equal({"label" => "gem-agent"}, @loader.to_lookup("tabs").call("agent"))
        end
      end
    end
  end
end
