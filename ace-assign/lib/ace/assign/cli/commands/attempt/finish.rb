# frozen_string_literal: true

require "json"
require_relative "base"

module Ace
  module Assign
    module CLI
      module Commands
        module Attempt
          # Accept a structured execution receipt and record the outcome.
          # Terminal and uncertain attempts refuse new receipts.
          class Finish < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base
            include Attempt::Base

            desc "Finish an attempt with a structured execution receipt"

            option :attempt, desc: "Attempt ID"
            option :receipt, desc: "Path to the receipt JSON file"

            def call(**options)
              attempt_id = require_option(options, :attempt, "finish --attempt ID --receipt FILE")
              receipt = require_option(options, :receipt, "finish --attempt ID --receipt FILE")

              result = build_coordinator.finish(attempt_id: attempt_id, receipt_path: receipt)

              emit_json(result.projection)
            end
          end
        end
      end
    end
  end
end
