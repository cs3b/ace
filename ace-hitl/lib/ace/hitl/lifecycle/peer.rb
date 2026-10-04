# frozen_string_literal: true

require "etc"

module Ace
  module Hitl
    module Lifecycle
      # The authenticated caller of one boundary connection (spec
      # 8wq.t.34i): resolved from KERNEL PEER CREDENTIALS, never from
      # payload fields, environment variables, or claim strings. A peer
      # whose uid has no passwd entry is unknown identity — an error,
      # never permission.
      class Peer
        attr_reader :uid, :gid, :username

        def self.for_uid(uid, gid: nil)
          entry = Etc.getpwuid(Integer(uid))
          raise Lifecycle::PermissionError, "unknown peer identity: uid #{uid}" unless entry

          new(uid: Integer(uid), gid: gid.nil? ? entry.gid : Integer(gid), username: entry.name)
        rescue ArgumentError
          raise Lifecycle::PermissionError, "unknown peer identity: uid #{uid}"
        end

        def initialize(uid:, gid:, username:)
          @uid = uid
          @gid = gid
          @username = username
        end

        def root?
          uid.zero?
        end

        # The effective uid used by the effect drop check (Effects).
        def euid
          uid
        end

        # The uid/gid pair used for ownership transitions that target this
        # peer (public projections, answer hand-off).
        def ids
          [uid, gid]
        end

        def user_ids(name)
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
