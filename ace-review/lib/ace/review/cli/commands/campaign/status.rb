# frozen_string_literal: true
require_relative "base"
module Ace
  module Review
    module CLI
      module Commands
        module Campaign
          class Status < Base
            desc "Inspect durable history and current evidence currency"
            argument :id, required: true, desc: "Durable campaign ID"

            def call(id:, **options)
              payload = run(options) { |manager| manager.status(id) }
              # Read-only status succeeds for known stale or blocked state.
              0
            end
          end
        end
      end
    end
  end
end
