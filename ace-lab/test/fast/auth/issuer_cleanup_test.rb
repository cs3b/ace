# frozen_string_literal: true

require_relative "../../test_helper"
require "ace/lab/auth/issuer_cleanup"
require "stringio"
require "open3"
require "rbconfig"

module Ace
  module Lab
    module Auth
      class IssuerCleanupTest < Minitest::Test
        def test_passes_the_systemd_invocation_to_the_existing_lease_owner
          calls = []
          service = Object.new
          service.define_singleton_method(:revoke_issuer) { |invocation:| calls << invocation; [{"lease" => "lease-1", "cleanup" => "revoked"}] }
          output = StringIO.new
          assert_equal 0, IssuerCleanup.run(service: service, env: {"INVOCATION_ID" => "a" * 32}, output: output, errors: StringIO.new)
          assert_equal ["a" * 32], calls
          assert_equal "revoked", JSON.parse(output.string).fetch("leases").first.fetch("cleanup")
        end

        def test_missing_invocation_and_failed_cleanup_are_nonzero
          service = Object.new
          service.define_singleton_method(:revoke_issuer) { |invocation:| raise Error, "not confirmed" }
          assert_equal 1, IssuerCleanup.run(service: service, env: {}, output: StringIO.new, errors: StringIO.new)
          assert_equal 1, IssuerCleanup.run(service: service, env: {"INVOCATION_ID" => "a" * 32}, output: StringIO.new, errors: StringIO.new)
        end

        def test_packaged_internal_entry_point_exits_nonzero_without_systemd_identity
          entry = File.expand_path("../../../libexec/issuer-cleanup", __dir__)
          lib = File.expand_path("../../../lib", __dir__)
          _, stderr, status = Open3.capture3({"INVOCATION_ID" => nil}, RbConfig.ruby, "-I", lib, entry)
          refute status.success?
          assert_match(/issuer invocation is unavailable/, stderr)
        end
      end
    end
  end
end
