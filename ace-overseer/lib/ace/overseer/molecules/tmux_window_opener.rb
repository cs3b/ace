# frozen_string_literal: true

module Ace
  module Overseer
    module Molecules
      class TmuxWindowOpener
        def initialize(window_manager: nil, tmux: "tmux")
          unless window_manager
            executor = Ace::Tmux::Molecules::TmuxExecutor.new
            preset_loader = Ace::Tmux::Molecules::PresetLoader.new(gem_root: Ace::Tmux.gem_root)
            session_builder = Ace::Tmux::Molecules::SessionBuilder.new(preset_loader: preset_loader)
            window_manager = Ace::Tmux::Organisms::WindowManager.new(
              executor: executor,
              session_builder: session_builder,
              tmux: tmux
            )
          end

          @window_manager = window_manager
        end

        def open(worktree_path:, window_name:, session_name: nil, preset:)
          effective_name = @window_manager.add_window(
            preset,
            session: session_name,
            root: worktree_path,
            name: window_name
          )

          { window_name: effective_name || window_name }
        end
      end
    end
  end
end
