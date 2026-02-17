# frozen_string_literal: true

module Ace
  module Assign
    module Atoms
      # Pure function: renders assignment hierarchy as an indented tree string.
      #
      # Takes a flat list of AssignmentInfo objects with parent fields
      # and renders them as a visual tree with Unicode box-drawing characters.
      #
      # @example
      #   TreeFormatter.format(assignments)
      #   # =>  task-148-implement
      #   #     +-- onboard (completed)
      #   #     +-- work-on-task (running)
      #   #     |   +-- onboard (completed)
      #   #     |   +-- implement (in_progress)
      #   #     |   \-- verify-tests (pending)
      #   #     \-- review-pr (pending)
      module TreeFormatter
        # State display labels matching list command
        STATE_LABELS = {
          pending: "pending",
          in_progress: "in_progress",
          running: "running",
          paused: "paused",
          completed: "completed",
          failed: "failed",
          empty: "empty"
        }.freeze

        # Format a flat list of assignment info objects as a tree.
        #
        # @param assignments [Array<Models::AssignmentInfo>] Flat list with parent metadata
        # @return [String] Formatted tree string
        def self.format(assignments)
          return "No assignments found." if assignments.empty?

          # Build ID index first (pass 1), then attach children (pass 2)
          by_id = {}
          assignments.each { |info| by_id[info.id] = info }

          children_of = Hash.new { |h, k| h[k] = [] }
          assignments.each do |info|
            parent_id = extract_parent_id(info)
            if parent_id && by_id.key?(parent_id)
              children_of[parent_id] << info
            end
          end

          # Find roots: assignments whose parent is nil or not in the set
          roots = assignments.reject do |info|
            parent_id = extract_parent_id(info)
            parent_id && by_id.key?(parent_id)
          end

          lines = []
          roots.each do |root|
            render_node(root, children_of, lines, prefix: "", is_last: true, is_root: true)
          end

          lines.join("\n")
        end

        # Extract parent assignment ID from an AssignmentInfo.
        #
        # @param info [Models::AssignmentInfo] Assignment info
        # @return [String, nil] Parent assignment ID or nil
        def self.extract_parent_id(info)
          return nil unless info.assignment.respond_to?(:parent)

          info.assignment.parent
        end
        private_class_method :extract_parent_id

        # Render a single node and its children recursively.
        #
        # @param info [Models::AssignmentInfo] Current node
        # @param children_of [Hash] Children index
        # @param lines [Array<String>] Output lines accumulator
        # @param prefix [String] Indentation prefix
        # @param is_last [Boolean] Whether this is the last sibling
        # @param is_root [Boolean] Whether this is a root node
        def self.render_node(info, children_of, lines, prefix:, is_last:, is_root:)
          state_label = STATE_LABELS[info.state] || info.state.to_s

          if is_root
            lines << "#{info.name} [#{info.id}] (#{state_label}) #{info.progress}"
            child_prefix = ""
          else
            connector = is_last ? "\\-- " : "+-- "
            lines << "#{prefix}#{connector}#{info.name} [#{info.id}] (#{state_label}) #{info.progress}"
            child_prefix = prefix + (is_last ? "    " : "|   ")
          end

          children = children_of[info.id] || []
          children.each_with_index do |child, idx|
            child_is_last = idx == children.size - 1
            render_node(child, children_of, lines, prefix: child_prefix, is_last: child_is_last, is_root: false)
          end
        end
        private_class_method :render_node
      end
    end
  end
end
