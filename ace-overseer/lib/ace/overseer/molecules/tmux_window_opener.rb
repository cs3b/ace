# frozen_string_literal: true

module Ace
  module Overseer
    module Molecules
      class TmuxWindowOpener
        def initialize(session_manager: nil, window_manager: nil, executor: nil, tmux: "tmux")
          @tmux = tmux
          @executor = executor || Ace::Tmux::Molecules::TmuxExecutor.new

          if session_manager && window_manager
            @session_manager = session_manager
            @window_manager = window_manager
          else
            preset_loader = Ace::Tmux::Molecules::PresetLoader.new(gem_root: Ace::Tmux.gem_root)
            session_builder = Ace::Tmux::Molecules::SessionBuilder.new(preset_loader: preset_loader)
            @session_manager = session_manager || Ace::Tmux::Organisms::SessionManager.new(
              executor: @executor,
              session_builder: session_builder,
              tmux: @tmux
            )
            @window_manager = window_manager || Ace::Tmux::Organisms::WindowManager.new(
              executor: @executor,
              session_builder: session_builder,
              tmux: @tmux
            )
          end
        end

        def open(worktree_path:, window_name:, session_name:, preset:)
          ensure_session_exists(session_name, root: worktree_path)

          if window_exists?(session_name, window_name)
            return { window_name: window_name, reused: true }
          end

          effective_name = @window_manager.add_window(
            preset,
            session: session_name,
            root: worktree_path,
            name: window_name
          )

          { window_name: effective_name || window_name, reused: false }
        end

        private

        def ensure_session_exists(session_name, root:)
          return if session_exists?(session_name)

          if session_name == "default"
            @session_manager.start("default", detach: true, root: root)
            return
          end

          created = @executor.run([@tmux, "new-session", "-d", "-s", session_name, "-c", root])
          raise Error, "Failed to create tmux session '#{session_name}'" unless created
        end

        def session_exists?(session_name)
          result = @executor.capture([@tmux, "has-session", "-t", session_name])
          result.success?
        rescue Errno::ENOENT
          false
        end

        def window_exists?(session_name, window_name)
          result = @executor.capture([@tmux, "list-windows", "-t", session_name, "-F", %q(#{window_name})])
          return false unless result.success?

          result.stdout.to_s.split("\n").map(&:strip).include?(window_name)
        rescue Errno::ENOENT
          false
        end
      end
    end
  end
end
