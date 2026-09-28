# frozen_string_literal: true

module Ace
  module Lab
    module Organisms
      # Public query facade for all ace-lab CLI commands (spec 8wq.t.1w4):
      # loads and validates topology, derives the verified caller identity,
      # and returns classified QueryResults. Read-only by contract — it never
      # invokes a service, grants credentials, or creates any state.
      class TopologyService
        # Build a service from the ADR-022-resolved lab configuration
        def self.from_config(config = nil)
          config ||= Ace::Lab.config
          loader = Molecules::TopologyLoader.new(config)
          authorizer = Molecules::CallerAuthorizer.new(
            principals: config["authorization"].is_a?(Hash) ? config["authorization"]["principals"] : {}
          )
          new(loader: loader, authorizer: authorizer)
        end

        # @param loader [Molecules::TopologyLoader]
        # @param authorizer [Molecules::CallerAuthorizer]
        def initialize(loader:, authorizer:)
          @loader = loader
          @authorizer = authorizer
        end

        def projects
          query { |index| Molecules::InventoryQuery.new(index: index, authorizer: @authorizer).projects }
        end

        def agents(project:)
          query { |index| Molecules::InventoryQuery.new(index: index, authorizer: @authorizer).agents(project: project) }
        end

        def services(project:)
          query do |index|
            Molecules::InventoryQuery.new(index: index, authorizer: @authorizer).services(project: project)
          end
        end

        def resolve(id:)
          query { |index| Molecules::ExactResolver.new(index: index, authorizer: @authorizer).resolve(id) }
        end

        private

        # Run a query against the validated index; configuration violations
        # surface as the classified invalid_configuration result
        def query
          index = @loader.load
          yield index
        rescue Ace::Lab::InvalidConfigurationError => e
          Models::QueryResult.failure("invalid_configuration", e.message)
        end
      end
    end
  end
end
