# frozen_string_literal: true

require "ace/support/items"

module Ace
  module Task
    module Molecules
      # Wraps ShortcutResolver for task-format IDs (9-char formatted IDs like "8pp.t.q7w").
      #
      # Normalizes various reference forms before resolving:
      #   "8pp.t.q7w"    → full ID lookup (9 chars)
      #   "t.q7w"        → strip marker, suffix lookup "q7w"
      #   "q7w"          → bare suffix lookup
      #   "8pp.t.q7w.a"  → subtask lookup (11 chars: parent + ".{char}")
      class TaskResolver
        # Task formatted IDs are 9 chars: "8pp.t.q7w"
        FULL_ID_LENGTH = 9

        # Short reference pattern: "t.q7w" → extract suffix "q7w"
        SHORT_REF_PATTERN = /^[a-z]\.([0-9a-z]{3})$/

        # Subtask reference pattern: "8pp.t.q7w.a" (parent ID + dot + single char)
        SUBTASK_REF_PATTERN = /^([0-9a-z]{3}\.[a-z]\.[0-9a-z]{3})\.([a-z0-9])$/

        # Short subtask reference: "q7w.a" or "t.q7w.a" (suffix + subtask char)
        SHORT_SUBTASK_REF_PATTERN = /^(?:[a-z]\.)?([0-9a-z]{3})\.([a-z0-9])$/

        # @param scan_results [Array<ScanResult>] Scan results to resolve against
        def initialize(scan_results)
          @scan_results = scan_results
          @resolver = Ace::Support::Items::Molecules::ShortcutResolver.new(
            scan_results,
            full_id_length: FULL_ID_LENGTH
          )
        end

        # Resolve a task reference to a ScanResult.
        # Handles full IDs, shortcuts, and subtask references.
        #
        # @param ref [String] Task reference (full ID, short, suffix, or subtask)
        # @param on_ambiguity [Proc, nil] Called with array of matches on ambiguity
        # @return [ScanResult, nil]
        def resolve(ref, on_ambiguity: nil)
          return nil if ref.nil? || ref.empty?

          cleaned = ref.strip.downcase

          # Check for full subtask reference first: "8pp.t.q7w.a"
          if (subtask_match = cleaned.match(SUBTASK_REF_PATTERN))
            return resolve_subtask(subtask_match[1], subtask_match[2])
          end

          # Check for short subtask reference: "q7w.a" or "t.q7w.a"
          if (short_sub = cleaned.match(SHORT_SUBTASK_REF_PATTERN))
            suffix = short_sub[1]
            subtask_char = short_sub[2]
            parent_result = @resolver.resolve(suffix)
            return resolve_subtask(parent_result.id, subtask_char) if parent_result
          end

          normalized = normalize_ref(cleaned)
          @resolver.resolve(normalized, on_ambiguity: on_ambiguity)
        end

        private

        def normalize_ref(ref)
          # Check for short ref pattern: "t.q7w" → "q7w"
          if (match = ref.match(SHORT_REF_PATTERN))
            match[1]
          else
            ref
          end
        end

        # Resolve a subtask reference by finding the parent's scan result,
        # then looking for the subtask folder within that parent's directory.
        # Supports both new short format ("0-slug") and legacy format ("8pp.t.q7w.0-slug").
        def resolve_subtask(parent_id, subtask_char)
          parent_result = @scan_results.find { |sr| sr.id == parent_id }
          return nil unless parent_result

          subtask_id = "#{parent_id}.#{subtask_char}"

          Dir.entries(parent_result.dir_path).sort.each do |entry|
            next if entry.start_with?(".")

            full_path = File.join(parent_result.dir_path, entry)
            next unless File.directory?(full_path)

            slug = nil

            # New short format: "0-slug" or "a-slug"
            if (short_match = entry.match(/^([a-z0-9])-(.+)$/))
              next unless short_match[1] == subtask_char
              slug = short_match[2]
            # Legacy format: "8pp.t.q7w.0-slug"
            elsif (legacy_match = entry.match(/^([0-9a-z]{3}\.[a-z]\.[0-9a-z]{3}\.[a-z0-9])-?(.*)$/))
              next unless legacy_match[1] == subtask_id
              slug = legacy_match[2].empty? ? entry : legacy_match[2]
            else
              next
            end

            spec_files = Dir.glob(File.join(full_path, "*.s.md"))
            next if spec_files.empty?

            return Ace::Support::Items::Models::ScanResult.new(
              id: subtask_id,
              slug: slug,
              folder_name: entry,
              dir_path: full_path,
              file_path: spec_files.first,
              special_folder: parent_result.special_folder
            )
          end

          nil
        end
      end
    end
  end
end
