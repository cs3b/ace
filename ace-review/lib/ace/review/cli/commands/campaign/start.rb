# frozen_string_literal: true
require_relative "base"
module Ace
  module Review
    module CLI
      module Commands
        module Campaign
          class Start < Base
            desc "Start/reuse a campaign with frozen subject, requirements and policy"
            option :subject, required: true, desc: "JSON subject: repository and PR or local_candidate_id"
            option :contract, required: true, desc: "Nonempty frozen requirements document"
            option :profile, default: "delivery", desc: "Configured policy profile (default: delivery)"
            option :policy, desc: "Explicit policy JSON snapshot"
            option :predecessor, desc: "Predecessor campaign for changed requirements"
            option :reason, desc: "Required reason for a linked successor"

            def call(**options)
              run(options) do |manager|
                manager.start(subject: read_json(options[:subject]), contract: File.read(options[:contract]),
                  profile: options[:profile], policy: options[:policy] && read_json(options[:policy]),
                  predecessor: options[:predecessor], reason: options[:reason], dry_run: options[:dry_run])
              end
              0
            end
          end
        end
      end
    end
  end
end
