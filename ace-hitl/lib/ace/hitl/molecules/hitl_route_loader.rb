# frozen_string_literal: true

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
          normalized["route"] = route.empty? ? adapter : route
          normalized["adapter"] = adapter
          normalized
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
