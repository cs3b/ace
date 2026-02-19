# frozen_string_literal: true

module Ace
  module Tmux
    module Atoms
      # Pure functions for building tmux CLI command arrays
      #
      # Each method returns an Array<String> suitable for Open3.capture3 or system().
      # No I/O — just data transformation.
      module TmuxCommandBuilder
        module_function

        # @param tmux [String] tmux binary path
        # @return [Array<String>]
        def version(tmux: "tmux")
          [tmux, "-V"]
        end

        # Check if a session exists
        # @param name [String] Session name
        # @param tmux [String] tmux binary path
        # @return [Array<String>]
        def has_session(name, tmux: "tmux")
          [tmux, "has-session", "-t", name]
        end

        # Create a new detached session
        # @param name [String] Session name
        # @param root [String, nil] Working directory
        # @param window_name [String, nil] Name for the first window
        # @param tmux_options [String, nil] Additional tmux options
        # @param print_format [String, nil] Format string for -P -F (captures window info)
        # @param tmux [String] tmux binary path
        # @return [Array<String>]
        def new_session(name, root: nil, window_name: nil, tmux_options: nil, print_format: nil, tmux: "tmux")
          cmd = [tmux]
          cmd.concat(tmux_options.split) if tmux_options
          cmd.concat(["new-session", "-d", "-s", name])
          cmd.concat(["-n", window_name]) if window_name
          cmd.concat(["-c", File.expand_path(root)]) if root
          cmd.concat(["-P", "-F", print_format]) if print_format
          cmd
        end

        # Create a new window in an existing session
        # @param session [String] Session name
        # @param name [String, nil] Window name
        # @param root [String, nil] Working directory
        # @param print_format [String, nil] Format string for -P -F (captures window info)
        # @param tmux [String] tmux binary path
        # @return [Array<String>]
        def new_window(session, name: nil, root: nil, print_format: nil, tmux: "tmux")
          cmd = [tmux, "new-window", "-t", "#{session}:"]
          cmd.concat(["-n", name]) if name
          cmd.concat(["-c", File.expand_path(root)]) if root
          cmd.concat(["-P", "-F", print_format]) if print_format
          cmd
        end

        # Split a window to create a new pane
        # @param target [String] Target window (e.g., "session:window")
        # @param root [String, nil] Working directory
        # @param horizontal [Boolean] Split horizontally (default: vertically)
        # @param tmux [String] tmux binary path
        # @return [Array<String>]
        def split_window(target, root: nil, horizontal: false, tmux: "tmux")
          cmd = [tmux, "split-window"]
          cmd << "-h" if horizontal
          cmd.concat(["-t", target])
          cmd.concat(["-c", File.expand_path(root)]) if root
          cmd
        end

        # Send keys (commands) to a target pane
        # @param target [String] Target pane (e.g., "session:window.pane")
        # @param keys [String] Keys/command to send
        # @param tmux [String] tmux binary path
        # @return [Array<String>]
        def send_keys(target, keys, tmux: "tmux")
          [tmux, "send-keys", "-t", target, keys, "Enter"]
        end

        # Set the layout for a window
        # @param target [String] Target window
        # @param layout [String] Layout name (e.g., "main-vertical", "tiled")
        # @param tmux [String] tmux binary path
        # @return [Array<String>]
        def select_layout(target, layout, tmux: "tmux")
          [tmux, "select-layout", "-t", target, layout]
        end

        # Select (focus) a specific window
        # @param target [String] Target window (e.g., "session:window")
        # @param tmux [String] tmux binary path
        # @return [Array<String>]
        def select_window(target, tmux: "tmux")
          [tmux, "select-window", "-t", target]
        end

        # Select (focus) a specific pane
        # @param target [String] Target pane (e.g., "session:window.pane")
        # @param tmux [String] tmux binary path
        # @return [Array<String>]
        def select_pane(target, tmux: "tmux")
          [tmux, "select-pane", "-t", target]
        end

        # Attach to a session
        # @param name [String] Session name
        # @param tmux [String] tmux binary path
        # @return [Array<String>]
        def attach_session(name, tmux: "tmux")
          [tmux, "attach-session", "-t", name]
        end

        # Kill a session
        # @param name [String] Session name
        # @param tmux [String] tmux binary path
        # @return [Array<String>]
        def kill_session(name, tmux: "tmux")
          [tmux, "kill-session", "-t", name]
        end

        # List sessions
        # @param format [String, nil] Format string
        # @param tmux [String] tmux binary path
        # @return [Array<String>]
        def list_sessions(format: nil, tmux: "tmux")
          cmd = [tmux, "list-sessions"]
          cmd.concat(["-F", format]) if format
          cmd
        end

        # Set a window option
        # @param target [String] Target window
        # @param option [String] Option name (e.g., "main-pane-width")
        # @param value [String, Integer] Option value
        # @param tmux [String] tmux binary path
        # @return [Array<String>]
        def set_window_option(target, option, value, tmux: "tmux")
          [tmux, "set-window-option", "-t", target, option, value.to_s]
        end

        # Set a pane option
        # @param target [String] Target pane
        # @param option [String] Option name
        # @param value [String, Integer] Option value
        # @param tmux [String] tmux binary path
        # @return [Array<String>]
        def set_pane_option(target, option, value, tmux: "tmux")
          [tmux, "set-option", "-p", "-t", target, option, value.to_s]
        end

        # Set or unset a session environment variable
        # @param session [String] Session name
        # @param name [String] Environment variable name
        # @param value [String, nil] Value to set (ignored when unset: true)
        # @param unset [Boolean] Unset the variable instead of setting it
        # @param tmux [String] tmux binary path
        # @return [Array<String>]
        def set_environment(session, name, value: nil, unset: false, tmux: "tmux")
          cmd = [tmux, "set-environment", "-t", session]
          if unset
            cmd.concat(["-u", name])
          elsif value
            cmd.concat([name, value])
          else
            cmd << name
          end
          cmd
        end

        # Display a message (useful for getting current session name)
        # @param format [String] Format string (e.g., "#S" for session name)
        # @param tmux [String] tmux binary path
        # @return [Array<String>]
        def display_message(format, tmux: "tmux")
          [tmux, "display-message", "-p", format]
        end

        # Display a message for a specific target (useful for getting window dimensions)
        # @param target [String] Target window/pane (e.g., "session:window.0")
        # @param format [String] Format string (e.g., "#{window_width}x#{window_height}")
        # @param tmux [String] tmux binary path
        # @return [Array<String>]
        def display_message_target(target, format, tmux: "tmux")
          [tmux, "display-message", "-t", target, "-p", format]
        end

        # List panes in a window
        # @param target [String] Target window (e.g., "session:window")
        # @param format [String, nil] Format string (e.g., "#{pane_index}")
        # @param tmux [String] tmux binary path
        # @return [Array<String>]
        def list_panes(target, format: nil, tmux: "tmux")
          cmd = [tmux, "list-panes", "-t", target]
          cmd.concat(["-F", format]) if format
          cmd
        end
      end
    end
  end
end
