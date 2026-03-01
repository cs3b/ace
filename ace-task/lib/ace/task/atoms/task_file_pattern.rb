# frozen_string_literal: true

module Ace
  module Task
    module Atoms
      # Glob patterns and matching logic for task spec files.
      # Tasks use `.s.md` extension but exclude `.idea.s.md` (ideas).
      # Subtask files are distinguished from primary files by their ID suffix.
      module TaskFilePattern
        # Pattern matching all spec files
        SPEC_PATTERN = "*.s.md"

        # Pattern to exclude idea spec files
        IDEA_PATTERN = "*.idea.s.md"

        # Subtask ID pattern: parent ID + dot + single char (e.g., "8pp.t.q7w.a")
        SUBTASK_ID_REGEX = /^([0-9a-z]{3}\.[a-z]\.[0-9a-z]{3})\.([a-z0-9])$/

        # Check if a spec file is the primary file for its containing folder.
        # The primary file's ID prefix matches the folder's ID prefix exactly.
        # Subtask files have an additional `.{char}` suffix.
        #
        # @param filename [String] Spec filename (e.g., "8pp.t.q7w-fix-login.s.md")
        # @param folder_id [String] ID extracted from folder name (e.g., "8pp.t.q7w")
        # @return [Boolean]
        def self.primary_file?(filename, folder_id)
          return false if filename.end_with?(".idea.s.md")

          # Extract ID from filename: "8pp.t.q7w-fix-login.s.md" → "8pp.t.q7w"
          # or subtask: "8pp.t.q7w.a-setup-db.s.md" → "8pp.t.q7w.a"
          file_id = extract_id_from_filename(filename)
          return false unless file_id

          file_id == folder_id
        end

        # Check if a spec file is a subtask file.
        #
        # @param filename [String] Spec filename
        # @return [Boolean]
        def self.subtask_file?(filename)
          return false if filename.end_with?(".idea.s.md")

          file_id = extract_id_from_filename(filename)
          return false unless file_id

          file_id.match?(SUBTASK_ID_REGEX)
        end

        # Extract the task ID from a spec filename.
        # "8pp.t.q7w-fix-login.s.md" → "8pp.t.q7w"
        # "8pp.t.q7w.a-setup-db.s.md" → "8pp.t.q7w.a"
        #
        # @param filename [String] Spec filename
        # @return [String, nil] Extracted ID or nil
        def self.extract_id_from_filename(filename)
          # Remove .s.md extension
          base = filename.sub(/\.s\.md$/, "")
          return nil if base == filename # No .s.md extension

          # Match task ID at start: "8pp.t.q7w" or "8pp.t.q7w.a"
          match = base.match(/^([0-9a-z]{3}\.[a-z]\.[0-9a-z]{3}(?:\.[a-z0-9])?)/)
          match&.[](1)
        end
      end
    end
  end
end
