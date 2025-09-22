# frozen_string_literal: true

require "test_helper"
require "ace/core/molecules/project_root_finder"
require "tmpdir"
require "fileutils"

module Ace
  module Core
    module Molecules
      class ProjectRootFinderTest < AceTestCase
        include Ace::TestSupport::SubprocessRunner

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

          code = <<~RUBY
            require 'ace/core/molecules/project_root_finder'
            Dir.chdir("#{nested_dir}")
            finder = Ace::Core::Molecules::ProjectRootFinder.new
            puts finder.find
          RUBY

          output, status = run_in_clean_env(code: code, requires: [])
          assert status.success?, "Subprocess failed: #{output}"
          assert_equal File.realpath(project_dir), File.realpath(output.strip)
        end

        def test_finds_rakefile_root
          # Create project structure with Rakefile
          project_dir = File.join(@test_dir, "project")
          nested_dir = File.join(project_dir, "src")
          FileUtils.mkdir_p(nested_dir)
          FileUtils.touch(File.join(project_dir, "Rakefile"))

          code = <<~RUBY
            require 'ace/core/molecules/project_root_finder'
            Dir.chdir("#{nested_dir}")
            finder = Ace::Core::Molecules::ProjectRootFinder.new
            puts finder.find
          RUBY

          output, status = run_in_clean_env(code: code, requires: [])
          assert status.success?, "Subprocess failed: #{output}"
          assert_equal File.realpath(project_dir), File.realpath(output.strip)
        end

        def test_finds_gemfile_root
          # Create Ruby project structure
          project_dir = File.join(@test_dir, "ruby_project")
          nested_dir = File.join(project_dir, "lib", "modules")
          FileUtils.mkdir_p(nested_dir)
          FileUtils.touch(File.join(project_dir, "Gemfile"))

          code = <<~RUBY
            require 'ace/core/molecules/project_root_finder'
            Dir.chdir("#{nested_dir}")
            finder = Ace::Core::Molecules::ProjectRootFinder.new
            puts finder.find
          RUBY

          output, status = run_in_clean_env(code: code, requires: [])
          assert status.success?, "Subprocess failed: #{output}"
          assert_equal File.realpath(project_dir), File.realpath(output.strip)
        end

        def test_returns_nil_when_no_markers_found
          # Create directory without markers
          no_project_dir = File.join(@test_dir, "no_project")
          FileUtils.mkdir_p(no_project_dir)

          code = <<~RUBY
            require 'ace/core/molecules/project_root_finder'
            Dir.chdir("#{no_project_dir}")
            finder = Ace::Core::Molecules::ProjectRootFinder.new
            result = finder.find
            puts result.nil? ? "nil" : result
          RUBY

          output, status = run_in_clean_env(code: code, requires: [])
          assert status.success?, "Subprocess failed: #{output}"
          assert_equal "nil", output.strip
        end

        def test_find_or_current_returns_current_when_not_found
          # Create directory without markers
          no_project_dir = File.join(@test_dir, "no_project")
          FileUtils.mkdir_p(no_project_dir)

          code = <<~RUBY
            require 'ace/core/molecules/project_root_finder'
            Dir.chdir("#{no_project_dir}")
            finder = Ace::Core::Molecules::ProjectRootFinder.new
            puts finder.find_or_current
          RUBY

          output, status = run_in_clean_env(code: code, requires: [])
          assert status.success?, "Subprocess failed: #{output}"
          assert_equal File.realpath(no_project_dir), File.realpath(output.strip)
        end

        def test_in_project_returns_true_when_found
          project_dir = File.join(@test_dir, "project")
          FileUtils.mkdir_p(project_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))

          code = <<~RUBY
            require 'ace/core/molecules/project_root_finder'
            Dir.chdir("#{project_dir}")
            finder = Ace::Core::Molecules::ProjectRootFinder.new
            puts finder.in_project?
          RUBY

          output, status = run_in_clean_env(code: code, requires: [])
          assert status.success?, "Subprocess failed: #{output}"
          assert_equal "true", output.strip
        end

        def test_in_project_returns_false_when_not_found
          no_project_dir = File.join(@test_dir, "no_project")
          FileUtils.mkdir_p(no_project_dir)

          code = <<~RUBY
            require 'ace/core/molecules/project_root_finder'
            Dir.chdir("#{no_project_dir}")
            finder = Ace::Core::Molecules::ProjectRootFinder.new
            puts finder.in_project?
          RUBY

          output, status = run_in_clean_env(code: code, requires: [])
          assert status.success?, "Subprocess failed: #{output}"
          assert_equal "false", output.strip
        end

        def test_relative_path_from_project_root
          project_dir = File.join(@test_dir, "project")
          nested_file = File.join(project_dir, "lib", "nested", "file.rb")
          FileUtils.mkdir_p(File.dirname(nested_file))
          FileUtils.touch(nested_file)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))

          code = <<~RUBY
            require 'ace/core/molecules/project_root_finder'
            Dir.chdir("#{File.dirname(nested_file)}")
            finder = Ace::Core::Molecules::ProjectRootFinder.new
            puts finder.relative_path("#{nested_file}")
          RUBY

          output, status = run_in_clean_env(code: code, requires: [])
          assert status.success?, "Subprocess failed: #{output}"
          assert_equal "lib/nested/file.rb", output.strip
        end

        def test_relative_path_returns_nil_when_not_in_project
          no_project_dir = File.join(@test_dir, "no_project")
          file_path = File.join(no_project_dir, "file.rb")
          FileUtils.mkdir_p(no_project_dir)
          FileUtils.touch(file_path)

          code = <<~RUBY
            require 'ace/core/molecules/project_root_finder'
            Dir.chdir("#{no_project_dir}")
            finder = Ace::Core::Molecules::ProjectRootFinder.new
            result = finder.relative_path("#{file_path}")
            puts result.nil? ? "nil" : result
          RUBY

          output, status = run_in_clean_env(code: code, requires: [])
          assert status.success?, "Subprocess failed: #{output}"
          assert_equal "nil", output.strip
        end

        def test_custom_markers
          # Create project with custom marker
          project_dir = File.join(@test_dir, "custom_project")
          nested_dir = File.join(project_dir, "deep", "nested")
          FileUtils.mkdir_p(nested_dir)
          FileUtils.touch(File.join(project_dir, ".custom-root"))

          code = <<~RUBY
            require 'ace/core/molecules/project_root_finder'
            Dir.chdir("#{nested_dir}")
            finder = Ace::Core::Molecules::ProjectRootFinder.new(markers: ['.custom-root'])
            puts finder.find
          RUBY

          output, status = run_in_clean_env(code: code, requires: [])
          assert status.success?, "Subprocess failed: #{output}"
          assert_equal File.realpath(project_dir), File.realpath(output.strip)
        end

        def test_class_method_find
          project_dir = File.join(@test_dir, "project")
          FileUtils.mkdir_p(project_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))

          code = <<~RUBY
            require 'ace/core/molecules/project_root_finder'
            puts Ace::Core::Molecules::ProjectRootFinder.find(start_path: "#{project_dir}")
          RUBY

          output, status = run_in_clean_env(code: code, requires: [])
          assert status.success?, "Subprocess failed: #{output}"
          assert_equal File.realpath(project_dir), File.realpath(output.strip)
        end

        def test_class_method_find_or_current
          no_project_dir = File.join(@test_dir, "no_project")
          FileUtils.mkdir_p(no_project_dir)

          code = <<~RUBY
            require 'ace/core/molecules/project_root_finder'
            Dir.chdir("#{no_project_dir}")
            puts Ace::Core::Molecules::ProjectRootFinder.find_or_current
          RUBY

          output, status = run_in_clean_env(code: code, requires: [])
          assert status.success?, "Subprocess failed: #{output}"
          assert_equal File.realpath(no_project_dir), File.realpath(output.strip)
        end

        def test_start_path_option
          project_dir = File.join(@test_dir, "project")
          nested_dir = File.join(project_dir, "lib", "nested")
          FileUtils.mkdir_p(nested_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))

          code = <<~RUBY
            require 'ace/core/molecules/project_root_finder'
            finder = Ace::Core::Molecules::ProjectRootFinder.new(start_path: "#{nested_dir}")
            puts finder.find
          RUBY

          output, status = run_in_clean_env(code: code, requires: [])
          assert status.success?, "Subprocess failed: #{output}"
          assert_equal File.realpath(project_dir), File.realpath(output.strip)
        end

        def test_prefers_markers_in_order
          # Create structure where .git is deeper than Gemfile
          outer_dir = File.join(@test_dir, "outer")
          inner_dir = File.join(outer_dir, "inner")
          FileUtils.mkdir_p(inner_dir)
          FileUtils.touch(File.join(outer_dir, "Gemfile"))
          FileUtils.mkdir_p(File.join(inner_dir, ".git"))

          code = <<~RUBY
            require 'ace/core/molecules/project_root_finder'
            Dir.chdir("#{inner_dir}")
            finder = Ace::Core::Molecules::ProjectRootFinder.new
            puts finder.find
          RUBY

          output, status = run_in_clean_env(code: code, requires: [])
          assert status.success?, "Subprocess failed: #{output}"
          # Should find .git first (higher priority)
          assert_equal File.realpath(inner_dir), File.realpath(output.strip)
        end

        def test_caching
          project_dir = File.join(@test_dir, "project")
          FileUtils.mkdir_p(project_dir)
          FileUtils.mkdir_p(File.join(project_dir, ".git"))

          # Test that cache works within subprocess
          code = <<~RUBY
            require 'ace/core/molecules/project_root_finder'
            Dir.chdir("#{project_dir}")

            finder1 = Ace::Core::Molecules::ProjectRootFinder.new
            result1 = finder1.find

            # Clear cache
            Ace::Core::Molecules::ProjectRootFinder.clear_cache!

            # Should return nil after clearing when no PROJECT_ROOT_PATH
            # But we're in a dir with .git, so it should still find it
            finder2 = Ace::Core::Molecules::ProjectRootFinder.new
            result2 = finder2.find

            puts result1 == result2
          RUBY

          output, status = run_in_clean_env(code: code, requires: [])
          assert status.success?, "Subprocess failed: #{output}"
          assert_equal "true", output.strip
        end
      end
    end
  end
end