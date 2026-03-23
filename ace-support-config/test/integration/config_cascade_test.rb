# frozen_string_literal: true

require "test_helper"

module Ace
  module Support
    module Config
      class ConfigCascadeTest < TestCase
        def test_create_returns_resolver
          resolver = Ace::Support::Config.create

          assert_instance_of Organisms::ConfigResolver, resolver
        end

        def test_create_with_custom_config_dir
          resolver = Ace::Support::Config.create(config_dir: ".my-app")

          assert_equal ".my-app", resolver.config_dir
        end

        def test_create_with_custom_defaults_dir
          resolver = Ace::Support::Config.create(defaults_dir: ".my-defaults")

          assert_equal ".my-defaults", resolver.defaults_dir
        end

        def test_create_with_gem_path
          resolver = Ace::Support::Config.create(gem_path: "/some/gem/path")

          assert_equal "/some/gem/path", resolver.gem_path
        end

        def test_cascade_with_temp_config
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "key: project_value"
            }
          ) do |_tmpdir|
            resolver = Ace::Support::Config.create
            config = resolver.resolve

            assert_equal "project_value", config.get("key")
          end
        end

        def test_cascade_merges_configs
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "settings.yml" => "base_key: base\noverride_key: will_be_overridden"
            },
            "subdir" => {
              ".ace" => {
                "settings.yml" => "override_key: overridden\nnew_key: new"
              }
            }
          ) do |tmpdir|
            # Work from the subdir
            Dir.chdir(File.join(tmpdir, "subdir")) do
              resolver = Ace::Support::Config.create
              config = resolver.resolve

              assert_equal "base", config.get("base_key")
              assert_equal "overridden", config.get("override_key")
              assert_equal "new", config.get("new_key")
            end
          end
        end

        def test_resolve_for_specific_patterns
          with_temp_config(
            ".git" => "",
            ".ace" => {
              "custom.yml" => "custom_key: custom_value"
            }
          ) do |_tmpdir|
            resolver = Ace::Support::Config.create
            config = resolver.resolve_for(["custom.yml"])

            assert_equal "custom_value", config.get("custom_key")
          end
        end

        def test_gem_defaults_lowest_priority
          with_temp_config(
            ".git" => "",
            ".my-defaults" => {
              "config.yml" => "default_key: default\noverride_key: default"
            },
            ".my-app" => {
              "config.yml" => "override_key: user"
            }
          ) do |tmpdir|
            resolver = Ace::Support::Config.create(
              config_dir: ".my-app",
              defaults_dir: ".my-defaults",
              gem_path: tmpdir
            )
            config = resolver.resolve_for(["config.yml"])

            assert_equal "default", config.get("default_key")
            assert_equal "user", config.get("override_key")
          end
        end

        def test_finder_with_custom_dirs
          finder = Ace::Support::Config.finder(
            config_dir: ".custom",
            defaults_dir: ".custom-defaults"
          )

          assert_equal ".custom", finder.config_dir
          assert_equal ".custom-defaults", finder.defaults_dir
        end

        def test_find_project_root
          with_temp_config(".git" => "") do |tmpdir|
            # Clear cache before testing to ensure fresh lookup
            Ace::Support::Fs::Molecules::ProjectRootFinder.clear_cache!

            # Create finder and stub ENV to avoid PROJECT_ROOT_PATH interference
            finder = Ace::Support::Fs::Molecules::ProjectRootFinder.new(start_path: tmpdir)
            finder.stub(:env_project_root, nil) do
              root = finder.find

              assert_equal tmpdir, root
            end
          end
        end

        def test_path_expander
          expander = Ace::Support::Config.path_expander(
            source_dir: "/source",
            project_root: "/project"
          )

          assert_equal "/source", expander.source_dir
          assert_equal "/project", expander.project_root
        end

        def test_virtual_resolver_returns_virtual_config_resolver
          resolver = Ace::Support::Config.virtual_resolver

          assert_instance_of Organisms::VirtualConfigResolver, resolver
        end

        def test_virtual_resolver_with_custom_config_dir
          resolver = Ace::Support::Config.virtual_resolver(config_dir: ".my-app")

          assert_equal ".my-app", resolver.config_dir
        end

        def test_virtual_resolver_with_custom_defaults_dir
          resolver = Ace::Support::Config.virtual_resolver(defaults_dir: ".my-defaults")

          assert_equal ".my-defaults", resolver.defaults_dir
        end

        def test_virtual_resolver_with_start_path
          resolver = Ace::Support::Config.virtual_resolver(start_path: "/some/path")

          assert_equal "/some/path", resolver.start_path
        end
      end
    end
  end
end
