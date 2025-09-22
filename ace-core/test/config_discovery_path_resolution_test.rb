# frozen_string_literal: true

require "test_helper"
require "ace/core/config_discovery"
require "tmpdir"
require "fileutils"
require "yaml"

module Ace
  module Core
    class ConfigDiscoveryPathResolutionTest < Minitest::Test
      def setup
        @test_dir = Dir.mktmpdir("ace-test-")
        @original_pwd = Dir.pwd
      end

      def teardown
        Dir.chdir(@original_pwd)
        FileUtils.rm_rf(@test_dir) if @test_dir && Dir.exist?(@test_dir)
      end

      def test_resolves_paths_in_ace_directory
        # Create project structure
        project_dir = File.join(@test_dir, "project")
        ace_dir = File.join(project_dir, ".ace")
        FileUtils.mkdir_p(ace_dir)

        # Create directories that paths will reference
        FileUtils.mkdir_p(File.join(project_dir, "subdir1"))
        FileUtils.mkdir_p(File.join(project_dir, "subdir2"))

        # Create config with relative paths
        config = {
          "test_suite" => {
            "packages" => [
              { "name" => "pkg1", "path" => "./subdir1" },
              { "name" => "pkg2", "path" => "./subdir2" }
            ],
            "some_file" => "./config.yml"
          }
        }

        config_file = File.join(ace_dir, "test.yml")
        File.write(config_file, YAML.dump(config))

        Dir.chdir(project_dir)
        discovery = ConfigDiscovery.new
        loaded = discovery.load_config("test.yml")

        assert_equal File.join(project_dir, "subdir1"), loaded["test_suite"]["packages"][0]["path"]
        assert_equal File.join(project_dir, "subdir2"), loaded["test_suite"]["packages"][1]["path"]
        assert_equal File.join(project_dir, "config.yml"), loaded["test_suite"]["some_file"]
      end

      def test_resolves_paths_in_nested_ace_directory
        # Create project structure with nested .ace
        project_dir = File.join(@test_dir, "project")
        ace_dir = File.join(project_dir, ".ace", "configs")
        FileUtils.mkdir_p(ace_dir)

        # Create directories that paths will reference
        FileUtils.mkdir_p(File.join(project_dir, "lib"))

        # Create config with relative paths
        config = {
          "settings" => {
            "source_dir" => "./lib",
            "output" => "../output"
          }
        }

        config_file = File.join(ace_dir, "settings.yml")
        File.write(config_file, YAML.dump(config))

        Dir.chdir(project_dir)

        # Mock the find_config_file to return our nested config
        discovery = ConfigDiscovery.new
        discovery.instance_variable_get(:@finder).stub :find_file, config_file do
          loaded = discovery.load_config("settings.yml")

          # Paths should be relative to project root (parent of .ace)
          assert_equal File.join(project_dir, "lib"), loaded["settings"]["source_dir"]
          assert_equal File.expand_path(File.join(project_dir, "..", "output")), loaded["settings"]["output"]
        end
      end

      def test_preserves_non_relative_paths
        # Create project structure
        project_dir = File.join(@test_dir, "project")
        ace_dir = File.join(project_dir, ".ace")
        FileUtils.mkdir_p(ace_dir)

        # Create config with various path types
        config = {
          "paths" => {
            "relative" => "./relative",
            "absolute" => "/usr/local/bin",
            "home" => "~/Documents",
            "plain" => "some_file.txt"
          }
        }

        config_file = File.join(ace_dir, "paths.yml")
        File.write(config_file, YAML.dump(config))

        Dir.chdir(project_dir)
        discovery = ConfigDiscovery.new
        loaded = discovery.load_config("paths.yml")

        # Only relative paths starting with ./ should be resolved
        assert_equal File.join(project_dir, "relative"), loaded["paths"]["relative"]
        assert_equal "/usr/local/bin", loaded["paths"]["absolute"]
        assert_equal "~/Documents", loaded["paths"]["home"]
        assert_equal "some_file.txt", loaded["paths"]["plain"]
      end

      def test_resolves_paths_in_arrays
        # Create project structure
        project_dir = File.join(@test_dir, "project")
        ace_dir = File.join(project_dir, ".ace")
        FileUtils.mkdir_p(ace_dir)

        # Create config with paths in arrays
        config = {
          "include_dirs" => [
            "./include1",
            "./include2",
            "/absolute/path"
          ]
        }

        config_file = File.join(ace_dir, "build.yml")
        File.write(config_file, YAML.dump(config))

        Dir.chdir(project_dir)
        discovery = ConfigDiscovery.new
        loaded = discovery.load_config("build.yml")

        assert_equal File.join(project_dir, "include1"), loaded["include_dirs"][0]
        assert_equal File.join(project_dir, "include2"), loaded["include_dirs"][1]
        assert_equal "/absolute/path", loaded["include_dirs"][2]
      end

      def test_disable_path_resolution
        # Create project structure
        project_dir = File.join(@test_dir, "project")
        ace_dir = File.join(project_dir, ".ace")
        FileUtils.mkdir_p(ace_dir)

        # Create config with relative paths
        config = {
          "paths" => {
            "dir" => "./some_dir"
          }
        }

        config_file = File.join(ace_dir, "test.yml")
        File.write(config_file, YAML.dump(config))

        Dir.chdir(project_dir)
        discovery = ConfigDiscovery.new

        # With path resolution disabled, paths should remain as-is
        loaded = discovery.load_config("test.yml", resolve_paths: false)
        assert_equal "./some_dir", loaded["paths"]["dir"]
      end
    end
  end
end