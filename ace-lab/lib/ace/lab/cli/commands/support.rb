# frozen_string_literal: true

require "json"
require "ace/support/cli"
require "ace/core"

module Ace
  module Lab
    module CLI
      module Commands
        # Shared collaborator construction for ace-lab commands. The topology
        # service is injectable so tests can substitute fixtures; registered
        # commands resolve the ADR-022 cascade. Output is deterministic JSON
        # only; classified failures emit one error document and then raise
        # for a non-zero exit (ADR-023).
        module Runtime
          def topology_service
            @topology_service ||= Organisms::TopologyService.from_config
          end

          # The interface accepts only JSON; anything else is a usage error
          def ensure_json_format!(options)
            format = options[:format]
            return if format.nil? || format == "json"

            cli_error("--format #{format.inspect} is not supported; only --format json is available")
          end

          # Caller identity is derived from the verified local process owner.
          # Role/principal flags would blur the authorization boundary and are
          # rejected outright (spec 8wq.t.1w4).
          def reject_identity_flags!(options)
            spoofed = %i[role principal caller].select { |flag| options[flag] }
            return if spoofed.empty?

            cli_error("--#{spoofed.first.to_s.tr("_", "-")} is not supported; caller identity is derived " \
                      "from the verified local process owner")
          end

          # Emit the result envelope; classified errors still print exactly
          # one deterministic JSON document before failing
          def emit_result(result, quiet: false)
            envelope = result.envelope
            puts JSON.generate(envelope) unless quiet
            return if result.ok?

            raise Ace::Support::Cli::Error, "#{envelope["error"]["code"]}: #{envelope["error"]["message"]}"
          end

          def cli_error(message)
            raise Ace::Support::Cli::Error, message
          end
        end
      end
    end
  end
end
