# frozen_string_literal: true

require "test_helper"

module Ace
  module Runtime
    module Atoms
      class DetectorTest < AceRuntimeTestCase
        def test_neither_runtime_returns_nil_without_exception
          assert_nil Detector.detect(env: {})
        end

        def test_tmux_env_detects_tmux
          assert_equal :tmux, Detector.detect(env: {"TMUX" => "/tmp/tmux-0/default,123,0"})
        end

        def test_ace_tmux_session_detects_tmux
          assert_equal :tmux, Detector.detect(env: {"ACE_TMUX_SESSION" => "work"})
        end

        def test_blank_tmux_values_do_not_detect
          assert_nil Detector.detect(env: {"TMUX" => ""})
          assert_nil Detector.detect(env: {"ACE_TMUX_SESSION" => "   "})
        end

        def test_herdr_requires_session_and_pane
          assert_equal :herdr, Detector.detect(env: {"HERDR_SESSION" => "ws1", "HERDR_PANE" => "w1:p1"})
          assert_nil Detector.detect(env: {"HERDR_SESSION" => "ws1"})
          assert_nil Detector.detect(env: {"HERDR_PANE" => "w1:p1"})
          assert_nil Detector.detect(env: {"HERDR_SESSION" => "ws1", "HERDR_PANE" => ""})
        end

        def test_both_live_detects_tmux
          env = {
            "TMUX" => "/tmp/tmux-0/default,123,0",
            "HERDR_SESSION" => "ws1",
            "HERDR_PANE" => "w1:p1"
          }

          assert_equal :tmux, Detector.detect(env: env)
        end

        def test_detection_is_side_effect_free
          env = {"TMUX" => "x"}

          Detector.detect(env: env)

          assert_equal({"TMUX" => "x"}, env)
        end
      end
    end
  end
end
