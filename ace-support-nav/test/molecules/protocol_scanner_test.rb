# frozen_string_literal: true

require "test_helper"
require "ace/support/nav/molecules/protocol_scanner"

module Ace
  module Support
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

          def test_find_resources_with_prefix_pattern
            # Test the new prefix pattern functionality (pattern ending with /)
            resource_dir = File.join(@test_dir, "test-resources", "test")
            FileUtils.mkdir_p(resource_dir)

            # Create resources with common prefixes
            File.write(File.join(resource_dir, "create-task.test.md"), "# Create Task")
            File.write(File.join(resource_dir, "create-project.test.md"), "# Create Project")
            File.write(File.join(resource_dir, "create-user.test.md"), "# Create User")
            File.write(File.join(resource_dir, "delete-task.test.md"), "# Delete Task")
            File.write(File.join(resource_dir, "update-task.test.md"), "# Update Task")

            Dir.chdir(@test_dir) do
              # Find resources with "create" prefix using trailing slash
              resources = @scanner.find_resources("test", "create/")

              assert_equal 3, resources.length
              paths = resources.map { |r| r[:relative_path] }

              assert paths.any? { |p| p.include?("create-task") }
              assert paths.any? { |p| p.include?("create-project") }
              assert paths.any? { |p| p.include?("create-user") }
              refute paths.any? { |p| p.include?("delete") }
              refute paths.any? { |p| p.include?("update") }
            end
          end

          def test_find_resources_with_subdirectory_pattern
            # Test actual subdirectory pattern functionality
            resource_dir = File.join(@test_dir, "test-resources", "test")
            subdir = File.join(resource_dir, "admin")
            FileUtils.mkdir_p(subdir)

            # Create resources in subdirectory
            File.write(File.join(subdir, "users.test.md"), "# Admin Users")
            File.write(File.join(subdir, "roles.test.md"), "# Admin Roles")
            File.write(File.join(resource_dir, "main.test.md"), "# Main")

            Dir.chdir(@test_dir) do
              # Find resources in admin/ subdirectory
              resources = @scanner.find_resources("test", "admin/")

              assert_equal 2, resources.length
              paths = resources.map { |r| r[:relative_path] }

              assert paths.any? { |p| p.include?("admin/users") }
              assert paths.any? { |p| p.include?("admin/roles") }
            end
          end

          def test_find_resources_with_nested_subdirectory_pattern
            # Test nested subdirectory pattern functionality
            resource_dir = File.join(@test_dir, "test-resources", "test")
            nested_dir = File.join(resource_dir, "workflows", "create")
            FileUtils.mkdir_p(nested_dir)

            # Create resources in nested subdirectory
            File.write(File.join(nested_dir, "task.test.md"), "# Create Task Workflow")
            File.write(File.join(nested_dir, "project.test.md"), "# Create Project Workflow")
            File.write(File.join(resource_dir, "workflows", "delete.test.md"), "# Delete Workflow")

            Dir.chdir(@test_dir) do
              # Find resources in workflows/create/ subdirectory
              resources = @scanner.find_resources("test", "workflows/create/")

              assert_equal 2, resources.length
              paths = resources.map { |r| r[:relative_path] }

              assert paths.any? { |p| p.include?("workflows/create/task") }
              assert paths.any? { |p| p.include?("workflows/create/project") }
            end
          end

          def test_find_resources_with_exact_subdirectory_path
            # Test exact resource lookup: "namespace/name" resolves to namespace/name.ext
            resource_dir = File.join(@test_dir, "test-resources", "test")
            subdir = File.join(resource_dir, "lint")
            FileUtils.mkdir_p(subdir)

            File.write(File.join(subdir, "run.test.md"), "# Lint Run Workflow")
            File.write(File.join(subdir, "process-report.test.md"), "# Process Report Workflow")

            Dir.chdir(@test_dir) do
              # Exact match: "lint/run" should resolve to lint/run.test.md
              resources = @scanner.find_resources("test", "lint/run")

              assert_equal 1, resources.length
              assert_includes resources.first[:relative_path], "lint/run"
              refute_includes resources.first[:relative_path], "process-report"
            end
          end

          def test_find_resources_with_subdirectory_glob
            # Test glob: "lint/*" resolves all files in lint/ namespace
            resource_dir = File.join(@test_dir, "test-resources", "test")
            subdir = File.join(resource_dir, "lint")
            FileUtils.mkdir_p(subdir)

            File.write(File.join(subdir, "run.test.md"), "# Lint Run")
            File.write(File.join(subdir, "process-report.test.md"), "# Process Report")

            Dir.chdir(@test_dir) do
              resources = @scanner.find_resources("test", "lint/*")

              assert_equal 2, resources.length
              paths = resources.map { |r| r[:relative_path] }
              assert paths.any? { |p| p.include?("lint/run") }
              assert paths.any? { |p| p.include?("lint/process-report") }
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

          def test_find_skill_resources_with_wildcard
            fresh_dir = create_temp_ace_directory

            create_test_protocol(fresh_dir, "skill", {
              "name" => "Canonical Skills",
              "extensions" => ["/SKILL.md"],
              "inferred_extensions" => ["/SKILL.md"]
            })

            primary_root = File.join(fresh_dir, "primary", "handbook", "skills")
            secondary_root = File.join(fresh_dir, "secondary", "handbook", "skills")
            FileUtils.mkdir_p(File.join(primary_root, "as-task-plan"))
            FileUtils.mkdir_p(File.join(secondary_root, "as-assign-drive"))

            File.write(File.join(primary_root, "as-task-plan", "SKILL.md"), "---\nname: as-task-plan\n")
            File.write(File.join(secondary_root, "as-assign-drive", "SKILL.md"), "---\nname: as-assign-drive\n")

            create_test_source(fresh_dir, "skill", "primary-source", {
              "path" => primary_root,
              "priority" => 10
            })
            create_test_source(fresh_dir, "skill", "secondary-source", {
              "path" => secondary_root,
              "priority" => 20
            })

            Dir.chdir(fresh_dir) do
              scanner = ProtocolScanner.new(config_loader: create_test_config_loader(fresh_dir))
              resources = scanner.find_resources("skill", "*")
              paths = resources.map { |r| r[:relative_path] }

              assert_includes paths, "as-task-plan"
              assert_includes paths, "as-assign-drive"
            end
          ensure
            cleanup_temp_directory(fresh_dir)
          end

          def test_find_skill_resource_exact_match_prefers_higher_priority_source
            fresh_dir = create_temp_ace_directory

            create_test_protocol(fresh_dir, "skill", {
              "name" => "Canonical Skills",
              "extensions" => ["/SKILL.md"],
              "inferred_extensions" => ["/SKILL.md"]
            })

            preferred_root = File.join(fresh_dir, "preferred", "handbook", "skills")
            fallback_root = File.join(fresh_dir, "fallback", "handbook", "skills")
            FileUtils.mkdir_p(File.join(preferred_root, "as-task-plan"))
            FileUtils.mkdir_p(File.join(fallback_root, "as-task-plan"))

            preferred_skill = File.join(preferred_root, "as-task-plan", "SKILL.md")
            fallback_skill = File.join(fallback_root, "as-task-plan", "SKILL.md")
            File.write(preferred_skill, "---\nname: as-task-plan\nsource: preferred\n")
            File.write(fallback_skill, "---\nname: as-task-plan\nsource: fallback\n")

            create_test_source(fresh_dir, "skill", "preferred-source", {
              "path" => preferred_root,
              "priority" => 10
            })
            create_test_source(fresh_dir, "skill", "fallback-source", {
              "path" => fallback_root,
              "priority" => 20
            })

            Dir.chdir(fresh_dir) do
              scanner = ProtocolScanner.new(config_loader: create_test_config_loader(fresh_dir))
              resources = scanner.find_resources("skill", "as-task-plan")

              assert_equal 2, resources.length
              assert_equal preferred_skill, resources[0][:path]
              assert_equal "as-task-plan", resources[0][:relative_path]
              assert_equal "preferred-source", resources[0][:source].name
            end
          ensure
            cleanup_temp_directory(fresh_dir)
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
              # Create project handbook override directory
              FileUtils.mkdir_p(File.join(@test_dir, ".ace-handbook"))

              source = @scanner.scan_source_by_alias("@project")

              assert source
              assert_equal "project", source.name
              assert_equal "@project", source.alias_name
              assert_equal :project, source.type
              assert_equal 10, source.priority
            end
          end

          def test_scan_source_by_alias_user
            # Ensure user handbook override directory exists
            user_ace = File.expand_path("~/.ace-handbook")
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

          def test_extension_inference_finds_file_without_extension
            # Create a test protocol with inferred extensions
            create_test_protocol(@test_dir, "guide", {
              "extensions" => [".g.md", ".guide.md", ".md"],
              "inferred_extensions" => [".g", ".guide", ".g.md", ".guide.md", ".md"]
            })

            # Create source for guide protocol
            create_test_source(@test_dir, "guide", "guide_source", {
              "path" => File.join(@test_dir, "guide-resources", "guide")
            })

            # Create a guide file with full extension
            resource_dir = File.join(@test_dir, "guide-resources", "guide")
            FileUtils.mkdir_p(resource_dir)
            File.write(File.join(resource_dir, "markdown-style.g.md"), "# Markdown Style Guide")

            Dir.chdir(@test_dir) do
              @config_loader = create_test_config_loader(@test_dir)
              @scanner = ProtocolScanner.new(config_loader: @config_loader)

              # Find resource using base name without extension - should use inference
              resources = @scanner.find_resources("guide", "markdown-style")

              assert_equal 1, resources.length
              assert resources[0][:path].include?("markdown-style.g.md")
            end
          end

          def test_extension_inference_disabled_returns_no_results
            # Create a test protocol where file extension is NOT in protocol extensions
            create_test_protocol(@test_dir, "custom", {
              "extensions" => [".full.md"],  # Only .full.md is protocol extension
              "inferred_extensions" => [".sh", ".full.md", ".md"]
            })

            create_test_source(@test_dir, "custom", "custom_source", {
              "path" => File.join(@test_dir, "custom-resources", "custom")
            })

            resource_dir = File.join(@test_dir, "custom-resources", "custom")
            FileUtils.mkdir_p(resource_dir)
            # Create file with shorthand extension (not in protocol extensions)
            File.write(File.join(resource_dir, "doc.sh.md"), "# Doc")

            Dir.chdir(@test_dir) do
              # Create config with extension inference disabled
              config_dir = File.join(@test_dir, ".ace", "nav")
              FileUtils.mkdir_p(config_dir)
              File.write(File.join(config_dir, "config.yml"), {
                "extension_inference" => { "enabled" => false }
              }.to_yaml)

              # Reload config loader to pick up the new config
              @config_loader = create_test_config_loader(@test_dir)
              @scanner = ProtocolScanner.new(config_loader: @config_loader)

              # Should not find the resource since:
              # - exact match "doc.full.md" doesn't exist
              # - inference is disabled, so won't try "doc.sh.md"
              resources = @scanner.find_resources("custom", "doc")

              assert_equal 0, resources.length
            end
          end

          def test_extension_inference_with_wfi_protocol
            # Test wfi:// protocol inference
            create_test_protocol(@test_dir, "wfi", {
              "extensions" => [".wf.md", ".wfi.md", ".workflow.md", ".md"],
              "inferred_extensions" => [".wf", ".wfi", ".workflow", ".wf.md", ".wfi.md", ".workflow.md", ".md"]
            })

            create_test_source(@test_dir, "wfi", "wfi_source", {
              "path" => File.join(@test_dir, "wfi-resources", "wfi")
            })

            resource_dir = File.join(@test_dir, "wfi-resources", "wfi")
            FileUtils.mkdir_p(resource_dir)
            File.write(File.join(resource_dir, "setup.wf.md"), "# Setup Workflow")

            Dir.chdir(@test_dir) do
              @config_loader = create_test_config_loader(@test_dir)
              @scanner = ProtocolScanner.new(config_loader: @config_loader)

              # Find using base name - should infer .wf.md
              resources = @scanner.find_resources("wfi", "setup")

              assert_equal 1, resources.length
              assert resources[0][:path].include?("setup.wf.md")
            end
          end

          def test_extension_inference_returns_first_match
            # Test that inference stops at first match (deterministic behavior)
            # Create a different protocol where extension is NOT in the protocol list
            create_test_protocol(@test_dir, "custom", {
              "extensions" => [".custom.md"],  # Only .custom.md is a valid extension
              "inferred_extensions" => [".cst.md", ".cst", ".custom", ".custom.md", ".md"]
            })

            create_test_source(@test_dir, "custom", "custom_source", {
              "path" => File.join(@test_dir, "custom-resources", "custom")
            })

            resource_dir = File.join(@test_dir, "custom-resources", "custom")
            FileUtils.mkdir_p(resource_dir)

            # Create file with shorthand extension that's NOT in protocol extensions
            File.write(File.join(resource_dir, "mydoc.cst.md"), "# Shorthand Extension")

            Dir.chdir(@test_dir) do
              @config_loader = create_test_config_loader(@test_dir)
              @scanner = ProtocolScanner.new(config_loader: @config_loader)

              # Search for base name - original search won't find it (mydoc.custom.md doesn't exist)
              # Inference will try .cst and find mydoc.cst.md
              resources = @scanner.find_resources("custom", "mydoc")

              assert_equal 1, resources.length
              # The relative_path should be "mydoc" after extension stripping
              # It might be "mydoc.cst" if .cst is not being stripped
              # or "mydoc.cst.md" if no extensions are being stripped
              assert_equal "mydoc", resources[0][:relative_path],
                "Expected 'mydoc' but got '#{resources[0][:relative_path]}'"
            end
          end

          def test_extension_inference_does_not_affect_exact_matches
            # Verify that exact matches still work (no regression)
            # Use a fresh protocol to avoid interference from setup_test_environment
            create_test_protocol(@test_dir, "exact", {
              "extensions" => [".exact.md"],
              "inferred_extensions" => [".ex", ".exact.md"]
            })

            create_test_source(@test_dir, "exact", "exact_source", {
              "path" => File.join(@test_dir, "exact-resources", "exact")
            })

            resource_dir = File.join(@test_dir, "exact-resources", "exact")
            FileUtils.mkdir_p(resource_dir)
            file_path = File.join(resource_dir, "exact-match.exact.md")
            File.write(file_path, "# Exact Match")

            Dir.chdir(@test_dir) do
              @config_loader = create_test_config_loader(@test_dir)
              @scanner = ProtocolScanner.new(config_loader: @config_loader)

              # Exact match with full extension should work
              resources = @scanner.find_resources("exact", "exact-match.exact.md")

              assert_equal 1, resources.length
              assert_equal file_path, resources[0][:path]
            end
          end

          def test_extension_inference_prefix_collision
            # TC-004: Shorthand prefix collision - "multi-ext.g" should NOT match "multi-ext.guide.md"
            # The bug: start_with? was too permissive - "multi-ext.guide".start_with?("multi-ext.g") is true
            #
            # To trigger inference (not regular search), protocol extensions must NOT directly match files.
            # Files have shorthand extensions (.g.md, .guide.md) that are NOT in protocol extensions,
            # so regular search fails and inference kicks in.
            create_test_protocol(@test_dir, "prefix", {
              "extensions" => [".full.md"],  # Only .full.md is a protocol extension
              "inferred_extensions" => [".g", ".guide", ".g.md", ".guide.md", ".md"]  # Inference tries .g first
            })

            create_test_source(@test_dir, "prefix", "prefix_source", {
              "path" => File.join(@test_dir, "prefix-resources", "prefix")
            })

            resource_dir = File.join(@test_dir, "prefix-resources", "prefix")
            FileUtils.mkdir_p(resource_dir)

            # Create both files with shorthand extensions (NOT in protocol extensions)
            File.write(File.join(resource_dir, "multi-ext.g.md"), "# Shorthand")
            File.write(File.join(resource_dir, "multi-ext.guide.md"), "# Full Guide")

            Dir.chdir(@test_dir) do
              @config_loader = create_test_config_loader(@test_dir)
              @scanner = ProtocolScanner.new(config_loader: @config_loader)

              # Search for "multi-ext" - regular search fails (no .full.md file)
              # Inference tries candidates in order: multi-ext.g, multi-ext.guide, etc.
              # The bug: "multi-ext.g" incorrectly matched "multi-ext.guide.md"
              # The fix: Only match if next char is end-of-string or dot separator
              resources = @scanner.find_resources("prefix", "multi-ext")

              assert_equal 1, resources.length
              # Should match .g.md, NOT .guide.md
              assert resources[0][:path].end_with?("multi-ext.g.md"),
                "Expected multi-ext.g.md but got #{resources[0][:path]}"
            end
          end

          def test_extension_inference_skips_wildcard_patterns
            # Extension inference should not trigger for wildcard patterns
            create_test_protocol(@test_dir, "wild", {
              "extensions" => [".wild.md"],
              "inferred_extensions" => [".wd", ".wild.md"]
            })

            create_test_source(@test_dir, "wild", "wild_source", {
              "path" => File.join(@test_dir, "wild-resources", "wild")
            })

            resource_dir = File.join(@test_dir, "wild-resources", "wild")
            FileUtils.mkdir_p(resource_dir)
            File.write(File.join(resource_dir, "file1.wild.md"), "# File 1")

            Dir.chdir(@test_dir) do
              @config_loader = create_test_config_loader(@test_dir)
              @scanner = ProtocolScanner.new(config_loader: @config_loader)

              # Wildcard should work normally without inference interference
              resources = @scanner.find_resources("wild", "*")

              assert_equal 1, resources.length
            end
          end
        end
      end
    end
  end
end
