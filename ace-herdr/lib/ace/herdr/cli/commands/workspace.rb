# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"
require_relative "support"

module Ace
  module Herdr
    module CLI
      module Commands
        class Workspace < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc <<~DESC.strip
            Create a workspace from a preset (≈ ace-tmux start)

            Presets resolve through the ADR-022 cascade (.ace/herdr/ >
            ~/.ace/herdr/ > gem defaults) and may compose via `preset:` refs.
            Tabs, panes, splits, commands, and agents are created in declared
            order; --cwd overrides the resolved root/tab cwd.
          DESC

          example [
            "development",
            "development --cwd /path/to/project",
            "development --quiet"
          ]

          argument :preset, desc: "Workspace preset name (list with ace-herdr --list-presets workspaces)"
          option :cwd, type: :string, desc: "Working directory overriding the resolved root/tab cwd"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"

          def initialize(executor: nil, control: nil)
            @executor = executor
            @control = control
          end

          def call(preset: nil, **options)
            translate_errors do
              cli_error("preset name is required") if preset.to_s.empty?
              control = @control || Organisms::ControlSurface.from_config(executor: executor, config: config)
              result = control.create_workspace(preset, cwd: options[:cwd])
              puts JSON.generate(result) unless options[:quiet]
            end
          end
        end
      end
    end
  end
end
