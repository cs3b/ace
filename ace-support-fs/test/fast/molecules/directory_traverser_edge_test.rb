# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"
require "timeout"

module Ace
  module Support
    module Fs
      module Molecules
        class DirectoryTraverserEdgeTest < TestCase
          def setup
            super
            @original_pwd = Dir.pwd
            @test_dir = Dir.mktmpdir("ace-edge-test-")
            ProjectRootFinder.clear_cache!
          end

          def teardown
            super
          ensure
            Dir.chdir(@original_pwd) if @original_pwd && Dir.exist?(@original_pwd)
            FileUtils.rm_rf(@test_dir) if @test_dir && Dir.exist?(@test_dir)
          end

          def test_traverse_from_very_deep_directory
            # Create 10-level deep directory structure
            project_dir = File.join(@test_dir, "project")
            deep_path = File.join(project_dir, Array.new(10) { "level" })

            FileUtils.mkdir_p(deep_path)
            FileUtils.mkdir_p(File.join(project_dir, ".git"))
            FileUtils.mkdir_p(File.join(project_dir, ".ace"))

            # Add config at different depths
            FileUtils.mkdir_p(File.join(project_dir, "level", "level", ".ace"))
            FileUtils.mkdir_p(File.join(project_dir, "level", "level", "level", "level", "level", ".ace"))

            Dir.chdir(deep_path)
            traverser = DirectoryTraverser.new

            directories = traverser.traverse

            # Should find all config directories up to project root
            assert directories.length >= 3, "Should find multiple config directories from deep path"
            assert directories.all? { |d| Dir.exist?(File.join(d, ".ace")) }
          end

          def test_directory_hierarchy_for_deep_nesting
            # Create 5-level deep directory
            project_dir = File.join(@test_dir, "project")
            deep_path = File.join(project_dir, Array.new(5) { "level" })

            FileUtils.mkdir_p(deep_path)
            FileUtils.mkdir_p(File.join(project_dir, ".git"))

            Dir.chdir(deep_path)
            traverser = DirectoryTraverser.new

            hierarchy = traverser.directory_hierarchy

            # Should have at least 6 levels (project + 5 nested)
            # May have more if it goes beyond project root
            assert hierarchy.length >= 6, "Should have at least 6 levels in hierarchy"
            # Use File.realpath to normalize paths for comparison (handles /private prefix on macOS)
            assert_equal File.realpath(deep_path), File.realpath(hierarchy[0])
          end

          def test_handles_unicode_directory_names
            # Create directories with unicode characters
            project_dir = File.join(@test_dir, "project")
            unicode_dir = File.join(project_dir, "café", "文件夹")

            FileUtils.mkdir_p(unicode_dir)
            FileUtils.mkdir_p(File.join(project_dir, ".git"))
            FileUtils.mkdir_p(File.join(project_dir, ".ace"))
            FileUtils.mkdir_p(File.join(unicode_dir, ".ace"))

            Dir.chdir(unicode_dir)
            traverser = DirectoryTraverser.new

            directories = traverser.traverse

            assert directories.length >= 2, "Should traverse unicode directory names"
            assert directories.any? { |d| d.include?("café") || d.include?("文件夹") }
          end

          def test_handles_directories_with_spaces
            # Create directories with spaces in names
            project_dir = File.join(@test_dir, "my project")
            spaced_dir = File.join(project_dir, "lib folder", "nested module")

            FileUtils.mkdir_p(spaced_dir)
            FileUtils.mkdir_p(File.join(project_dir, ".git"))
            FileUtils.mkdir_p(File.join(project_dir, ".ace"))
            FileUtils.mkdir_p(File.join(spaced_dir, ".ace"))

            Dir.chdir(spaced_dir)
            traverser = DirectoryTraverser.new

            directories = traverser.traverse

            assert directories.length >= 2, "Should handle spaces in directory names"
            assert directories.any? { |d| d.include?("my project") }
          end

          def test_handles_symlinked_directories
            # Create real directory with .ace
            project_dir = File.join(@test_dir, "project")
            real_dir = File.join(project_dir, "real")

            FileUtils.mkdir_p(real_dir)
            FileUtils.mkdir_p(File.join(project_dir, ".git"))
            FileUtils.mkdir_p(File.join(project_dir, ".ace"))
            FileUtils.mkdir_p(File.join(real_dir, ".ace"))

            # Create symlink to nested directory
            link_dir = File.join(project_dir, "link")
            FileUtils.ln_s(real_dir, link_dir)

            Dir.chdir(link_dir)
            traverser = DirectoryTraverser.new

            # Should handle symlinks without crashing
            directories = traverser.traverse
            assert directories.is_a?(Array), "Should return array even with symlinks"
          end

          def test_handles_long_path_names
            # Create very long directory names (approaching filesystem limits)
            project_dir = File.join(@test_dir, "project")
            long_name = "a" * 200  # Very long directory name
            long_dir = File.join(project_dir, long_name)

            begin
              FileUtils.mkdir_p(long_dir)
              FileUtils.mkdir_p(File.join(project_dir, ".git"))
              FileUtils.mkdir_p(File.join(project_dir, ".ace"))

              Dir.chdir(long_dir)
              traverser = DirectoryTraverser.new

              directories = traverser.traverse
              assert directories.is_a?(Array), "Should handle long path names"
            rescue Errno::ENAMETOOLONG
              skip "Filesystem doesn't support paths this long"
            end
          end

          def test_handles_special_characters_in_paths
            # Create directory with special characters
            project_dir = File.join(@test_dir, "project")
            special_dir = File.join(project_dir, "test-dir_v1.0", "sub#dir")

            FileUtils.mkdir_p(special_dir)
            FileUtils.mkdir_p(File.join(project_dir, ".git"))
            FileUtils.mkdir_p(File.join(project_dir, ".ace"))
            FileUtils.mkdir_p(File.join(special_dir, ".ace"))

            Dir.chdir(special_dir)
            traverser = DirectoryTraverser.new

            directories = traverser.traverse

            assert directories.length >= 2, "Should handle special characters"
            assert directories.any? { |d| d.include?("test-dir_v1.0") }
          end

          def test_traverse_prevents_infinite_loops
            # Create directory and traverse from it
            project_dir = File.join(@test_dir, "project")
            nested_dir = File.join(project_dir, "nested")

            FileUtils.mkdir_p(nested_dir)
            FileUtils.mkdir_p(File.join(project_dir, ".git"))
            FileUtils.mkdir_p(File.join(project_dir, ".ace"))

            Dir.chdir(nested_dir)
            traverser = DirectoryTraverser.new

            # Should complete without hanging
            Timeout.timeout(5) do
              directories = traverser.traverse
              assert directories.is_a?(Array), "Should complete without infinite loop"
            end
          end

          def test_execution_from_nested_subdirectories
            # Simulate real-world scenario: running from deep in source tree
            project_dir = File.join(@test_dir, "myapp")
            src_dir = File.join(project_dir, "src", "components", "ui", "buttons")

            FileUtils.mkdir_p(src_dir)
            FileUtils.mkdir_p(File.join(project_dir, ".git"))
            FileUtils.mkdir_p(File.join(project_dir, ".ace"))

            Dir.chdir(src_dir)
            traverser = DirectoryTraverser.new

            directories = traverser.traverse

            # Should find project config from deep directory
            assert directories.length >= 1, "Should find config from nested source directory"
            assert directories.last.end_with?("myapp"), "Should reach project root"
          end

          def test_handles_missing_permissions_gracefully
            # Create directory we can read but subdirectory we might not
            project_dir = File.join(@test_dir, "project")
            restricted_dir = File.join(project_dir, "restricted")

            FileUtils.mkdir_p(restricted_dir)
            FileUtils.mkdir_p(File.join(project_dir, ".git"))
            FileUtils.mkdir_p(File.join(project_dir, ".ace"))

            # Try to make restricted (may not work on all systems)
            begin
              File.chmod(0o000, restricted_dir)

              Dir.chdir(project_dir)
              traverser = DirectoryTraverser.new

              # Should handle gracefully without crashing
              directories = traverser.traverse
              assert directories.is_a?(Array), "Should handle permission errors gracefully"
            rescue Errno::EACCES
              # Expected - test passed
            ensure
              # Restore permissions for cleanup
              begin
                File.chmod(0o755, restricted_dir)
              rescue
                nil
              end
            end
          end

          def test_cascade_priorities_with_deep_nesting
            # Test priority assignment with many levels
            project_dir = File.join(@test_dir, "project")
            deep_path = File.join(project_dir, "a", "b", "c", "d", "e")

            FileUtils.mkdir_p(deep_path)
            FileUtils.mkdir_p(File.join(project_dir, ".git"))
            FileUtils.mkdir_p(File.join(project_dir, ".ace"))
            FileUtils.mkdir_p(File.join(project_dir, "a", ".ace"))
            FileUtils.mkdir_p(File.join(project_dir, "a", "b", "c", ".ace"))
            FileUtils.mkdir_p(File.join(deep_path, ".ace"))

            Dir.chdir(deep_path)
            traverser = DirectoryTraverser.new

            priorities = traverser.build_cascade_priorities

            # Closest directory should have priority 0
            deepest_ace = File.join(deep_path, ".ace")
            assert_equal 0, priorities[File.realpath(deepest_ace)]

            # Each parent level should have incrementing priority
            sorted_priorities = priorities.values.sort
            assert_equal sorted_priorities, sorted_priorities.uniq, "Priorities should be unique"
            assert_equal sorted_priorities[1] - sorted_priorities[0], 10, "Priority increment should be 10"
          end

          def test_empty_config_dir_handling
            # Edge case: what if someone passes empty string?
            project_dir = File.join(@test_dir, "project")

            FileUtils.mkdir_p(project_dir)
            FileUtils.mkdir_p(File.join(project_dir, ".git"))

            Dir.chdir(project_dir)

            # Should handle empty config dir name gracefully
            # Note: new API uses config_dir: instead of config_dir_name:
            traverser = DirectoryTraverser.new(config_dir: "")

            directories = traverser.traverse
            assert directories.is_a?(Array), "Should handle empty config dir name"
          end

          def test_relative_vs_absolute_start_paths
            # Test both relative and absolute paths
            project_dir = File.join(@test_dir, "project")
            nested_dir = File.join(project_dir, "nested")

            FileUtils.mkdir_p(nested_dir)
            FileUtils.mkdir_p(File.join(project_dir, ".git"))
            FileUtils.mkdir_p(File.join(project_dir, ".ace"))

            # Test with absolute path
            traverser_abs = DirectoryTraverser.new(start_path: nested_dir)
            dirs_abs = traverser_abs.traverse

            # Test with relative path (if possible)
            Dir.chdir(project_dir)
            traverser_rel = DirectoryTraverser.new(start_path: "nested")
            dirs_rel = traverser_rel.traverse

            # Both should find the same number of directories
            assert_equal dirs_abs.length, dirs_rel.length, "Relative and absolute paths should yield same results"
          end
        end
      end
    end
  end
end
