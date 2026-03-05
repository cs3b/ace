# frozen_string_literal: true

require "test_helper"

module Ace
  module Support
    module Config
      module Molecules
        class ProjectConfigScannerTest < TestCase
          def test_scan_returns_empty_hash_for_nonexistent_root
            scanner = ProjectConfigScanner.new(project_root: "/nonexistent/path/that/does/not/exist")
            assert_equal({}, scanner.scan)
          end

          def test_scan_returns_empty_hash_when_no_ace_dirs
            with_temp_config(".git" => "") do |tmpdir|
              scanner = ProjectConfigScanner.new(project_root: tmpdir)
              assert_equal({}, scanner.scan)
            end
          end

          def test_scan_returns_root_ace_folder
            with_temp_config(
              ".git" => "",
              ".ace" => { "git" => { "commit.yml" => "model: default" } }
            ) do |tmpdir|
              scanner = ProjectConfigScanner.new(project_root: tmpdir)
              result = scanner.scan

              assert result.key?(".")
              assert_includes result["."], "git/commit.yml"
            end
          end

          def test_scan_returns_nested_ace_folders
            with_temp_config(
              ".git" => "",
              ".ace" => { "git" => { "commit.yml" => "model: root" } },
              "ace-bundle" => { ".ace" => { "git" => { "commit.yml" => "model: bundle" } } }
            ) do |tmpdir|
              scanner = ProjectConfigScanner.new(project_root: tmpdir)
              result = scanner.scan

              assert result.key?(".")
              assert result.key?("ace-bundle")
              assert_includes result["."], "git/commit.yml"
              assert_includes result["ace-bundle"], "git/commit.yml"
            end
          end

          def test_scan_skips_git_directory
            with_temp_config(
              ".git" => { ".ace" => { "settings.yml" => "key: val" } },
              ".ace" => { "settings.yml" => "key: root" }
            ) do |tmpdir|
              scanner = ProjectConfigScanner.new(project_root: tmpdir)
              result = scanner.scan

              assert result.key?(".")
              refute result.any? { |k, _| k.include?(".git") }
            end
          end

          def test_scan_skips_vendor_directory
            with_temp_config(
              ".git" => "",
              "vendor" => { "gem" => { ".ace" => { "settings.yml" => "key: val" } } },
              ".ace" => { "settings.yml" => "key: root" }
            ) do |tmpdir|
              scanner = ProjectConfigScanner.new(project_root: tmpdir)
              result = scanner.scan

              refute result.any? { |k, _| k.include?("vendor") }
            end
          end

          def test_scan_skips_node_modules_directory
            with_temp_config(
              ".git" => "",
              "node_modules" => { "pkg" => { ".ace" => { "settings.yml" => "key: val" } } },
              ".ace" => { "settings.yml" => "key: root" }
            ) do |tmpdir|
              scanner = ProjectConfigScanner.new(project_root: tmpdir)
              result = scanner.scan

              refute result.any? { |k, _| k.include?("node_modules") }
            end
          end

          def test_scan_includes_empty_ace_folder_with_empty_list
            with_temp_config(
              ".git" => "",
              ".ace" => {}
            ) do |tmpdir|
              scanner = ProjectConfigScanner.new(project_root: tmpdir)
              result = scanner.scan

              assert result.key?(".")
              assert_equal [], result["."]
            end
          end

          def test_scan_includes_deeply_nested_ace_folders
            with_temp_config(
              ".git" => "",
              ".ace" => { "settings.yml" => "key: root" },
              "pkg" => { "sub" => { ".ace" => { "settings.yml" => "key: sub" } } }
            ) do |tmpdir|
              scanner = ProjectConfigScanner.new(project_root: tmpdir)
              result = scanner.scan

              assert result.key?(".")
              assert result.key?("pkg/sub")
            end
          end

          def test_scan_returns_relative_keys_not_absolute
            with_temp_config(
              ".git" => "",
              ".ace" => { "settings.yml" => "key: val" },
              "subpkg" => { ".ace" => { "settings.yml" => "key: sub" } }
            ) do |tmpdir|
              scanner = ProjectConfigScanner.new(project_root: tmpdir)
              result = scanner.scan

              result.each_key do |key|
                refute key.start_with?("/"), "Key #{key.inspect} should be relative"
              end
            end
          end

          def test_scan_config_files_are_relative_to_ace_dir
            with_temp_config(
              ".git" => "",
              ".ace" => { "git" => { "commit.yml" => "model: default" } }
            ) do |tmpdir|
              scanner = ProjectConfigScanner.new(project_root: tmpdir)
              result = scanner.scan

              assert_includes result["."], "git/commit.yml"
              result["."].each do |file|
                refute file.start_with?("/"), "File #{file.inspect} should be relative to .ace dir"
              end
            end
          end

          def test_scan_uses_custom_config_dir
            with_temp_config(
              ".git" => "",
              ".myconf" => { "settings.yml" => "key: val" }
            ) do |tmpdir|
              scanner = ProjectConfigScanner.new(project_root: tmpdir, config_dir: ".myconf")
              result = scanner.scan

              assert result.key?(".")
              assert_includes result["."], "settings.yml"
            end
          end

          def test_scan_defaults_to_current_directory
            with_temp_config(
              ".git" => "",
              ".ace" => { "settings.yml" => "key: val" }
            ) do |_tmpdir|
              # Dir.chdir is set by with_temp_config, so Dir.pwd is tmpdir
              scanner = ProjectConfigScanner.new
              result = scanner.scan

              assert result.key?(".")
            end
          end

          # find_all tests

          def test_find_all_returns_empty_hash_when_no_match
            with_temp_config(
              ".git" => "",
              ".ace" => { "lint" => { "kramdown.yml" => "key: val" } }
            ) do |tmpdir|
              scanner = ProjectConfigScanner.new(project_root: tmpdir)
              result = scanner.find_all(namespace: "git", filename: "commit")

              assert_equal({}, result)
            end
          end

          def test_find_all_returns_matching_configs
            with_temp_config(
              ".git" => "",
              ".ace" => { "git" => { "commit.yml" => "model: root" } },
              "ace-bundle" => { ".ace" => { "git" => { "commit.yml" => "model: bundle" } } }
            ) do |tmpdir|
              scanner = ProjectConfigScanner.new(project_root: tmpdir)
              result = scanner.find_all(namespace: "git", filename: "commit")

              assert result.key?(".")
              assert result.key?("ace-bundle")
              assert result["."].end_with?("git/commit.yml")
              assert result["ace-bundle"].end_with?("git/commit.yml")
            end
          end

          def test_find_all_returns_absolute_paths
            with_temp_config(
              ".git" => "",
              ".ace" => { "git" => { "commit.yml" => "model: default" } }
            ) do |tmpdir|
              scanner = ProjectConfigScanner.new(project_root: tmpdir)
              result = scanner.find_all(namespace: "git", filename: "commit")

              assert result["."].start_with?("/"), "Expected absolute path, got #{result['.'].inspect}"
              assert File.exist?(result["."]), "Expected file to exist at #{result['.']}"
            end
          end

          def test_find_all_matches_yaml_extension
            with_temp_config(
              ".git" => "",
              ".ace" => { "git" => { "commit.yaml" => "model: default" } }
            ) do |tmpdir|
              scanner = ProjectConfigScanner.new(project_root: tmpdir)
              result = scanner.find_all(namespace: "git", filename: "commit")

              assert result.key?(".")
              assert result["."].end_with?("commit.yaml")
            end
          end

          def test_find_all_prefers_yml_over_yaml
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "git" => {
                  "commit.yml" => "model: yml",
                  "commit.yaml" => "model: yaml"
                }
              }
            ) do |tmpdir|
              scanner = ProjectConfigScanner.new(project_root: tmpdir)
              result = scanner.find_all(namespace: "git", filename: "commit")

              assert result["."].end_with?("commit.yml")
            end
          end

          def test_find_all_skips_locations_without_match
            with_temp_config(
              ".git" => "",
              ".ace" => { "git" => { "commit.yml" => "model: root" } },
              "ace-bundle" => { ".ace" => { "lint" => { "kramdown.yml" => "key: val" } } }
            ) do |tmpdir|
              scanner = ProjectConfigScanner.new(project_root: tmpdir)
              result = scanner.find_all(namespace: "git", filename: "commit")

              assert result.key?(".")
              refute result.key?("ace-bundle")
            end
          end
        end
      end
    end
  end
end
