# frozen_string_literal: true

module Ace
  module Lab
    module Molecules
      # Exact stable-ID resolution (spec 8wq.t.1w4). Labels never resolve or
      # disambiguate; only an exact configured ID matches. An entry outside
      # the caller's authorization resolves exactly like a nonexistent one,
      # so callers cannot probe private topology by comparing classified
      # errors (review round 3, F3). A matched, authorized entry with an
      # unfresh binding is an explicit stale result, never a routeable answer.
      class ExactResolver
        # @param index [Molecules::TopologyIndex]
        # @param authorizer [Molecules::CallerAuthorizer]
        def initialize(index:, authorizer:)
          @index = index
          @authorizer = authorizer
        end

        def resolve(id)
          entry = visible_entry(id)
          return missing(id) if entry.nil?

          unless entry.project? || Atoms::BindingFreshness.fresh?(entry.binding)
            return Models::QueryResult.failure(
              "stale",
              "stable ID #{id.inspect} has a stale runtime binding; a replaced process must re-attest before routing",
              id: id, project: entry.project
            )
          end

          Models::QueryResult.ok("entry" => Atoms::PublicProjection.entry(entry))
        end

        private

        def visible_entry(id)
          entry = @index.lookup(id)
          return nil if entry.nil?

          authorized = if entry.project?
            @authorizer.authorized?(entry.id)
          else
            @authorizer.authorized?(entry.project)
          end

          authorized ? entry : nil
        end

        def missing(id)
          Models::QueryResult.failure("missing", "no topology entry with stable ID #{id.inspect}", id: id)
        end
      end
    end
  end
end
