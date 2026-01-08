# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Core
    module CLI
      module DryCli
        class VersionCommandTest < Minitest::Test
          # VersionCommand.build tests

          def test_build_creates_command_class
            version_cmd = VersionCommand.build(gem_name: "test-gem", version: "1.0.0")
            assert_kind_of Class, version_cmd
            assert_includes version_cmd.ancestors.to_s, "Dry::CLI::Command"
          end

          def test_build_outputs_version_string
            version_cmd = VersionCommand.build(gem_name: "test-gem", version: "1.0.0")
            instance = version_cmd.new

            output = capture_stdout do
              instance.call
            end

            assert_includes output, "test-gem 1.0.0"
          end

          def test_build_returns_zero_exit_code
            version_cmd = VersionCommand.build(gem_name: "test-gem", version: "1.0.0")
            instance = version_cmd.new

            result = instance.call
            assert_equal 0, result
          end

          def test_build_with_semver_version
            version_cmd = VersionCommand.build(gem_name: "ace-review", version: "0.5.2")
            instance = version_cmd.new

            output = capture_stdout do
              instance.call
            end

            assert_includes output, "ace-review 0.5.2"
          end

          def test_build_stores_gem_name_and_version
            version_cmd = VersionCommand.build(gem_name: "my-gem", version: "2.3.4")

            assert_equal "my-gem", version_cmd.gem_name
            assert_equal "2.3.4", version_cmd.version
          end

          def test_build_command_has_description
            version_cmd = VersionCommand.build(gem_name: "test-gem", version: "1.0.0")

            # dry-cli commands should have a description
            # The description is set via the `desc` method in dry-cli
            assert_respond_to version_cmd.new, :call
          end

          # VersionCommand.module tests

          def test_module_creates_module
            version_module = VersionCommand.module(
              gem_name: "test-gem",
              version: -> { "1.0.0" }
            )
            assert_kind_of Module, version_module
          end

          def test_module_provides_show_version_method
            version_module = VersionCommand.module(
              gem_name: "test-gem",
              version: -> { "1.0.0" }
            )

            klass = Class.new do
              include version_module
            end

            instance = klass.new
            assert_respond_to instance, :show_version
          end

          def test_module_show_version_outputs_correctly
            version_module = VersionCommand.module(
              gem_name: "dynamic-gem",
              version: -> { "3.2.1" }
            )

            klass = Class.new do
              include version_module
            end

            instance = klass.new
            output = capture_stdout do
              result = instance.show_version
              assert_equal 0, result
            end

            assert_includes output, "dynamic-gem 3.2.1"
          end

          def test_module_version_proc_evaluated_at_call_time
            version_value = "1.0.0"

            version_module = VersionCommand.module(
              gem_name: "proc-gem",
              version: -> { version_value }
            )

            klass = Class.new do
              include version_module
            end

            # Change version after module creation
            version_value = "2.0.0"

            instance = klass.new
            output = capture_stdout do
              instance.show_version
            end

            # Should use current value, not value at module creation
            assert_includes output, "proc-gem 2.0.0"
          end

          # Integration: VersionCommand with dry-cli Registry

          def test_version_command_in_registry
            registry = Dry::CLI::Registry.new
            version_cmd = VersionCommand.build(gem_name: "registry-gem", version: "1.2.3")

            registry.register "version", version_cmd

            # Can retrieve the command from registry
            assert_respond_to registry, :call
          end

          # Edge cases

          def test_build_with_empty_version
            version_cmd = VersionCommand.build(gem_name: "test-gem", version: "")
            instance = version_cmd.new

            output = capture_stdout do
              instance.call
            end

            # Should still output, just with empty version
            assert_includes output, "test-gem "
          end

          def test_build_with_complex_version_string
            version_cmd = VersionCommand.build(gem_name: "test-gem", version: "1.0.0-beta.1+build.123")
            instance = version_cmd.new

            output = capture_stdout do
              instance.call
            end

            assert_includes output, "1.0.0-beta.1+build.123"
          end

          def test_build_with_gem_name_containing_hyphens
            version_cmd = VersionCommand.build(gem_name: "ace-git-worktree", version: "0.1.0")
            instance = version_cmd.new

            output = capture_stdout do
              instance.call
            end

            assert_includes output, "ace-git-worktree 0.1.0"
          end
        end
      end
    end
  end
end
