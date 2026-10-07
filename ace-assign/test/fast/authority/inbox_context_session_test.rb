# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/inbox_context_session"

module Ace
  module Assign
    class InboxContextSessionTest < AceAssignTestCase
      def session(state:, extra: false, fingerprint: "a" * 64)
        grant = {"fingerprint" => fingerprint, "operation_id" => "b" * 32, "key_generation" => 1, "state" => state}
        grant["extra"] = true if extra
        client = Object.new
        client.define_singleton_method(:request) { |*| grant }
        Authority::InboxContextSession.new(client: client, params: {"inbox_context_id" => "context", "event_id" => "event"},
          map: {}, mutation_id: "mutation", authority_peer: {})
      end

      def test_only_validated_pending_grant_has_pending_settlement_classification
        assert session(state: "admitted").require_idle!
        assert_raises(AttemptErrors::InboxContextPending) { session(state: "unknown").require_idle! }
        error = assert_raises(AttemptErrors::EvidenceUnavailable) { session(state: "unknown", extra: true) }
        refute_kind_of AttemptErrors::InboxContextPending, error
        [nil, 1, "not-a-digest"].each do |fingerprint|
          error = assert_raises(AttemptErrors::EvidenceUnavailable) { session(state: "unknown", fingerprint: fingerprint) }
          refute_kind_of AttemptErrors::InboxContextPending, error
        end
        error = assert_raises(AttemptErrors::EvidenceUnavailable) { session(state: "caller-pending") }
        refute_kind_of AttemptErrors::InboxContextPending, error
      end
    end
  end
end
