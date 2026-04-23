# frozen_string_literal: true

module Ace
  module Tmux
    module Organisms
      class ControlSurface
        DEFAULT_LINES = 40
        DEFAULT_TIMEOUT = 10.0
        DEFAULT_INTERVAL = 0.2
        DEFAULT_SETTLE = 1.0
        INTERACTIVE_SUBMIT_DELAY = 0.15
        INTERACTIVE_CLI_COMMANDS = %w[codex claude pi].freeze
        INTERACTIVE_BUSY_PATTERNS = [
          /esc to interrupt/i,
          /\bWorking \(/,
          /Booting MCP server:/i
        ].freeze
        PANE_PROFILE_FORMAT = '#{pane_current_command}' + "\t" + '#{pane_height}' + "\t" + '#{alternate_on}' + "\t" + '#{pane_pid}'
        SESSION_LIST_FORMAT = '#{session_name}' + "\t" + '#{session_attached}' + "\t" + '#{session_windows}'
        WINDOW_LIST_FORMAT = '#{window_active}' + "\t" + '#{window_id}' + "\t" + '#{session_name}' + "\t" + '#{window_index}' + "\t" + '#{window_name}' + "\t" + '#{window_panes}'
        PANE_LIST_FORMAT = '#{pane_active}' + "\t" + '#{pane_id}' + "\t" + '#{session_name}' + "\t" + '#{window_id}' + "\t" + '#{window_index}' + "\t" + '#{window_name}' + "\t" + '#{pane_index}' + "\t" + '#{pane_current_command}' + "\t" + '#{pane_current_path}'

        def initialize(executor: Ace::Tmux::Molecules::TmuxExecutor.new, resolver: nil, process_inspector: nil, tmux: "tmux")
          @executor = executor
          @tmux = tmux
          @resolver = resolver || Molecules::RuntimeTargetResolver.new(executor: executor, tmux: tmux)
          @process_inspector = process_inspector || Molecules::LocalProcessInspector.new
        end

        def send_command(session: nil, window: nil, pane: nil, command:)
          raise Ace::Tmux::ValidationError, "--cmd is required" if command.to_s.strip.empty?

          send_sequence(session: session, window: window, pane: pane, command: command)
        end

        def send_text(session: nil, window: nil, pane: nil, text:)
          raise Ace::Tmux::ValidationError, "--msg is required" if text.to_s.empty?

          target = resolver.resolve_pane(session: session, window: window, pane: pane)
          send_text_to_target(target.pane_target, text)
        end

        def send_key(session: nil, window: nil, pane: nil, key:)
          send_sequence(session: session, window: window, pane: pane, keys: [key])
        end

        def send_sequence(session: nil, window: nil, pane: nil, command: nil, messages: [], keys: [])
          target = resolver.resolve_pane(session: session, window: window, pane: pane)
          pane_profile = fetch_pane_profile(target.pane_target)
          normalized_command = normalize_optional_text(command)
          normalized_messages = Array(messages).map(&:to_s)
          normalized_keys = Array(keys)
          text_pending_submit = false

          normalized_messages.each do |message|
            send_text_to_target(target.pane_target, message)
            text_pending_submit = true
          end

          if normalized_command
            send_text_to_target(target.pane_target, normalized_command)
            pause_before_interactive_submit(pane_profile, "Enter")
            send_named_key_to_target(target.pane_target, "Enter")
            text_pending_submit = false
          end

          normalized_keys.each_with_index do |key, index|
            pause_before_interactive_submit(pane_profile, key) if text_pending_submit && index.zero?
            send_named_key_to_target(target.pane_target, key)
          end
        end

        def capture_recent_output(session: nil, window: nil, pane: nil, lines: DEFAULT_LINES)
          target = resolver.resolve_pane(session: session, window: window, pane: pane)
          pane_profile = fetch_pane_profile(target.pane_target)
          capture_output_for_target(target.pane_target, pane_profile: pane_profile, lines: lines)
        end

        def wait_for_condition(
          condition:,
          session: nil,
          window: nil,
          pane: nil,
          pattern: nil,
          timeout: DEFAULT_TIMEOUT,
          interval: DEFAULT_INTERVAL,
          lines: DEFAULT_LINES,
          settle: DEFAULT_SETTLE,
          baseline_output: nil,
          require_change: false
        )
          normalized = Molecules::WaitConditionValidator.validate!(condition: condition, pattern: pattern)
          deadline = monotonic_now + timeout.to_f

          if normalized == "agent"
            return wait_for_agent_condition(
              session: session,
              window: window,
              pane: pane,
              timeout_deadline: deadline,
              interval: interval.to_f,
              lines: lines,
              settle: settle.to_f,
              baseline_output: baseline_output,
              require_change: require_change
            )
          end

          if normalized == "output" && !baseline_output.nil?
            return wait_for_output_condition(
              session: session,
              window: window,
              pane: pane,
              pattern: pattern,
              timeout_deadline: deadline,
              interval: interval.to_f,
              lines: lines,
              baseline_output: baseline_output
            )
          end

          loop do
            return true if condition_met?(normalized, session: session, window: window, pane: pane, pattern: pattern)

            raise_wait_timeout(normalized) if monotonic_now >= deadline

            sleep(interval.to_f)
          end
        end

        def attach_session(session: nil)
          target = resolver.resolve_session(session: session)
          executor.exec(Atoms::TmuxCommandBuilder.attach_session(target.session_target, tmux: tmux))
        end

        def detach_session(session: nil)
          target = resolver.resolve_session(session: session)
          run!(
            Atoms::TmuxCommandBuilder.detach_client(target.session_target, tmux: tmux),
            "detach clients from #{target.session_target}"
          )
          target.session_target
        end

        def list_sessions
          result = executor.capture(
            Atoms::TmuxCommandBuilder.list_sessions(format: SESSION_LIST_FORMAT, tmux: tmux)
          )
          return [] unless result.success?

          result.stdout.split("\n").map { |line| parse_session_row(line) }.compact.sort_by { |entry| entry[:session] }
        end

        def list_windows(session: nil)
          target = resolver.resolve_session(session: session)
          list_window_rows(target.session_target)
        end

        def list_panes(session: nil, window: nil, all_panes: false)
          if all_panes
            target = resolver.resolve_session(session: session)
            return window_identities_for_session(target.session_target).flat_map { |entry| pane_rows_for_window(entry[:id]) }
          end

          target = resolver.resolve_window(session: session, window: window)
          pane_rows_for_window(target.window_target)
        end

        private

        attr_reader :executor, :resolver, :process_inspector, :tmux

        def condition_met?(condition, session:, window:, pane:, pattern:)
          case condition
          when "output"
            capture_recent_output(session: session, window: window, pane: pane).include?(pattern)
          when "window-exists"
            target = resolver.resolve_window(session: session, window: window)
            window_rows = list_window_rows(target.session_target)
            window_target_exists?(target, window_rows)
          when "window-active"
            target = resolver.resolve_window(session: session, window: window)
            window_active?(target, list_window_rows(target.session_target))
          when "pane-exists"
            pane_exists_for?(session: session, window: window, pane: pane)
          when "pane-exited"
            pane_exited?(session: session, window: window, pane: pane)
          else
            false
          end
        end

        def wait_for_output_condition(session:, window:, pane:, pattern:, timeout_deadline:, interval:, lines:, baseline_output:)
          baseline_count = pattern_match_count(baseline_output.to_s, pattern)

          loop do
            current_output = capture_recent_output(session: session, window: window, pane: pane, lines: lines)
            return true if pattern_match_count(current_output, pattern) > baseline_count

            raise_wait_timeout("output") if monotonic_now >= timeout_deadline

            sleep(interval)
          end
        end

        def window_identities_for_session(session)
          result = executor.capture(
            Atoms::TmuxCommandBuilder.list_windows(session, format: WINDOW_LIST_FORMAT, tmux: tmux)
          )
          return [] unless result.success?

          result.stdout.split("\n").map { |line| parse_window_row(line) }.compact.sort_by { |entry| [entry[:index], entry[:name]] }
        end

        def list_window_rows(session)
          window_identities_for_session(session)
        end

        def pane_exists?(pane_target)
          result = executor.capture(
            Atoms::TmuxCommandBuilder.display_message_target(pane_target, '#{pane_id}', tmux: tmux)
          )
          result.success? && !result.stdout.to_s.strip.empty?
        end

        def pane_exists_for?(session:, window:, pane:)
          target = resolver.resolve_pane(session: session, window: window, pane: pane)
          pane_exists?(target.pane_target)
        rescue Ace::Tmux::TargetResolutionError
          false
        end

        def pane_exited?(session:, window:, pane:)
          target = resolver.resolve_pane(session: session, window: window, pane: pane)
          result = executor.capture(
            Atoms::TmuxCommandBuilder.display_message_target(target.pane_target, '#{pane_dead}', tmux: tmux)
          )
          !result.success? || result.stdout == "1"
        rescue Ace::Tmux::TargetResolutionError
          true
        end

        def window_target_exists?(target, rows)
          if target.window_target&.start_with?("@")
            rows.any? { |entry| entry[:id] == target.window_target }
          else
            rows.any? { |entry| entry[:name] == target.window }
          end
        end

        def window_active?(target, rows)
          if target.window_target&.start_with?("@")
            rows.any? { |entry| entry[:id] == target.window_target && entry[:active] }
          else
            rows.any? { |entry| entry[:name] == target.window && entry[:active] }
          end
        end

        def pane_rows_for_window(window_target)
          result = executor.capture(
            Atoms::TmuxCommandBuilder.list_panes(window_target, format: PANE_LIST_FORMAT, tmux: tmux)
          )
          return [] unless result.success?

          result.stdout.split("\n").map { |line| parse_pane_row(line) }.compact.sort_by do |entry|
            [entry[:window_index], entry[:pane_index]]
          end
        end

        def parse_session_row(line)
          session, attached, windows = line.to_s.split("\t", 3)
          return nil if session.to_s.empty?

          {
            session: session,
            attached_clients: integer_or_zero(attached),
            window_count: integer_or_zero(windows)
          }
        end

        def parse_window_row(line)
          active, id, session, index, name, panes = line.to_s.split("\t", 6)
          return nil if [id, session, index, name].any? { |value| value.to_s.empty? }

          {
            active: active == "1",
            id: id,
            session: session,
            index: integer_or_zero(index),
            name: name,
            pane_count: integer_or_zero(panes)
          }
        end

        def parse_pane_row(line)
          active, pane_id, session, window_id, window_index, window_name, pane_index, command, path = line.to_s.split("\t", 9)
          return nil if [pane_id, session, window_id, window_index, window_name, pane_index].any? { |value| value.to_s.empty? }

          {
            active: active == "1",
            pane_id: pane_id,
            session: session,
            window_id: window_id,
            window_index: integer_or_zero(window_index),
            window_name: window_name,
            pane_index: integer_or_zero(pane_index),
            target: "#{session}:#{window_name}.#{pane_index}",
            command: normalize_optional_text(command) || "-",
            cwd: path_basename(path)
          }
        end

        def integer_or_zero(value)
          Integer(value.to_s.strip)
        rescue ArgumentError
          0
        end

        def path_basename(path)
          value = path.to_s.strip
          return "-" if value.empty?

          File.basename(value)
        end

        def pattern_match_count(output, pattern)
          text = output.to_s
          return 0 if text.empty?

          Regexp.new(Regexp.escape(pattern.to_s)).match(text) ? text.scan(pattern.to_s).length : 0
        end

        def normalize_optional_text(value)
          text = value.to_s
          return nil if text.strip.empty?

          text
        end

        def fetch_pane_profile(pane_target)
          result = executor.capture(
            Atoms::TmuxCommandBuilder.display_message_target(pane_target, PANE_PROFILE_FORMAT, tmux: tmux)
          )
          return default_pane_profile unless result.success?

          parse_pane_profile(result.stdout)
        rescue Errno::ENOENT
          default_pane_profile
        end

        def parse_pane_profile(stdout)
          command, height, alternate_on, pane_pid = stdout.to_s.split("\t", 4)
          normalized_command = normalize_command(command)
          normalized_height = Integer(height.to_s.strip)

          build_pane_profile(
            command: normalized_command,
            height: normalized_height,
            alternate_on: alternate_on.to_s.strip == "1",
            pane_pid: pane_pid
          )
        rescue ArgumentError
          default_pane_profile(command: command, pane_pid: pane_pid)
        end

        def default_pane_profile(command: nil, pane_pid: nil)
          normalized_command = normalize_command(command)
          interactive_command = resolve_interactive_cli_command(command: normalized_command, pane_pid: pane_pid)

          {
            command: interactive_command || normalized_command,
            height: nil,
            alternate_on: false,
            pane_pid: normalize_pid(pane_pid),
            interactive_cli: !interactive_command.nil?
          }
        end

        def wait_for_agent_condition(session:, window:, pane:, timeout_deadline:, interval:, lines:, settle:, baseline_output:, require_change:)
          target = resolver.resolve_pane(session: session, window: window, pane: pane)
          pane_profile = fetch_pane_profile(target.pane_target)
          unless pane_profile[:interactive_cli]
            raise Ace::Tmux::ValidationError, "--for agent requires an interactive CLI pane such as codex, claude, or pi."
          end

          previous_output = baseline_output.nil? ? capture_output_for_target(target.pane_target, pane_profile: pane_profile, lines: lines) : baseline_output.to_s
          baseline = previous_output
          change_observed = !require_change
          stable_since = nil

          loop do
            current_output = capture_output_for_target(target.pane_target, pane_profile: pane_profile, lines: lines)
            busy = interactive_agent_busy?(current_output)

            if current_output != previous_output
              previous_output = current_output
              change_observed ||= current_output != baseline
              stable_since = nil
            elsif change_observed && !busy
              stable_since ||= monotonic_now
              return true if monotonic_now - stable_since >= settle
            else
              stable_since = nil
            end

            raise_wait_timeout("agent") if monotonic_now >= timeout_deadline

            sleep(interval)
          end
        end

        def interactive_agent_busy?(output)
          text = output.to_s
          INTERACTIVE_BUSY_PATTERNS.any? { |pattern| text.match?(pattern) }
        end

        def build_pane_profile(command:, height:, alternate_on:, pane_pid:)
          interactive_command = resolve_interactive_cli_command(command: command, pane_pid: pane_pid)

          {
            command: interactive_command || command,
            height: height,
            alternate_on: alternate_on,
            pane_pid: normalize_pid(pane_pid),
            interactive_cli: !interactive_command.nil?
          }
        end

        def resolve_interactive_cli_command(command:, pane_pid:)
          normalized_command = normalize_command(command)
          return normalized_command if INTERACTIVE_CLI_COMMANDS.include?(normalized_command)

          process_inspector.find_descendant_command(normalize_pid(pane_pid), allowed_commands: INTERACTIVE_CLI_COMMANDS)
        end

        def normalize_command(value)
          value.to_s.strip.downcase
        end

        def normalize_pid(value)
          candidate = value.to_s.strip
          return nil if candidate.empty?

          Integer(candidate).to_s
        rescue ArgumentError
          nil
        end

        def monotonic_now
          Process.clock_gettime(Process::CLOCK_MONOTONIC)
        end

        def raise_wait_timeout(condition)
          raise Ace::Tmux::WaitTimeoutError, "Timed out waiting for tmux condition '#{condition}'."
        end

        def pause_before_interactive_submit(pane_profile, key)
          return unless pane_profile[:interactive_cli]
          return unless submit_key?(key)

          sleep(INTERACTIVE_SUBMIT_DELAY)
        end

        def submit_key?(key)
          Atoms::NamedKeyRegistry.normalize(key) == "Enter"
        rescue Ace::Tmux::ValidationError
          false
        end

        def capture_command_for(pane_target, pane_profile:, lines:)
          normalized_lines = [Integer(lines.to_i.abs), 1].max
          return Atoms::TmuxCommandBuilder.capture_pane(pane_target, lines: normalized_lines, tmux: tmux) unless pane_profile[:interactive_cli]

          pane_height = pane_profile[:height].to_i
          return Atoms::TmuxCommandBuilder.capture_pane(pane_target, lines: normalized_lines, tmux: tmux) unless pane_height.positive?

          visible_lines = [normalized_lines, pane_height].min
          start_line = [pane_height - visible_lines, 0].max
          end_line = pane_height - 1

          Atoms::TmuxCommandBuilder.capture_pane_visible(
            pane_target,
            start_line: start_line,
            end_line: end_line,
            include_alternate: pane_profile[:alternate_on],
            tmux: tmux
          )
        end

        def capture_output_for_target(pane_target, pane_profile:, lines:)
          result = executor.capture(
            capture_command_for(pane_target, pane_profile: pane_profile, lines: lines)
          )
          raise Ace::Tmux::Error, "Failed to capture pane #{pane_target}: #{result.stderr}" unless result.success?

          result.stdout
        end

        def send_text_to_target(target, text)
          run!(
            Atoms::TmuxCommandBuilder.send_raw_keys(target, text, tmux: tmux),
            "send text to #{target}"
          )
        end

        def send_named_key_to_target(target, key)
          normalized_key = Atoms::NamedKeyRegistry.normalize(key)
          run!(
            Atoms::TmuxCommandBuilder.send_raw_keys(target, normalized_key, tmux: tmux),
            "send key to #{target}"
          )
        end

        def run!(cmd, action)
          result = executor.run(cmd)
          return true if result

          raise Ace::Tmux::Error, "Failed to #{action}"
        end
      end
    end
  end
end
