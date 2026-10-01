# frozen_string_literal: true
require_relative "base"
module Ace
  module Assign
    module CLI
      module Commands
        module Attempt
          class Evidence < Ace::Support::Cli::Command
            include Attempt::Base
            desc "Read coordinator-accepted live execution or historical review authority"
            option :attempt, required: true, desc: "Accepted execution attempt ID"
            option :receipt_digest, required: true, desc: "Accepted receipt digest"
            option :kind, default: "check", desc: "Evidence purpose: check, review-collection or review-approval"
            option :check_name, default: "tests", desc: "Required check name (tests binds operation test)"
            option :historical_head, desc: "Recorded collection/approval head for historical authority only"
            option :format, default: "json", desc: "JSON evidence projection"

            def call(**options)
              raise Ace::Support::Cli::Error, "evidence supports --format json" unless options[:format] == "json"
              emit_json(build_coordinator.evidence(attempt_id: options[:attempt], receipt_digest: options[:receipt_digest],
                kind: options[:kind], check_name: options[:check_name], historical_head: options[:historical_head]))
            end
          end
        end
      end
    end
  end
end
