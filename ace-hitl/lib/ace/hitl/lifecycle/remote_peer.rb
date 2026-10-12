# frozen_string_literal: true

require "etc"

module Ace
  module Hitl
    module Lifecycle
      # The authenticated caller of one mutually authenticated TLS
      # connection (spec 8xa.t.nh0): resolved from the VERIFIED
      # project-scoped client certificate — single URI SAN, exact
      # fingerprint, issuing CA and EKU checked before any lifecycle
      # frame is decoded — never from payload fields or claim strings.
      #
      # A remote peer has no local uid: every check that would use one
      # fails closed. The username is the exact verified URI SAN token,
      # so requester-only store paths never match a foreign remote peer,
      # and effect callbacks that would need a local privilege drop
      # escalate exactly like the existing non-root transport case. The
      # peer's OWN token materializes to the service identity that
      # terminates the crossing (public projections and attribution of
      # the requests it created); foreign names still resolve through
      # the passwd database and unknown ones fail closed.
      class RemotePeer
        attr_reader :project, :identity

        def initialize(project:, identity:)
          @project = project.to_s
          @identity = identity
        end

        def username
          @identity
        end

        def root?
          false
        end

        # No local identity exists across the crossing; used only for
        # fail-closed comparisons (see Effects.run).
        def euid
          nil
        end

        def uid
          nil
        end

        def gid
          nil
        end

        def pid
          nil
        end

        def ids
          [nil, nil]
        end

        def user_ids(name)
          return [Process.uid, Process.gid] if name.to_s == @identity

          entry = Etc.getpwnam(name.to_s)
          [entry.uid, entry.gid]
        rescue ArgumentError
          raise Lifecycle::Error, "unknown requester identity: #{name}"
        end

        def group_id(name)
          Etc.getgrnam(name.to_s).gid
        rescue ArgumentError
          raise Lifecycle::Error, "unknown group identity: #{name}"
        end
      end
    end
  end
end
