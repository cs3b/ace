# frozen_string_literal: true

require "etc"

module Ace
  module Hitl
    module Lifecycle
      # The single identity gateway of the generic lifecycle: euid, user
      # and group lookups, and the privilege drop for effect execution.
      # Every identity decision goes through here so tests can pin a
      # faithful unprivileged fixture without patching call sites
      # (spec 8wm.t.y21 §2).
      module Identity
        module_function

        def euid
          Process.euid
        end

        def uid
          Process.uid
        end

        def gid
          Process.gid
        end

        def root?
          euid.zero?
        end

        def username
          Etc.getpwuid(euid)&.name || Process.uid.to_s
        end

        # The requester's uid/gid; unknown names fail closed.
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

        # Drop to the exact requester identity for effect execution.
        # Root drops fully (setgroups/setgid/setuid); a non-root process
        # may only "drop" to itself, so a foreign requester fails closed.
        def drop_to!(uid, gid)
          if root?
            Process::Sys.setgroups([gid])
            Process::Sys.setgid(gid)
            Process::Sys.setuid(uid)
          elsif uid != euid
            raise Lifecycle::PermissionError,
              "effect callback requires the requester's identity and root authority to drop to it"
          end
        end
      end
    end
  end
end
