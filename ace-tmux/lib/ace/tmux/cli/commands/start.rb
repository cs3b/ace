# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Tmux
    module CLI
      module Commands
        # Start a tmux session from a preset
        class Start < Ace::Support::Cli::Command
          include Ace::Core::CLI::Base

          desc <<~DESC.strip
            Start a tmux session from a YAML preset

            SYNTAX:
              ace-tmux start <preset> [OPTIONS]

            EXAMPLES:

              # Start the default session
              $ ace-tmux start default

              # Start without attaching
              $ ace-tmux start dev --detach

              # Force recreate existing session
              $ ace-tmux start dev --force
          DESC

          example [
            "default                    # Start default session",
            "dev                        # Start dev session",
            "dev --detach               # Create without attaching",
            "dev --force                # Kill existing and recreate"
          ]

          argument :preset, required: false, desc: "Session preset name (default: from config)"

          option :detach, type: :boolean, aliases: %w[-D], desc: "Don't attach after creating session"
          option :force, type: :boolean, desc: "Kill existing session and recreate"
          option :root, type: :string, aliases: %w[-r], desc: "Working directory for the session"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(preset: nil, **options)
            config = Tmux.config
            tmux_bin = config.dig("tmux_binary") || "tmux"

            preset ||= config.dig("defaults", "session")
            raise Ace::Core::CLI::Error.new("No preset specified and no default session configured") unless preset

            preset_loader = Molecules::PresetLoader.new(
              gem_root: Tmux.gem_root
            )
            session_builder = Molecules::SessionBuilder.new(
              preset_loader: preset_loader
            )
            executor = Molecules::TmuxExecutor.new
            manager = Organisms::SessionManager.new(
              executor: executor,
              session_builder: session_builder,
              tmux: tmux_bin
            )

            puts "Starting session '#{preset}'..." unless options[:quiet]
            manager.start(
              preset,
              detach: options[:detach] || false,
              force: options[:force] || false,
              root: options[:root]
            )
            puts "Session '#{preset}' created." if options[:detach] && !options[:quiet]
          rescue Molecules::PresetNotFoundError => e
            raise Ace::Core::CLI::Error.new(e.message)
          end
        end
      end
    end
  end
end
