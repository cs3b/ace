# frozen_string_literal: true

require "test_helper"
require "stringio"
require "ace/support/config/cli"

module Ace
  module Support
    module Config
      class CLITest < TestCase
        def test_help_uses_ace_config_command_name
          output = capture_io { CLI.start(["help"]) }.first

          assert_includes output, "ace-config - Configuration management"
          assert_includes output, "ace-config COMMAND [OPTIONS]"
        end

        def test_version_prints_ace_support_config_version
          output = capture_io { CLI.start(["version"]) }.first

          assert_equal "ace-config #{Ace::Support::Config::VERSION}\n", output
        end

        def test_unknown_command_exits_with_help
          output, = capture_io do
            error = assert_raises(SystemExit) { CLI.start(["bogus"]) }
            assert_equal 1, error.status
          end

          assert_includes output, "Unknown command: bogus"
          assert_includes output, "ace-config COMMAND [OPTIONS]"
        end

        def test_list_includes_usage_footer
          templates = Class.new do
            class << self
              def all_gems
                ["ace-demo"]
              end

              def gem_info
                {"ace-demo" => {source: :local, path: "/tmp/demo"}}
              end

              def example_dir_for(_gem_name)
                nil
              end
            end
          end

          Models.send(:remove_const, :ConfigTemplates)
          Models.const_set(:ConfigTemplates, templates)

          output = capture_io { CLI.start(["list"]) }.first

          assert_includes output, "ace-demo [local]"
          assert_includes output, "Use 'ace-config init [GEM]'"
        ensure
          Models.send(:remove_const, :ConfigTemplates)
          load File.expand_path("../../lib/ace/support/config/models/config_templates.rb", __dir__)
        end
      end
    end
  end
end
