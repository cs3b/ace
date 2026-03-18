# frozen_string_literal: true

module Ace
  module Tmux
    module Organisms
      # Orchestrates adding a window to an existing session from a preset
      #
      # Flow:
      #   1. Detect current session (from $TMUX env or --session flag)
      #   2. Load and resolve window preset
      #   3. Create window in session
      #   4. Set up panes
      #   5. Apply layout
      class WindowManager
        # @param executor [Molecules::TmuxExecutor] Command executor
        # @param session_builder [Molecules::SessionBuilder] Preset resolver/builder
        # @param tmux [String] tmux binary path
        def initialize(executor:, session_builder:, tmux: "tmux")
          @executor = executor
          @session_builder = session_builder
          @tmux = tmux
        end

        # Add a window from a preset to a session
        #
        # @param preset_name [String] Window preset name (used as fallback window name)
        # @param session [String, nil] Target session name (nil = detect current)
        # @param root [String, nil] Working directory override
        # @param name [String, nil] Explicit window name override
        # @return [String] The effective window name
        def add_window(preset_name, session: nil, root: nil, name: nil)
          target_session = session || detect_current_session
          raise NotInTmuxError, "Not inside a tmux session. Use --session to specify one." unless target_session

          window = @session_builder.build_window(preset_name)
          effective_root = root || window.root
          effective_name = resolve_window_name(name, root, preset_name)

          # Create the window and capture its unique ID
          cmd = Atoms::TmuxCommandBuilder.new_window(
            target_session,
            name: effective_name,
            root: effective_root,
            print_format: '#{window_id}',
            tmux: @tmux
          )
          result = @executor.capture(cmd)
          unless result.success?
            detail = result.respond_to?(:stderr) && !result.stderr.to_s.empty? ? ": #{result.stderr.strip}" : ""
            raise "Failed to create window#{detail}"
          end

          window_target = result.stdout.strip
          setup_panes(window, window_target, effective_root)

          effective_name
        end

        private

        def resolve_window_name(explicit_name, root, preset_name)
          return explicit_name if explicit_name
          return File.basename(root) if root

          preset_name
        end

        def detect_current_session
          return ENV["ACE_TMUX_SESSION"] if ENV["ACE_TMUX_SESSION"]
          return nil unless ENV["TMUX"]

          cmd = Atoms::TmuxCommandBuilder.display_message("#S", tmux: @tmux)
          result = @executor.capture(cmd)
          result.success? ? result.stdout : nil
        end

        def setup_panes(window, window_target, base_root = nil)
          return unless window.panes.any?

          if window.nested_layout?
            setup_nested_panes(window, window_target, base_root)
          else
            setup_flat_panes(window, window_target, base_root)
          end
        end

        def setup_flat_panes(window, window_target, base_root = nil)
          # Create additional panes via split (first pane already exists)
          window.panes.drop(1).each do |pane|
            pane_root = pane.root || base_root || window.root
            cmd = Atoms::TmuxCommandBuilder.split_window(
              window_target,
              root: pane_root,
              tmux: @tmux
            )
            @executor.run(cmd)
          end

          # Apply window options before layout
          window.options.each do |option, value|
            cmd = Atoms::TmuxCommandBuilder.set_window_option(window_target, option, value, tmux: @tmux)
            @executor.run(cmd)
          end

          # Apply layout
          if window.layout
            cmd = Atoms::TmuxCommandBuilder.select_layout(window_target, window.layout, tmux: @tmux)
            @executor.run(cmd)
          end

          # Send commands to all panes (after layout is stable)
          window.panes.each_with_index do |pane, idx|
            send_pane_commands(window, pane, "#{window_target}.#{idx}")
          end

          # Focus pane
          focus_pane = window.panes.index(&:focus?)
          if focus_pane
            cmd = Atoms::TmuxCommandBuilder.select_pane("#{window_target}.#{focus_pane}", tmux: @tmux)
            @executor.run(cmd)
          end
        end

        def setup_nested_panes(window, window_target, base_root = nil)
          tree = window.layout_tree
          leaves = tree.leaves
          leaf_count = leaves.length

          # Create leaf_count - 1 additional panes via flat splits
          # Use per-leaf root when available, falling back to base/window root
          leaves.drop(1).each do |leaf|
            pane_root = leaf.pane.root || base_root || window.root
            cmd = Atoms::TmuxCommandBuilder.split_window(
              window_target,
              root: pane_root,
              tmux: @tmux
            )
            @executor.run(cmd)
          end

          # Get pane IDs
          pane_ids = query_pane_ids(window_target)

          # Get window dimensions
          width, height = query_window_dimensions(window_target, pane_ids.first || 0)

          # Build and apply custom layout string
          layout_string = Atoms::LayoutStringBuilder.build(
            tree, width: width, height: height, pane_ids: pane_ids
          )
          cmd = Atoms::TmuxCommandBuilder.select_layout(window_target, layout_string, tmux: @tmux)
          @executor.run(cmd)

          # Apply window options
          window.options.each do |option, value|
            cmd = Atoms::TmuxCommandBuilder.set_window_option(window_target, option, value, tmux: @tmux)
            @executor.run(cmd)
          end

          # Send commands to each leaf pane
          # First leaf was created with window root; cd if it has its own root
          first_leaf = leaves.first
          leaves.each do |leaf|
            pane_target = "#{window_target}.#{leaf.pane_id}"
            if leaf == first_leaf && leaf.pane.root
              cd_cmd = Atoms::TmuxCommandBuilder.send_keys(pane_target, "cd #{leaf.pane.root}", tmux: @tmux)
              @executor.run(cd_cmd)
            end
            send_pane_commands(window, leaf.pane, pane_target)
          end

          # Focus the appropriate leaf pane
          focus_leaf = leaves.find { |l| l.pane.focus? }
          if focus_leaf
            cmd = Atoms::TmuxCommandBuilder.select_pane("#{window_target}.#{focus_leaf.pane_id}", tmux: @tmux)
            @executor.run(cmd)
          end
        end

        def query_pane_ids(window_target)
          cmd = Atoms::TmuxCommandBuilder.list_panes(window_target, format: '#{pane_index}', tmux: @tmux)
          result = @executor.capture(cmd)
          return [] unless result.success?

          result.stdout.split("\n").map(&:to_i)
        end

        def query_window_dimensions(window_target, pane_id)
          cmd = Atoms::TmuxCommandBuilder.display_message_target(
            "#{window_target}.#{pane_id}",
            '#{window_width}x#{window_height}',
            tmux: @tmux
          )
          result = @executor.capture(cmd)
          return [200, 50] unless result.success?

          parts = result.stdout.strip.split("x")
          [parts[0].to_i, parts[1].to_i]
        end

        def send_pane_commands(window, pane, pane_target)
          if window.pre_window
            cmd = Atoms::TmuxCommandBuilder.send_keys(pane_target, window.pre_window, tmux: @tmux)
            @executor.run(cmd)
          end

          # Apply pane options
          pane.options.each do |option, value|
            cmd = Atoms::TmuxCommandBuilder.set_pane_option(pane_target, option, value, tmux: @tmux)
            @executor.run(cmd)
          end

          pane.commands.each do |command|
            cmd = Atoms::TmuxCommandBuilder.send_keys(pane_target, command, tmux: @tmux)
            @executor.run(cmd)
          end
        end
      end
    end
  end
end
