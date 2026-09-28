# frozen_string_literal: true

require "ace/runtime"

module Ace
  module Runtime
    # Reference duck-typed adapter used to prove the shared contract
    # suite. It implements the full published intent API over the
    # ScriptedRuntime fixture and is the model real adapters
    # (ace-tmux, ace-herdr) follow: normalize public input through
    # SendContract, translate fixture/native signals at the boundary,
    # keep every target handle opaque.
    class FakeRuntimeAdapter
      DEFAULT_POLL_INTERVAL = 0.005

      attr_reader :send_profile

      def initialize(fixture:, send_profile:, poll_interval: DEFAULT_POLL_INTERVAL)
        @fixture = fixture
        @send_profile = send_profile
        @poll_interval = poll_interval
      end

      # --- op 1: context detection ---

      def context
        fixture.context.dup
      end

      # --- op 2: ensure named window (idempotent by normalized name) ---

      def ensure_window(name:, root:, preset: nil)
        guard_available!
        sanitized = Atoms::NameSanitizer.call(name)

        info = fixture.window_info(sanitized)
        if info
          conflict = info[:root] != root || normalized_preset(info[:preset]) != normalized_preset(preset)
          raise WindowConflictError,
            "window '#{sanitized}' already exists with root '#{info[:root]}' and preset '#{info[:preset]}'" if conflict

          return info[:id]
        end

        fixture.create_window(name: sanitized, root: root, preset: preset)
      end

      # --- op 3: prepare pane (split when needed, retained after exit) ---

      def prepare_pane(window:)
        guard_available!
        info = fixture.window_info(window)
        raise TargetNotFoundError, "no window '#{window}'" unless info

        retained = info[:panes].find { |pane_id| fixture.panes[pane_id][:keep_alive] && fixture.panes[pane_id][:alive] }
        return retained if retained

        pane = fixture.split_window(window)
        fixture.set_keep_alive(pane, true)
        pane
      end

      # --- op 4: select/focus ---

      def focus(window:)
        guard_available!
        name = Atoms::NameSanitizer.call(window)
        raise TargetNotFoundError, "no window '#{name}'" unless fixture.window_exists?(name)

        fixture.focus_window(name)
      end

      # --- op 5: send (central matrix lives in SendContract) ---

      def send(pane:, command: nil, items: [])
        request = Atoms::SendContract.normalize!(command: command, items: items, profile: send_profile)
        execute_normalized(request, pane)
      end

      def send_command(pane:, command:)
        execute_normalized(Atoms::SendContract.command_request(command: command, profile: send_profile), pane)
      end

      def send_text(pane:, text:)
        request = Atoms::SendContract.normalize!(command: nil, items: [{message: text}], profile: send_profile)
        execute_normalized(request, pane)
      end

      def send_keys(pane:, keys:)
        request = Atoms::SendContract.keys_request(keys, profile: send_profile)
        execute_normalized(request, pane)
      end

      # --- op 6: capture recent output ---

      def capture(pane:, lines: 40)
        guard_available!
        unless fixture.pane_exists?(pane)
          raise TargetNotFoundError, "no pane '#{pane}'"
        end

        fixture.capture_output(pane, lines: lines)
      end

      # --- op 7: waits (timeout in SECONDS) ---

      def wait_output(pane:, pattern:, timeout:)
        wait_until(timeout: timeout, condition: "output", target: pane) do
          capture(pane: pane, lines: 40).include?(pattern)
        end
      end

      def wait_agent(pane:, states:, timeout:)
        guard_available!
        raise TargetNotFoundError, "no pane '#{pane}'" unless fixture.pane_exists?(pane)

        wanted = Array(states).map(&:to_s)
        wait_until(timeout: timeout, condition: "agent", target: pane) do
          wanted.include?(fixture.agent_state(pane).to_s)
        end
      end

      def wait_lifecycle(condition:, target:, timeout:)
        guard_available!
        unless Atoms::SendContract::LIFECYCLE_CONDITIONS.include?(condition.to_s)
          raise ArgumentError,
            "unknown lifecycle condition '#{condition}' (expected one of: " \
            "#{Atoms::SendContract::LIFECYCLE_CONDITIONS.join(', ')})"
        end

        wait_until(timeout: timeout, condition: condition, target: target) do
          lifecycle_met?(condition.to_s, target)
        end
      end

      # --- op 8: close/kill by name ---

      def close_window(window:)
        guard_available!
        name = Atoms::NameSanitizer.call(window)
        raise TargetNotFoundError, "no window '#{name}'" unless fixture.window_exists?(name)

        fixture.kill_window(name)
      end

      # --- op 9: listing ---

      def list_windows
        guard_available!

        fixture.windows.map do |name, info|
          {name: name, active: info[:focused]}
        end
      end

      def list_panes(window:)
        guard_available!

        info = fixture.window_info(window)
        return [] unless info

        info[:panes].map.with_index do |pane_id, index|
          {pane: pane_id, active: index.zero?}
        end
      end

      # Op 10 (name sanitization) is the shared module-level
      # Ace::Runtime.sanitize_name; op 11 is the error model above.

      private

      attr_reader :fixture, :poll_interval

      def execute_normalized(request, pane)
        guard_available!
        raise SendStalledError, "target accepted the submission but did not start processing" if fixture.take_stall!

        unless fixture.pane_exists?(pane)
          raise TargetNotFoundError, "no pane '#{pane}'"
        end

        deliver(request, pane)

        Atoms::SendContract::Result.new(dropped_trailing_enter: request.dropped_trailing_enter)
      end

      def deliver(request, pane)
        if request.command
          fixture.write_text(pane, request.command)
          fixture.press_key(pane, "Enter")
        end

        request.items.each do |item|
          if item.key?(:message)
            fixture.write_text(pane, item[:message])
          else
            fixture.press_key(pane, item[:key])
          end
        end
      end

      def lifecycle_met?(condition, target)
        case condition
        when "window-exists"
          fixture.window_exists?(target)
        when "window-active"
          info = fixture.window_info(target)
          info && info[:focused]
        when "pane-exists"
          fixture.pane_exists?(target)
        when "pane-exited"
          !fixture.pane_exists?(target) || !fixture.alive?(target)
        end
      end

      def wait_until(timeout:, condition:, target:)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout.to_f

        loop do
          return true if yield

          if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
            raise WaitTimeoutError.new(condition: condition, target: target, timeout: timeout)
          end

          sleep(poll_interval)
        end
      end

      def guard_available!
        raise RuntimeUnavailableError, "runtime backend is not reachable" if fixture.unavailable?
      end

      def normalized_preset(preset)
        preset.nil? || preset.to_s.strip.empty? ? nil : preset.to_s
      end
    end
  end
end
