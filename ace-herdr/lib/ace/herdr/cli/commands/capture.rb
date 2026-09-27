# frozen_string_literal: true

require "ace/support/cli"
require "ace/core"
require_relative "support"

module Ace
  module Herdr
    module CLI
      module Commands
        class Capture < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc <<~DESC.strip
            Print recent pane output as raw text (no JSON wrapping)

            --source visible reads the current screen; recent (default)
            reads terminal history. Read-only: agent routing rules do not
            apply.
          DESC

          example [
            "--pane p5",
            "--pane p5 --lines 40",
            "--pane p5 --source visible"
          ]

          option :pane, type: :string, desc: "Target pane id"
          option :lines, type: :integer, desc: "Number of lines (default: 40)"
          option :source, type: :string, desc: "Snapshot source: visible or recent (default: recent)"

          def initialize(executor: nil)
            @executor = executor
          end

          def call(**options)
            translate_errors do
              cli_error("--pane is required") if options[:pane].to_s.empty?
              source = options[:source] || "recent"
              unless %w[visible recent].include?(source)
                cli_error("--source must be visible or recent")
              end
              control = Organisms::ControlSurface.new(executor: executor)
              puts control.capture(
                pane: options.fetch(:pane), source: source,
                lines: options[:lines] || Organisms::ControlSurface::DEFAULT_LINES
              )
            end
          end
        end
      end
    end
  end
end
