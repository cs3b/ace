# frozen_string_literal: true

module Ace
  module Lab
    module Molecules
      # Project-scoped inventory queries over a validated TopologyIndex
      # (spec 8wq.t.1w4). Every result is authorization-filtered: a caller
      # sees only projects covered by a configured principal, and an
      # unauthorized project is indistinguishable from any other
      # unauthorized project (classified error, no metadata).
      class InventoryQuery
        # @param index [Molecules::TopologyIndex]
        # @param authorizer [Molecules::CallerAuthorizer]
        def initialize(index:, authorizer:)
          @index = index
          @authorizer = authorizer
        end

        # Authorized projects only; a caller with no principals sees nothing
        def projects
          return unauthorized_inventory unless @authorizer.authorized?

          visible = @index.projects.select { |project| @authorizer.authorized?(project.id) }
          Models::QueryResult.ok("projects" => visible.map { |p| Atoms::PublicProjection.project(p) })
        end

        def agents(project:)
          return unauthorized_project(project) unless @authorizer.authorized?(project)

          scoped = @index.agents.select { |agent| agent.project == project }
          Models::QueryResult.ok("agents" => scoped.map { |a| Atoms::PublicProjection.agent(a) })
        end

        def services(project:)
          return unauthorized_project(project) unless @authorizer.authorized?(project)

          scoped = @index.services.select { |service| service.project == project }
          Models::QueryResult.ok("services" => scoped.map { |s| Atoms::PublicProjection.service(s) })
        end

        private

        def unauthorized_inventory
          Models::QueryResult.failure(
            "unauthorized",
            "caller has no configured authorization for any lab project"
          )
        end

        def unauthorized_project(project)
          Models::QueryResult.failure(
            "unauthorized",
            "caller is not authorized for project #{project.inspect}",
            project: project
          )
        end
      end
    end
  end
end
