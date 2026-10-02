# frozen_string_literal: true

module Ace
  module Tmux
    # Runtime-neutral intent surface backed by ace-tmux's existing control API.
    class RuntimeAdapter
      SEND = Ace::Runtime::Atoms::SendContract
      LIFECYCLE = SEND::LIFECYCLE_CONDITIONS

      def initialize(backend: NativeRuntimeBackend.new)
        @backend = backend
      end

      def send_profile = :plain_pane

      def context
        backend.context
      end

      def ensure_window(name:, root:, preset: nil)
        with_errors do
          backend.available!
          normalized = Ace::Runtime.sanitize_name(name)
          existing = backend.window_info(normalized)
          if existing
            if File.expand_path(existing[:root]) != File.expand_path(root) || existing[:preset] != preset
              raise Ace::Runtime::WindowConflictError, "window '#{normalized}' has a different root or preset"
            end
            return existing[:id]
          end

          backend.create_window(name: normalized, root: root, preset: preset)
        end
      end

      def prepare_pane(window:)
        with_errors do
          backend.available!
          raise Ace::Runtime::TargetNotFoundError, "window is unavailable" unless backend.window_info(window)

          reusable = backend.panes_for(window).find { |pane| pane[:keep_alive] && pane[:alive] }
          return reusable[:pane] if reusable

          pane = backend.split_window(window)
          backend.set_keep_alive(pane, true)
          pane
        end
      end

      def focus(window:)
        with_errors { backend.focus_window(window) }
      end

      def send(pane:, command: nil, items: [])
        request = SEND.normalize!(command: command, items: items, profile: send_profile)
        with_errors do
          backend.available!
          if request.command
            backend.write_text(pane, request.command)
            backend.press_key(pane, "Enter")
          end
          request.items.each do |item|
            if item.key?(:message)
              backend.write_text(pane, item[:message])
            else
              backend.press_key(pane, item[:key])
            end
          end
          SEND::Result.new(dropped_trailing_enter: false)
        end
      end

      def send_command(pane:, command:) = send(pane: pane, command: command)
      def send_text(pane:, text:) = send(pane: pane, items: [{message: text}])
      def send_keys(pane:, keys:) = send(pane: pane, items: Array(keys).map { |key| {key: key} })

      def capture(pane:, lines: 40)
        with_errors { backend.capture_output(pane, lines: lines) }
      end

      def wait_output(pane:, pattern:, timeout:)
        wait_until(condition: "output", target: pane, timeout: timeout) do
          backend.capture_output(pane, lines: 40).include?(pattern.to_s)
        end
      end

      def wait_agent(pane:, states:, timeout:)
        desired = Array(states).map(&:to_s)
        if backend.respond_to?(:wait_agent)
          return with_errors do
            backend.available!
            backend.wait_agent(pane: pane, states: desired, timeout: timeout)
          end
        end

        wait_until(condition: "agent", target: pane, timeout: timeout) do
          desired.include?(backend.agent_state(pane).to_s)
        end
      rescue Ace::Tmux::WaitTimeoutError
        raise Ace::Runtime::WaitTimeoutError.new(condition: "agent", target: pane, timeout: timeout)
      end

      def wait_lifecycle(condition:, target:, timeout:)
        unless LIFECYCLE.include?(condition.to_s)
          raise ArgumentError, "lifecycle condition must be one of: #{LIFECYCLE.join(", ")}"
        end

        wait_until(condition: condition, target: target, timeout: timeout) do
          backend.lifecycle?(condition.to_s, target)
        end
      end

      def close_window(window:)
        with_errors { backend.kill_window(window) }
      end

      def list_windows
        with_errors { backend.windows }
      end

      def list_panes(window:)
        with_errors do
          backend.available!
          next [] unless backend.window_info(window)

          backend.panes_for(window).map { |entry| {pane: entry[:pane]} }
        end
      end

      private

      attr_reader :backend

      def wait_until(condition:, target:, timeout:)
        duration = Float(timeout)
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + duration
        loop do
          observed = with_errors do
            backend.available!
            yield
          end
          return true if observed
          break if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

          sleep([0.02, duration].min)
        end
        raise Ace::Runtime::WaitTimeoutError.new(condition: condition, target: target, timeout: timeout)
      end

      def with_errors
        yield
      rescue Ace::Runtime::Error
        raise
      rescue Errno::ENOENT, Ace::Tmux::NotInTmuxError
        raise Ace::Runtime::RuntimeUnavailableError, "tmux runtime is unavailable"
      rescue Ace::Tmux::TargetResolutionError
        raise Ace::Runtime::TargetNotFoundError, "tmux target is unavailable"
      rescue Ace::Tmux::WaitTimeoutError
        raise
      rescue Ace::Tmux::Error
        raise Ace::Runtime::RuntimeUnavailableError, "tmux runtime is unavailable"
      rescue => e
        raise backend.translate_error(e) if backend.respond_to?(:translate_error)

        raise
      end
    end
  end
end
