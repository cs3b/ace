# frozen_string_literal: true

require "delegate"

module Ace
  module Hitl
    module Lifecycle
      # The one-project guard of a TLS lifecycle authority (spec
      # 8xa.t.nh0): the verified remote peer is bound to EXACTLY ONE
      # project, so every flow that carries or could resolve to another
      # project is refused BEFORE store access — pending flows carry the
      # channel's project, the global states projection and foreign
      # creates are unreachable, and cross-authority correlation is
      # impossible through this boundary.
      class TlsProjectScope < SimpleDelegator
        def initialize(store, project:)
          super(store)
          @project = project
        end

        def pending(project: nil, after: nil)
          require_bound_project!(project)
          super(project: @project, after: after)
        end

        def pending_page(project: nil, after: nil)
          require_bound_project!(project)
          super(project: @project, after: after)
        end

        # The global cross-project projection is not reachable through a
        # single-project authority.
        def states
          raise PermissionError, "the TLS authority serves only project #{@project.inspect}"
        end

        def create(**params)
          require_bound_project!(params[:project])
          super
        end

        def proposal_wake(project:, after: nil)
          require_bound_project!(project)
          super(project: @project, after: after)
        end

        def proposal_due(project:, after: nil)
          require_bound_project!(project)
          super(project: @project, after: after)
        end

        def proposal_history(project:, query: "", after: nil)
          require_bound_project!(project)
          super(project: @project, query: query, after: after)
        end

        private

        def require_bound_project!(project)
          return if project.nil? || project.to_s == @project

          raise PermissionError,
            "the TLS authority of project #{@project.inspect} never serves project #{project.to_s.inspect}"
        end
      end
    end
  end
end
