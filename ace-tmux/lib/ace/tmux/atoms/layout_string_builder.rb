# frozen_string_literal: true

module Ace
  module Tmux
    module Atoms
      # Pure function that builds a tmux custom layout string from a LayoutNode tree.
      #
      # Takes a tree of LayoutNode objects, window dimensions, and pane IDs,
      # then produces a tmux layout string like:
      #   "a]b4,200x50,0,0{80x50,0,0,0,119x50,81,0[119x25,81,0,1,119x24,81,26,2]}"
      #
      # tmux layout string format:
      #   - `{...}` = horizontal split (children side by side)
      #   - `[...]` = vertical split (children stacked)
      #   - Leaf: `WxH,xoff,yoff,pane_id`
      #   - Container: `WxH,xoff,yoff{child1,child2,...}` or `WxH,xoff,yoff[child1,child2,...]`
      module LayoutStringBuilder
        module_function

        # Build a complete tmux layout string with checksum.
        #
        # @param root [Models::LayoutNode] Root of the layout tree
        # @param width [Integer] Window width in cells
        # @param height [Integer] Window height in cells
        # @param pane_ids [Array<Integer>] Pane IDs in DFS leaf order
        # @return [String] Complete tmux layout string with checksum
        def build(root, width:, height:, pane_ids:)
          # Assign pane IDs to leaves in DFS order
          # Fall back to sequential index if pane_ids is shorter than leaves
          leaves = root.leaves
          leaves.each_with_index { |leaf, i| leaf.pane_id = pane_ids[i] || i }

          body = generate_node(root, x: 0, y: 0, width: width, height: height)
          checksum = layout_checksum(body)
          "#{checksum},#{body}"
        end

        # Recursively generate the layout string for a node.
        #
        # @param node [Models::LayoutNode] Current node
        # @param x [Integer] X offset
        # @param y [Integer] Y offset
        # @param width [Integer] Available width
        # @param height [Integer] Available height
        # @return [String] Layout string fragment
        def generate_node(node, x:, y:, width:, height:)
          if node.leaf?
            "#{width}x#{height},#{x},#{y},#{node.pane_id}"
          else
            sizes = allocate_sizes(node.children, total: split_dimension(node.direction, width, height))
            open_bracket, close_bracket = brackets_for(node.direction)

            child_strings = []
            offset = split_offset(node.direction, x, y)

            node.children.each_with_index do |child, i|
              child_w, child_h = child_dimensions(node.direction, width, height, sizes[i])
              child_x, child_y = child_offsets(node.direction, x, y, offset)

              child_strings << generate_node(child, x: child_x, y: child_y, width: child_w, height: child_h)

              # Advance offset past this child + 1-cell separator (except after last)
              offset += sizes[i] + 1
            end

            "#{width}x#{height},#{x},#{y}#{open_bracket}#{child_strings.join(",")}#{close_bracket}"
          end
        end

        # Allocate cell sizes for children along the split axis.
        #
        # Handles explicit sizes (percentage or absolute) and distributes
        # remaining space evenly among auto-sized children.
        # Accounts for 1-cell separators between adjacent panes.
        #
        # @param children [Array<Models::LayoutNode>] Child nodes
        # @param total [Integer] Total cells available along the split axis
        # @return [Array<Integer>] Cell sizes for each child
        def allocate_sizes(children, total:)
          separator_count = children.length - 1
          available = total - separator_count

          sizes = children.map { |child| parse_size(child.size, available) }

          # Distribute remaining space among auto-sized children
          claimed = sizes.compact.sum
          auto_count = sizes.count(&:nil?)

          if auto_count > 0
            remaining = available - claimed
            base = remaining / auto_count
            extra = remaining % auto_count

            auto_index = 0
            sizes = sizes.map do |s|
              next s unless s.nil?

              # Give extra cells to the first auto children
              cell_size = base + ((auto_index < extra) ? 1 : 0)
              auto_index += 1
              cell_size
            end
          end

          sizes
        end

        # Parse an explicit size value into cells.
        #
        # @param size [String, nil] Size string (e.g., "40%", "80") or nil
        # @param total [Integer] Total available cells (for percentage calculation)
        # @return [Integer, nil] Size in cells, or nil if auto
        def parse_size(size, total)
          return nil if size.nil?

          size = size.to_s
          if size.end_with?("%")
            (total * size.to_f / 100).round
          else
            size.to_i
          end
        end

        # Compute tmux layout checksum (CRC16 variant: rotate-right-and-add).
        #
        # @param str [String] Layout string body (without checksum prefix)
        # @return [String] 4-digit hex checksum
        def layout_checksum(str)
          csum = 0
          str.each_byte do |byte|
            csum = ((csum >> 1) | ((csum & 1) << 15)) + byte
            csum &= 0xffff
          end
          format("%04x", csum)
        end

        # @api private
        def brackets_for(direction)
          (direction == :horizontal) ? ["{", "}"] : ["[", "]"]
        end

        # @api private — the dimension we split along
        def split_dimension(direction, width, height)
          (direction == :horizontal) ? width : height
        end

        # @api private — starting offset along split axis
        def split_offset(direction, x, y)
          (direction == :horizontal) ? x : y
        end

        # @api private — child dimensions given parent dimensions and allocated size
        def child_dimensions(direction, parent_w, parent_h, size)
          if direction == :horizontal
            [size, parent_h]
          else
            [parent_w, size]
          end
        end

        # @api private — child offsets
        def child_offsets(direction, parent_x, parent_y, offset)
          if direction == :horizontal
            [offset, parent_y]
          else
            [parent_x, offset]
          end
        end
      end
    end
  end
end
