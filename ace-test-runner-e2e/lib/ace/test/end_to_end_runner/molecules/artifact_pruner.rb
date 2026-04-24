# frozen_string_literal: true

require "fileutils"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Prunes stale E2E run artifacts while preserving suite reports and runtime cache.
        class ArtifactPruner
          ROOT_RELATIVE_PATH = File.join(".ace-local", "test-e2e")
          PRESERVED_DIRECTORY_NAMES = %w[runtime-cache].freeze
          PRESERVED_FILE_PATTERNS = [
            /-suite-report\.md\z/,
            /-suite-final-report\.md\z/
          ].freeze

          def prune(base_dir: Dir.pwd)
            root = File.join(File.expand_path(base_dir), ROOT_RELATIVE_PATH)
            return summary(root, [], []) unless Dir.exist?(root)

            removed_paths = []
            preserved_paths = []

            Dir.children(root).sort.each do |entry|
              path = File.join(root, entry)
              if preserve_entry?(entry, path)
                preserved_paths << path
              else
                FileUtils.rm_rf(path)
                removed_paths << path
              end
            end

            summary(root, removed_paths, preserved_paths)
          end

          private

          def preserve_entry?(entry, path)
            return true if File.directory?(path) && PRESERVED_DIRECTORY_NAMES.include?(entry)
            return false unless File.file?(path)

            PRESERVED_FILE_PATTERNS.any? { |pattern| pattern.match?(entry) }
          end

          def summary(root, removed_paths, preserved_paths)
            {
              root: root,
              root_display: ROOT_RELATIVE_PATH,
              removed_paths: removed_paths,
              preserved_paths: preserved_paths,
              deleted_count: removed_paths.length,
              preserved_count: preserved_paths.length
            }
          end
        end
      end
    end
  end
end
