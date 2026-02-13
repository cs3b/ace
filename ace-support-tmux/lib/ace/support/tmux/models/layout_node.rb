# frozen_string_literal: true

module Ace
  module Support
    module Tmux
      module Models
        # A tree node for nested pane layouts.
        #
        # Either a **leaf** (wraps a Pane model) or a **container**
        # (direction + children). Used by LayoutStringBuilder to produce
        # tmux custom layout strings.
        class LayoutNode
          attr_reader :direction, :children, :pane, :size
          attr_accessor :pane_id

          # @param direction [:horizontal, :vertical, nil] Split direction (nil for leaf)
          # @param children [Array<LayoutNode>] Child nodes (empty for leaf)
          # @param pane [Models::Pane, nil] Pane model (nil for container)
          # @param size [String, nil] Size hint (e.g., "40%", "80")
          def initialize(direction: nil, children: [], pane: nil, size: nil)
            @direction = direction
            @children = children
            @pane = pane
            @size = size
            @pane_id = nil
          end

          # @return [Boolean] true if this node is a leaf (has a pane, no children)
          def leaf?
            @pane != nil
          end

          # @return [Boolean] true if this node is a container (has direction + children)
          def container?
            !leaf?
          end

          # @return [Integer] Total number of leaf panes in this subtree
          def leaf_count
            return 1 if leaf?

            @children.sum(&:leaf_count)
          end

          # @return [Array<LayoutNode>] All leaf nodes in DFS left-to-right order
          def leaves
            return [self] if leaf?

            @children.flat_map(&:leaves)
          end
        end
      end
    end
  end
end
