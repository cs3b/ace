# frozen_string_literal: true

module Ace
  module Assign
    # Explicit boundary double for existing fixed-merge transport/CAS tests.
    # These tests do not attest native candidate/review/test execution. The real
    # ordinary lifecycle proof join is exercised by ordinary_reviews_test.
    class FixedMergeEvidenceFixture
      attr_accessor :enabled
      def initialize = @enabled = true
      def with_merge_scope(**) = yield
      def verify_merge_evidence_at!(**)
        raise AttemptErrors::ReceiptRejected, "controlled canonical evidence revoked" unless @enabled
        true
      end
    end
  end
end
