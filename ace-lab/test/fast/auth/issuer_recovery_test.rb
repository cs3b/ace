# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth/issuer_recovery"
require "stringio"

module Ace
  module Lab
    module Auth
      class IssuerRecoveryTest < Minitest::Test
        def test_reports_recovered_leases
          service = Object.new
          def service.recover_issuers = [{"lease" => "lease-1", "cleanup" => "revoked"}]
          output = StringIO.new
          assert_equal 0, IssuerRecovery.run(service: service, output: output, errors: StringIO.new)
          assert_equal "revoked", JSON.parse(output.string).fetch("leases").first.fetch("cleanup")
        end

        def test_unresolved_recovery_is_nonzero
          service = Object.new
          def service.recover_issuers = raise(Error, "unresolved")
          assert_equal 1, IssuerRecovery.run(service: service, output: StringIO.new, errors: StringIO.new)
        end
      end
    end
  end
end
