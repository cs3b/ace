# frozen_string_literal: true

module Ace
  module Assign
    module Atoms
      # Pure validation and canonicalization of attempt scopes.
      #
      # An attempt scope is the step/subtree an attempt owns, expressed as a
      # step number ("010", "010.01"). Scopes are canonicalized before they
      # key ownership locks, journal paths, or binding comparisons so that
      # cosmetic differences cannot create a second writer.
      module AssignmentScope
        SCOPE_PATTERN = /\A\d+(?:\.\d+)*\z/.freeze

        # Canonicalize and validate a step/subtree scope.
        #
        # @param step [String] Step or subtree root number
        # @return [String] Canonical scope
        # @raise [Ace::Assign::AttemptErrors::InvalidScope] if blank or malformed
        def self.canonicalize(step)
          scope = step.to_s.strip
          if scope.empty? || !scope.match?(SCOPE_PATTERN)
            raise Ace::Assign::AttemptErrors::InvalidScope,
              "Invalid attempt scope '#{step}': expected a step number such as 010 or 010.01"
          end

          scope
        end

        # Filesystem-safe token for an assignment/scope pair, used to key
        # active-attempt ownership records.
        #
        # @param assignment_id [String] Assignment ID
        # @param scope [String] Canonical scope
        # @return [String] Ownership key token
        def self.ownership_key(assignment_id, scope)
          "#{assignment_id}-#{canonicalize(scope)}.json"
        end

        # Compare two scopes for binding identity.
        #
        # @param left [String] First scope
        # @param right [String] Second scope
        # @return [Boolean] True if both canonicalize to the same scope
        def self.equal?(left, right)
          canonicalize(left) == canonicalize(right)
        rescue Ace::Assign::AttemptErrors::InvalidScope
          false
        end
      end
    end
  end
end
