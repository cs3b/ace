# frozen_string_literal: true

module Ace
  module Lab
    module Molecules
      # Exact stable-ID resolution (spec 8wq.t.1w4). Labels never resolve or
      # disambiguate; only an exact configured ID matches. A matched entry is
      # disclosed only to authorized callers, and only when its runtime
      # binding is fresh — a stale binding is an explicit classified
      # unavailable result, never a routeable answer.
      class ExactResolver
        # @param index [Molecules::TopologyIndex]
        # @param authorizer [Molecules::CallerAuthorizer]
        def initialize(index:, authorizer:)
          @index = index
          @authorizer = authorizer
        end

        def resolve(id)
          entry = @index.lookup(id)
          return Models::QueryResult.failure("missing", "no topology entry with stable ID #{id.inspect}", id: id) if entry.nil?

          if entry.project? && !@authorizer.authorized?(entry.id)
            return Models::QueryResult.failure(
              "unauthorized", "caller is not authorized for project #{entry.id.inspect}", id: id, project: entry.id
            )
          end
          if !entry.project? && !@authorizer.authorized?(entry.project)
            # No project disclosure: the configured project is topology the
            # caller is not authorized to see (review R6). The requested ID
            # is echoed because the caller supplied it.
            return Models::QueryResult.failure(
              "unauthorized", "caller is not authorized to resolve stable ID #{id.inspect}", id: id
            )
          end

          unless entry.project? || Atoms::BindingFreshness.fresh?(entry.binding)
            return Models::QueryResult.failure(
              "stale",
              "stable ID #{id.inspect} has a stale runtime binding; a replaced process must re-attest before routing",
              id: id, project: entry.project
            )
          end

          Models::QueryResult.ok("entry" => Atoms::PublicProjection.entry(entry))
        end
      end
    end
  end
end
