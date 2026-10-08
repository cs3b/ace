# frozen_string_literal: true
require_relative "base"
module Ace
  module Review
    module CLI
      module Commands
        module Campaign
          class Finish < Base
            desc "Validate acceptance and emit a local campaign result"
            argument :id, required: true, desc: "Durable campaign ID"

            option :profile, desc: "Expected frozen campaign profile"

            def call(id:, **options)
              payload = run(options) { |manager| manager.finish(id, dry_run: options[:dry_run], profile: options[:profile]) }
              raise Ace::Support::Cli::Error, payload["reasons"].join("; ") unless payload["accepted"] || payload["outcome"] == "discovery_complete"
              0
            end
          end
        end
      end
    end
  end
end
