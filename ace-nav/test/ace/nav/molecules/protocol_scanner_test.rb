# frozen_string_literal: true

require "test_helper"
require "ace/nav/molecules/protocol_scanner"

module Ace
  module Nav
    module Molecules
      class ProtocolScannerTest < Minitest::Test
        def setup
          @test_dir = setup_test_environment
          @config_loader = create_test_config_loader(@test_dir)
          @scanner = ProtocolScanner.new(config_loader: @config_loader)
        end

        def teardown
          cleanup_temp_directory(@test_dir)
        end

        def test_sources_for_protocol
          # Add source for test protocol
          create_test_source(@test_dir, "test", "scanner_source", {
            "path" => File.join(@test_dir, "test-resources", "test"),
            "priority" => 15
          })

          Dir.chdir(@test_dir) do
            sources = @scanner.sources_for_protocol("test")

            # Should find the source we created
            scanner_source = sources.find { |s| s.name == "scanner_source" }
            assert scanner_source
            assert_equal 15, scanner_source.priority
          end
        end

        def test_find_resources_with_pattern
          # Create test resources matching pattern
          resource_dir = File.join(@test_dir, "test-resources", "test")
          FileUtils.mkdir_p(resource_dir)

          File.write(File.join(resource_dir, "setup.test.md"), "# Setup")
          File.write(File.join(resource_dir, "demo.test.md"), "# Demo")
          File.write(File.join(resource_dir, "sample.test.md"), "# Sample")

          Dir.chdir(@test_dir) do
            # Find resources matching "setup"
            resources = @scanner.find_resources("test", "setup")

            assert_equal 1, resources.length
            assert resources[0][:relative_path].include?("setup")
          end
        end

        def test_find_resources_with_wildcard
          # Create nested test resources
          resource_dir = File.join(@test_dir, "test-resources", "test")
          subdirs = File.join(resource_dir, "admin", "users")
          FileUtils.mkdir_p(subdirs)

          File.write(File.join(resource_dir, "root.test.md"), "# Root")
          File.write(File.join(subdirs, "nested.test.md"), "# Nested")

          Dir.chdir(@test_dir) do
            # Find all resources
            resources = @scanner.find_resources("test", "*")

            assert_equal 4, resources.length # 2 new + 2 from setup_test_environment

            paths = resources.map { |r| r[:relative_path] }
            assert paths.any? { |p| p.include?("root") }
            assert paths.any? { |p| p.include?("admin/users/nested") }
          end
        end

        def test_find_resources_filters_by_extensions
          # Create resources with different extensions
          resource_dir = File.join(@test_dir, "test-resources", "test")
          FileUtils.mkdir_p(resource_dir)

          File.write(File.join(resource_dir, "valid.test.md"), "# Valid")
          File.write(File.join(resource_dir, "also_valid.tst.md"), "# Also valid")
          File.write(File.join(resource_dir, "invalid.txt"), "Not matched")

          Dir.chdir(@test_dir) do
            resources = @scanner.find_resources("test", "*")

            # Should only match files with protocol extensions
            paths = resources.map { |r| File.basename(r[:path]) }
            assert paths.include?("valid.test.md")
            assert paths.include?("also_valid.tst.md")
            refute paths.include?("invalid.txt")
          end
        end

        def test_find_resources_in_multiple_sources
          # Create secondary source
          secondary_dir = File.join(@test_dir, "secondary-resources", "test")
          FileUtils.mkdir_p(secondary_dir)
          File.write(File.join(secondary_dir, "secondary.test.md"), "# Secondary")

          create_test_source(@test_dir, "test", "secondary", {
            "path" => secondary_dir,
            "priority" => 20
          })

          Dir.chdir(@test_dir) do
            resources = @scanner.find_resources("test", "*")

            # Should find resources from both sources
            paths = resources.map { |r| File.basename(r[:path]) }
            assert paths.include?("sample.test.md") # From primary
            assert paths.include?("secondary.test.md") # From secondary
          end
        end

        def test_find_resources_skips_nonexistent_sources
          # Create source pointing to nonexistent directory
          create_test_source(@test_dir, "test", "missing", {
            "path" => "/nonexistent/path",
            "priority" => 5
          })

          Dir.chdir(@test_dir) do
            # Should not crash, just skip missing source
            resources = @scanner.find_resources("test", "*")
            assert resources.is_a?(Array)
          end
        end

        def test_find_resources_removes_extension_from_relative_path
          resource_dir = File.join(@test_dir, "test-resources", "test")
          FileUtils.mkdir_p(resource_dir)

          File.write(File.join(resource_dir, "document.test.md"), "# Document")

          Dir.chdir(@test_dir) do
            resources = @scanner.find_resources("test", "document")

            assert_equal 1, resources.length
            # Extension should be removed from relative path
            assert_equal "document", resources[0][:relative_path]
          end
        end

        def test_scan_all_sources_legacy_compatibility
          # Create sources for multiple protocols
          create_test_source(@test_dir, "example", "ex_source", {
            "path" => File.join(@test_dir, "example-resources")
          })

          Dir.chdir(@test_dir) do
            sources = @scanner.scan_all_sources

            # Should return HandbookSource objects for compatibility
            assert sources.all? { |s| s.is_a?(Models::HandbookSource) }

            # Should have sources from both protocols
            names = sources.map(&:name)
            assert names.include?("local") # From test protocol
            assert names.include?("ex_source") # From example protocol
          end
        end

        def test_scan_source_by_alias_project
          Dir.chdir(@test_dir) do
            # Create project .ace directory
            FileUtils.mkdir_p(File.join(@test_dir, ".ace"))

            source = @scanner.scan_source_by_alias("@project")

            assert source
            assert_equal "project", source.name
            assert_equal "@project", source.alias_name
            assert_equal :project, source.type
            assert_equal 10, source.priority
          end
        end

        def test_scan_source_by_alias_user
          # Ensure user .ace directory exists
          user_ace = File.expand_path("~/.ace")
          FileUtils.mkdir_p(user_ace)

          source = @scanner.scan_source_by_alias("@user")

          assert source
          assert_equal "user", source.name
          assert_equal "@user", source.alias_name
          assert_equal :user, source.type
          assert_equal 20, source.priority
        ensure
          # Don't remove user directory as it might contain real config
        end

        def test_scan_source_by_alias_registered
          create_test_source(@test_dir, "test", "custom", {
            "path" => "/custom/path",
            "type" => "git"
          })

          Dir.chdir(@test_dir) do
            source = @scanner.scan_source_by_alias("@custom")

            assert source
            assert_equal "custom", source.name
            assert_equal "@custom", source.alias_name
            assert_equal :git, source.type
          end
        end

        def test_scan_source_by_alias_not_found
          source = @scanner.scan_source_by_alias("@nonexistent")
          assert_nil source
        end

        def test_find_resources_with_no_extensions
          # Create protocol without extensions
          create_test_protocol(@test_dir, "any", {
            "extensions" => []
          })

          # Create resources
          resource_dir = File.join(@test_dir, "any-resources")
          FileUtils.mkdir_p(resource_dir)
          File.write(File.join(resource_dir, "file.txt"), "Text")
          File.write(File.join(resource_dir, "script.rb"), "Ruby")

          create_test_source(@test_dir, "any", "any_source", {
            "path" => resource_dir
          })

          Dir.chdir(@test_dir) do
            @config_loader = create_test_config_loader(@test_dir)
            @scanner = ProtocolScanner.new(config_loader: @config_loader)

            resources = @scanner.find_resources("any", "*")

            # Should match all files when no extensions specified
            assert_equal 2, resources.length
            paths = resources.map { |r| File.basename(r[:path]) }
            assert_includes paths, "file.txt"
            assert_includes paths, "script.rb"
          end
        end

        def test_find_resources_in_source_internal_with_protocol_source
          # Test the internal method directly with ProtocolSource
          create_test_source(@test_dir, "test", "internal", {
            "path" => File.join(@test_dir, "test-resources", "test")
          })

          Dir.chdir(@test_dir) do
            sources = @scanner.sources_for_protocol("test")
            internal_source = sources.find { |s| s.name == "internal" }

            protocol_config = @config_loader.load_protocol_config("test")
            resources = @scanner.find_resources_in_source_internal(
              internal_source,
              protocol_config,
              "*"
            )

            # Should find the test resources
            assert resources.length > 0
          end
        end

        def test_create_resource_info_structure
          resource_dir = File.join(@test_dir, "test-resources", "test")
          FileUtils.mkdir_p(resource_dir)
          file_path = File.join(resource_dir, "info.test.md")
          File.write(file_path, "# Info")

          Dir.chdir(@test_dir) do
            resources = @scanner.find_resources("test", "info")

            assert_equal 1, resources.length
            resource = resources[0]

            # Check resource info structure
            assert_equal file_path, resource[:path]
            assert_equal "info", resource[:relative_path]
            assert resource[:source]
            assert_equal "test", resource[:protocol]
          end
        end
      end
    end
  end
end