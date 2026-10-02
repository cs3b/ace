# frozen_string_literal: true

module Ace
  module Tmux
    # Maps runtime intents onto the existing tmux executor and control surface.
    class NativeRuntimeBackend
      B = Atoms::TmuxCommandBuilder
      # tmux target errors are phrased can't-find/unknown-target; bare "no
      # such" also matches socket connection failures and must not classify
      # as a missing target.
      TARGET_ERROR_PATTERN = /can't find|unknown target|not found/i
      WINDOW_FORMAT = Organisms::ControlSurface::WINDOW_LIST_FORMAT
      PANE_FORMAT = Organisms::ControlSurface::PANE_LIST_FORMAT

      def initialize(executor: Molecules::TmuxExecutor.new, env: ENV, tmux: "tmux", surface: nil)
        @executor = executor
        @env = env
        @tmux = tmux
        @resolver = Molecules::RuntimeTargetResolver.new(executor: executor, tmux: tmux, env: env)
        @surface = surface || Organisms::ControlSurface.new(executor: executor, resolver: @resolver, tmux: tmux)
      end

      def context
        present = !env["TMUX"].to_s.empty? || !env["ACE_TMUX_SESSION"].to_s.empty?
        return {in_runtime: false, session: nil, window: nil, pane: nil} unless present

        session = resolver.resolve_session.session
        window = context_window(session)
        pane = context_pane(session, window)
        {in_runtime: true, session: session, window: window, pane: pane}
      rescue Ace::Tmux::TargetResolutionError
        {in_runtime: false, session: nil, window: nil, pane: nil}
      end

      def available!
        raise Ace::Tmux::NotInTmuxError unless executor.tmux_available?(tmux: tmux)

        resolver.resolve_session
        true
      end

      def window_info(name)
        entry = windows.find { |window| window[:name] == name || window[:id] == name }
        return nil unless entry

        root = option(entry[:id], "@ace_runtime_root")
        root ||= query(B.display_message_target(entry[:id], "\#{pane_current_path}", tmux: tmux))
        preset = option(entry[:id], "@ace_runtime_preset")
        {id: entry[:id], root: root, preset: preset}
      end

      def create_window(name:, root:, preset: nil)
        session = resolver.resolve_session.session
        if preset
          loader = Molecules::PresetLoader.new(gem_root: Ace::Tmux.gem_root)
          builder = Molecules::SessionBuilder.new(preset_loader: loader)
          begin
            Organisms::WindowManager.new(executor: executor, session_builder: builder, tmux: tmux)
              .add_window(preset, session: session, root: root, name: name)
          rescue Ace::Tmux::Error
            raise
          rescue StandardError => e
            raise Ace::Tmux::Error, "preset window creation failed: #{e.message}"
          end
          id = window_info(name)[:id]
        else
          id = query(B.new_window(session, name: name, root: root, print_format: "\#{window_id}", tmux: tmux))
        end
        run!(B.set_window_option(id, "@ace_runtime_root", File.expand_path(root), tmux: tmux))
        run!(B.set_window_option(id, "@ace_runtime_preset", preset, tmux: tmux)) if preset
        id
      end

      def panes_for(window)
        target = resolve_window!(window)
        result = executor.capture(B.list_panes(target, format: PANE_FORMAT, tmux: tmux))
        unless result.success?
          detail = result.stderr.to_s
          raise Ace::Tmux::TargetResolutionError, "tmux target is unavailable" if detail.match?(TARGET_ERROR_PATTERN)

          raise Ace::Tmux::Error, detail
        end
        result.stdout.lines.filter_map do |line|
          parts = line.chomp.split("\t", -1)
          next unless parts.length == 9

          pane = parts[1]
          {pane: pane, keep_alive: option(pane, "@ace_runtime_prepared", pane: true) == "1",
           alive: query(B.display_message_target(pane, "\#{pane_dead}", tmux: tmux)) != "1"}
        end
      end

      def split_window(window)
        target = resolve_window!(window)
        query(B.split_window(target, root: window_info(window)[:root], print_format: "\#{pane_id}", tmux: tmux))
      end

      def set_keep_alive(pane, value)
        run!(B.set_pane_option(pane, "remain-on-exit", value ? "on" : "off", tmux: tmux))
        run!(B.set_pane_option(pane, "@ace_runtime_prepared", value ? "1" : "0", tmux: tmux))
      end

      def focus_window(window)
        run!(B.select_window(resolve_window!(window), tmux: tmux))
      end

      def write_text(pane, text)
        run!([tmux, "send-keys", "-l", "-t", pane, text])
        @pending_text_pane = pane
      end

      def press_key(pane, key)
        if @pending_text_pane == pane && Atoms::NamedKeyRegistry.normalize(key) == "Enter"
          profile = surface.send(:fetch_pane_profile, pane)
          sleep(Organisms::ControlSurface::INTERACTIVE_SUBMIT_DELAY) if profile[:interactive_cli]
        end
        normalized = Atoms::NamedKeyRegistry.normalize(key)
        run!(B.send_raw_keys(pane, normalized, tmux: tmux))
        @pending_text_pane = nil
      end

      def capture_output(pane, lines:)
        surface.capture_recent_output(pane: pane, lines: lines)
      rescue Ace::Tmux::Error
        raise Ace::Tmux::TargetResolutionError, "tmux target is unavailable" unless pane_exists?(pane)

        raise
      end

      def agent_state(pane)
        agent_state_from_output(capture_output(pane, lines: 40))
      end

      def agent_state_from_output(output)
        busy = Organisms::ControlSurface::INTERACTIVE_BUSY_PATTERNS.any? { |pattern| output.match?(pattern) }
        busy ? "working" : "idle"
      end

      def wait_agent(pane:, states:, timeout:)
        desired = Array(states).map(&:to_s)
        completion_states = %w[idle done working-done ready]
        supported_states = completion_states + ["working"]
        if desired.empty? || (desired - supported_states).any?
          raise ArgumentError, "agent states must be one or more of: #{supported_states.join(", ")}"
        end

        interval = (timeout.to_f / 5).clamp(0.02, 0.2)
        # The stability+settle completion wait only supports interactive CLI
        # panes and only observes completion. Shell panes and any requested
        # "working" state must poll the observed state instead. Shell panes
        # only ever observe idle/working, so completion aliases read as idle.
        if (desired - completion_states).empty? && interactive_cli_pane?(pane)
          return surface.wait_for_condition(
            condition: "agent", pane: pane, timeout: timeout,
            interval: interval,
            settle: [timeout.to_f / 2, 1.0].min
          )
        end

        # Shell panes only ever observe idle/working, so completion
        # aliases read as idle.
        observable = desired.flat_map { |state| %w[idle working].include?(state) ? [state] : %w[idle] }.uniq
        poll_agent_states(pane, observable, interval: interval, timeout: timeout)
      end

      def validate_key!(key)
        Atoms::NamedKeyRegistry.normalize(key)
      rescue Ace::Tmux::ValidationError => e
        raise Ace::Runtime::SendRejectedError, e.message
      end

      def lifecycle?(condition, target)
        case condition
        when "window-exists" then !window_info(target).nil?
        when "window-active" then windows.any? { |entry| (entry[:name] == target || entry[:id] == target) && entry[:active] }
        when "pane-exists" then pane_exists?(target)
        when "pane-exited" then pane_exited?(target)
        end
      end

      def kill_window(window)
        run!([tmux, "kill-window", "-t", resolve_window!(window)])
      end

      def windows
        session = resolver.resolve_session.session
        output = query(B.list_windows(session, format: WINDOW_FORMAT, tmux: tmux))
        output.lines.filter_map do |line|
          active, id, _session, _index, name, _panes = line.chomp.split("\t", 6)
          {name: name, id: id, active: active == "1"} if id && name
        end
      end

      private

      attr_reader :executor, :env, :tmux, :resolver, :surface

      def interactive_cli_pane?(pane)
        surface.send(:fetch_pane_profile, pane)[:interactive_cli]
      rescue Ace::Tmux::Error
        false
      end

      # Shell-pane wait: a working observation matches immediately; a
      # completion observation only counts once pane output has held
      # still for the settle window (the documented output-stability
      # heuristic) so a running command never reads as done.
      def poll_agent_states(pane, observable, interval:, timeout:)
        settle = [timeout.to_f / 2, 1.0].min
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout.to_f
        current_output = capture_output(pane, lines: 40)
        stable_since = nil
        loop do
          now = Process.clock_gettime(Process::CLOCK_MONOTONIC)
          state = agent_state_from_output(current_output)
          if observable.include?(state)
            return true if state == "working" && now < deadline

            stable_since ||= now
            return true if now < deadline && now - stable_since >= settle
          else
            stable_since = nil
          end
          raise Ace::Tmux::WaitTimeoutError if now >= deadline

          sleep(interval)
          fresh_output = capture_output(pane, lines: 40)
          stable_since = nil if fresh_output != current_output
          current_output = fresh_output
        end
      end

      # Pane absence and a dead pane both satisfy the pane-exited
      # observation; any other query failure is a runtime error, never
      # silent evidence of exit.
      def pane_exited?(target)
        result = executor.capture(B.display_message_target(target, "\#{pane_dead}", tmux: tmux))
        return true if !result.success? && result.stderr.to_s.match?(TARGET_ERROR_PATTERN)
        raise Ace::Tmux::Error, result.stderr.to_s unless result.success?

        result.stdout.to_s.strip == "1"
      end

      # A missing pane must not erase an explicitly available session or
      # window from the reported context.
      def context_window(session)
        return nil if env["TMUX"].to_s.empty? && env["ACE_TMUX_WINDOW"].to_s.empty?

        resolver.resolve_window(session: session).window
      rescue Ace::Tmux::TargetResolutionError
        nil
      end

      def context_pane(session, window)
        return nil unless window

        resolver.resolve_pane(session: session, window: window).pane_target
      rescue Ace::Tmux::TargetResolutionError
        nil
      end

      def pane_exists?(pane)
        result = executor.capture(B.display_message_target(pane, "\#{pane_id}", tmux: tmux))
        return false if !result.success? && result.stderr.to_s.match?(TARGET_ERROR_PATTERN)
        raise Ace::Tmux::Error, result.stderr.to_s unless result.success?

        !result.stdout.to_s.strip.empty?
      end

      def resolve_window!(window)
        info = window_info(window)
        raise Ace::Tmux::TargetResolutionError, "window target is unavailable" unless info

        info[:id]
      end

      def option(target, name, pane: false)
        command = [tmux, "show-options", "-v"]
        command << "-p" if pane
        # Runtime window marks live in the window scope; without -w tmux
        # reports the option as unset and idempotency checks conflict.
        command << "-w" unless pane
        result = executor.capture(command + ["-t", target, name])
        if result.success?
          value = result.stdout.to_s.strip
          value.empty? ? nil : value
        else
          detail = result.stderr.to_s
          raise Ace::Tmux::TargetResolutionError, "tmux target is unavailable" if detail.match?(TARGET_ERROR_PATTERN)
          # tmux exits non-zero with quiet output for an unset option.
          return nil if detail.strip.empty?

          raise Ace::Tmux::Error, detail
        end
      end

      def query(command)
        result = executor.capture(command)
        unless result.success?
          detail = result.stderr.to_s
          raise Ace::Tmux::TargetResolutionError, "tmux target is unavailable" if detail.match?(TARGET_ERROR_PATTERN)

          raise Ace::Tmux::Error, detail
        end

        result.stdout.to_s.strip
      end

      def run!(command)
        result = executor.capture(command)
        unless result.success?
          detail = result.stderr.to_s
          raise Ace::Tmux::TargetResolutionError, "tmux target is unavailable" if detail.match?(TARGET_ERROR_PATTERN)

          raise Ace::Tmux::Error, detail
        end

        true
      end
    end
  end
end
