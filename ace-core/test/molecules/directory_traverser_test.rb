# frozen_string_literal: true

require "test_helper"
require "ace/core/molecules/directory_traverser"
require "ace/core/molecules/project_root_finder"
require "tmpdir"
require "fileutils"

module Ace
  module Core
    module Molecules
      class DirectoryTraverserTest < AceTestCase
        include Ace::TestSupport::SubprocessRunner
        def setup
          @original_pwd = Dir.pwd
          @test_dir = Dir.mktmpdir("ace-test-")
          ProjectRootFinder.clear_cache!
        end

        def teardown
          Dir.chdir(@original_pwd)
          FileUtils.rm_rf(@test_dir) if @test_dir && Dir.exist?(@test_dir)
        end

        def test_traverse_finds_config_dirs_up_to_project_root
          # Create project structure with .ace at multiple levels
          project_dir = File.join(@test_dir, "project")
          middle_dir = File.join(project_dir, "lib")
          nested_dir = File.join(middle_dir, "nested")

          FileUtils.mkdir_p(nested_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))  # Project root marker
          FileUtils.mkdir_p(File.join(project_dir, ".ace"))  # Config at project root
          FileUtils.mkdir_p(File.join(middle_dir, ".ace"))   # Config at middle level
          FileUtils.mkdir_p(File.join(nested_dir, ".ace"))   # Config at nested level

          Dir.chdir(nested_dir)
          traverser = DirectoryTraverser.new

          directories = traverser.traverse
          assert_equal 3, directories.length
          assert directories.all? { |d| Dir.exist?(File.join(d, ".ace")) }
        end

        def test_find_config_directories_returns_full_paths
          project_dir = File.join(@test_dir, "project")
          nested_dir = File.join(project_dir, "nested")

          FileUtils.mkdir_p(nested_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))
          FileUtils.mkdir_p(File.join(project_dir, ".ace"))
          FileUtils.mkdir_p(File.join(nested_dir, ".ace"))

          Dir.chdir(nested_dir)
          traverser = DirectoryTraverser.new

          config_dirs = traverser.find_config_directories
          assert config_dirs.all? { |d| d.end_with?("/.ace") }
          assert config_dirs.all? { |d| Dir.exist?(d) }
        end

        def test_traverse_without_project_root
          # Create structure without project markers
          dir1 = File.join(@test_dir, "dir1")
          dir2 = File.join(dir1, "dir2")
          dir3 = File.join(dir2, "dir3")

          FileUtils.mkdir_p(dir3)
          FileUtils.mkdir_p(File.join(dir1, ".ace"))
          FileUtils.mkdir_p(File.join(dir2, ".ace"))
          FileUtils.mkdir_p(File.join(dir3, ".ace"))

          Dir.chdir(dir3)
          traverser = DirectoryTraverser.new

          # Should traverse all the way up since no project root
          directories = traverser.traverse
          assert_equal 3, directories.length
        end

        def test_directory_hierarchy
          project_dir = File.join(@test_dir, "project")
          middle_dir = File.join(project_dir, "lib")
          nested_dir = File.join(middle_dir, "nested")

          FileUtils.mkdir_p(nested_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))

          code = <<~RUBY
            require 'ace/core/molecules/directory_traverser'
            require 'pathname'
            Dir.chdir("#{nested_dir}")
            traverser = Ace::Core::Molecules::DirectoryTraverser.new

            hierarchy = traverser.directory_hierarchy
            puts hierarchy.length
            hierarchy.each { |dir| puts Pathname.new(dir).realpath }
          RUBY

          output, status = run_in_clean_env(code: code, requires: [])
          assert status.success?, "Subprocess failed: #{output}"

          lines = output.strip.split("\n")
          assert_equal "3", lines[0]
          assert_equal File.realpath(nested_dir), File.realpath(lines[1])
          assert_equal File.realpath(middle_dir), File.realpath(lines[2])
          assert_equal File.realpath(project_dir), File.realpath(lines[3])
        end

        def test_build_cascade_priorities
          project_dir = File.join(@test_dir, "project")
          nested_dir = File.join(project_dir, "nested")

          FileUtils.mkdir_p(nested_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))
          FileUtils.mkdir_p(File.join(project_dir, ".ace"))
          FileUtils.mkdir_p(File.join(nested_dir, ".ace"))

          # Create home .ace for testing
          home_ace = File.expand_path("~/.ace")
          home_ace_existed = Dir.exist?(home_ace)
          FileUtils.mkdir_p(home_ace) unless home_ace_existed

          begin
            Dir.chdir(nested_dir)
            traverser = DirectoryTraverser.new

            priorities = traverser.build_cascade_priorities

            # Nested should have highest priority (0)
            nested_ace = File.realpath(File.join(nested_dir, ".ace"))
            assert_equal 0, priorities[nested_ace]

            # Project root should have lower priority
            project_ace = File.realpath(File.join(project_dir, ".ace"))
            assert_equal 10, priorities[project_ace]

            # Home should have lowest priority
            assert priorities[home_ace] > priorities[project_ace] if priorities.key?(home_ace)
          ensure
            FileUtils.rm_rf(home_ace) unless home_ace_existed
          end
        end

        def test_custom_config_dir_name
          project_dir = File.join(@test_dir, "project")
          nested_dir = File.join(project_dir, "nested")

          FileUtils.mkdir_p(nested_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))
          FileUtils.mkdir_p(File.join(project_dir, ".myconfig"))
          FileUtils.mkdir_p(File.join(nested_dir, ".myconfig"))

          Dir.chdir(nested_dir)
          traverser = DirectoryTraverser.new(config_dir_name: ".myconfig")

          config_dirs = traverser.find_config_directories
          assert config_dirs.all? { |d| d.end_with?("/.myconfig") }
        end

        def test_start_path_option
          project_dir = File.join(@test_dir, "project")
          nested_dir = File.join(project_dir, "nested")

          FileUtils.mkdir_p(nested_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))
          FileUtils.mkdir_p(File.join(project_dir, ".ace"))
          FileUtils.mkdir_p(File.join(nested_dir, ".ace"))

          # Run from outside the project
          Dir.chdir(@test_dir)
          traverser = DirectoryTraverser.new(start_path: nested_dir)

          directories = traverser.traverse
          assert_equal 2, directories.length
        end

        def test_no_config_directories
          project_dir = File.join(@test_dir, "project")
          nested_dir = File.join(project_dir, "nested")

          FileUtils.mkdir_p(nested_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))
          # No .ace directories created

          Dir.chdir(nested_dir)
          traverser = DirectoryTraverser.new

          directories = traverser.traverse
          assert_empty directories

          config_dirs = traverser.find_config_directories
          assert_empty config_dirs
        end
      end
    end
  end
end