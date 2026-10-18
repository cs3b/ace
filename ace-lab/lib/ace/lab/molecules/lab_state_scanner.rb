# frozen_string_literal: true

module Ace
  module Lab
    module Molecules
      # Read-only scan of the file-based lab state-owner locations
      # (ADR-034). Every location reports presence and — unless it is
      # private or reserved — an entry count; a per-location read failure
      # becomes that location's :error and never masks its siblings
      # (task 8xg.t.sbz.6.0: a source failure is shown alongside
      # available results).
      class LabStateScanner
        # presence_only locations are never enumerated: _overseer is the
        # private task list, coworker is reserved L3 configuration.
        LOCATIONS = [
          {key: "tasks", path: ".ace-tasks", note: nil},
          {key: "overseer", path: ".ace-tasks/_overseer", note: "private; not listed"},
          {key: "assignments", path: ".ace-local/assign", note: nil},
          {key: "hitl", path: ".ace-local/hitl", note: nil},
          {key: "worktrees", path: ".ace-wt", note: "enriched view: ace-git-worktree list"},
          {key: "coworker", path: ".ace-local/coworker", note: "reserved L3; informational"}
        ].freeze

        PRESENCE_ONLY = %w[overseer coworker].freeze

        class << self
          # @param root [String] project root to scan
          # @return [Array<Hash>] {key, path, state, entries, note} per
          #   location; state is :present, :absent, or :error
          def scan(root: Dir.pwd)
            LOCATIONS.map do |location|
              absolute = File.join(root, location[:path])
              entry = {key: location[:key], path: location[:path], note: location[:note]}
              begin
                if File.directory?(absolute)
                  entry[:state] = :present
                  entry[:entries] = PRESENCE_ONLY.include?(location[:key]) ? nil : Dir.children(absolute).length
                  entry[:state] = :prepared if PRESENCE_ONLY.include?(location[:key])
                else
                  entry[:state] = :absent
                  entry[:entries] = nil
                end
              rescue SystemCallError => e
                entry[:state] = :error
                entry[:entries] = nil
                entry[:note] = e.message
              end
              entry
            end
          end
        end
      end
    end
  end
end
