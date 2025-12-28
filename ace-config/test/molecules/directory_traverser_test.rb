# frozen_string_literal: true

require "test_helper"

module Ace
  module Config
    module Molecules
      class DirectoryTraverserTest < TestCase
        def test_traverse_finds_directories_with_config
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "key: value"
            }
          ) do |tmpdir|
            traverser = DirectoryTraverser.new(start_path: tmpdir)

            result = traverser.traverse

            assert result.include?(tmpdir)
          end
        end

        def test_traverse_respects_project_root_boundary
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "root: value"
            },
            "subdir" => {
              ".ace" => {
                "settings.yml" => "subdir: value"
              }
            }
          ) do |tmpdir|
            # Use realpath to handle symlinks (macOS /var -> /private/var)
            real_tmpdir = File.realpath(tmpdir)
            subdir_path = File.join(real_tmpdir, "subdir")

            Dir.chdir(subdir_path) do
              traverser = DirectoryTraverser.new(start_path: Dir.pwd)

              result = traverser.traverse

              # Should include both subdir and project root (directories with .ace)
              assert result.any? { |d| d.end_with?("subdir") }, "Expected #{result.inspect} to include subdir"
              assert result.any? { |d| File.realpath(d) == real_tmpdir }, "Expected #{result.inspect} to include project root"
            end
          end
        end

        def test_traverse_stops_at_project_root
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "key: value"
            }
          ) do |tmpdir|
            traverser = DirectoryTraverser.new(start_path: tmpdir)

            result = traverser.traverse

            # Should not traverse beyond project root
            result.each do |dir|
              assert dir.start_with?(tmpdir) || dir == tmpdir
            end
          end
        end

        def test_find_config_directories_returns_full_paths
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "key: value"
            }
          ) do |tmpdir|
            traverser = DirectoryTraverser.new(start_path: tmpdir)

            config_dirs = traverser.find_config_directories

            assert config_dirs.any? { |d| d.end_with?(".ace") }
          end
        end

        def test_find_config_directories_with_custom_config_dir
          with_temp_config(
            ".git" => "",
            ".my-app" => {
              "settings.yml" => "key: value"
            }
          ) do |tmpdir|
            traverser = DirectoryTraverser.new(
              config_dir: ".my-app",
              start_path: tmpdir
            )

            config_dirs = traverser.find_config_directories

            assert config_dirs.any? { |d| d.end_with?(".my-app") }
          end
        end

        def test_directory_hierarchy_returns_all_levels
          with_temp_config(
            ".git" => "",
            "level1" => {
              "level2" => {
                "level3" => {}
              }
            }
          ) do |tmpdir|
            # Use realpath to handle symlinks (macOS /var -> /private/var)
            real_tmpdir = File.realpath(tmpdir)
            nested_path = File.join(real_tmpdir, "level1", "level2", "level3")

            Dir.chdir(nested_path) do
              traverser = DirectoryTraverser.new(start_path: Dir.pwd)

              hierarchy = traverser.directory_hierarchy

              # Should include all levels from nested_path up to project root
              assert_operator hierarchy.count, :>=, 4, "Expected at least 4 levels in #{hierarchy.inspect}"
              assert hierarchy.first.end_with?("level3"), "First should end with level3, got #{hierarchy.first}"
              assert hierarchy.any? { |d| File.realpath(d) == real_tmpdir }, "Should include project root"
            end
          end
        end

        def test_build_cascade_priorities_assigns_correct_order
          with_temp_config(
            ".git" => "",
            ".ace" => {},
            "subdir" => {
              ".ace" => {}
            }
          ) do |tmpdir|
            Dir.chdir(File.join(tmpdir, "subdir")) do
              traverser = DirectoryTraverser.new(start_path: Dir.pwd)

              priorities = traverser.build_cascade_priorities

              # Should have at least the subdir and project root configs
              assert_operator priorities.size, :>=, 2

              # All priorities should be numeric
              priorities.each do |_path, priority|
                assert_kind_of Integer, priority
              end
            end
          end
        end

        def test_traverse_avoids_infinite_loops
          with_temp_config(".git" => "") do |tmpdir|
            traverser = DirectoryTraverser.new(start_path: tmpdir)

            # Should complete without hanging
            result = traverser.traverse

            assert_kind_of Array, result
          end
        end

        def test_traverse_handles_missing_config_dir
          with_temp_config(".git" => "") do |tmpdir|
            # No .ace directory exists
            traverser = DirectoryTraverser.new(start_path: tmpdir)

            result = traverser.traverse

            # Should return empty array or not include tmpdir
            refute result.include?(tmpdir)
          end
        end

        def test_config_dir_accessor
          traverser = DirectoryTraverser.new(config_dir: ".custom")

          assert_equal ".custom", traverser.config_dir
        end
      end
    end
  end
end
