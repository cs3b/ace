# frozen_string_literal: true

require "pathname"

module Ace
  module Support
    module Items
      module Atoms
        # Detects and normalizes "special" folder names used for item organization.
        # Special folders use underscore prefix convention (e.g., _archive, _maybe).
        # Short names (without underscore) are auto-expanded: "archive" => "_archive".
        class SpecialFolderDetector
          # Built-in special folders
          SPECIAL_FOLDERS = %w[_archive _maybe _anytime].freeze

          # Short-name aliases for convenience
          SHORT_ALIASES = {
            "archive" => "_archive",
            "maybe" => "_maybe",
            "anytime" => "_anytime"
          }.freeze

          # Virtual filters — not physical folders, used for list filtering
          VIRTUAL_FILTERS = { "next" => :next, "all" => :all }.freeze

          # Check if a name is a virtual filter
          # @param name [String] The name to check
          # @return [Symbol, nil] :next, :all, or nil
          def self.virtual_filter?(name)
            return nil if name.nil? || name.empty?

            VIRTUAL_FILTERS[name.downcase]
          end

          # Detect if a folder name is a special folder
          # @param folder_name [String] The folder name to check
          # @return [Boolean] True if it's a special folder
          def self.special?(folder_name)
            return false if folder_name.nil? || folder_name.empty?

            normalized = normalize(folder_name)
            normalized.start_with?("_")
          end

          # Normalize a folder name to its canonical form
          # Short names are expanded: "archive" => "_archive"
          # Underscore-prefixed names are returned as-is
          # @param folder_name [String] The folder name to normalize
          # @return [String] Canonical folder name
          def self.normalize(folder_name)
            return folder_name if folder_name.nil? || folder_name.empty?

            # Check short aliases first
            return SHORT_ALIASES[folder_name.downcase] if SHORT_ALIASES.key?(folder_name.downcase)

            # Already has underscore prefix - return as-is
            folder_name
          end

          # Extract the special folder from a path (if any)
          # Returns the first path component that is a special folder
          # @param path [String] File path to inspect
          # @param root [String] Root path to make path relative
          # @return [String, nil] Special folder name or nil
          def self.detect_in_path(path, root: nil)
            check_path = if root
              begin
                Pathname.new(path).relative_path_from(Pathname.new(root)).to_s
              rescue ArgumentError
                path
              end
            else
              path
            end

            parts = check_path.split(File::SEPARATOR).reject(&:empty?)
            parts.find { |part| special?(part) }
          end
        end
      end
    end
  end
end
