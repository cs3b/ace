# frozen_string_literal: true

module Ace
  module Hitl
    module Lifecycle
      # The authorization seam of one TLS lifecycle authority (spec
      # 8xa.t.nh0): the verified project-scoped client certificate is
      # the ONLY admitted peer and it is bound to the authority's exact
      # project. A certificate for one project cannot authorize another
      # even when issued by the same CA, and no operation against any
      # other project is reachable through this authority.
      class TlsAccessPolicy < AccessPolicy
        def initialize(project:)
          @project = project.to_s
        end

        def transport?(peer, project: nil)
          bound?(peer) && (project.nil? || project.to_s == @project)
        end

        def proposal?(peer, project:)
          transport?(peer, project: project)
        end

        # A TLS authority has no Unix service uid; client endpoint
        # verification is certificate-based.
        def service_uid
          nil
        end

        private

        def bound?(peer)
          peer.is_a?(RemotePeer) && peer.project == @project
        end
      end
    end
  end
end
