# frozen_string_literal: true

require_relative "../test_helper"
require "ace/support/nav/cli"
require "stringio"

module Ace
  module Support
    module Nav
      class CliTest < Minitest::Test
        def setup
          @resolve_cmd = CLI::Commands::Resolve.new
          @original_stdout = $stdout
        end

        def teardown
          $stdout = @original_stdout
        end

        def test_auto_list_with_trailing_slash
          # Test the pattern detection logic
          assert @resolve_cmd.send(:magic_wildcard_pattern?, "prompt://guidelines/"),
                 "Trailing slash should trigger wildcard pattern"
        end

        def test_auto_list_with_wildcard
          # Test the pattern detection logic
          assert @resolve_cmd.send(:magic_wildcard_pattern?, "prompt://format/*"),
                 "Wildcard pattern should trigger wildcard pattern"
        end

        def test_auto_list_with_question_mark
          # Test the pattern detection logic
          assert @resolve_cmd.send(:magic_wildcard_pattern?, "prompt://format/standar?"),
                 "Question mark pattern should trigger wildcard pattern"
        end

        def test_no_auto_list_for_specific_file
          # Test the pattern detection logic
          refute @resolve_cmd.send(:magic_wildcard_pattern?, "prompt://guidelines/tone.md"),
                 "Specific file path should not trigger wildcard pattern"
        end

        def test_protocol_only_auto_list
          # Test the pattern detection logic
          assert @resolve_cmd.send(:magic_wildcard_pattern?, "prompt://"),
                 "Protocol-only URI should trigger wildcard pattern"
        end

        def test_cli_raises_error_when_resource_not_found
          # Test that CLI raises Ace::Support::Cli::Error when resource is not found
          # Regression test for ADR-023 exception-based exit code pattern
          @test_dir = setup_test_environment

          begin
            Dir.chdir(@test_dir) do
              # Reset config to pick up test environment
              Ace::Support::Nav.reset_config!

              error = assert_raises(Ace::Support::Cli::Error) do
                capture_io { @resolve_cmd.call(uri: "test://nonexistent") }
              end

              assert_includes error.message, "Resource not found"
              assert_equal 1, error.exit_code
            end
          ensure
            cleanup_temp_directory(@test_dir)
            Ace::Support::Nav.reset_config!
          end
        end

        def test_cli_raises_error_when_create_fails
          # Test that CLI raises Ace::Support::Cli::Error when create command fails
          # Regression test for ADR-023 exception-based exit code pattern
          @test_dir = setup_test_environment

          begin
            Dir.chdir(@test_dir) do
              # Reset config to pick up test environment
              Ace::Support::Nav.reset_config!

              create_cmd = CLI::Commands::Create.new

              # Try to create from a nonexistent template
              error = assert_raises(Ace::Support::Cli::Error) do
                capture_io { create_cmd.call(uri: "wfi://nonexistent-template") }
              end

              assert_equal 1, error.exit_code
            end
          ensure
            cleanup_temp_directory(@test_dir)
            Ace::Support::Nav.reset_config!
          end
        end

        def test_cli_honors_disabled_extension_inference_config
          # Regression test: CLI should honor extension_inference.enabled: false
          # When disabled, only exact matches should work (no fallback)
          @test_dir = create_temp_ace_directory

          begin
            # Create protocol with specific extensions
            create_test_protocol(@test_dir, "custom", {
              "extensions" => [".custom.md"],  # Only .custom.md is valid
              "inferred_extensions" => [".cst.md", ".custom.md", ".md"]
            })

            # Create source
            create_test_source(@test_dir, "custom", "local", {
              "path" => File.join(@test_dir, "test-resources", "custom")
            })

            # Create resource with shorthand extension (NOT in protocol extensions)
            resource_dir = File.join(@test_dir, "test-resources", "custom")
            FileUtils.mkdir_p(resource_dir)
            File.write(File.join(resource_dir, "document.cst.md"), "# Document")

            # Create config with extension inference DISABLED
            config_dir = File.join(@test_dir, ".ace", "nav")
            FileUtils.mkdir_p(config_dir)
            File.write(File.join(config_dir, "config.yml"), {
              "extension_inference" => { "enabled" => false }
            }.to_yaml)

            Dir.chdir(@test_dir) do
              # Reset config to pick up our test config
              Ace::Support::Nav.reset_config!

              # Should NOT find the resource because:
              # - exact match "document.custom.md" doesn't exist
              # - inference is disabled, so won't try "document.cst.md"
              error = assert_raises(Ace::Support::Cli::Error) do
                capture_io { @resolve_cmd.call(uri: "custom://document") }
              end

              assert_includes error.message, "Resource not found"
            end
          ensure
            cleanup_temp_directory(@test_dir)
            Ace::Support::Nav.reset_config!
          end
        end

        def test_cli_resolves_canonical_skill_resource
          @test_dir = create_temp_ace_directory

          begin
            create_test_protocol(@test_dir, "skill", {
              "name" => "Canonical Skills",
              "extensions" => ["/SKILL.md"],
              "inferred_extensions" => ["/SKILL.md"]
            })

            skills_root = File.join(@test_dir, "test-resources", "skill")
            skill_dir = File.join(skills_root, "as-task-plan")
            FileUtils.mkdir_p(skill_dir)
            skill_path = File.join(skill_dir, "SKILL.md")
            File.write(skill_path, "---\nname: as-task-plan\n")

            create_test_source(@test_dir, "skill", "local", {
              "path" => skills_root,
              "priority" => 10
            })

            Dir.chdir(@test_dir) do
              Ace::Support::Nav.reset_config!
              output, = capture_io { @resolve_cmd.call(uri: "skill://as-task-plan") }
              assert_includes output, skill_path
            end
          ensure
            cleanup_temp_directory(@test_dir)
            Ace::Support::Nav.reset_config!
          end
        end

        def test_cli_raises_error_for_missing_canonical_skill
          @test_dir = create_temp_ace_directory

          begin
            create_test_protocol(@test_dir, "skill", {
              "name" => "Canonical Skills",
              "extensions" => ["/SKILL.md"],
              "inferred_extensions" => ["/SKILL.md"]
            })

            empty_skills_root = File.join(@test_dir, "test-resources", "skill")
            FileUtils.mkdir_p(empty_skills_root)
            create_test_source(@test_dir, "skill", "local", {
              "path" => empty_skills_root,
              "priority" => 10
            })

            Dir.chdir(@test_dir) do
              Ace::Support::Nav.reset_config!

              error = assert_raises(Ace::Support::Cli::Error) do
                capture_io { @resolve_cmd.call(uri: "skill://missing-skill") }
              end

              assert_includes error.message, "Resource not found"
            end
          ensure
            cleanup_temp_directory(@test_dir)
            Ace::Support::Nav.reset_config!
          end
        end
      end
    end
  end
end
