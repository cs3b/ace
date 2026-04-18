# frozen_string_literal: true

module Ace
  module Overseer
    module Molecules
      class TmuxWindowOpener
        def initialize(tmux_window_command: nil, tmux_executor: nil)
          @tmux_window_command = tmux_window_command || Ace::Tmux::CLI::Commands::Window.new
          @tmux_executor = tmux_executor || Ace::Tmux::Molecules::TmuxExecutor.new
        end

        def open(worktree_path:, preset: nil)
          ensure_session_exists
          return if window_already_open?(worktree_path)

          @tmux_window_command.call(
            root: worktree_path.to_s,
            preset: preset,
            quiet: true,
            session: ENV["ACE_TMUX_SESSION"]
          )
        end

        private

        def ensure_session_exists
          session = ENV["ACE_TMUX_SESSION"]
          return unless session && !session.empty?
          return if @tmux_executor.capture(["tmux", "has-session", "-t", session]).success?

          created = @tmux_executor.run(["tmux", "new-session", "-d", "-s", session])
          raise "Failed to create tmux session '#{session}'" unless created
        end

        def window_already_open?(worktree_path)
          session = ENV["ACE_TMUX_SESSION"]
          return false unless session

          name = File.basename(worktree_path.to_s)
          result = @tmux_executor.capture(["tmux", "list-windows", "-t", session, "-F", '#{window_name}'])
          return false unless result.success?

          result.stdout.split("\n").any? { |w| w.strip == name }
        rescue
          false
        end
      end
    end
  end
end
