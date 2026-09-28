# frozen_string_literal: true

require "etc"

module Ace
  module Lab
    module Molecules
      # Derives the verified local caller identity and enforces the
      # project-visibility policy from configured authorization principals
      # (spec 8wq.t.1w4). Caller identity comes from the local process owner
      # (username or numeric uid) — never from a CLI flag. An identity with no
      # matching principal is authorized for nothing.
      class CallerAuthorizer
        # Identity strings of the verified local process owner: the passwd
        # username and the numeric uid, either of which may be configured.
        def self.local_identity
          uid = Process.uid
          name = begin
            Etc.getpwuid(uid)&.name
          rescue
            nil
          end
          [name, uid.to_s].compact.uniq
        end

        # @param principals [Hash] authorization.principals from normalized config
        # @param identity [Array<String>, nil] verified caller identities
        #   (defaults to the local process owner)
        def initialize(principals: {}, identity: nil)
          @principals = principals || {}
          @identity = identity || self.class.local_identity
        end

        # Union of project IDs visible to the verified caller
        # @return [Array<String>]
        def authorized_project_ids
          @authorized_project_ids ||= @identity.each_with_object([]) do |name, projects|
            policy = @principals[name]
            projects.concat(policy["projects"]) if policy.is_a?(Hash)
          end.uniq
        end

        # @return [Boolean] true when the caller may see the project; without
        #   an argument, true when the caller may see anything at all
        def authorized?(project_id = nil)
          return authorized_project_ids.any? if project_id.nil?

          authorized_project_ids.include?(project_id)
        end
      end
    end
  end
end
