# frozen_string_literal: true

require "ace/tmux"
require "fileutils"
require "shellwords"
require "yaml"

module Ace
  module Assign
    module Molecules
      # Shared ace-tmux backed runtime helper for tmux fork launches.
      class TmuxControlSurfaceRunner
        def initialize(executor: Ace::Tmux::Molecules::TmuxExecutor.new, resolver: nil, control_surface: nil, tmux: "tmux", env: ENV)
          @executor = executor
          @tmux = tmux
          @env = env
          @resolver = resolver || Ace::Tmux::Molecules::RuntimeTargetResolver.new(executor: executor, tmux: tmux, env: env)
          @control_surface = control_surface || Ace::Tmux::Organisms::ControlSurface.new(
            executor: executor,
            resolver: @resolver,
            tmux: tmux
          )
        end

        def tmux_context?
          !current_session.to_s.strip.empty?
        end

        def current_session
          resolver.resolve_session.session
        rescue Ace::Tmux::TargetResolutionError
          nil
        end

        def current_window
          explicit = env["ACE_ASSIGN_FORK_WINDOW"].to_s.strip
          return explicit unless explicit.empty?

          resolver.resolve_window(session: current_session).window
        rescue Ace::Tmux::TargetResolutionError
          nil
        end

        def current_pane
          explicit = env["ACE_ASSIGN_CALLBACK_PANE"].to_s.strip
          return explicit unless explicit.empty?

          resolver.resolve_pane(session: current_session, window: current_window).pane_target
        rescue Ace::Tmux::TargetResolutionError
          nil
        end

        def fork_window_name(base_window)
          base = base_window.to_s.strip.sub(/-fs\z/, "")
          sanitized = Ace::Tmux::Atoms::WindowNameSanitizer.call(base, fallback: "fork")

          "#{sanitized}-fs"
        end

        def ensure_window(session:, name:, root:)
          if (window_id = find_window_id(session: session, name: name))
            return {created: false, target: window_id, window_id: window_id, name: name}
          end

          result = executor.capture(
            Ace::Tmux::Atoms::TmuxCommandBuilder.new_window(
              session,
              name: name,
              root: root,
              print_format: '#{window_id}',
              tmux: tmux
            )
          )
          raise Error, "Failed to create tmux fork window #{name}: #{result.stderr}" unless result.success?

          window_id = result.stdout.to_s.strip
          raise Error, "Failed to create tmux fork window #{name}: empty window id" if window_id.empty?

          {created: true, target: window_id, window_id: window_id, name: name}
        end

        def prepare_pane(session:, window:, root:, keep_existing:, window_target: nil)
          target = window_target || "#{session}:#{window}"
          pane = if keep_existing
            first_pane(target)
          else
            create_pane(target, root)
          end

          set_pane_remain_on_exit(pane)
          select_layout(target)
          pane
        end

        def select_window(session:, window:, window_target: nil)
          target = window_target || "#{session}:#{window}"
          run!(
            Ace::Tmux::Atoms::TmuxCommandBuilder.select_window(target, tmux: tmux),
            "select tmux fork window #{window}"
          )
        end

        def run_invocation_in_pane(pane_target:, command:, env: nil, working_dir: nil, visible_handoff: nil)
          shell_command = build_pane_shell_command(
            command: command,
            env: env,
            working_dir: working_dir,
            visible_handoff: visible_handoff
          )
          control_surface.send_command(pane: pane_target, command: shell_command)
        rescue Ace::Tmux::Error => e
          raise Error, "Failed to send tmux fork command: #{e.message}"
        end

        def run_script_in_pane(pane_target:, script_path:)
          control_surface.send_command(pane: pane_target, command: "bash #{File.expand_path(script_path).shellescape}")
        rescue Ace::Tmux::Error => e
          raise Error, "Failed to send tmux fork command: #{e.message}"
        end

        def capture_recent_output(pane_target:, lines: 40)
          control_surface.capture_recent_output(pane: pane_target, lines: lines)
        rescue Ace::Tmux::Error => e
          raise Error, "Failed to capture pane #{pane_target}: #{e.message}"
        end

        def merge_tmux_metadata(session_meta_file:, session:, window:, pane:, window_id: nil, callback_pane: nil)
          data = if File.exist?(session_meta_file)
            YAML.safe_load_file(session_meta_file) || {}
          else
            {}
          end
          data["launch_mode"] = "tmux"
          data["tmux_session"] = session
          data["tmux_window"] = window
          data["tmux_window_id"] = window_id if window_id
          data["tmux_pane_id"] = pane
          data["callback_pane"] = callback_pane if callback_pane && !callback_pane.empty?
          File.write(session_meta_file, data.to_yaml)
        end

        private

        attr_reader :control_surface, :env, :executor, :resolver, :tmux

        def find_window_id(session:, name:)
          result = executor.capture(
            Ace::Tmux::Atoms::TmuxCommandBuilder.list_windows(
              session,
              format: '#{window_id}' + "\t" + '#{window_name}',
              tmux: tmux
            )
          )
          return nil unless result.success?

          result.stdout.split("\n").map(&:strip).reject(&:empty?).each do |line|
            window_id, window_name = line.split("\t", 2)
            return window_id if window_name == name && !window_id.to_s.empty?
          end

          nil
        end

        def first_pane(target)
          result = executor.capture(
            Ace::Tmux::Atoms::TmuxCommandBuilder.list_panes(target, format: '#{pane_id}', tmux: tmux)
          )
          raise Error, "Failed to inspect panes for #{target}: #{result.stderr}" unless result.success?

          pane = result.stdout.split("\n").map(&:strip).reject(&:empty?).first
          raise Error, "No panes found for #{target}" if pane.to_s.empty?

          pane
        end

        def create_pane(target, root)
          result = executor.capture(
            Ace::Tmux::Atoms::TmuxCommandBuilder.split_window(
              target,
              root: root,
              print_format: '#{pane_id}',
              tmux: tmux
            )
          )
          raise Error, "Failed to create tmux fork pane in #{target}: #{result.stderr}" unless result.success?

          pane = result.stdout.to_s.strip
          raise Error, "Failed to create tmux fork pane in #{target}: empty pane id" if pane.empty?

          pane
        end

        def set_pane_remain_on_exit(pane_target)
          run!(
            Ace::Tmux::Atoms::TmuxCommandBuilder.set_pane_option(pane_target, "remain-on-exit", "on", tmux: tmux),
            "enable remain-on-exit"
          )
        end

        def select_layout(target)
          run!(
            Ace::Tmux::Atoms::TmuxCommandBuilder.select_layout(target, "tiled", tmux: tmux),
            "apply tiled layout"
          )
        end

        def run!(cmd, action)
          return if executor.run(cmd)

          raise Error, "Failed to #{action}"
        end

        def build_pane_shell_command(command:, env:, working_dir:, visible_handoff:)
          steps = []
          resolved_working_dir = working_dir.to_s.strip
          steps << "cd #{Shellwords.escape(File.expand_path(resolved_working_dir))}" unless resolved_working_dir.empty?

          handoff = visible_handoff.to_s
          steps << "printf '%s\\n' #{Shellwords.escape(handoff)}" unless handoff.empty?

          steps << "exec #{build_exec_command(command: command, env: env)}"
          steps.join(" && ")
        end

        def build_exec_command(command:, env:)
          cmd = Array(command).map { |part| Shellwords.escape(part.to_s) }.join(" ")
          env_hash = env.respond_to?(:to_h) ? env.to_h : {}
          unset_parts = []
          assign_parts = []

          env_hash.each do |key, value|
            next if key.to_s.strip.empty?

            if value.nil?
              unset_parts << "-u #{Shellwords.escape(key.to_s)}"
            else
              assign_parts << "#{key}=#{Shellwords.escape(value.to_s)}"
            end
          end
          env_parts = unset_parts + assign_parts

          return cmd if env_parts.empty?

          "env #{env_parts.join(' ')} #{cmd}"
        end
      end
    end
  end
end
