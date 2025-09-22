# frozen_string_literal: true

require "test_helper"
require "ace/core/molecules/project_root_finder"
require "tmpdir"
require "fileutils"

module Ace
  module Core
    module Molecules
      class ProjectRootFinderTest < Minitest::Test
        def setup
          @original_pwd = Dir.pwd
          @test_dir = Dir.mktmpdir("ace-test-")
          # Clear cache before each test
          ProjectRootFinder.clear_cache!
        end

        def teardown
          Dir.chdir(@original_pwd)
          FileUtils.rm_rf(@test_dir) if @test_dir && Dir.exist?(@test_dir)
        end

        def test_finds_git_root
          # Create project structure with .git
          project_dir = File.join(@test_dir, "project")
          nested_dir = File.join(project_dir, "lib", "nested")
          FileUtils.mkdir_p(nested_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))

          Dir.chdir(nested_dir)
          finder = ProjectRootFinder.new

          assert_equal File.realpath(project_dir), File.realpath(finder.find)
        end

        def test_finds_rakefile_root
          # Create project structure with Rakefile
          project_dir = File.join(@test_dir, "project")
          nested_dir = File.join(project_dir, "src")
          FileUtils.mkdir_p(nested_dir)
          FileUtils.touch(File.join(project_dir, "Rakefile"))

          Dir.chdir(nested_dir)
          finder = ProjectRootFinder.new

          assert_equal File.realpath(project_dir), File.realpath(finder.find)
        end

        def test_finds_gemfile_root
          # Create Ruby project structure
          project_dir = File.join(@test_dir, "ruby_project")
          nested_dir = File.join(project_dir, "lib", "modules")
          FileUtils.mkdir_p(nested_dir)
          FileUtils.touch(File.join(project_dir, "Gemfile"))

          Dir.chdir(nested_dir)
          finder = ProjectRootFinder.new

          assert_equal File.realpath(project_dir), File.realpath(finder.find)
        end

        def test_returns_nil_when_no_markers_found
          # Create directory without markers
          no_project_dir = File.join(@test_dir, "no_project")
          FileUtils.mkdir_p(no_project_dir)

          Dir.chdir(no_project_dir)
          finder = ProjectRootFinder.new

          assert_nil finder.find
        end

        def test_find_or_current_returns_current_when_not_found
          # Create directory without markers
          no_project_dir = File.join(@test_dir, "no_project")
          FileUtils.mkdir_p(no_project_dir)

          Dir.chdir(no_project_dir)
          finder = ProjectRootFinder.new

          assert_equal Dir.pwd, finder.find_or_current
        end

        def test_in_project_returns_true_when_found
          project_dir = File.join(@test_dir, "project")
          FileUtils.mkdir_p(project_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))

          Dir.chdir(project_dir)
          finder = ProjectRootFinder.new

          assert finder.in_project?
        end

        def test_in_project_returns_false_when_not_found
          no_project_dir = File.join(@test_dir, "no_project")
          FileUtils.mkdir_p(no_project_dir)

          Dir.chdir(no_project_dir)
          finder = ProjectRootFinder.new

          refute finder.in_project?
        end

        def test_relative_path_from_project_root
          project_dir = File.join(@test_dir, "project")
          nested_file = File.join(project_dir, "lib", "nested", "file.rb")
          FileUtils.mkdir_p(File.dirname(nested_file))
          FileUtils.touch(nested_file)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))

          Dir.chdir(File.dirname(nested_file))
          finder = ProjectRootFinder.new

          assert_equal "lib/nested/file.rb", finder.relative_path(nested_file)
        end

        def test_relative_path_returns_nil_when_not_in_project
          no_project_dir = File.join(@test_dir, "no_project")
          FileUtils.mkdir_p(no_project_dir)

          Dir.chdir(no_project_dir)
          finder = ProjectRootFinder.new

          assert_nil finder.relative_path(Dir.pwd)
        end

        def test_custom_markers
          project_dir = File.join(@test_dir, "custom_project")
          nested_dir = File.join(project_dir, "src")
          FileUtils.mkdir_p(nested_dir)
          FileUtils.touch(File.join(project_dir, ".custom_marker"))

          Dir.chdir(nested_dir)
          finder = ProjectRootFinder.new(markers: [".custom_marker"])

          assert_equal File.realpath(project_dir), File.realpath(finder.find)
        end

        def test_class_method_find
          project_dir = File.join(@test_dir, "project")
          FileUtils.mkdir_p(project_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))

          Dir.chdir(project_dir)

          assert_equal File.realpath(project_dir), File.realpath(ProjectRootFinder.find)
        end

        def test_class_method_find_or_current
          no_project_dir = File.join(@test_dir, "no_project")
          FileUtils.mkdir_p(no_project_dir)

          Dir.chdir(no_project_dir)

          assert_equal Dir.pwd, ProjectRootFinder.find_or_current
        end

        def test_start_path_option
          project_dir = File.join(@test_dir, "project")
          nested_dir = File.join(project_dir, "lib", "nested")
          FileUtils.mkdir_p(nested_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))

          # Test from outside the project
          Dir.chdir(@test_dir)
          finder = ProjectRootFinder.new(start_path: nested_dir)

          assert_equal File.realpath(project_dir), File.realpath(finder.find)
        end

        def test_prefers_markers_in_order
          # Create nested projects with different markers
          outer_project = File.join(@test_dir, "outer")
          inner_project = File.join(outer_project, "inner")
          FileUtils.mkdir_p(inner_project)

          # Outer has lower priority marker
          FileUtils.touch(File.join(outer_project, "package.json"))

          # Inner has higher priority marker
          FileUtils.mkdir_p(File.join(inner_project, ".git"))

          Dir.chdir(inner_project)
          finder = ProjectRootFinder.new

          # Should find .git first (higher priority)
          assert_equal File.realpath(inner_project), File.realpath(finder.find)
        end

        def test_caching
          project_dir = File.join(@test_dir, "project")
          FileUtils.mkdir_p(project_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))

          Dir.chdir(project_dir)

          # First call should find the project root
          result1 = ProjectRootFinder.find

          # Remove the .git directory
          FileUtils.rm_rf(File.join(project_dir, ".git"))

          # Second call should return cached result
          result2 = ProjectRootFinder.find

          assert_equal result1, result2

          # Clear cache and try again
          ProjectRootFinder.clear_cache!
          result3 = ProjectRootFinder.find

          assert_nil result3
        end
      end
    end
  end
end