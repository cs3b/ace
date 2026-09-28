# frozen_string_literal: true

module Ace
  module Runtime
    module Testing
      # Fixture-local signals. Adapters translate these at their
      # boundary into the contract error model:
      #   FixtureUnavailable    -> RuntimeUnavailableError
      #   FixtureStall          -> SendStalledError
      #   FixtureTargetMissing  -> TargetNotFoundError
      class FixtureError < StandardError; end
      class FixtureUnavailable < FixtureError; end
      class FixtureStall < FixtureError; end
      class FixtureTargetMissing < FixtureError; end

      # In-memory terminal runtime used by the shared adapter contract
      # suite. It models the native capabilities adapters bind to
      # (windows, panes, raw text writes, named keys, capture, agent
      # state) and records every mutation op in order so the suite can
      # assert delivery ordering and rejection-before-transport.
      #
      # Real adapter suites bind their adapter to this same fixture via
      # a thin transport bridge; the reference implementation is
      # test/support/fake_runtime_adapter.rb in the ace-runtime gem.
      class ScriptedRuntime
        attr_reader :calls, :context, :windows, :panes
        attr_accessor :unavailable

        def initialize
          @calls = []
          @context = {in_runtime: true, session: "main", window: nil, pane: nil}
          @windows = {}
          @panes = {}
          @unavailable = false
          @stall_next_send = false
          @window_seq = 0
          @pane_seq = 0
        end

        # --- test controls (never recorded) ---

        def set_context(context)
          @context = context
        end

        def set_output(pane_id, text)
          fetch_pane!(pane_id)[:output] = text
        end

        def set_agent_state(pane_id, state)
          fetch_pane!(pane_id)[:agent_state] = state
        end

        def exit_pane(pane_id)
          fetch_pane!(pane_id)[:alive] = false
        end

        def stall_next_send!
          @stall_next_send = true
        end

        # Silent setup mutator for pre-existing windows; adapter-driven
        # creation goes through #create_window so it gets recorded.
        def seed_window(name, root: "/", preset: nil)
          @windows[name] = {
            id: next_window_id, root: root, preset: preset, focused: false, panes: []
          }
          @windows[name][:id]
        end

        # Silent setup mutator for pre-existing panes.
        def seed_pane(window_name, alive: true, keep_alive: true)
          pane_id = next_pane_id
          @panes[pane_id] = {
            window: window_name, alive: alive, keep_alive: keep_alive,
            output: "", agent_state: nil
          }
          @windows.fetch(window_name)[:panes] << pane_id
          pane_id
        end

        # --- queries (never recorded) ---

        def unavailable?
          @unavailable
        end

        def window_exists?(name)
          @windows.key?(name)
        end

        def window_info(name)
          @windows[name]
        end

        def pane_exists?(pane_id)
          @panes.key?(pane_id)
        end

        def alive?(pane_id)
          fetch_pane!(pane_id)[:alive]
        end

        def agent_state(pane_id)
          fetch_pane!(pane_id)[:agent_state]
        end

        # One-shot: a scripted stall means the submission was accepted
        # but the target never started processing it.
        def take_stall!
          stall = @stall_next_send
          @stall_next_send = false
          stall
        end

        # --- native mutation ops (recorded in order) ---

        def create_window(name:, root:, preset: nil)
          guard_available!
          raise FixtureTargetMissing, "window '#{name}' already exists" if window_exists?(name)

          record(:create_window, name: name, root: root, preset: preset)
          @windows[name] = {
            id: next_window_id, root: root, preset: preset, focused: false, panes: []
          }
          @windows[name][:id]
        end

        def kill_window(name)
          guard_available!
          raise FixtureTargetMissing, "no window '#{name}'" unless window_exists?(name)

          record(:kill_window, name: name)
          @windows.delete(name)
        end

        def focus_window(name)
          guard_available!
          raise FixtureTargetMissing, "no window '#{name}'" unless window_exists?(name)

          record(:focus_window, name: name)
          @windows.each_value { |info| info[:focused] = false }
          @windows[name][:focused] = true
        end

        def split_window(window_name)
          guard_available!
          info = @windows[window_name]
          raise FixtureTargetMissing, "no window '#{window_name}'" unless info

          record(:split_window, window: window_name)
          pane_id = next_pane_id
          @panes[pane_id] = {
            window: window_name, alive: true, keep_alive: false,
            output: "", agent_state: nil
          }
          info[:panes] << pane_id
          pane_id
        end

        def set_keep_alive(pane_id, value)
          guard_available!
          fetch_pane!(pane_id)

          record(:set_keep_alive, pane: pane_id, value: value)
          @panes[pane_id][:keep_alive] = value
        end

        def write_text(pane_id, text)
          guard_available!
          pane = fetch_pane!(pane_id)

          raise FixtureStall, "target accepted the submission but never started processing" if take_stall!

          record(:write_text, pane: pane_id, text: text)
          pane[:output] = text
        end

        def press_key(pane_id, key)
          guard_available!
          pane = fetch_pane!(pane_id)

          raise FixtureStall, "target accepted the submission but never started processing" if take_stall!

          record(:press_key, pane: pane_id, key: key)
          pane[:alive] = false if key.to_s.match?(/\Aexit\z/i)
        end

        def capture_output(pane_id, lines:)
          guard_available!
          output = fetch_pane!(pane_id)[:output]
          output.lines.last([lines, 1].max).join
        end

        private

        def record(op, **args)
          @calls << {op: op}.merge(args)
        end

        def guard_available!
          raise FixtureUnavailable, "runtime backend is not reachable" if @unavailable
        end

        def fetch_pane!(pane_id)
          pane = @panes[pane_id]
          raise FixtureTargetMissing, "no pane '#{pane_id}'" unless pane

          pane
        end

        def next_window_id
          @window_seq += 1
          "w#{@window_seq}"
        end

        def next_pane_id
          @pane_seq += 1
          "%#{@pane_seq}"
        end
      end
    end
  end
end
