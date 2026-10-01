# frozen_string_literal: true
require_relative "base"
module Ace
  module Review
    module CLI
      module Commands
        module Campaign
          class RecordRound < Base
            desc "Pin or record a round from completed sessions and verified feedback"
            argument :id, required: true, desc: "Durable campaign ID"
            option :input, required: true, desc: "Round JSON with attempt/round IDs, head/base, scopes and session references"

            def call(id:, **options)
              run(options) do |manager|
                manager.record_round(id, read_json(options[:input]), dry_run: options[:dry_run])
              end
              0
            end
          end
        end
      end
    end
  end
end
