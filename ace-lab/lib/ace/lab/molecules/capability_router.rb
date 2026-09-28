# frozen_string_literal: true

module Ace
  module Lab
    module Molecules
      # Project-local capability routing (spec 8wq.t.1w4). Candidates are
      # configured capable services of the requested project with fresh
      # bindings — never services from another project, never stale entries.
      # Exactly one candidate routes directly; several require exactly one
      # configured default; otherwise the result is classified ambiguous.
      class CapabilityRouter
        # @param index [Molecules::TopologyIndex]
        # @param authorizer [Molecules::CallerAuthorizer]
        def initialize(index:, authorizer:)
          @index = index
          @authorizer = authorizer
        end

        def route(project:, capability:)
          unless @authorizer.authorized?(project)
            return Models::QueryResult.failure(
              "unauthorized", "caller is not authorized for project #{project.inspect}", project: project
            )
          end

          capability = normalize_capability(capability)
          candidates = @index.services.select do |service|
            service.project == project &&
              service.capable_of?(capability) &&
              Atoms::BindingFreshness.fresh?(service.binding)
          end

          if candidates.empty?
            return Models::QueryResult.failure(
              "missing",
              "no available service with capability #{capability.inspect} in project #{project.inspect}",
              project: project, capability: capability
            )
          end

          if candidates.length == 1
            return Models::QueryResult.ok("entry" => Atoms::PublicProjection.service(candidates.first))
          end

          # Conflicting defaults are not a preference: exactly one configured
          # default may win, several classify ambiguous (review R1)
          defaults = candidates.select { |service| service.default_for.include?(capability) }
          if defaults.length == 1
            Models::QueryResult.ok("entry" => Atoms::PublicProjection.service(defaults.first))
          else
            Models::QueryResult.failure(
              "ambiguous",
              "multiple capable services in project #{project.inspect} for capability #{capability.inspect}: " \
                "#{candidates.map(&:id).join(", ")}; configure default_for on exactly one to disambiguate",
              project: project, capability: capability
            )
          end
        end

        private

        # Requested capabilities normalize the same way as configured ones
        def normalize_capability(capability)
          capability.to_s.strip.downcase
        end
      end
    end
  end
end
