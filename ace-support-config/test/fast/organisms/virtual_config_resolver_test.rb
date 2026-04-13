# frozen_string_literal: true

require "test_helper"

module Ace
  module Support
    module Config
      module Organisms
        class VirtualConfigResolverTest < TestCase
          def test_resolve_path_returns_absolute_path
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "presets" => {
                  "default.yml" => "key: value"
                }
              }
            ) do |tmpdir|
              resolver = VirtualConfigResolver.new(start_path: tmpdir)

              path = resolver.resolve_path("presets/default.yml")

              assert path
              assert path.end_with?("presets/default.yml")
              assert File.exist?(path)
            end
          end

          def test_resolve_path_returns_nil_for_missing
            with_temp_config(
              ".git" => "",
              ".ace" => {}
            ) do |tmpdir|
              resolver = VirtualConfigResolver.new(start_path: tmpdir)

              path = resolver.resolve_path("nonexistent.yml")

              assert_nil path
            end
          end

          def test_resolve_path_normalizes_input
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "file.yml" => "key: value"
              }
            ) do |tmpdir|
              resolver = VirtualConfigResolver.new(start_path: tmpdir)

              # Should handle various input formats
              path1 = resolver.resolve_path("file.yml")
              path2 = resolver.resolve_path("./file.yml")
              path3 = resolver.resolve_path(".ace/file.yml")

              assert path1
              assert path2
              assert path3
            end
          end

          def test_glob_returns_matching_files
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "presets" => {
                  "a.yml" => "a: 1",
                  "b.yml" => "b: 2"
                },
                "other.txt" => "text"
              }
            ) do |tmpdir|
              resolver = VirtualConfigResolver.new(start_path: tmpdir)

              matches = resolver.glob("presets/*.yml")

              assert_equal 2, matches.size
              assert matches.key?("presets/a.yml")
              assert matches.key?("presets/b.yml")
            end
          end

          def test_glob_with_double_star
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "a" => {
                  "b" => {
                    "file.yml" => "key: value"
                  }
                }
              }
            ) do |tmpdir|
              resolver = VirtualConfigResolver.new(start_path: tmpdir)

              matches = resolver.glob("**/*.yml")

              assert_operator matches.size, :>=, 1
            end
          end

          def test_glob_returns_empty_for_no_matches
            with_temp_config(
              ".git" => "",
              ".ace" => {}
            ) do |tmpdir|
              resolver = VirtualConfigResolver.new(start_path: tmpdir)

              matches = resolver.glob("*.xyz")

              assert_empty matches
            end
          end

          def test_exists_returns_true_for_existing
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "file.yml" => "key: value"
              }
            ) do |tmpdir|
              resolver = VirtualConfigResolver.new(start_path: tmpdir)

              assert resolver.exists?("file.yml")
            end
          end

          def test_exists_returns_false_for_missing
            with_temp_config(
              ".git" => "",
              ".ace" => {}
            ) do |tmpdir|
              resolver = VirtualConfigResolver.new(start_path: tmpdir)

              refute resolver.exists?("nonexistent.yml")
            end
          end

          def test_config_directories_returns_ordered_list
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "root.yml" => "level: root"
              },
              "subdir" => {
                ".ace" => {
                  "sub.yml" => "level: sub"
                }
              }
            ) do |tmpdir|
              Dir.chdir(File.join(tmpdir, "subdir")) do
                resolver = VirtualConfigResolver.new(start_path: Dir.pwd)

                dirs = resolver.config_directories

                # Nearer directories should be first
                assert_operator dirs.size, :>=, 2
                assert dirs.first.include?("subdir")
              end
            end
          end

          def test_nearer_config_wins
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "shared.yml" => "level: root"
              },
              "subdir" => {
                ".ace" => {
                  "shared.yml" => "level: subdir"
                }
              }
            ) do |tmpdir|
              Dir.chdir(File.join(tmpdir, "subdir")) do
                resolver = VirtualConfigResolver.new(start_path: Dir.pwd)

                path = resolver.resolve_path("shared.yml")

                # Should return the nearer (subdir) version
                assert path.include?("subdir")
              end
            end
          end

          def test_reload_refreshes_virtual_map
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "initial.yml" => "key: value"
              }
            ) do |tmpdir|
              resolver = VirtualConfigResolver.new(start_path: tmpdir)

              assert resolver.exists?("initial.yml")

              # Add new file
              File.write(File.join(tmpdir, ".ace", "new.yml"), "new: value")

              # Should not exist until reload
              refute resolver.exists?("new.yml")

              resolver.reload!

              assert resolver.exists?("new.yml")
            end
          end

          def test_custom_config_dir
            with_temp_config(
              ".git" => "",
              ".my-app" => {
                "file.yml" => "key: value"
              }
            ) do |tmpdir|
              resolver = VirtualConfigResolver.new(
                config_dir: ".my-app",
                start_path: tmpdir
              )

              assert resolver.exists?("file.yml")
            end
          end

          def test_accessors
            resolver = VirtualConfigResolver.new(
              config_dir: ".custom",
              defaults_dir: ".custom-defaults",
              start_path: "/some/path",
              gem_path: "/gem/path"
            )

            assert_equal ".custom", resolver.config_dir
            assert_equal ".custom-defaults", resolver.defaults_dir
            assert_equal "/some/path", resolver.start_path
            assert_equal "/gem/path", resolver.gem_path
          end

          def test_gem_path_defaults_to_nil
            resolver = VirtualConfigResolver.new(start_path: "/some/path")

            assert_nil resolver.gem_path
          end

          def test_gem_defaults_included_in_virtual_map
            with_temp_config(
              ".git" => "",
              ".ace" => {},
              "gem" => {
                ".ace-defaults" => {
                  "presets" => {
                    "default.yml" => "from: gem"
                  }
                }
              }
            ) do |tmpdir|
              resolver = VirtualConfigResolver.new(
                start_path: tmpdir,
                gem_path: File.join(tmpdir, "gem")
              )

              assert resolver.exists?("presets/default.yml")

              path = resolver.resolve_path("presets/default.yml")
              assert path.include?("gem")
              assert path.include?(".ace-defaults")
            end
          end

          def test_gem_defaults_have_lowest_priority
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "shared.yml" => "from: project"
              },
              "gem" => {
                ".ace-defaults" => {
                  "shared.yml" => "from: gem"
                }
              }
            ) do |tmpdir|
              resolver = VirtualConfigResolver.new(
                start_path: tmpdir,
                gem_path: File.join(tmpdir, "gem")
              )

              path = resolver.resolve_path("shared.yml")

              # Project config should override gem defaults
              refute path.include?("gem")
              assert path.include?(".ace")
            end
          end

          def test_gem_defaults_provide_fallback
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "project.yml" => "from: project"
              },
              "gem" => {
                ".ace-defaults" => {
                  "gem-only.yml" => "from: gem"
                }
              }
            ) do |tmpdir|
              resolver = VirtualConfigResolver.new(
                start_path: tmpdir,
                gem_path: File.join(tmpdir, "gem")
              )

              # Project file exists
              assert resolver.exists?("project.yml")
              # Gem-only file also available as fallback
              assert resolver.exists?("gem-only.yml")

              path = resolver.resolve_path("gem-only.yml")
              assert path.include?("gem")
            end
          end

          def test_gem_defaults_in_config_directories
            with_temp_config(
              ".git" => "",
              ".ace" => {},
              "gem" => {
                ".ace-defaults" => {
                  "file.yml" => "key: value"
                }
              }
            ) do |tmpdir|
              resolver = VirtualConfigResolver.new(
                start_path: tmpdir,
                gem_path: File.join(tmpdir, "gem")
              )

              dirs = resolver.config_directories

              # Gem defaults should be last in the list (lowest priority)
              assert dirs.last.include?(".ace-defaults")
            end
          end

          def test_glob_includes_gem_defaults
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "presets" => {
                  "project.yml" => "from: project"
                }
              },
              "gem" => {
                ".ace-defaults" => {
                  "presets" => {
                    "gem.yml" => "from: gem"
                  }
                }
              }
            ) do |tmpdir|
              resolver = VirtualConfigResolver.new(
                start_path: tmpdir,
                gem_path: File.join(tmpdir, "gem")
              )

              matches = resolver.glob("presets/*.yml")

              # Should find files from both project and gem
              assert matches.key?("presets/project.yml")
              assert matches.key?("presets/gem.yml")
            end
          end

          def test_virtual_map_is_hash
            with_temp_config(
              ".git" => "",
              ".ace" => {}
            ) do |tmpdir|
              resolver = VirtualConfigResolver.new(start_path: tmpdir)

              assert_instance_of Hash, resolver.virtual_map
            end
          end

          def test_handles_empty_config_directory
            with_temp_config(
              ".git" => "",
              ".ace" => {}
            ) do |tmpdir|
              resolver = VirtualConfigResolver.new(start_path: tmpdir)

              # Should not raise
              matches = resolver.glob("*")

              assert_instance_of Hash, matches
            end
          end

          def test_handles_nested_directories
            with_temp_config(
              ".git" => "",
              ".ace" => {
                "a" => {
                  "b" => {
                    "c" => {
                      "deep.yml" => "key: value"
                    }
                  }
                }
              }
            ) do |tmpdir|
              resolver = VirtualConfigResolver.new(start_path: tmpdir)

              path = resolver.resolve_path("a/b/c/deep.yml")

              assert path
              assert File.exist?(path)
            end
          end
        end
      end
    end
  end
end
