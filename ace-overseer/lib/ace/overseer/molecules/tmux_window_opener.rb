# frozen_string_literal: true

module Ace
  module Overseer
    module Molecules
      class TmuxWindowOpener
        def initialize(tmux_window_command: nil)
          @tmux_window_command = tmux_window_command || Ace::Tmux::CLI::Commands::Window.new
        end

        def open(worktree_path:)
          @tmux_window_command.call(root: worktree_path.to_s, quiet: true)
        end
      end
    end
  end
end
