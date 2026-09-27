# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"
require_relative "support"

module Ace
  module Herdr
    module CLI
      module Commands
        class ListPresets < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc <<~DESC.strip
            List available workspace/tab presets as one JSON line

            The inventory reflects the merged ADR-022 cascade: gem defaults
            under .ace-defaults/herdr/, overridden by ~/.ace/herdr/ and the
            project .ace/herdr/.
          DESC

          example [
            "",
            "workspaces",
            "tabs"
          ]

          argument :type, required: false, desc: "Scope: workspaces or tabs (default: both)"

          def initialize(executor: nil, control: nil)
            @executor = executor
            @control = control
          end

          def call(type: nil, **options)
            translate_errors do
              control = @control || Organisms::ControlSurface.new(executor: executor)
              puts JSON.generate(control.list_presets(type: type))
            end
          end
        end
      end
    end
  end
end
