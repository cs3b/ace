# frozen_string_literal: true

require_relative "../test_helper"

module Ace
  module Core
    module CLI
      class ConfigSummaryMixinTest < AceTestCase
        module MockGem
          class << self
            def config
              { "model" => "gflash", "preset" => "pr", "max_tokens" => 1000 }
            end

            def default_config
              { "model" => "glite", "preset" => "pr", "max_tokens" => 1000 }
            end
          end
        end

        class TestCommandWithGemClass
          include Ace::Core::CLI::ConfigSummaryMixin::GemClassMixin
        end

        class BaseMixinCommand
          include Ace::Core::CLI::ConfigSummaryMixin

          def gem_config
            { "key" => "value" }
          end

          def gem_defaults
            { "key" => "default" }
          end
        end

        class NotImplementedCommand
          include Ace::Core::CLI::ConfigSummaryMixin
        end

        def setup
          @command = TestCommandWithGemClass.new
          TestCommandWithGemClass.define_singleton_method(:gem_class) { MockGem }
        end

        def test_display_config_summary_shows_when_verbose
          output = capture_stderr { @command.display_config_summary("test", { verbose: true }) }
          assert_includes output, "Config:"
          assert_includes output, "model=gflash"
        end

        def test_display_config_summary_quiet_when_quiet
          output = capture_stderr { @command.display_config_summary("test", { verbose: true, quiet: true }) }
          refute_includes output, "Config:"
        end

        def test_help_requested
          assert @command.help_requested?(help: true)
          assert @command.help_requested?(h: true)
          refute @command.help_requested?(verbose: true)
        end

        def test_gem_class_mixin_provides_config
          assert_equal MockGem.config, @command.send(:gem_config)
          assert_equal MockGem.default_config, @command.send(:gem_defaults)
        end

        def test_base_mixin_works_with_implemented_methods
          command = BaseMixinCommand.new
          output = capture_stderr { command.display_config_summary("test", { verbose: true }) }
          assert_includes output, "Config:"
        end

        def test_base_mixin_raises_without_gem_config
          command = NotImplementedCommand.new
          assert_raises(NotImplementedError) do
            command.display_config_summary("test", { verbose: true })
          end
        end
      end
    end
  end
end
