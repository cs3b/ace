# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"

module Ace
  module Tmux
    module CLI
      module Commands
        # Add a window to an existing session from a preset
        class Window < Ace::Support::Cli::Command
          include Ace::Core::CLI::Base

          desc <<~DESC.strip
            Add a window to an existing tmux session from a preset

            SYNTAX:
              ace-tmux window <preset> [OPTIONS]

            EXAMPLES:

              # Add code-editor window to current session
              $ ace-tmux window code-editor

              # Add to a specific session
              $ ace-tmux window code-editor --session dev
          DESC

          example [
            "code-editor               # Add to current session",
            "code-editor -s dev        # Add to specific session"
          ]

          argument :preset, required: false, desc: "Window preset name (default: from config)"

          option :name, type: :string, aliases: %w[-n], desc: "Window name (default: basename of --root)"
          option :root, type: :string, aliases: %w[-r], desc: "Working directory for the window"
          option :session, type: :string, aliases: %w[-s], desc: "Target session name"
          option :verbose, type: :boolean, aliases: %w[-v], desc: "Show verbose output"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress non-essential output"

          def call(preset: nil, **options)
            config = Tmux.config
            tmux_bin = config.dig("tmux_binary") || "tmux"

            preset ||= config.dig("defaults", "window")
            raise Ace::Core::CLI::Error.new("No preset specified and no default window configured") unless preset

            preset_loader = Molecules::PresetLoader.new(
              gem_root: Tmux.gem_root
            )
            session_builder = Molecules::SessionBuilder.new(
              preset_loader: preset_loader
            )
            executor = Molecules::TmuxExecutor.new
            manager = Organisms::WindowManager.new(
              executor: executor,
              session_builder: session_builder,
              tmux: tmux_bin
            )

            effective_name = options[:name] || (options[:root] ? File.basename(options[:root]) : preset)
            puts "Adding window '#{effective_name}' (preset: #{preset})..." unless options[:quiet]
            manager.add_window(preset, session: options[:session], root: options[:root], name: options[:name])
            puts "Window '#{effective_name}' added." unless options[:quiet]
          rescue Molecules::PresetNotFoundError => e
            raise Ace::Core::CLI::Error.new(e.message)
          rescue Organisms::NotInTmuxError => e
            raise Ace::Core::CLI::Error.new(e.message)
          end
        end
      end
    end
  end
end
