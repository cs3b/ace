# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../support/endcap_result_owner_fixture"

module Ace
  module Assign
    class CanonicalJournalInitializationTest < AceAssignTestCase
      include EndcapResultOwnerFixture

      def test_canonical_initialization_preserves_actual_registration_prepared_bundle_and_result_import
        fixture do
          before = @journal.ref_value
          assert_equal before, @journal.initialize_canonical!(owner_uid: Process.uid, owner_gid: Process.gid, owner_groups: Process.groups)
          data = submit.fetch(:data)
          completed = @journal.ref_value
          assert_equal completed, @journal.initialize_canonical!(owner_uid: Process.uid, owner_gid: Process.gid, owner_groups: Process.groups)
          assert_equal completed, @journal.ref_value
          assert_equal "first\x00\r\n".b, fetch(data).fetch(:transfer_parts).first
          assert_equal "second evidence", fetch(data, 1).fetch(:transfer_parts).first
          assert_equal completed, @journal.ref_value
        end
      end

    end
  end
end
