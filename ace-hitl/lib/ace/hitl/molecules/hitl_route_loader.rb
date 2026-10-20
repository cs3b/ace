# frozen_string_literal: true

require_relative "hitl_address_resolver"

module Ace
  module Hitl
    module Molecules
      # Loads and validates the configured adapter route set from the hitl
      # cascade (`hitl.adapters.routes`). Fail-closed: no routes, malformed
      # entries, and duplicate route names are actionable errors raised
      # before any delivery is attempted.
      class HitlRouteLoader
        CONFIG_LOCATION = "hitl.adapters.routes (.ace/hitl/config.yml)"

        class NoRoutesError < StandardError; end
        class InvalidRouteError < StandardError; end

        # Delivery retention persists `delivery.<route>` as nested dot-keys
        # and reads back the literal route key, so route names must be a
        # single path segment (no dots).
        ROUTE_NAME_PATTERN = /\A[a-z0-9][a-z0-9_-]*\z/i.freeze

        # @param config [Hash] merged hitl namespace config
        # @return [Array<Hash>] validated string-keyed routes
        # @raise [NoRoutesError, InvalidRouteError]
        def self.load(config)
          routes = config.is_a?(Hash) ? config.dig("hitl", "adapters", "routes") : nil
          if routes.nil?
            raise NoRoutesError,
              "no adapter routes configured; set #{CONFIG_LOCATION}"
          end
          unless routes.is_a?(Array) && !routes.empty?
            raise NoRoutesError,
              "no adapter routes configured; set #{CONFIG_LOCATION}"
          end

          validated = routes.map { |entry| validate_entry(entry) }
          names = validated.map { |route| route["route"] }
          duplicates = names.tally.select { |_, count| count > 1 }.keys
          unless duplicates.empty?
            raise InvalidRouteError,
              "duplicate route name(s) #{duplicates.sort.join(", ")} in #{CONFIG_LOCATION}"
          end

          validated
        end

        def self.validate_entry(entry)
          unless entry.is_a?(Hash)
            raise InvalidRouteError, "route entry must be a mapping, got #{entry.class} in #{CONFIG_LOCATION}"
          end

          normalized = stringified(entry)
          adapter = normalized["adapter"].to_s.strip
          if adapter.empty?
            raise InvalidRouteError, "route entry missing required 'adapter' in #{CONFIG_LOCATION}"
          end

          route = normalized["route"].to_s.strip
          route = adapter if route.empty?
          unless route.match?(ROUTE_NAME_PATTERN)
            raise InvalidRouteError,
              "route name '#{route}' is invalid in #{CONFIG_LOCATION}: must match #{ROUTE_NAME_PATTERN.source} " \
              "(delivery retention keys route names literally; a dot would nest frontmatter keys and break retry/skip)"
          end

          normalized["route"] = route
          normalized["adapter"] = adapter
          if normalized.key?("recipients") &&
              (!normalized["recipients"].is_a?(Array) || normalized["recipients"].empty? ||
               !normalized["recipients"].all? { |name| name.is_a?(String) && !name.strip.empty? })
            raise InvalidRouteError, "route '#{route}' recipients must be a non-empty list of configured recipient names"
          end
          normalized
        end

        # Selection happens before adapter construction or delivery-state writes.
        # Names are configuration references, not labels copied onto an event:
        # compare their resolved addresses to the event's immutable destination.
        def self.for_recipient(routes, recipient:, config:)
          return routes if recipient.nil?

          resolver = HitlAddressResolver.new(config: config)
          destination = recipient.reject { |key, _| key == "id" }
          selected = routes.select do |route|
            addresses = Array(route["recipients"]).map do |name|
              resolver.resolve(name).reject { |key, _| key == "id" }
            end
            addresses.include?(destination)
          end
          if selected.empty?
            raise NoRoutesError, "no adapter route matches recipient #{Atoms::HitlAddress.to_s(recipient)}; " \
              "set route recipients to configured recipient names in #{CONFIG_LOCATION}"
          end
          selected
        rescue HitlAddressResolver::UnknownRecipientError, HitlAddressResolver::InvalidAddressError => e
          raise InvalidRouteError, e.message
        end

        def self.stringified(entry)
          entry.each_with_object({}) do |(key, value), memo|
            memo[key.to_s] = value
          end
        end
      end
    end
  end
end
