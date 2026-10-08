# frozen_string_literal: true
require_relative "base"
module Ace
  module Review
    module CLI
      module Commands
        module Campaign
          class Assess < Base
            desc "Record verified severity correction or evidenced repair attempt"
            argument :id, required: true, desc: "Durable campaign ID"
            option :input, required: true, desc: "Assessment JSON with source identity, kind, reason and evidence"

            def call(id:, **options)
              run(options) { |manager| manager.assess_finding(id, read_json(options[:input]), dry_run: options[:dry_run]) }
              0
            end
          end
        end
      end
    end
  end
end
