# frozen_string_literal: true
require_relative "base"
module Ace
  module Assign
    module CLI
      module Commands
        module Attempt
          class Evidence < Ace::Support::Cli::Command
            include Attempt::Base
            desc "Read coordinator-accepted current-head execution evidence"
            option :attempt, required: true, desc: "Accepted execution attempt ID"
            option :receipt_digest, required: true, desc: "Accepted receipt digest"
            option :kind, default: "check", desc: "Evidence purpose: check or review-collection"
            option :check_name, default: "tests", desc: "Required check name (tests binds operation test)"
            option :format, default: "json", desc: "JSON evidence projection"

            def call(**options)
              raise Ace::Support::Cli::Error, "evidence supports --format json" unless options[:format] == "json"
              emit_json(build_coordinator.evidence(attempt_id: options[:attempt], receipt_digest: options[:receipt_digest],
                kind: options[:kind], check_name: options[:check_name]))
            end
          end
        end
      end
    end
  end
end
