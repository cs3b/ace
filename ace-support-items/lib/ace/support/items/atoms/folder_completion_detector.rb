# frozen_string_literal: true

require_relative "frontmatter_parser"

module Ace
  module Support
    module Items
      module Atoms
        # Detects whether all spec files in a folder have terminal status.
        # Used by orchestrator auto-archive: when all subtasks are done/skipped/blocked,
        # the parent can be auto-archived.
        class FolderCompletionDetector
          TERMINAL_STATUSES = %w[done skipped blocked].freeze

          # Check if all spec files in a directory have terminal status.
          #
          # @param dir_path [String] Directory to check
          # @param spec_pattern [String] Glob pattern for spec files (default: "*.s.md")
          # @param terminal_statuses [Array<String>] Statuses considered terminal
          # @param recursive [Boolean] If true, also check one level of subdirectories
          # @return [Boolean] True if all found specs have terminal status; false if none found
          def self.all_terminal?(dir_path, spec_pattern: "*.s.md", terminal_statuses: TERMINAL_STATUSES, recursive: false)
            patterns = [File.join(dir_path, spec_pattern)]
            patterns << File.join(dir_path, "*", spec_pattern) if recursive

            files = patterns.flat_map { |p| Dir.glob(p) }
            return false if files.empty?

            files.all? do |file|
              content = File.read(file)
              frontmatter, = FrontmatterParser.parse(content)
              status = frontmatter["status"].to_s.downcase
              terminal_statuses.include?(status)
            end
          end
        end
      end
    end
  end
end
