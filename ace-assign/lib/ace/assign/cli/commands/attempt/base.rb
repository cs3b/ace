# frozen_string_literal: true

require "json"

module Ace
  module Assign
    module CLI
      module Commands
        # Public `ace-assign attempt` command namespace (interface contract:
        # start, status, finish, reconcile).
        module Attempt
          # Shared coordinator construction, option validation, and JSON output.
          module Base
            private

            def build_coordinator
              Organisms::AttemptCoordinator.new
            end

            def require_option(options, key, usage)
              value = options[key].to_s.strip
              raise Ace::Support::Cli::Error, "Missing --#{key}: usage: ace-assign attempt #{usage}" if value.empty?

              value
            end

            def emit_json(payload)
              puts JSON.generate(payload)
            end
          end
        end
      end
    end
  end
end
