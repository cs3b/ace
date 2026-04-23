# frozen_string_literal: true

module Ace
  module Tmux
    module Molecules
      class RuntimeTargetResolver
        def initialize(executor: Ace::Tmux::Molecules::TmuxExecutor.new, tmux: "tmux", env: ENV)
          @executor = executor
          @tmux = tmux
          @env = env
        end

        def resolve_session(session: nil)
          explicit = normalize(session)
          return Models::RuntimeTarget.new(session: explicit, source: "explicit") if explicit

          env_session = normalize(env["ACE_TMUX_SESSION"])
          return Models::RuntimeTarget.new(session: env_session, source: "env") if env_session

          live_session = resolve_live_session
          return Models::RuntimeTarget.new(session: live_session, source: "live") if live_session

          raise Ace::Tmux::TargetResolutionError, "Could not resolve tmux session from flags, ACE_TMUX_SESSION, or live tmux context."
        end

        def resolve_window(session: nil, window: nil)
          session_target = resolve_session(session: session)

          explicit_window = normalize(window)
          if explicit_window
            return build_window_target(session: session_target.session, raw_window: explicit_window, source: "explicit")
          end

          env_window = normalize(env["ACE_TMUX_WINDOW"])
          if env_window
            return build_window_target(session: session_target.session, raw_window: env_window, source: "env")
          end

          live_window = resolve_live_window(session: session_target.session)
          return Models::RuntimeTarget.new(
            session: session_target.session,
            window: live_window[:name],
            raw_window_target: live_window[:id],
            source: "live"
          ) if live_window

          raise Ace::Tmux::TargetResolutionError, "Could not resolve tmux window from flags, ACE_TMUX_WINDOW, or live tmux context."
        end

        def resolve_pane(session: nil, window: nil, pane: nil)
          explicit = normalize(pane)
          return build_pane_target(explicit, session: session, window: window, source: "explicit") if explicit

          env_pane = normalize(env["ACE_TMUX_PANE"])
          return build_pane_target(env_pane, session: session, window: window, source: "env") if env_pane

          window_target = resolve_window(session: session, window: window)
          live_pane = resolve_live_pane(window_target.window_target)
          return Models::RuntimeTarget.new(
            session: window_target.session,
            window: window_target.window,
            pane: live_pane,
            raw_window_target: window_target.window_target,
            source: "live"
          ) if live_pane

          raise Ace::Tmux::TargetResolutionError, "Could not resolve tmux pane from flags, ACE_TMUX_PANE, or live tmux context."
        end

        private

        attr_reader :executor, :tmux, :env

        def build_window_target(session:, raw_window:, source:)
          identity = resolve_window_reference(session, raw_window)
          unless identity
            return Models::RuntimeTarget.new(
              session: session,
              window: raw_window,
              raw_window_target: raw_window.start_with?("@") ? raw_window : nil,
              source: source
            )
          end

          Models::RuntimeTarget.new(
            session: session,
            window: identity[:name],
            raw_window_target: identity[:id],
            source: source
          )
        end

        def build_pane_target(raw_pane, session:, window:, source:)
          if raw_pane.start_with?("%") || raw_window_pane_target?(raw_pane)
            return Models::RuntimeTarget.new(pane: raw_pane, source: source)
          end

          if (full_target = parse_full_pane_target(raw_pane))
            window_target = resolve_window(session: full_target[:session], window: full_target[:window])
            return Models::RuntimeTarget.new(
              session: window_target.session,
              window: window_target.window,
              pane: full_target[:pane],
              raw_window_target: window_target.window_target,
              source: source
            )
          end

          shorthand = pane_index_shorthand(raw_pane)
          if shorthand
            window_target = resolve_window(session: session, window: window)
            return Models::RuntimeTarget.new(
              session: window_target.session,
              window: window_target.window,
              pane: shorthand,
              raw_window_target: window_target.window_target,
              source: source
            )
          end

          raise Ace::Tmux::ValidationError, invalid_pane_target_message(raw_pane)
        end

        def raw_window_pane_target?(raw_pane)
          raw_pane.match?(/\A@\d+\.\d+\z/)
        end

        def parse_full_pane_target(raw_pane)
          session_name, rest = raw_pane.split(":", 2)
          return nil unless rest

          separator = rest.rindex(".")
          return nil unless separator

          window_name = rest[0...separator]
          pane_index = rest[(separator + 1)..]
          return nil unless pane_index
          return nil if session_name.to_s.empty? || window_name.to_s.empty? || pane_index.to_s.empty?

          {
            session: session_name,
            window: window_name,
            pane: pane_index
          }
        end

        def pane_index_shorthand(raw_pane)
          return raw_pane if raw_pane.match?(/\A\d+\z/)
          return raw_pane[1..] if raw_pane.match?(/\A\.\d+\z/)

          nil
        end

        def invalid_pane_target_message(raw_pane)
          colon_form = raw_pane.match(/\A([^:\s]+):([^:\s]+):([^:\s]+)\z/)
          if colon_form
            corrected = "#{colon_form[1]}:#{colon_form[2]}.#{colon_form[3]}"
            return "Invalid pane target '#{raw_pane}'. Use '%8', '#{corrected}', '.1', or '--window #{colon_form[2]} --pane #{colon_form[3]}'."
          end

          if raw_pane.start_with?("@") && !raw_pane.include?(".")
            return "Invalid pane target '#{raw_pane}'. Use '%8', 'default:3.1', '.1', or '--window 3 --pane 1'. '#{raw_pane}' is a tmux window id, not a pane target."
          end

          "Invalid pane target '#{raw_pane}'. Use '%8', 'default:3.1', '.1', or '--window 3 --pane 1'."
        end

        def resolve_window_reference(session, raw_window)
          windows = list_window_identities(session)

          if raw_window.start_with?("@")
            windows.find { |entry| entry[:id] == raw_window }
          elsif raw_window.match?(/\A\d+\z/)
            windows.find { |entry| entry[:index] == raw_window }
          else
            windows.find { |entry| entry[:name] == raw_window }
          end
        end

        def list_window_identities(session)
          result = executor.capture(
            Atoms::TmuxCommandBuilder.list_windows(
              session,
              format: '#{window_id}' + "\t" + '#{window_index}' + "\t" + '#{window_name}' + "\t" + '#{window_active}',
              tmux: tmux
            )
          )
          return [] unless result.success?

          result.stdout.split("\n").map { |line| parse_window_identity(line) }.compact
        end

        def parse_window_identity(line)
          id, index, name, active = line.to_s.split("\t", 4)
          return nil if [id, index, name].any? { |value| value.to_s.empty? }

          {
            id: id,
            index: index,
            name: name,
            active: active == "1"
          }
        end

        def resolve_live_session
          return nil if normalize(env["TMUX"]).nil?

          result = executor.capture(Atoms::TmuxCommandBuilder.display_message("#S", tmux: tmux))
          result.success? ? normalize(result.stdout) : nil
        rescue Errno::ENOENT
          nil
        end

        def resolve_live_window(session:)
          result = executor.capture(
            Atoms::TmuxCommandBuilder.display_message_target(
              "#{session}:",
              '#{window_id}' + "\t" + '#{window_index}' + "\t" + '#{window_name}',
              tmux: tmux
            )
          )
          identity = parse_window_identity(result.stdout)
          return identity if identity

          explicit_session = normalize(env["ACE_TMUX_SESSION"])
          if explicit_session == session
            fallback = active_window_identity(session)
            return fallback if fallback
          end

          return nil if normalize(env["TMUX"]).nil?

          fallback = executor.capture(
            Atoms::TmuxCommandBuilder.display_message(
              '#{window_id}' + "\t" + '#{window_index}' + "\t" + '#{window_name}',
              tmux: tmux
            )
          )
          parse_window_identity(fallback.stdout)
        rescue Errno::ENOENT
          nil
        end

        def resolve_live_pane(window_target)
          return nil if normalize(env["TMUX"]).nil?

          result = executor.capture(
            Atoms::TmuxCommandBuilder.display_message_target(window_target, '#{pane_index}', tmux: tmux)
          )
          result.success? ? normalize(result.stdout) : nil
        rescue Errno::ENOENT
          nil
        end

        def normalize(value)
          candidate = value.to_s.strip
          candidate.empty? ? nil : candidate
        end

        def active_window_identity(session)
          windows = list_window_identities(session)
          windows.find { |entry| entry[:active] } || windows.first
        end
      end
    end
  end
end
