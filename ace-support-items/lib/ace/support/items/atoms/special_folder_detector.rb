# frozen_string_literal: true

require "pathname"

module Ace
  module Support
    module Items
      module Atoms
        # Detects and normalizes "special" folder names used for item organization.
        # Special folders use a configurable prefix convention (default: "_").
        # Short names (without prefix) are auto-expanded: "archive" => "_archive".
        class SpecialFolderDetector
          # Default prefix for special folders (single source of truth)
          DEFAULT_PREFIX = "_"

          # Virtual filters — not physical folders, used for list filtering
          VIRTUAL_FILTERS = { "next" => :next, "all" => :all }.freeze

          # Aliases that mean "move back to root" (no special folder).
          # "next" is the primary label; "root" and "/" are convenience aliases.
          MOVE_TO_ROOT_ALIASES = %w[next root /].freeze

          # Check if a name means "move to root" (out of any special folder).
          # @param name [String] The name to check
          # @return [Boolean] True if the name is a move-to-root alias
          def self.move_to_root?(name)
            return false if name.nil? || name.empty?

            MOVE_TO_ROOT_ALIASES.include?(name.downcase)
          end

          # Check if a name is a virtual filter
          # @param name [String] The name to check
          # @return [Symbol, nil] :next, :all, or nil
          def self.virtual_filter?(name)
            return nil if name.nil? || name.empty?

            VIRTUAL_FILTERS[name.downcase]
          end

          # Detect if a folder name is a special folder
          # @param folder_name [String] The folder name to check
          # @param prefix [String] The prefix that marks special folders
          # @return [Boolean] True if it's a special folder
          def self.special?(folder_name, prefix: DEFAULT_PREFIX)
            return false if folder_name.nil? || folder_name.empty?

            folder_name.start_with?(prefix)
          end

          # Normalize a folder name to its canonical form
          # Short names are expanded: "archive" => "_archive"
          # Already-prefixed names are returned as-is
          # Virtual filters are returned as-is (not expanded)
          # @param folder_name [String] The folder name to normalize
          # @param prefix [String] The prefix to prepend for expansion
          # @return [String] Canonical folder name
          def self.normalize(folder_name, prefix: DEFAULT_PREFIX)
            return folder_name if folder_name.nil? || folder_name.empty?
            return folder_name if folder_name.start_with?(prefix)
            return folder_name if VIRTUAL_FILTERS.key?(folder_name.downcase)
            return folder_name if folder_name.include?(File::SEPARATOR) || folder_name.include?("..")

            "#{prefix}#{folder_name}"
          end

          # Strip the special folder prefix to get the short display name
          # @param folder_name [String] The folder name (e.g. "_archive")
          # @param prefix [String] The prefix to strip
          # @return [String] Short name (e.g. "archive")
          def self.short_name(folder_name, prefix: DEFAULT_PREFIX)
            return folder_name if folder_name.nil? || folder_name.empty?

            folder_name.delete_prefix(prefix)
          end

          # Extract the special folder from a path (if any)
          # Returns the first path component that is a special folder
          # @param path [String] File path to inspect
          # @param root [String] Root path to make path relative
          # @param prefix [String] The prefix that marks special folders
          # @return [String, nil] Special folder name or nil
          def self.detect_in_path(path, root: nil, prefix: DEFAULT_PREFIX)
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
            parts.find { |part| special?(part, prefix: prefix) }
          end
        end
      end
    end
  end
end
