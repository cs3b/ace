# frozen_string_literal: true

module Ace
  module Lab
    module Organisms
      # Public query facade for all ace-lab CLI commands (spec 8wq.t.1w4):
      # loads and validates topology, derives the verified caller identity,
      # and returns classified QueryResults. Read-only by contract — it never
      # invokes a service, grants credentials, or creates any state.
      class TopologyService
        # Build a service from configuration (ADR-022 cascade when omitted).
        # Normalization happens lazily inside the classified boundary so
        # configuration defects surface as invalid_configuration results.
        def self.from_config(config = nil)
          new(config: config)
        end

        # @param config [Hash, nil] pre-supplied configuration to normalize
        # @param loader [Molecules::TopologyLoader, nil] injected loader
        # @param authorizer [Molecules::CallerAuthorizer, nil] injected authorizer
        def initialize(config: nil, loader: nil, authorizer: nil)
          @config = config
          @loader = loader
          @authorizer = authorizer
        end

        def projects
          query { |index, authorizer| Molecules::InventoryQuery.new(index: index, authorizer: authorizer).projects }
        end

        def agents(project:)
          query do |index, authorizer|
            Molecules::InventoryQuery.new(index: index, authorizer: authorizer).agents(project: project)
          end
        end

        def services(project:)
          query do |index, authorizer|
            Molecules::InventoryQuery.new(index: index, authorizer: authorizer).services(project: project)
          end
        end

        def resolve(id:)
          query { |index, authorizer| Molecules::ExactResolver.new(index: index, authorizer: authorizer).resolve(id) }
        end

        def route(project:, capability:)
          query do |index, authorizer|
            Molecules::CapabilityRouter.new(index: index, authorizer: authorizer)
              .route(project: project, capability: capability)
          end
        end

        private

        # Run a query against the validated index. Configuration loading,
        # schema validation, and authorization derivation all happen inside
        # this boundary so every defect classifies as invalid_configuration
        # (review R4) and authorization always uses the normalized document
        # the topology was validated against (review R3).
        def query
          index, authorizer = dependencies
          yield index, authorizer
        rescue Ace::Lab::InvalidConfigurationError => e
          Models::QueryResult.failure("invalid_configuration", e.message)
        end

        # Dependencies are derived fresh for EVERY query: nothing is
        # memoized, so revoking deployment grants revokes access on the next
        # query even for a reused service instance (review round 6, F1).
        def dependencies
          return [@loader.load, @authorizer] if @loader

          config = @config || Ace::Lab.config
          normalized = Atoms::TopologySchema.normalize!(config)
          grants = if @config
            # Explicitly injected configuration is a trusted in-process
            # input (API use and fixtures)
            normalized["authorization"]["principals"]
          else
            # Cascade path: grants come only from the trusted deployment-
            # controlled document, re-read and re-verified per query; cascade
            # tiers can never define or expand authorization (review round 4, F3)
            Molecules::GrantResolver.resolve(
              documents: Ace::Lab.cascade_documents,
              topology: normalized["topology"],
              trusted_path: Ace::Lab.authorization_path
            )["principals"]
          end

          loader = Molecules::TopologyLoader.new(normalized)
          authorizer = Molecules::CallerAuthorizer.new(principals: grants)
          [loader.load, authorizer]
        end
      end
    end
  end
end
