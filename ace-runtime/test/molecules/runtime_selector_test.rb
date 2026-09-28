# frozen_string_literal: true

require "test_helper"

module Ace
  module Runtime
    module Molecules
      class RuntimeSelectorTest < AceRuntimeTestCase
        def setup
          @registry = Registry.new
          @registry.register(:tmux, -> { :tmux_runtime })
          @registry.register(:herdr, -> { :herdr_runtime })
        end

        def test_explicit_name_wins_over_everything
          selector = build_selector(env: {"ACE_RUNTIME" => "herdr"}, config: {"runtime" => "herdr"})

          assert_equal :tmux_runtime, selector.resolve(explicit: "tmux")
          assert_equal "tmux", selector.selected_name
        end

        def test_ace_runtime_env_overrides_config_and_detection
          selector = build_selector(env: {"ACE_RUNTIME" => "herdr", "TMUX" => "x"}, config: {"runtime" => "tmux"})

          assert_equal :herdr_runtime, selector.resolve
          assert_equal "herdr", selector.selected_name
        end

        def test_configured_runtime_overrides_detection
          selector = build_selector(env: {"TMUX" => "x"}, config: {"runtime" => "herdr"})

          assert_equal :herdr_runtime, selector.resolve
        end

        def test_detection_applies_when_nothing_else_selected
          selector = build_selector(env: {"HERDR_SESSION" => "ws", "HERDR_PANE" => "w1:p1"})

          assert_equal :herdr_runtime, selector.resolve
        end

        def test_both_runtimes_live_detects_tmux
          selector = build_selector(env: {"TMUX" => "x", "HERDR_SESSION" => "ws", "HERDR_PANE" => "w1:p1"})

          assert_equal :tmux_runtime, selector.resolve
        end

        def test_no_selection_raises_runtime_unavailable
          selector = build_selector(env: {})

          error = assert_raises(RuntimeUnavailableError) do
            selector.resolve
          end

          assert_match(/no terminal runtime selected/, error.message)
        end

        def test_unknown_explicit_name_fails_closed_with_available_list
          selector = build_selector(env: {})

          error = assert_raises(UnknownRuntimeError) do
            selector.resolve(explicit: "bogus")
          end

          assert_match(/available: herdr, tmux/, error.message)
        end

        def test_unknown_configured_name_fails_closed
          selector = build_selector(env: {}, config: {"runtime" => "bogus"})

          error = assert_raises(UnknownRuntimeError) do
            selector.resolve
          end

          assert_match(/unknown runtime 'bogus'/, error.message)
        end

        def test_unavailable_explicit_runtime_is_never_downgraded
          @registry.register(:flaky, -> { raise RuntimeUnavailableError, "herdr daemon down" })
          selector = build_selector(env: {"TMUX" => "x"})

          error = assert_raises(RuntimeUnavailableError) do
            selector.resolve(explicit: "flaky")
          end

          assert_match(/daemon down/, error.message)
        end

        def test_blank_env_and_config_fall_through_to_detection
          selector = build_selector(env: {"ACE_RUNTIME" => "  ", "TMUX" => "x"}, config: {"runtime" => ""})

          assert_equal :tmux_runtime, selector.resolve
        end

        private

        def build_selector(env:, config: nil)
          RuntimeSelector.new(config: config, registry: @registry, env: env)
        end
      end
    end
  end
end
