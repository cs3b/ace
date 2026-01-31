# frozen_string_literal: true

require_relative "../../test_helper"

module Ace
  module Core
    module CLI
      module DryCli
        class ConfigSummaryMixinTest < AceTestCase
          # Mock gem class for testing
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

          # Test command class implementing the mixin
          class TestCommandWithGemClass
            # Use full module path to avoid conflicts
            include Ace::Core::CLI::DryCli::ConfigSummaryMixin::GemClassMixin

            def call(**options); end
          end

          def setup
            @command = TestCommandWithGemClass.new
            # Set gem class for GemClassMixin
            TestCommandWithGemClass.define_singleton_method(:gem_class) { MockGem }
          end

          # display_config_summary tests

          def test_display_config_summary_shows_when_verbose
            output = capture_stderr do
              @command.display_config_summary("test-command", { verbose: true })
            end
            # Should show config summary with verbose enabled
            assert_includes output, "Config:"
            # Should show model that differs from default
            assert_includes output, "model=gflash"
          end

          def test_display_config_summary_quiet_when_quiet
            output = capture_stderr do
              @command.display_config_summary("test-command", { verbose: true, quiet: true })
            end
            # Quiet mode suppresses all output
            refute_includes output, "Config:"
          end

          def test_display_config_summary_no_output_when_not_verbose
            output = capture_stderr do
              @command.display_config_summary("test-command", { verbose: false })
            end
            # No config without verbose mode
            refute_includes output, "Config:"
          end

          def test_display_config_summary_with_summary_keys
            output = capture_stderr do
              @command.display_config_summary("test-command",
                                              { verbose: true },
                                              summary_keys: %w[model])
            end
            # Should only show model (in allowlist)
            assert_includes output, "model=gflash"
            # Should NOT show other keys
            refute_match(/preset=/, output)
          end

          def test_display_config_summary_without_verbose_flag
            output = capture_stderr do
              @command.display_config_summary("test-command", {})
            end
            # No output when verbose not explicitly enabled
            refute_includes output, "Config:"
          end

          # help_requested? tests

          def test_help_requested_returns_true_with_help_option
            assert @command.help_requested?(help: true)
          end

          def test_help_requested_returns_true_with_h_option
            assert @command.help_requested?(h: true)
          end

          def test_help_requested_returns_false_without_help
            refute @command.help_requested?(verbose: true)
          end

          # GemClassMixin integration tests

          def test_gem_class_mixin_provides_config
            assert_equal MockGem.config, @command.send(:gem_config)
          end

          def test_gem_class_mixin_provides_defaults
            assert_equal MockGem.default_config, @command.send(:gem_defaults)
          end

          # ConfigSummaryMixin base class tests

          class BaseMixinCommand
            # Use full module path to avoid conflicts
            include Ace::Core::CLI::DryCli::ConfigSummaryMixin

            def call(**options); end

            def gem_config
              { "key" => "value" }
            end

            def gem_defaults
              { "key" => "default" }
            end
          end

          def test_base_mixin_requires_gem_config_implementation
            command = BaseMixinCommand.new
            # Should not raise NotImplementedError when gem_config is implemented
            output = capture_stderr do
              command.display_config_summary("test", { verbose: true })
            end
            assert_includes output, "Config:"
          end

          class NotImplementedCommand
            # Use full module path to avoid conflicts
            include Ace::Core::CLI::DryCli::ConfigSummaryMixin

            def call(**options); end
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
end
