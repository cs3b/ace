# frozen_string_literal: true

module Ace
  module Lab
    module Molecules
      # Indexed view of validated lab topology (spec 8wq.t.1w4): entries by
      # globally-unique stable ID plus per-kind collections. Immutable.
      class TopologyIndex
        attr_reader :projects, :agents, :services, :by_id

        def initialize(projects:, agents:, services:, by_id:)
          @projects = projects.freeze
          @agents = agents.freeze
          @services = services.freeze
          @by_id = by_id.freeze
          freeze
        end

        def lookup(id)
          by_id[id]
        end
      end

      # Loads ADR-022-resolved lab configuration, validates it through
      # Atoms::TopologySchema, and builds the immutable TopologyIndex.
      class TopologyLoader
        def initialize(config = nil)
          @config = config
        end

        # @return [TopologyIndex]
        # @raise [Ace::Lab::InvalidConfigurationError]
        def load
          normalized = Atoms::TopologySchema.normalize!(@config || Ace::Lab.config)

          projects = normalized["topology"]["projects"].map { |h| Models::TopologyEntry.project(h) }
          agents = normalized["topology"]["agents"].map { |h| Models::TopologyEntry.agent(h) }
          services = normalized["topology"]["services"].map { |h| Models::TopologyEntry.service(h) }

          by_id = (projects + agents + services).each_with_object({}) do |entry, index|
            index[entry.id] = entry
          end

          TopologyIndex.new(projects: projects, agents: agents, services: services, by_id: by_id)
        end
      end
    end
  end
end
