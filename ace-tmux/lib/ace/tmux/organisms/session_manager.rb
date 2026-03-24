# frozen_string_literal: true

module Ace
  module Tmux
    module Organisms
      # Orchestrates session creation from a preset
      #
      # Flow:
      #   1. Check if session already exists
      #   2. Run on_project_start hooks
      #   3. Create session (first window implicitly created)
      #   4. Set up additional windows and panes
      #   5. Set layouts and focus
      #   6. Select startup window
      #   7. Attach (unless --detach)
      class SessionManager
        POLLUTING_ENV_VARS = %w[BUNDLE_GEMFILE BUNDLE_BIN_PATH RUBYOPT RUBYLIB].freeze

        # @param executor [Molecules::TmuxExecutor] Command executor
        # @param session_builder [Molecules::SessionBuilder] Preset resolver/builder
        # @param tmux [String] tmux binary path
        def initialize(executor:, session_builder:, tmux: "tmux")
          @executor = executor
          @session_builder = session_builder
          @tmux = tmux
        end

        # Start a session from a preset
        #
        # @param preset_name [String] Session preset name
        # @param detach [Boolean] Skip attach after creation
        # @param force [Boolean] Kill existing session and recreate
        # @param root [String, nil] Override working directory for the session
        # @return [void]
        def start(preset_name, detach: false, force: false, root: nil)
          session = @session_builder.build(preset_name)
          session.root = root if root

          if session_exists?(session.name)
            if force
              kill_session(session.name)
            else
              attach_session(session) unless detach
              return
            end
          end

          run_hooks(session.on_project_start)
          first_window_target = create_session(session, root_override: root)
          clean_environment(session)
          setup_windows(session)
          select_startup_window(session, first_window_target: first_window_target)
          attach_session(session) unless detach
        end

        private

        # Derive the first window name from the effective working directory.
        # Mirrors WindowManager#resolve_window_name: root basename wins over preset name.
        def resolve_first_window_name(preset_window_name, root_override, session_root)
          effective_root = root_override || session_root || Dir.pwd
          File.basename(effective_root)
        end

        def session_exists?(name)
          cmd = Atoms::TmuxCommandBuilder.has_session(name, tmux: @tmux)
          result = @executor.capture(cmd)
          result.success?
        end

        def kill_session(name)
          cmd = Atoms::TmuxCommandBuilder.kill_session(name, tmux: @tmux)
          @executor.run(cmd)
        end

        def create_session(session, root_override: nil)
          first_window = session.windows.first
          first_window_name = resolve_first_window_name(first_window&.name, root_override, session.root)
          cmd = Atoms::TmuxCommandBuilder.new_session(
            session.name,
            root: session.root,
            window_name: first_window_name,
            tmux_options: session.tmux_options,
            print_format: '#{window_id}',
            tmux: @tmux
          )
          result = @executor.capture(cmd)
          window_target = result.stdout.strip

          # Set up panes for the first window (it was created with the session)
          setup_panes(session, first_window, window_target) if first_window
          window_target
        end

        def setup_windows(session)
          # Skip first window (already created with session)
          session.windows.drop(1).each do |window|
            window_root = window.root || session.root
            cmd = Atoms::TmuxCommandBuilder.new_window(
              session.name,
              name: window.name,
              root: window_root,
              print_format: '#{window_id}',
              tmux: @tmux
            )
            result = @executor.capture(cmd)
            window_target = result.stdout.strip
            setup_panes(session, window, window_target)
          end
        end

        def setup_panes(session, window, window_target)
          return unless window.panes.any?

          if window.nested_layout?
            setup_nested_panes(session, window, window_target)
          else
            setup_flat_panes(session, window, window_target)
          end
        end

        def setup_flat_panes(session, window, window_target)
          # Create additional panes via split (first pane already exists)
          window.panes.drop(1).each do |pane|
            pane_root = pane.root || window.root || session.root
            cmd = Atoms::TmuxCommandBuilder.split_window(
              window_target,
              root: pane_root,
              tmux: @tmux
            )
            @executor.run(cmd)
          end

          # Apply window options before layout (e.g., main-pane-width)
          apply_window_options(window, window_target)

          # Apply layout after all panes are created
          if window.layout
            cmd = Atoms::TmuxCommandBuilder.select_layout(window_target, window.layout, tmux: @tmux)
            @executor.run(cmd)
          end

          # Send commands to all panes (after layout is stable)
          window.panes.each_with_index do |pane, idx|
            send_pane_commands(session, window, pane, "#{window_target}.#{idx}")
          end

          # Focus the appropriate pane
          focus_pane = window.panes.index(&:focus?)
          if focus_pane
            cmd = Atoms::TmuxCommandBuilder.select_pane("#{window_target}.#{focus_pane}", tmux: @tmux)
            @executor.run(cmd)
          end
        end

        def setup_nested_panes(session, window, window_target)
          tree = window.layout_tree
          leaves = tree.leaves
          leaves.length

          # Create leaf_count - 1 additional panes via flat splits
          # Use per-leaf root when available, falling back to window/session root
          leaves.drop(1).each do |leaf|
            pane_root = leaf.pane.root || window.root || session.root
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
          apply_window_options(window, window_target)

          # Send commands to each leaf pane
          # First leaf was created with window/session root; cd if it has its own root
          first_leaf = leaves.first
          leaves.each do |leaf|
            pane_target = "#{window_target}.#{leaf.pane_id}"
            if leaf == first_leaf && leaf.pane.root
              cd_cmd = Atoms::TmuxCommandBuilder.send_keys(pane_target, "cd #{leaf.pane.root}", tmux: @tmux)
              @executor.run(cd_cmd)
            end
            send_pane_commands(session, window, leaf.pane, pane_target)
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

        def send_pane_commands(session, window, pane, pane_target)
          # Send pre_window command if set (session-level, then window-level)
          pre_window = window.pre_window || session.pre_window
          if pre_window
            cmd = Atoms::TmuxCommandBuilder.send_keys(pane_target, pre_window, tmux: @tmux)
            @executor.run(cmd)
          end

          # Apply pane options
          apply_pane_options(pane, pane_target)

          # Send pane commands
          pane.commands.each do |command|
            cmd = Atoms::TmuxCommandBuilder.send_keys(pane_target, command, tmux: @tmux)
            @executor.run(cmd)
          end
        end

        def apply_window_options(window, target)
          window.options.each do |option, value|
            cmd = Atoms::TmuxCommandBuilder.set_window_option(target, option, value, tmux: @tmux)
            @executor.run(cmd)
          end
        end

        def apply_pane_options(pane, target)
          pane.options.each do |option, value|
            cmd = Atoms::TmuxCommandBuilder.set_pane_option(target, option, value, tmux: @tmux)
            @executor.run(cmd)
          end
        end

        def select_startup_window(session, first_window_target: nil)
          target = if session.startup_window
            "#{session.name}:#{session.startup_window}"
          else
            first_window_target || "#{session.name}:#{session.windows.first&.name || 0}"
          end

          cmd = Atoms::TmuxCommandBuilder.select_window(target, tmux: @tmux)
          @executor.run(cmd)
        end

        def attach_session(session)
          cmd = Atoms::TmuxCommandBuilder.attach_session(session.name, tmux: @tmux)
          @executor.exec(cmd)
        end

        def clean_environment(session)
          POLLUTING_ENV_VARS.each do |var|
            cmd = Atoms::TmuxCommandBuilder.set_environment(session.name, var, unset: true, tmux: @tmux)
            @executor.run(cmd)
          end
        end

        def run_hooks(commands)
          return if commands.nil? || commands.empty?

          commands.each do |command|
            system(command)
          end
        end
      end
    end
  end
end
