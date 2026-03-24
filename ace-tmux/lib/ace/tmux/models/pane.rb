# frozen_string_literal: true

module Ace
  module Tmux
    module Models
      # Represents a tmux pane configuration
      class Pane
        attr_reader :commands, :focus, :root, :name, :options

        # @param commands [Array<String>] Commands to run in the pane
        # @param focus [Boolean] Whether this pane should be focused
        # @param root [String, nil] Working directory for the pane
        # @param name [String, nil] Optional pane name
        # @param options [Hash] Raw tmux pane options (passed to set-option -p)
        def initialize(commands: [], focus: false, root: nil, name: nil, options: {})
          @commands = Array(commands)
          @focus = focus
          @root = root
          @name = name
          @options = options || {}
        end

        def focus?
          @focus == true
        end

        def to_h
          hash = {"commands" => @commands, "focus" => @focus}
          hash["root"] = @root if @root
          hash["name"] = @name if @name
          hash["options"] = @options unless @options.empty?
          hash
        end
      end
    end
  end
end
