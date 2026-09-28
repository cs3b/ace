# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"
require_relative "support"

module Ace
  module Herdr
    module CLI
      module Commands
        class Tidy < Ace::Support::Cli::Command
          include Ace::Support::Cli::Base
          include Runtime

          desc <<~DESC.strip
            Report cleanable agent panes and delivery records as one JSON line

            Dry run by default: nothing is closed or removed. With --apply,
            panes close only on positive completion evidence (observed done
            state or dead pane process) re-confirmed right before closing;
            delivered records older than tidy.delivered_retention_days are
            archived. Unknown, unreadable, pending, retryable, and failed
            resources are never touched.
          DESC

          example [
            "         # Dry run: report candidates only",
            "--apply  # Close eligible panes, archive old delivered records",
            "--quiet  # Suppress the report"
          ]

          option :apply, type: :boolean, desc: "Close eligible panes and archive old delivered records (default: dry run)"
          option :quiet, type: :boolean, aliases: %w[-q], desc: "Suppress output"

          def initialize(executor: nil, config: nil)
            @executor = executor
            @injected_config = config
          end

          def call(**options)
            translate_errors do
              report = tidy.run(apply: options[:apply] || false)
              puts JSON.generate(report) unless options[:quiet]
            end
          end

          private

          def config
            @injected_config || super
          end

          def tidy
            Organisms::Tidy.new(
              executor: executor,
              deliveries_dir: deliveries_dir,
              retention_days: (config["tidy"] || {})["delivered_retention_days"]
            )
          end
        end
      end
    end
  end
end
