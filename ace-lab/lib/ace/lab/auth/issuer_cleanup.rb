# frozen_string_literal: true

require "json"
require "ace/lab"
require_relative "../auth"

module Ace
  module Lab
    module Auth
      # Systemd ExecStopPost entry point. It uses the existing lease owner;
      # no independent cleanup state is introduced. A nonzero exit means the
      # host must retain and retry unresolved revocations.
      class IssuerCleanup
        def self.run(service: nil, env: ENV, output: $stdout, errors: $stderr)
          invocation = env["INVOCATION_ID"]
          unless invocation.is_a?(String) && invocation.match?(/\A[0-9a-f]{32}\z/) && invocation != "0" * 32
            raise Error, "systemd issuer invocation is unavailable"
          end
          leases = (service || Service.new).revoke_issuer(invocation: invocation)
          output.puts(JSON.generate("invocation" => invocation, "leases" => leases))
          0
        rescue Error, SystemCallError => e
          errors.puts("ace-lab auth issuer cleanup failed: #{e.message}")
          1
        end
      end
    end
  end
end
