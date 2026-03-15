# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Core
    module CLI
      class VersionCommandTest < AceTestCase
        def test_build_creates_command_class
          version_cmd = VersionCommand.build(gem_name: "test-gem", version: "1.0.0")
          assert_kind_of Class, version_cmd
          assert_includes version_cmd.ancestors.to_s, "Ace::Support::Cli::Command"
        end

        def test_build_outputs_version_string
          version_cmd = VersionCommand.build(gem_name: "test-gem", version: "1.0.0")
          output = capture_stdout { version_cmd.new.call }
          assert_includes output, "test-gem 1.0.0"
        end

        def test_module_show_version_outputs_correctly
          version_module = VersionCommand.module(gem_name: "dynamic-gem", version: -> { "3.2.1" })
          klass = Class.new { include version_module }

          output = capture_stdout do
            result = klass.new.show_version
            assert_equal 0, result
          end

          assert_includes output, "dynamic-gem 3.2.1"
        end
      end
    end
  end
end
