# frozen_string_literal: true
require_relative "base"
module Ace
  module Review
    module CLI
      module Commands
        module Campaign
          class Resume < Base
            desc "Authorize a finite additional campaign phase"
            argument :id, required: true, desc: "Durable campaign ID"
            option :phase, required: true, desc: "Unique authorized phase ID"
            option :reason, required: true, desc: "Reason for additional exploration"
            option :route, required: true, desc: "Explicit selected route (diagnosis for recurrence)"
            option :additional_rounds, type: :integer, required: true, desc: "Finite positive additional budget"

            def call(id:, **options)
              run(options) do |manager|
                manager.resume(id, phase_id: options[:phase], reason: options[:reason], route: options[:route],
                  additional_rounds: options[:additional_rounds], dry_run: options[:dry_run])
              end
              0
            end
          end
        end
      end
    end
  end
end
