# frozen_string_literal: true

module Ace
  module Overseer
    module Molecules
      class TmuxWindowOpener
        def initialize(tmux_window_command: nil)
          @tmux_window_command = tmux_window_command || Ace::Tmux::CLI::Commands::Window.new
        end

        def open(worktree_path:, preset: nil)
          return if window_already_open?(worktree_path)

          @tmux_window_command.call(
            root: worktree_path.to_s,
            preset: preset,
            quiet: true,
            session: ENV["ACE_TMUX_SESSION"]
          )
        end

        private

        def window_already_open?(worktree_path)
          session = ENV["ACE_TMUX_SESSION"]
          return false unless session

          name = File.basename(worktree_path.to_s)
          executor = Ace::Tmux::Molecules::TmuxExecutor.new
          result = executor.capture(["tmux", "list-windows", "-t", session, "-F", '#{window_name}'])
          return false unless result.success?

          result.stdout.split("\n").any? { |w| w.strip == name }
        rescue
          false
        end
      end
    end
  end
end
