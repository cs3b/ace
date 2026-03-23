# frozen_string_literal: true

module Ace
  module Support
    module Items
      module Molecules
        # Resolves shortcut references to item ScanResult objects.
        #
        # Shortcuts are the last N characters of an item ID.
        # For ideas (6-char IDs): "8ppq7w" => shortcut "q7w"
        # For tasks (9-char formatted IDs): "8pp.t.q7w" => shortcut "q7w"
        # Full IDs are also accepted directly.
        #
        # Warns (via callback or STDERR) when multiple matches are found.
        class ShortcutResolver
          # @param scan_results [Array<ScanResult>] Scan results to resolve against
          # @param full_id_length [Integer] Length of a full ID (6 for raw b36ts, 9 for type-marked)
          def initialize(scan_results, full_id_length: 6)
            @scan_results = scan_results
            @full_id_length = full_id_length
          end

          # Resolve a reference to a single ScanResult
          # @param ref [String] Full ID or suffix shortcut
          # @param on_ambiguity [Proc, nil] Called with array of matches on ambiguity
          # @return [ScanResult, nil] The resolved result, or nil if not found
          def resolve(ref, on_ambiguity: nil)
            return nil if ref.nil? || ref.empty?

            ref = ref.strip.downcase

            if ref.length == @full_id_length
              # Full ID match
              exact = @scan_results.find { |r| r.id == ref }
              return exact
            end

            # Suffix match (last N characters)
            matches = @scan_results.select { |r| r.id.end_with?(ref) }

            if matches.empty?
              nil
            elsif matches.size == 1
              matches.first
            else
              # Ambiguity: multiple matches
              if on_ambiguity
                on_ambiguity.call(matches)
              else
                warn "Warning: Ambiguous shortcut '#{ref}' matches #{matches.size} items: " \
                     "#{matches.map(&:id).join(", ")}. Using most recent."
              end
              # Return most recent (last by sorted ID = chronologically latest)
              matches.last
            end
          end

          # Check if a reference would be ambiguous
          # @param ref [String] Reference to check
          # @return [Boolean] True if multiple matches exist
          def ambiguous?(ref)
            return false if ref.nil? || ref.length == @full_id_length

            ref = ref.strip.downcase
            matches = @scan_results.select { |r| r.id.end_with?(ref) }
            matches.size > 1
          end

          # Return all matches for a reference (useful for listing ambiguous matches)
          # @param ref [String] Reference to resolve
          # @return [Array<ScanResult>] All matching results
          def all_matches(ref)
            return [] if ref.nil? || ref.empty?

            ref = ref.strip.downcase

            if ref.length == @full_id_length
              @scan_results.select { |r| r.id == ref }
            else
              @scan_results.select { |r| r.id.end_with?(ref) }
            end
          end
        end
      end
    end
  end
end
