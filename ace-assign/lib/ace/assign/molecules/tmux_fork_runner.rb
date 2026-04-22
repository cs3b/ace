# frozen_string_literal: true

require "fileutils"
require "open3"
require "shellwords"
require "yaml"
require "ace/tmux"

module Ace
  module Assign
    module Molecules
      # Minimal tmux integration for forked subtree execution.
      class TmuxForkRunner
        DEFAULT_POLL_INTERVAL = 0.2

        def initialize(tmux_binary: "tmux")
          @tmux_binary = tmux_binary
        end

        def tmux_context?
          !current_session.to_s.strip.empty?
        end

        def current_session
          explicit = ENV["ACE_TMUX_SESSION"].to_s.strip
          return explicit unless explicit.empty?
          return nil if ENV["TMUX"].to_s.strip.empty?

          capture([tmux_binary, "display-message", "-p", "#S"]).stdout
        rescue
          nil
        end

        def current_window
          explicit = ENV["ACE_ASSIGN_FORK_WINDOW"].to_s.strip
          return explicit unless explicit.empty?
          session = ENV["ACE_TMUX_SESSION"].to_s.strip
          if !session.empty?
            window = capture([tmux_binary, "display-message", "-t", "#{session}:", "-p", "#W"]).stdout
            return window unless window.empty?

            return active_window_name(session)
          end
          return nil if ENV["TMUX"].to_s.strip.empty?

          capture([tmux_binary, "display-message", "-p", "#W"]).stdout
        rescue
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

          result = capture([
            tmux_binary, "new-window", "-t", "#{session}:", "-n", name, "-c", File.expand_path(root),
            "-P", "-F", '#{window_id}'
          ])
          raise Error, "Failed to create tmux fork window #{name}: #{result.stderr}" unless result.success?

          window_id = result.stdout
          {created: true, target: window_id, window_id: window_id, name: name}
        end

        def prepare_pane(session:, window:, root:, keep_existing:, window_target: nil)
          target = window_target || "#{session}:#{window}"
          if keep_existing
            pane = first_pane(target)
            set_pane_remain_on_exit(pane)
            select_layout(target)
            return pane
          end

          result = capture([tmux_binary, "split-window", "-t", target, "-c", File.expand_path(root), "-P", "-F", '#{pane_id}'])
          raise Error, "Failed to create tmux fork pane in #{window}: #{result.stderr}" unless result.success?

          pane = result.stdout
          set_pane_remain_on_exit(pane)
          select_layout(target)
          pane
        end

        def select_window(session:, window:, window_target: nil)
          target = window_target || "#{session}:#{window}"
          run!([tmux_binary, "select-window", "-t", target], "select tmux fork window #{window}")
        end

        def run_script_in_pane(pane_target:, script_path:)
          command = "bash #{Shellwords.escape(File.expand_path(script_path))}"
          run!([tmux_binary, "send-keys", "-t", pane_target, command, "Enter"], "send tmux fork command")
        end

        def wait_for_completion(status_file:, timeout:)
          deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout.to_i
          until File.exist?(status_file)
            if Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline
              raise Error, "Timed out waiting for tmux fork pane to finish (#{File.basename(status_file)})"
            end

            sleep(DEFAULT_POLL_INTERVAL)
          end

          status = File.read(status_file).strip
          Integer(status)
        rescue ArgumentError
          raise Error, "Invalid tmux fork status file: #{status_file}"
        end

        def merge_tmux_metadata(session_meta_file:, session:, window:, pane:, window_id: nil)
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
          File.write(session_meta_file, data.to_yaml)
        end

        private

        attr_reader :tmux_binary

        def find_window_id(session:, name:)
          result = capture([tmux_binary, "list-windows", "-t", session, "-F", "#{'#{window_id}'}\t#{'#{window_name}'}"])
          return nil unless result.success?

          result.stdout_lines.each do |line|
            window_id, window_name = line.split("\t", 2)
            return window_id if window_name == name && !window_id.to_s.empty?
          end

          nil
        end

        def active_window_name(session)
          result = capture([tmux_binary, "list-windows", "-t", session, "-F", '#{window_active} #{window_name}'])
          return nil unless result.success?

          active = result.stdout_lines.find { |line| line.start_with?("1 ") }
          active&.sub(/\A1\s+/, "") || result.stdout_lines.first&.sub(/\A[01]\s+/, "")
        end

        def first_pane(target)
          result = capture([tmux_binary, "list-panes", "-t", target, "-F", '#{pane_id}'])
          raise Error, "Failed to inspect panes for #{target}: #{result.stderr}" unless result.success?

          pane = result.stdout_lines.first
          raise Error, "No panes found for #{target}" if pane.to_s.empty?

          pane
        end

        def set_pane_remain_on_exit(pane_target)
          run!([tmux_binary, "set-option", "-p", "-t", pane_target, "remain-on-exit", "on"], "enable remain-on-exit")
        end

        def select_layout(target)
          run!([tmux_binary, "select-layout", "-t", target, "tiled"], "apply tiled layout")
        end

        def run!(cmd, action)
          result = capture(cmd)
          return if result.success?

          raise Error, "Failed to #{action}: #{result.stderr}"
        end

        def capture(cmd)
          stdout, stderr, status = Open3.capture3(*cmd)
          Result.new(stdout: stdout, stderr: stderr, status: status)
        end

        Result = Struct.new(:stdout, :stderr, :status, keyword_init: true) do
          def success?
            status.success?
          end

          def stdout
            self[:stdout].to_s.strip
          end

          def stderr
            self[:stderr].to_s.strip
          end

          def stdout_lines
            stdout.split("\n").map(&:strip).reject(&:empty?)
          end
        end
      end
    end
  end
end
