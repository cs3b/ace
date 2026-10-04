# frozen_string_literal: true

require "ace/runtime"
require "fileutils"
require "shellwords"
require "yaml"

module Ace
  module Assign
    module Molecules
      # Contract-backed terminal helper for fork launches. Every terminal
      # operation delegates to the resolved Ace::Runtime adapter; assign
      # never calls a runtime-native API directly (k86.3 interface rule).
      class RuntimeControlSurfaceRunner
        def initialize(runtime: nil, env: ENV)
          @runtime_name = runtime
          @env = env
        end

        attr_reader :runtime_name, :env

        def runtime
          @runtime ||= Ace::Runtime.resolve(runtime_name || selected_name)
        end

        def context
          runtime.context
        end

        # Side-effect-free runtime detection ("tmux", "herdr", or nil) for
        # the assign auto launch mode.
        def detect_runtime
          detected = Ace::Runtime.detect(env: env)
          detected&.to_s
        end

        def in_runtime?
          context[:in_runtime] ? true : false
        end

        def current_session
          context[:session]
        end

        def current_window
          explicit = env["ACE_ASSIGN_FORK_WINDOW"].to_s.strip
          return explicit unless explicit.empty?

          context[:window]
        end

        def current_pane
          explicit = env["ACE_ASSIGN_CALLBACK_PANE"].to_s.strip
          return explicit unless explicit.empty?

          context[:pane]
        end

        def fork_window_name(base_window)
          base = base_window.to_s.strip.sub(/-fs\z/, "")

          "#{Ace::Runtime.sanitize_name(base, fallback: "fork")}-fs"
        end

        def ensure_window(name:, root:)
          runtime.ensure_window(name: name, root: root)
        rescue Ace::Runtime::Error => e
          raise Error, "Failed to ensure fork window #{name}: #{e.message}"
        end

        def prepare_pane(window:)
          runtime.prepare_pane(window: window)
        rescue Ace::Runtime::Error => e
          raise Error, "Failed to prepare fork pane in #{window}: #{e.message}"
        end

        def run_invocation_in_pane(pane_target:, command:, env: nil, working_dir: nil, visible_handoff: nil)
          shell_command = build_pane_shell_command(
            command: command,
            env: env,
            working_dir: working_dir,
            visible_handoff: visible_handoff
          )
          runtime.send_command(pane: pane_target, command: shell_command)
        rescue Ace::Runtime::Error => e
          raise Error, "Failed to send fork command: #{e.message}"
        end

        def run_script_in_pane(pane_target:, script_path:)
          runtime.send_command(pane: pane_target, command: "bash #{File.expand_path(script_path).shellescape}")
        rescue Ace::Runtime::Error => e
          raise Error, "Failed to send fork command: #{e.message}"
        end

        def capture_recent_output(pane_target:, lines: 40)
          runtime.capture(pane: pane_target, lines: lines)
        rescue Ace::Runtime::Error => e
          raise Error, "Failed to capture pane #{pane_target}: #{e.message}"
        end

        def merge_runtime_metadata(session_meta_file:, session:, window:, pane:, window_id: nil, callback_pane: nil)
          data = if File.exist?(session_meta_file)
            YAML.safe_load_file(session_meta_file) || {}
          else
            {}
          end
          data["launch_mode"] = runtime_name
          data["runtime"] = runtime_name
          data["session"] = session
          data["window"] = window
          data["window_id"] = window_id if window_id
          data["pane"] = pane
          data["callback_pane"] = callback_pane if callback_pane && !callback_pane.empty?
          File.write(session_meta_file, data.to_yaml)
        end

        private

        def selected_name
          detected = Ace::Runtime.detect(env: env)
          return detected.to_s if detected

          raise Error, "no terminal runtime detected: run inside tmux/herdr, set ACE_RUNTIME, or pass an explicit runtime"
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
