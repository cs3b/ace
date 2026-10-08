# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../../../ace-lab/test/support/protected_service_boundary_fixture"
require_relative "../support/managed_prepared_registration_fixture"

module Ace
  module Assign
    class PreparedDeliveryFlowTest < AceAssignTestCase
      include ProtectedServiceBoundaryFixture
      include ManagedPreparedRegistrationFixture

      def test_managed_preparation_captures_shipped_merge_child_before_registration
        @managed_flow = @managed_delivery = true
        fixture do
          work = @prepared_registration.work
          assert_equal "010", work.manifest.fetch("scope")
          children = work.manifest.fetch("steps").reject { |entry| entry.fetch("number") == "010" }
          assert_equal 1, children.size
          child = children.first
          body = work.parse_queue_step!(work.files.fetch("steps/" + child.fetch("filename")))
          assert_includes body.fetch(:body), "For an original protected PreparedWorker"
          assert_includes body.fetch(:body), "Refusal, unavailable evidence or uncertainty leaves it unfinished"
          assert_equal @managed_input.fetch("selection_sha256"), work.selection_sha256
        end
      end
    end
  end
end
