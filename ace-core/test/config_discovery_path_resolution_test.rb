# frozen_string_literal: true

require "test_helper"
require "ace/core/config_discovery"
require "tmpdir"
require "fileutils"
require "yaml"

module Ace
  module Core
    class ConfigDiscoveryPathResolutionTest < AceTestCase
      include Ace::TestSupport::SubprocessRunner
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
        # Add project root marker so ProjectRootFinder works correctly
        FileUtils.mkdir_p(File.join(project_dir, ".git"))

        # Create directories that paths will reference
        FileUtils.mkdir_p(File.join(project_dir, "lib"))
        FileUtils.mkdir_p(File.join(project_dir, "src"))
        FileUtils.mkdir_p(File.join(project_dir, "config"))
        FileUtils.touch(File.join(project_dir, "config", "settings.yml"))

        # Create config with project-relative paths (no ./ prefix)
        # Using 'lib' and 'src' which are recognized as project paths
        config = {
          "test_suite" => {
            "packages" => [
              { "name" => "pkg1", "path" => "lib" },
              { "name" => "pkg2", "path" => "src" }
            ],
            "some_file" => "config/settings.yml"
          }
        }

        config_file = File.join(ace_dir, "test.yml")
        File.write(config_file, YAML.dump(config))

        code = <<~RUBY
          require 'ace/core/config_discovery'
          Dir.chdir("#{project_dir}")
          discovery = Ace::Core::ConfigDiscovery.new
          loaded = discovery.load_config("test.yml")

          puts loaded["test_suite"]["packages"][0]["path"]
          puts loaded["test_suite"]["packages"][1]["path"]
          puts loaded["test_suite"]["some_file"]
        RUBY

        output, status = run_in_clean_env(code: code, requires: [])
        assert status.success?, "Subprocess failed: #{output}"

        lines = output.strip.split("\n")
        # Plain paths (without ./) should resolve relative to project root
        # Use realpath to handle /private/var symlink on macOS
        assert_equal File.realpath(File.join(project_dir, "lib")), File.realpath(lines[0])
        assert_equal File.realpath(File.join(project_dir, "src")), File.realpath(lines[1])
        # config/settings.yml has 'config' which is recognized as project path
        assert_equal File.realpath(File.join(project_dir, "config/settings.yml")), File.realpath(lines[2])
      end

      def test_resolves_paths_in_nested_ace_directory
        # Create project structure with nested .ace
        project_dir = File.join(@test_dir, "project")
        ace_dir = File.join(project_dir, ".ace", "configs")
        FileUtils.mkdir_p(ace_dir)
        # Add project root marker
        FileUtils.mkdir_p(File.join(project_dir, ".git"))

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

        # For this test, we need to run it in the main process with stubbing
        # since stubbing doesn't work well in subprocess
        Dir.chdir(project_dir)

        # Temporarily unset PROJECT_ROOT_PATH
        original_env = ENV["PROJECT_ROOT_PATH"]
        ENV.delete("PROJECT_ROOT_PATH")

        begin
          discovery = ConfigDiscovery.new
          # Mock the find_config_file to return our nested config
          discovery.instance_variable_get(:@finder).stub :find_file, config_file do
            loaded = discovery.load_config("settings.yml")

            # Paths should be relative to project root (parent of .ace)
            assert_equal File.join(project_dir, "lib"), loaded["settings"]["source_dir"]
            assert_equal File.expand_path(File.join(project_dir, "..", "output")), loaded["settings"]["output"]
          end
        ensure
          ENV["PROJECT_ROOT_PATH"] = original_env if original_env
        end
      end

      def test_preserves_non_relative_paths
        # Create project structure
        project_dir = File.join(@test_dir, "project")
        ace_dir = File.join(project_dir, ".ace")
        FileUtils.mkdir_p(ace_dir)
        # Add project root marker
        FileUtils.mkdir_p(File.join(project_dir, ".git"))
        # Create the relative directory so File.realpath works
        FileUtils.mkdir_p(File.join(ace_dir, "relative"))

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

        code = <<~RUBY
          require 'ace/core/config_discovery'
          Dir.chdir("#{project_dir}")
          discovery = Ace::Core::ConfigDiscovery.new
          loaded = discovery.load_config("paths.yml")

          # Output paths for validation
          puts loaded["paths"]["relative"]
          puts loaded["paths"]["absolute"]
          puts loaded["paths"]["home"]
          puts loaded["paths"]["plain"]
        RUBY

        output, status = run_in_clean_env(code: code, requires: [])
        assert status.success?, "Subprocess failed: #{output}"

        lines = output.strip.split("\n")
        # ./relative should resolve relative to .ace/ directory (where config file is)
        # Use realpath to handle /private/var symlink on macOS
        assert_equal File.realpath(File.join(project_dir, ".ace", "relative")), File.realpath(lines[0])
        assert_equal "/usr/local/bin", lines[1]
        assert_equal "~/Documents", lines[2]
        assert_equal "some_file.txt", lines[3]
      end

      def test_resolves_paths_in_arrays
        # Create project structure
        project_dir = File.join(@test_dir, "project")
        ace_dir = File.join(project_dir, ".ace")
        FileUtils.mkdir_p(ace_dir)
        # Add project root marker
        FileUtils.mkdir_p(File.join(project_dir, ".git"))
        # Create directories so File.realpath works
        FileUtils.mkdir_p(File.join(project_dir, "lib"))
        FileUtils.mkdir_p(File.join(project_dir, "test"))

        # Create config with paths in arrays (using plain paths for project-relative)
        config = {
          "include_dirs" => [
            "lib",           # Recognized project path - resolves to project root
            "test",          # Recognized project path - resolves to project root
            "/absolute/path" # Absolute path - unchanged
          ]
        }

        config_file = File.join(ace_dir, "build.yml")
        File.write(config_file, YAML.dump(config))

        code = <<~RUBY
          require 'ace/core/config_discovery'
          Dir.chdir("#{project_dir}")
          discovery = Ace::Core::ConfigDiscovery.new
          loaded = discovery.load_config("build.yml")

          loaded["include_dirs"].each { |dir| puts dir }
        RUBY

        output, status = run_in_clean_env(code: code, requires: [])
        assert status.success?, "Subprocess failed: #{output}"

        lines = output.strip.split("\n")
        # Plain paths should resolve relative to project root
        # Use realpath to handle /private/var symlink on macOS
        assert_equal File.realpath(File.join(project_dir, "lib")), File.realpath(lines[0])
        assert_equal File.realpath(File.join(project_dir, "test")), File.realpath(lines[1])
        assert_equal "/absolute/path", lines[2]
      end

      def test_disable_path_resolution
        # Create project structure
        project_dir = File.join(@test_dir, "project")
        ace_dir = File.join(project_dir, ".ace")
        FileUtils.mkdir_p(ace_dir)
        # Add project root marker
        FileUtils.mkdir_p(File.join(project_dir, ".git"))

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