# frozen_string_literal: true

require "test_helper"
require "ace/core/molecules/project_root_finder"
require "tmpdir"
require "fileutils"

module Ace
  module Core
    module Molecules
      class ProjectRootFinderTest < AceTestCase
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

          Dir.chdir(nested_dir) do
            finder = ProjectRootFinder.new
            # Stub env_project_root to return nil (simulate clean environment)
            finder.stub :env_project_root, nil do
              assert_equal File.realpath(project_dir), File.realpath(finder.find)
            end
          end
        end

        def test_finds_rakefile_root
          # Create project structure with Rakefile
          project_dir = File.join(@test_dir, "project")
          nested_dir = File.join(project_dir, "src")
          FileUtils.mkdir_p(nested_dir)
          FileUtils.touch(File.join(project_dir, "Rakefile"))

          Dir.chdir(nested_dir) do
            finder = ProjectRootFinder.new
            finder.stub :env_project_root, nil do
              assert_equal File.realpath(project_dir), File.realpath(finder.find)
            end
          end
        end

        def test_finds_gemfile_root
          # Create Ruby project structure
          project_dir = File.join(@test_dir, "ruby_project")
          nested_dir = File.join(project_dir, "lib", "modules")
          FileUtils.mkdir_p(nested_dir)
          FileUtils.touch(File.join(project_dir, "Gemfile"))

          Dir.chdir(nested_dir) do
            finder = ProjectRootFinder.new
            finder.stub :env_project_root, nil do
              assert_equal File.realpath(project_dir), File.realpath(finder.find)
            end
          end
        end

        def test_returns_nil_when_no_markers_found
          # Create directory without markers
          no_project_dir = File.join(@test_dir, "no_project")
          FileUtils.mkdir_p(no_project_dir)

          Dir.chdir(no_project_dir) do
            finder = ProjectRootFinder.new
            finder.stub :env_project_root, nil do
              assert_nil finder.find
            end
          end
        end

        def test_find_or_current_returns_current_when_not_found
          # Create directory without markers
          no_project_dir = File.join(@test_dir, "no_project")
          FileUtils.mkdir_p(no_project_dir)

          Dir.chdir(no_project_dir) do
            finder = ProjectRootFinder.new
            finder.stub :env_project_root, nil do
              assert_equal File.realpath(no_project_dir), File.realpath(finder.find_or_current)
            end
          end
        end

        def test_in_project_returns_true_when_found
          project_dir = File.join(@test_dir, "project")
          FileUtils.mkdir_p(project_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))

          Dir.chdir(project_dir) do
            finder = ProjectRootFinder.new
            finder.stub :env_project_root, nil do
              assert finder.in_project?
            end
          end
        end

        def test_in_project_returns_false_when_not_found
          no_project_dir = File.join(@test_dir, "no_project")
          FileUtils.mkdir_p(no_project_dir)

          Dir.chdir(no_project_dir) do
            finder = ProjectRootFinder.new
            finder.stub :env_project_root, nil do
              refute finder.in_project?
            end
          end
        end

        def test_relative_path_from_project_root
          project_dir = File.join(@test_dir, "project")
          nested_file = File.join(project_dir, "lib", "nested", "file.rb")
          FileUtils.mkdir_p(File.dirname(nested_file))
          FileUtils.touch(nested_file)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))

          Dir.chdir(File.dirname(nested_file)) do
            finder = ProjectRootFinder.new
            finder.stub :env_project_root, nil do
              assert_equal "lib/nested/file.rb", finder.relative_path(nested_file)
            end
          end
        end

        def test_relative_path_returns_nil_when_not_in_project
          no_project_dir = File.join(@test_dir, "no_project")
          file_path = File.join(no_project_dir, "file.rb")
          FileUtils.mkdir_p(no_project_dir)
          FileUtils.touch(file_path)

          Dir.chdir(no_project_dir) do
            finder = ProjectRootFinder.new
            finder.stub :env_project_root, nil do
              assert_nil finder.relative_path(file_path)
            end
          end
        end

        def test_custom_markers
          # Create project with custom marker
          project_dir = File.join(@test_dir, "custom_project")
          nested_dir = File.join(project_dir, "deep", "nested")
          FileUtils.mkdir_p(nested_dir)
          FileUtils.touch(File.join(project_dir, ".custom-root"))

          Dir.chdir(nested_dir) do
            finder = ProjectRootFinder.new(markers: ['.custom-root'])
            finder.stub :env_project_root, nil do
              assert_equal File.realpath(project_dir), File.realpath(finder.find)
            end
          end
        end

        def test_class_method_find
          project_dir = File.join(@test_dir, "project")
          FileUtils.mkdir_p(project_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))

          # Create an instance to stub
          finder_instance = ProjectRootFinder.new(start_path: project_dir)
          finder_instance.stub :env_project_root, nil do
            ProjectRootFinder.stub :new, finder_instance do
              assert_equal File.realpath(project_dir), File.realpath(ProjectRootFinder.find(start_path: project_dir))
            end
          end
        end

        def test_class_method_find_or_current
          no_project_dir = File.join(@test_dir, "no_project")
          FileUtils.mkdir_p(no_project_dir)

          Dir.chdir(no_project_dir) do
            finder_instance = ProjectRootFinder.new
            finder_instance.stub :env_project_root, nil do
              ProjectRootFinder.stub :new, finder_instance do
                assert_equal File.realpath(no_project_dir), File.realpath(ProjectRootFinder.find_or_current)
              end
            end
          end
        end

        def test_start_path_option
          project_dir = File.join(@test_dir, "project")
          nested_dir = File.join(project_dir, "lib", "nested")
          FileUtils.mkdir_p(nested_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))

          finder = ProjectRootFinder.new(start_path: nested_dir)
          finder.stub :env_project_root, nil do
            assert_equal File.realpath(project_dir), File.realpath(finder.find)
          end
        end

        def test_prefers_markers_in_order
          # Create structure where .git is deeper than Gemfile
          outer_dir = File.join(@test_dir, "outer")
          inner_dir = File.join(outer_dir, "inner")
          FileUtils.mkdir_p(inner_dir)
          FileUtils.touch(File.join(outer_dir, "Gemfile"))
          FileUtils.mkdir_p(File.join(inner_dir, ".git"))

          Dir.chdir(inner_dir) do
            finder = ProjectRootFinder.new
            finder.stub :env_project_root, nil do
              # Should find .git first (higher priority)
              assert_equal File.realpath(inner_dir), File.realpath(finder.find)
            end
          end
        end

        def test_uses_env_variable_when_set
          # Test that PROJECT_ROOT_PATH takes precedence
          project_dir = File.join(@test_dir, "env_project")
          FileUtils.mkdir_p(project_dir)

          other_dir = File.join(@test_dir, "other")
          FileUtils.mkdir_p(other_dir)
          FileUtils.mkdir_p(File.join(other_dir, ".git"))

          Dir.chdir(other_dir) do
            finder = ProjectRootFinder.new
            # Stub to return the env project path
            finder.stub :env_project_root, project_dir do
              assert_equal project_dir, finder.find
            end
          end
        end

        def test_ignores_invalid_env_path
          # Test fallback when ENV points to non-existent directory
          project_dir = File.join(@test_dir, "actual_project")
          FileUtils.mkdir_p(project_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))

          Dir.chdir(project_dir) do
            finder = ProjectRootFinder.new
            # Stub to return non-existent path
            finder.stub :env_project_root, "/nonexistent/path" do
              # Should fall back to .git directory
              assert_equal File.realpath(project_dir), File.realpath(finder.find)
            end
          end
        end

        def test_caching
          project_dir = File.join(@test_dir, "project")
          FileUtils.mkdir_p(project_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))

          Dir.chdir(project_dir) do
            finder1 = ProjectRootFinder.new
            finder1.stub :env_project_root, nil do
              result1 = finder1.find

              # Clear cache
              ProjectRootFinder.clear_cache!

              # Should still find it after cache clear
              finder2 = ProjectRootFinder.new
              finder2.stub :env_project_root, nil do
                result2 = finder2.find
                assert_equal result1, result2
              end
            end
          end
        end
      end
    end
  end
end