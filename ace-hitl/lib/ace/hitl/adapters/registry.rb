# frozen_string_literal: true

module Ace
  module Hitl
    module Adapters
      # Duck-typed adapter registry with lazy entrypoint loading.
      # Semantics mirror Ace::Runtime::Registry (kept independent on
      # purpose): fail-closed resolution carrying the available list;
      # only a missing entrypoint counts as unknown — a LoadError raised
      # inside an installed entrypoint propagates so a broken adapter is
      # never misreported as unknown.
      class Registry
        NAME_PATTERN = /\A[a-z][a-z0-9_]*\z/
        ADAPTER_ENTRYPOINT_FORMAT = "ace/hitl/adapters/%s"

        def initialize
          @factories = {}
        end

        def register(name, factory = nil, &block)
          key = name.to_s
          callable = factory || block
          unless callable.respond_to?(:call)
            raise ArgumentError, "adapter factory for '#{key}' must respond to #call"
          end

          @factories[key] = callable
          nil
        end

        def registered?(name)
          @factories.key?(name.to_s)
        end

        def available
          @factories.keys.sort
        end

        # @return [Object] the built adapter (factory receives the route
        #   configuration hash)
        # @raise [UnknownAdapterError] when the name cannot be resolved
        def resolve(name, route: {})
          key = name.to_s
          load_adapter_entrypoint(key) unless @factories.key?(key)

          factory = @factories[key]
          raise UnknownAdapterError.new(requested: key, available: available) unless factory

          factory.call(route)
        end

        private

        def load_adapter_entrypoint(name)
          return unless name.match?(NAME_PATTERN)

          entrypoint = format(ADAPTER_ENTRYPOINT_FORMAT, name)
          require entrypoint
        rescue LoadError => e
          raise unless e.path == entrypoint
        end
      end
    end
  end
end
