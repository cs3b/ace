# frozen_string_literal: true

require "json"
require "ace/lab"
require_relative "../auth"

module Ace
  module Lab
    module Auth
      # Runs before the issuer socket can accept work. All state comes from
      # the existing lease store, and unresolved revocation blocks startup.
      class IssuerRecovery
        def self.run(service: nil, output: $stdout, errors: $stderr)
          leases = (service || Service.new).recover_issuers
          output.puts(JSON.generate("leases" => leases))
          0
        rescue Error, SystemCallError => e
          errors.puts("ace-lab auth startup recovery failed: #{e.message}")
          1
        end
      end
    end
  end
end
