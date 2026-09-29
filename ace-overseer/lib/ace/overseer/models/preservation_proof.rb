# frozen_string_literal: true

module Ace
  module Overseer
    module Models
      # Outcome of a preservation proof for one prune candidate.
      #
      # A proof is preserved only through an executed Git identity: accepted
      # ancestor containment, full-tree equality, or an exact content
      # transition against a verified destination. Anything else — missing,
      # failed or ambiguous evidence — is not preserved and carries the
      # blocking reason.
      class PreservationProof
        attr_reader :method, :reason, :head

        def initialize(preserved:, method: nil, reason: nil, head: nil)
          @preserved = preserved
          @method = method
          @reason = reason
          @head = head
        end

        def self.preserved(method, head: nil)
          new(preserved: true, method: method, head: head)
        end

        def self.blocked(reason)
          new(preserved: false, reason: reason)
        end

        def preserved?
          @preserved
        end
      end
    end
  end
end
