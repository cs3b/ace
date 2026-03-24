# frozen_string_literal: true

module Ace
  module Tmux
    module Models
      # Represents a tmux window configuration
      class Window
        attr_reader :name, :layout, :root, :panes, :pre_window, :focus, :options, :layout_tree

        # @param name [String, nil] Window name
        # @param layout [String, nil] tmux layout (e.g., "main-vertical", "tiled")
        # @param root [String, nil] Working directory for the window
        # @param panes [Array<Pane>] Pane configurations
        # @param pre_window [String, nil] Command to run before each pane
        # @param focus [Boolean] Whether this window should be focused
        # @param options [Hash] Raw tmux window options (passed to set-window-option)
        # @param layout_tree [Models::LayoutNode, nil] Nested layout tree (nil for flat layouts)
        def initialize(name: nil, layout: nil, root: nil, panes: [], pre_window: nil, focus: false, options: {}, layout_tree: nil)
          @name = name
          @layout = layout
          @root = root
          @panes = panes
          @pre_window = pre_window
          @focus = focus
          @options = options || {}
          @layout_tree = layout_tree
        end

        # @return [Boolean] true if this window uses a nested layout tree
        def nested_layout?
          !@layout_tree.nil?
        end

        def focus?
          @focus == true
        end

        def to_h
          hash = {"name" => @name, "panes" => @panes.map(&:to_h)}
          hash["layout"] = @layout if @layout
          hash["root"] = @root if @root
          hash["pre_window"] = @pre_window if @pre_window
          hash["focus"] = @focus if @focus
          hash["options"] = @options unless @options.empty?
          hash
        end
      end
    end
  end
end
