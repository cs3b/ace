# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"
require_relative "support"

module Ace
  module Herdr
    module CLI
      module Commands
        class Tab < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc <<~DESC.strip
            Create a tab from a preset (≈ ace-tmux window)

            The tab lands in the caller's workspace unless --workspace is
            given. Presets resolve through the ADR-022 cascade and may
            compose via `preset:` refs; --cwd overrides the resolved tab cwd.
          DESC

          example [
            "agent",
            "agent --workspace w1",
            "agent --cwd /path/to/project"
          ]

          argument :preset, desc: "Tab preset name (list with ace-herdr --list-presets tabs)"
          option :workspace, type: :string, desc: "Target workspace (default: caller's workspace)"
          option :cwd, type: :string, desc: "Working directory overriding the resolved tab/pane cwd"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"

          def initialize(executor: nil, control: nil)
            @executor = executor
            @control = control
          end

          def call(preset: nil, **options)
            translate_errors do
              cli_error("preset name is required") if preset.to_s.empty?
              control = @control || Organisms::ControlSurface.from_config(executor: executor, config: config)
              result = control.create_tab(
                preset, workspace_id: options[:workspace], cwd: options[:cwd]
              )
              puts JSON.generate(result) unless options[:quiet]
            end
          end
        end
      end
    end
  end
end
