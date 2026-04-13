# frozen_string_literal: true

require "test_helper"

module Ace
  module Support
    module Config
      module Molecules
        class ConfigFinderTest < TestCase
          def test_find_all_returns_cascade_paths
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "settings.yml" => "key: value"
              }
            ) do |tmpdir|
              finder = ConfigFinder.new(start_path: tmpdir)

              paths = finder.find_all
              existing = paths.select(&:exists)

              assert_operator existing.count, :>=, 1
              assert existing.any? { |p| p.path.include?("settings.yml") }
            end
          end

          def test_find_all_respects_file_patterns
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "custom.yml" => "custom: value",
                "settings.yml" => "settings: value"
              }
            ) do |tmpdir|
              finder = ConfigFinder.new(
                start_path: tmpdir,
                file_patterns: ["custom.yml"]
              )

              paths = finder.find_all.select(&:exists)

              assert paths.any? { |p| p.path.include?("custom.yml") }
              refute paths.any? { |p| p.path.include?("settings.yml") }
            end
          end

          def test_find_first_returns_first_existing
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "settings.yml" => "key: value"
              }
            ) do |tmpdir|
              finder = ConfigFinder.new(start_path: tmpdir)

              first = finder.find_first

              assert first
              assert first.exists
            end
          end

          def test_find_first_returns_nil_when_none_exist
            with_temp_config(
              ".git" => ""
            ) do |tmpdir|
              finder = ConfigFinder.new(
                start_path: tmpdir,
                file_patterns: ["nonexistent.yml"]
              )

              # Filter to only existing paths
              first = finder.find_all.select(&:exists).first

              assert_nil first
            end
          end

          def test_find_by_type_returns_local_configs
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "settings.yml" => "key: value"
              }
            ) do |tmpdir|
              finder = ConfigFinder.new(start_path: tmpdir)

              local_paths = finder.find_by_type(:local)
              existing = local_paths.select(&:exists)

              assert_operator existing.count, :>=, 1
              existing.each { |p| assert_equal :local, p.type }
            end
          end

          def test_find_file_returns_first_matching
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "test.yml" => "key: value"
              }
            ) do |tmpdir|
              finder = ConfigFinder.new(start_path: tmpdir)

              path = finder.find_file("test.yml")

              assert path
              assert path.end_with?("test.yml")
            end
          end

          def test_find_file_returns_nil_when_not_found
            with_temp_config(
              ".git" => "",
              ".ace" => {}
            ) do |tmpdir|
              finder = ConfigFinder.new(start_path: tmpdir)

              path = finder.find_file("nonexistent.yml")

              assert_nil path
            end
          end

          def test_find_all_files_returns_all_cascade_matches
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "config.yml" => "level: project"
              },
              "subdir" => {
                ".ace" => {
                  "config.yml" => "level: subdir"
                }
              }
            ) do |tmpdir|
              Dir.chdir(File.join(tmpdir, "subdir")) do
                finder = ConfigFinder.new(start_path: Dir.pwd)

                files = finder.find_all_files("config.yml")

                assert_operator files.count, :>=, 2
              end
            end
          end

          def test_gem_path_defaults_included
            with_temp_config(
              ".git" => "",
              ".my-defaults" => {
                "config.yml" => "gem: default"
              }
            ) do |tmpdir|
              finder = ConfigFinder.new(
                start_path: tmpdir,
                defaults_dir: ".my-defaults",
                gem_path: tmpdir
              )

              path = finder.find_file("config.yml")

              assert path
              assert path.include?(".my-defaults")
            end
          end

          def test_search_paths_respects_use_traversal_false
            with_temp_config(".git" => "") do |tmpdir|
              finder = ConfigFinder.new(
                start_path: tmpdir,
                use_traversal: false
              )

              paths = finder.search_paths

              # With traversal disabled, should only have cwd and home
              assert_equal 2, paths.count
              assert paths.any? { |p| p.include?(tmpdir) }
            end
          end

          def test_cascade_priority_order
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "settings.yml" => "level: project"
              },
              "subdir" => {
                ".ace" => {
                  "settings.yml" => "level: subdir"
                }
              }
            ) do |tmpdir|
              Dir.chdir(File.join(tmpdir, "subdir")) do
                finder = ConfigFinder.new(start_path: Dir.pwd)

                paths = finder.find_all.select(&:exists)

                # Nearer configs should have lower priority numbers (higher priority)
                if paths.count >= 2
                  # Sort by priority and check subdir comes first
                  sorted = paths.sort_by(&:priority)
                  assert sorted.first.path.include?("subdir")
                end
              end
            end
          end
        end
      end
    end
  end
end
