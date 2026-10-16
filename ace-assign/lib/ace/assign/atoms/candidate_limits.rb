# frozen_string_literal: true

module Ace
  module Assign
    module Atoms
      # Closed candidate-purpose budgets. Reports and release gems retain their
      # separate bounds; callers cannot select a larger wire/storage ceiling.
      module CandidateLimits
        BYTES = 128 * 1024 * 1024
        PREPARED_BYTES = 64 * 1024 * 1024
        REVIEW_SNAPSHOT_BYTES = 64 * 1024 * 1024
        # Explicit finite path shape (PATH_MAX/NAME_MAX-sized) so a hostile
        # tree entry cannot push unbounded path bytes into inventories,
        # filesystem prefix creation or per-component scans.
        PATH_BYTES = 4096
        PATH_COMPONENT_BYTES = 255
      end
    end
  end
end
