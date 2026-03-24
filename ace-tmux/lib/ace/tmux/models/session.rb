# frozen_string_literal: true

module Ace
  module Tmux
    module Models
      # Represents a tmux session configuration
      class Session
        attr_reader :name, :root, :windows, :pre_window, :startup_window,
          :on_project_start, :on_project_exit, :attach, :tmux_options
        attr_writer :root

        # @param name [String] Session name
        # @param root [String, nil] Base working directory
        # @param windows [Array<Window>] Window configurations
        # @param pre_window [String, nil] Command to run before each window/pane
        # @param startup_window [String, nil] Window to select after creation
        # @param on_project_start [Array<String>] Commands to run before session creation
        # @param on_project_exit [Array<String>] Commands to run on session exit
        # @param attach [Boolean] Whether to attach after creation
        # @param tmux_options [String, nil] Additional tmux options
        def initialize(
          name:,
          root: nil,
          windows: [],
          pre_window: nil,
          startup_window: nil,
          on_project_start: [],
          on_project_exit: [],
          attach: true,
          tmux_options: nil
        )
          @name = name
          @root = root
          @windows = windows
          @pre_window = pre_window
          @startup_window = startup_window
          @on_project_start = Array(on_project_start)
          @on_project_exit = Array(on_project_exit)
          @attach = attach
          @tmux_options = tmux_options
        end

        def attach?
          @attach != false
        end

        def to_h
          hash = {
            "name" => @name,
            "windows" => @windows.map(&:to_h),
            "attach" => @attach
          }
          hash["root"] = @root if @root
          hash["pre_window"] = @pre_window if @pre_window
          hash["startup_window"] = @startup_window if @startup_window
          hash["on_project_start"] = @on_project_start unless @on_project_start.empty?
          hash["on_project_exit"] = @on_project_exit unless @on_project_exit.empty?
          hash["tmux_options"] = @tmux_options if @tmux_options
          hash
        end
      end
    end
  end
end
