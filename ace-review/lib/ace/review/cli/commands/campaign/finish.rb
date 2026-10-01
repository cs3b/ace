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

            def call(id:, **options)
              payload = run(options) { |manager| manager.finish(id, dry_run: options[:dry_run]) }
              raise Ace::Support::Cli::Error, payload["reasons"].join("; ") unless payload["accepted"]
              0
            end
          end
        end
      end
    end
  end
end
