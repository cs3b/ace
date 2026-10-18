# frozen_string_literal: true

module Ace
  module Hitl
    module Molecules
      # Pure redelivery decisions over the persisted per-route delivery map
      # (event frontmatter `delivery.<route>`). No IO.
      #
      # Statuses: delivered (confirmed; skipped on default retry), failed /
      # unavailable (failure reason retained; retried), in_flight (marker
      # written before a delivery attempt; a stale one means the sending
      # process died — unknown result, retried). At-least-once: a retry after
      # an unknown result may duplicate, so recipients dedup by case ID.
      module HitlDeliveryState
        module_function

        # @param record [Hash, nil] persisted route record
        # @return [Boolean] true when the route must be (re)delivered;
        #   only a confirmed delivered record is skipped
        def retry?(record)
          return true if record.nil? || !record.is_a?(Hash)

          record["status"] != "delivered"
        end

        # A stale in_flight marker is an unknown result.
        def unknown?(record)
          record.is_a?(Hash) && record["status"] == "in_flight"
        end

        # @return [Boolean] some route has a delivery record and is not delivered
        def undelivered?(delivery_map)
          map = normalized(delivery_map)
          return false if map.empty?

          map.any? { |_route, record| record["status"] != "delivered" }
        end

        # @return [Boolean] a delivery map exists and every recorded route delivered
        def fully_delivered?(delivery_map)
          map = normalized(delivery_map)
          return false if map.empty?

          map.all? { |_route, record| record["status"] == "delivered" }
        end

        # Malformed entries (nil/scalar records from hand-written YAML) are
        # dropped, never raised through: a broken record is simply not a
        # delivery fact.
        def normalized(delivery_map)
          return {} unless delivery_map.is_a?(Hash)

          delivery_map.select { |_route, record| record.is_a?(Hash) }
        end
      end
    end
  end
end
