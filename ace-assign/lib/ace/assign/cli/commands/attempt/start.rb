# frozen_string_literal: true

require "json"
require_relative "base"

module Ace
  module Assign
    module CLI
      module Commands
        module Attempt
          # Bind an immutable attempt to an assignment step/subtree.
          #
          # Identity is derived from the execution boundary; a repeated
          # identical start returns the active attempt, and a conflicting
          # binding fails without launching a second writer.
          class Start < Ace::Support::Cli::Command
            include Ace::Support::Cli::Base
            include Attempt::Base

            desc "Start a scoped attempt for an assignment step"

            option :assignment, desc: "Assignment ID"
            option :step, desc: "Step or subtree scope (e.g. 010 or 010.01)"
            option :project, desc: "Project ID the attempt executes in"

            def call(**options)
              usage = "start --assignment ID --step STEP --project ID"
              assignment = require_option(options, :assignment, usage)
              step = require_option(options, :step, usage)
              project = require_option(options, :project, usage)

              attempt = build_coordinator.start(
                assignment_id: assignment,
                step: step,
                project_id: project
              )

              emit_json(attempt.projection)
            end
          end
        end
      end
    end
  end
end
