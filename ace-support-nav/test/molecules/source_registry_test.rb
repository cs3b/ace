# frozen_string_literal: true

require "test_helper"
require "ace/support/nav/molecules/source_registry"

module Ace
  module Support
    module Nav
      module Molecules
        class SourceRegistryTest < Minitest::Test
          def setup
            @test_dir = setup_test_environment
            @registry = SourceRegistry.new
          end

          def teardown
            cleanup_temp_directory(@test_dir)
          end

          def test_discovers_project_sources
            # Create test source files
            create_test_source(@test_dir, "test", "local", {
              "path" => "/test/path",
              "priority" => 10
            })

            create_test_source(@test_dir, "test", "secondary", {
              "path" => "/secondary/path",
              "priority" => 20
            })

            Dir.chdir(@test_dir) do
              sources = @registry.sources_for_protocol("test")

              assert_equal 2, sources.length

              # Should be sorted by priority
              assert_equal "local", sources[0].name
              assert_equal 10, sources[0].priority
              assert_equal "/test/path", sources[0].path

              assert_equal "secondary", sources[1].name
              assert_equal 20, sources[1].priority
              assert_equal "/secondary/path", sources[1].path
            end
          end

          def test_discovers_user_sources
            old_home = ENV["HOME"]
            temp_home = Dir.mktmpdir("ace_nav_home")
            ENV["HOME"] = temp_home

            # Create user source directory
            user_sources_dir = File.join(temp_home, ".ace", "nav", "protocols", "example-sources")
            FileUtils.mkdir_p(user_sources_dir)

            user_source = {
              "name" => "user_source",
              "type" => "directory",
              "path" => "~/user/examples",
              "priority" => 30
            }

            File.write(File.join(user_sources_dir, "user.yml"), user_source.to_yaml)

            sources = @registry.sources_for_protocol("example")

            user_source = sources.find { |s| s.name == "user_source" }
            assert user_source, "Should find user source"
            assert_equal "directory", user_source.type
            assert_equal 30, user_source.priority
          ensure
            ENV["HOME"] = old_home
            FileUtils.rm_rf(temp_home) if temp_home && Dir.exist?(temp_home)
          end

          def test_sources_sorted_by_priority
            # Use a fresh test dir without pre-created sources
            fresh_dir = create_temp_ace_directory

            # Create sources with different priorities
            create_test_source(fresh_dir, "test", "high", {
              "priority" => 5
            })

            create_test_source(fresh_dir, "test", "low", {
              "priority" => 100
            })

            create_test_source(fresh_dir, "test", "medium", {
              "priority" => 50
            })

            Dir.chdir(fresh_dir) do
              sources = @registry.sources_for_protocol("test")

              names = sources.map(&:name)
              assert_equal ["high", "medium", "low"], names
            end
          ensure
            cleanup_temp_directory(fresh_dir)
          end

          def test_expands_environment_variables
            # Set test environment variable
            ENV["TEST_VAR"] = "/test/value"
            ENV["PROJECT_ROOT_PATH"] = @test_dir

            create_test_source(@test_dir, "test", "env_source", {
              "path" => "$TEST_VAR/resources"
            })

            create_test_source(@test_dir, "test", "project_source", {
              "path" => "$PROJECT_ROOT_PATH/ace-handbook/handbook"
            })

            Dir.chdir(@test_dir) do
              sources = @registry.sources_for_protocol("test")

              env_source = sources.find { |s| s.name == "env_source" }
              assert_equal "/test/value/resources", env_source.path

              project_source = sources.find { |s| s.name == "project_source" }
              assert_equal "#{@test_dir}/ace-handbook/handbook", project_source.path
            end
          ensure
            ENV.delete("TEST_VAR")
          end

          def test_expands_home_variable
            create_test_source(@test_dir, "test", "home_source", {
              "path" => "$HOME/documents"
            })

            Dir.chdir(@test_dir) do
              sources = @registry.sources_for_protocol("test")

              home_source = sources.find { |s| s.name == "home_source" }
              assert_equal "#{ENV["HOME"]}/documents", home_source.path
            end
          end

          def test_caches_sources
            create_test_source(@test_dir, "test", "cached", {})

            Dir.chdir(@test_dir) do
              # First call should discover sources
              sources1 = @registry.sources_for_protocol("test")

              # Modify the source file
              create_test_source(@test_dir, "test", "cached", {
                "path" => "/new/path"
              })

              # Second call should return cached version
              sources2 = @registry.sources_for_protocol("test")

              assert_equal sources1.object_id, sources2.object_id
            end
          end

          def test_clear_cache
            create_test_source(@test_dir, "test", "cached", {
              "path" => "/old/path"
            })

            Dir.chdir(@test_dir) do
              # Load and cache sources
              sources1 = @registry.sources_for_protocol("test")
              cached = sources1.find { |s| s.name == "cached" }
              assert_equal "/old/path", cached.path

              # Modify the source
              create_test_source(@test_dir, "test", "cached", {
                "path" => "/new/path"
              })

              # Clear cache
              @registry.clear_cache

              # Should reload from disk
              sources2 = @registry.sources_for_protocol("test")
              cached = sources2.find { |s| s.name == "cached" }
              assert_equal "/new/path", cached.path
            end
          end

          def test_handles_malformed_yaml_gracefully
            # Use fresh dir to avoid pre-created sources
            fresh_dir = create_temp_ace_directory

            sources_dir = File.join(fresh_dir, ".ace", "protocols", "test-sources")
            FileUtils.mkdir_p(sources_dir)

            # Write malformed YAML
            File.write(File.join(sources_dir, "bad.yml"), "not: valid: yaml: here")

            # Write valid source
            create_test_source(fresh_dir, "test", "good", {
              "path" => "/good/path"
            })

            Dir.chdir(fresh_dir) do
              sources = @registry.sources_for_protocol("test")

              # Should skip bad source but include good one
              assert_equal 1, sources.length
              assert_equal "good", sources[0].name
            end
          ensure
            cleanup_temp_directory(fresh_dir)
          end

          def test_default_priority_by_origin
            # Create project source without explicit priority
            create_test_source(@test_dir, "test", "project", {})

            Dir.chdir(@test_dir) do
              sources = @registry.sources_for_protocol("test")
              project_source = sources.find { |s| s.name == "project" }

              # Project sources get priority 10 by default
              assert_equal 10, project_source.priority
              assert_equal "project", project_source.origin
            end
          end

          def test_discovers_sources_from_hierarchy
            # Use fresh directory to avoid conflicts
            fresh_dir = create_temp_ace_directory

            # Create nested .ace directories
            parent_dir = File.join(fresh_dir, "parent")
            child_dir = File.join(parent_dir, "child")
            FileUtils.mkdir_p(child_dir)

            # Create source in parent
            parent_sources_dir = File.join(parent_dir, ".ace", "nav/protocols", "test-sources")
            FileUtils.mkdir_p(parent_sources_dir)
            File.write(File.join(parent_sources_dir, "parent.yml"), {
              "name" => "parent_source",
              "path" => "/parent/path",
              "priority" => 20
            }.to_yaml)

            # Create source in child
            child_sources_dir = File.join(child_dir, ".ace", "nav/protocols", "test-sources")
            FileUtils.mkdir_p(child_sources_dir)
            File.write(File.join(child_sources_dir, "child.yml"), {
              "name" => "child_source",
              "path" => "/child/path",
              "priority" => 10
            }.to_yaml)

            Dir.chdir(child_dir) do
              sources = @registry.sources_for_protocol("test")

              # Should find both sources
              assert_equal 2, sources.length

              # Child source should come first (lower priority number)
              assert_equal "child_source", sources[0].name
              assert_equal "parent_source", sources[1].name
            end
          ensure
            cleanup_temp_directory(fresh_dir)
          end

          def test_protocol_source_attributes
            create_test_source(@test_dir, "test", "detailed", {
              "type" => "git",
              "path" => "/detailed/path",
              "priority" => 15,
              "description" => "A detailed source"
            })

            Dir.chdir(@test_dir) do
              sources = @registry.sources_for_protocol("test")
              detailed = sources.find { |s| s.name == "detailed" }

              assert_equal "detailed", detailed.name
              assert_equal "git", detailed.type
              assert_equal "/detailed/path", detailed.path
              assert_equal 15, detailed.priority
              assert_equal "A detailed source", detailed.description
              assert_equal "@detailed", detailed.alias_name
            end
          end

          def test_empty_sources_for_unknown_protocol
            sources = @registry.sources_for_protocol("nonexistent")
            assert_empty sources
          end

          def test_loads_gem_skill_source_with_config
            fresh_dir = create_temp_ace_directory

            create_test_source(fresh_dir, "skill", "ace-task", {
              "type" => "gem",
              "priority" => 10,
              "description" => "Canonical skills from ace-task gem",
              "config" => {
                "relative_path" => "handbook/skills",
                "pattern" => "*/SKILL.md",
                "enabled" => true
              }
            })

            Dir.chdir(fresh_dir) do
              sources = @registry.sources_for_protocol("skill")
              source = sources.find { |s| s.name == "ace-task" }

              assert source
              assert_equal "gem", source.type
              assert_nil source.path
              assert_equal 10, source.priority
              assert_equal "handbook/skills", source.config["relative_path"]
              assert_equal "*/SKILL.md", source.config["pattern"]
            end
          ensure
            cleanup_temp_directory(fresh_dir)
          end

          def test_uses_explicit_start_path_for_project_source_discovery
            fresh_dir = create_temp_ace_directory
            nested_dir = File.join(fresh_dir, "nested", "workspace")
            FileUtils.mkdir_p(nested_dir)

            create_test_source(fresh_dir, "skill", "root_source", {
              "path" => "/registered/from/root",
              "priority" => 10
            })

            registry = SourceRegistry.new(start_path: nested_dir)
            sources = registry.sources_for_protocol("skill")

            source = sources.find { |entry| entry.name == "root_source" }
            assert source
            assert_equal "/registered/from/root", source.path
          ensure
            cleanup_temp_directory(fresh_dir)
          end

          def test_discovers_gem_default_sources
            isolated_dir = create_temp_ace_directory
            registry = SourceRegistry.new(start_path: isolated_dir)
            gem_dir = Dir.mktmpdir("ace_nav_gem")
            cookbook_dir = File.join(gem_dir, "handbook", "cookbooks")
            FileUtils.mkdir_p(cookbook_dir)

            sources_dir = File.join(gem_dir, ".ace-defaults", "nav", "protocols", "cookbook-sources")
            FileUtils.mkdir_p(sources_dir)
            File.write(File.join(sources_dir, "ace-handbook.yml"), {
              "name" => "ace-handbook",
              "type" => "gem",
              "config" => {
                "relative_path" => "handbook/cookbooks",
                "pattern" => "*.cookbook.md",
                "enabled" => true
              }
            }.to_yaml)

            fake_spec = Struct.new(:name, :gem_dir).new("ace-handbook", gem_dir)
            stubbed_each = proc do |&block|
              [fake_spec].each(&block)
            end

            Gem::Specification.stub(:each, stubbed_each) do
              Gem::Specification.stub(:find_by_name, fake_spec) do
                sources = registry.sources_for_protocol("cookbook")
                source = sources.find { |entry| entry.name == "ace-handbook" && entry.origin == "gem-default" }

                assert source
                assert_equal "gem", source.type
                assert_equal "gem-default", source.origin
                assert_equal 100, source.priority
                assert_nil source.path
                assert_equal "handbook/cookbooks", source.config["relative_path"]
                assert_equal cookbook_dir, source.full_path
              end
            end
          ensure
            cleanup_temp_directory(isolated_dir)
            cleanup_temp_directory(gem_dir)
          end
        end
      end
    end
  end
end
